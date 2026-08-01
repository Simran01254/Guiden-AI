import 'dart:io';

import 'package:archive/archive.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Centralised Dio instance
// ─────────────────────────────────────────────────────────────────────────────

/// Shared [Dio] instance used across the entire app.
/// Configure interceptors, base options, and auth headers here.
class AppDio {
  AppDio._();

  static final Dio instance = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(minutes: 5),
      sendTimeout: const Duration(seconds: 30),
    ),
  )..interceptors.add(
      LogInterceptor(
        requestBody: false,
        responseBody: false,
        logPrint: (o) => debugPrint('[AppDio] $o'),
      ),
    );
}

// ─────────────────────────────────────────────────────────────────────────────
// YOLO11n Model Manager
// ─────────────────────────────────────────────────────────────────────────────

/// Manages YOLO11n model resolution with a local-cache-first strategy.
///
/// **Android**: looks for `yolo11n.tflite` in Documents; downloads if absent.
/// **iOS**: looks for `yolo11n.mlpackage` in Documents; tries bundled asset
///   zip first, then downloads from GitHub if not found.
class YoloModelManager {
  static const String _modelName = 'yolo11n';
  static const String _releaseBaseUrl =
      'https://github.com/ultralytics/yolo-flutter-app/releases/download/v0.0.0';

  /// Progress callback (0.0 → 1.0) during model download.
  final void Function(double progress)? onDownloadProgress;

  /// Human-readable status messages for the loading UI.
  final void Function(String message)? onStatusUpdate;

  YoloModelManager({this.onDownloadProgress, this.onStatusUpdate});

  // ─── Entry point ─────────────────────────────────────────────────────────

  Future<String?> getModelPath() async {
    try {
      if (Platform.isAndroid) return await _resolveAndroid();
      if (Platform.isIOS) return await _resolveIOS();
      return null;
    } catch (e, st) {
      _status('Unexpected error: $e');
      debugPrint('[YoloModelManager] $e\n$st');
      return null;
    }
  }

  // ─── Android ─────────────────────────────────────────────────────────────

  Future<String?> _resolveAndroid() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$_modelName.tflite');

    // 1 · Cache hit → return immediately.
    if (await _isValidFile(file)) {
      _status('Model ready ✓');
      debugPrint('[YoloModelManager] Using cached model: ${file.path}');
      return file.path;
    }

    // 2 · Download with Dio + progress.
    _status('Downloading $_modelName…');
    final url = '$_releaseBaseUrl/$_modelName.tflite';
    debugPrint('[YoloModelManager] Downloading from $url');

    try {
      await AppDio.instance.download(
        url,
        file.path,
        onReceiveProgress: (rcv, total) {
          if (total > 0) onDownloadProgress?.call(rcv / total);
        },
        options: Options(responseType: ResponseType.bytes),
      );

      if (await _isValidFile(file)) {
        onDownloadProgress?.call(1.0);
        _status('Model ready ✓');
        debugPrint('[YoloModelManager] Download complete: ${file.path}');
        return file.path;
      }

      // Incomplete download — remove to avoid stale file next run.
      await _deleteQuietly(file);
      _status('Download incomplete — check your internet connection');
      return null;
    } on DioException catch (e) {
      await _deleteQuietly(file);
      final msg = _friendlyDioError(e);
      _status(msg);
      debugPrint('[YoloModelManager] DioException: $e');
      return null;
    }
  }

  // ─── iOS ─────────────────────────────────────────────────────────────────

  Future<String?> _resolveIOS() async {
    final dir = await getApplicationDocumentsDirectory();
    final modelDir = Directory('${dir.path}/$_modelName.mlpackage');

    // 1 · Cache hit.
    if (await _isValidMlpackage(modelDir)) {
      _status('Model ready ✓');
      return modelDir.path;
    }

    // Remove corrupted/partial directory.
    if (await modelDir.exists()) {
      await modelDir.delete(recursive: true);
    }

    // 2 · Try bundled asset zip.
    try {
      _status('Loading bundled model…');
      final data = await rootBundle.load(
          'assets/models/$_modelName.mlpackage.zip');
      final bytes = data.buffer.asUint8List();
      final result = await _extractZip(bytes: bytes, targetDir: modelDir);
      if (result != null) {
        _status('Model ready ✓');
        return result;
      }
    } catch (_) {
      // No bundled asset — fall through.
    }

    // 3 · Download zip from GitHub.
    _status('Downloading $_modelName…');
    final tmpZip =
        File('${dir.path}/$_modelName.mlpackage_download.zip');

    try {
      await AppDio.instance.download(
        '$_releaseBaseUrl/$_modelName.mlpackage.zip',
        tmpZip.path,
        onReceiveProgress: (rcv, total) {
          if (total > 0) onDownloadProgress?.call(rcv / total);
        },
      );

      final bytes = await tmpZip.readAsBytes();
      final result = await _extractZip(bytes: bytes, targetDir: modelDir);
      await _deleteQuietly(tmpZip);

      if (result != null) {
        onDownloadProgress?.call(1.0);
        _status('Model ready ✓');
        return result;
      }
      _status('Extraction failed — please retry');
      return null;
    } on DioException catch (e) {
      await _deleteQuietly(tmpZip);
      _status(_friendlyDioError(e));
      debugPrint('[YoloModelManager] DioException: $e');
      return null;
    }
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  /// File is valid if it exists and has more than 1 KB of content.
  Future<bool> _isValidFile(File f) async =>
      await f.exists() && await f.length() > 1024;

  /// `.mlpackage` is valid when the `Manifest.json` sentinel exists.
  Future<bool> _isValidMlpackage(Directory d) async =>
      await d.exists() &&
      await File('${d.path}/Manifest.json').exists();

  Future<void> _deleteQuietly(FileSystemEntity e) async {
    try {
      if (await e.exists()) {
        if (e is Directory) {
          await e.delete(recursive: true);
        } else {
          await e.delete();
        }
      }
    } catch (_) {}
  }

  /// Extracts a zip [bytes] into [targetDir], stripping the top-level
  /// `.mlpackage` directory prefix when present.
  Future<String?> _extractZip({
    required List<int> bytes,
    required Directory targetDir,
  }) async {
    try {
      _status('Extracting model…');
      final archive = ZipDecoder().decodeBytes(bytes);
      await targetDir.create(recursive: true);

      // Detect & strip top-level prefix.
      String? prefix;
      if (archive.files.isNotEmpty) {
        final first = archive.files.first.name;
        if (first.contains('/') &&
            first.split('/').first.endsWith('.mlpackage')) {
          final top = first.split('/').first;
          if (archive.files
              .every((f) => f.name.startsWith('$top/') || f.name == top)) {
            prefix = '$top/';
          }
        }
      }

      for (final entry in archive) {
        var name = entry.name;
        if (prefix != null) {
          if (name.startsWith(prefix)) {
            name = name.substring(prefix.length);
          } else if (name == prefix.replaceAll('/', '')) {
            continue;
          }
        }
        if (name.isEmpty) continue;
        if (entry.isFile) {
          final out = File('${targetDir.path}/$name');
          await out.parent.create(recursive: true);
          await out.writeAsBytes(entry.content as List<int>);
        }
      }
      return targetDir.path;
    } catch (e) {
      debugPrint('[YoloModelManager] Extraction error: $e');
      await _deleteQuietly(targetDir);
      return null;
    }
  }

  String _friendlyDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Download timed out — check your internet connection';
      case DioExceptionType.connectionError:
        return 'No internet connection — could not download model';
      case DioExceptionType.badResponse:
        return 'Server error (${e.response?.statusCode}) — try again later';
      default:
        return 'Download failed: ${e.message}';
    }
  }

  void _status(String msg) => onStatusUpdate?.call(msg);
}
