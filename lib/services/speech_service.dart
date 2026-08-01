// lib/app/data/services/speech_service.dart

import 'dart:async';

import 'package:get/get.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// Wraps speech_to_text for voice command listening.
class SpeechService extends GetxService {
  final stt.SpeechToText _speech = stt.SpeechToText();

  final RxBool isListening = false.obs;
  final RxBool isAvailable = false.obs;
  final RxString lastWords = ''.obs;
  final RxDouble confidence = 0.0.obs;

  Completer<String>? _resultCompleter;

  Future<SpeechService> init() async {
    isAvailable.value = await _speech.initialize(
      onError: (error) {
        isListening.value = false;
        if (_resultCompleter != null && !_resultCompleter!.isCompleted) {
          _resultCompleter!.complete(lastWords.value);
        }
      },
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          isListening.value = false;
          if (_resultCompleter != null && !_resultCompleter!.isCompleted) {
            _resultCompleter!.complete(lastWords.value);
          }
        }
      },
    );
    return this;
  }

  /// Start listening and return a Future that completes with the recognized text.
  Future<String> listenForCommand({
    Duration timeout = const Duration(seconds: 10),
    String listenFor = 'en_US',
  }) async {
    if (!isAvailable.value) return '';

    lastWords.value = '';
    confidence.value = 0.0;
    _resultCompleter = Completer<String>();

    await _speech.listen(
      onResult: _onResult,
      listenFor: timeout,
      localeId: listenFor,
      cancelOnError: true,
      partialResults: true,
      listenMode: stt.ListenMode.dictation,
    );
    isListening.value = true;

    // Wait for result with timeout
    final result = await _resultCompleter!.future.timeout(
      timeout + const Duration(seconds: 2),
      onTimeout: () {
        stopListening();
        return lastWords.value;
      },
    );

    return result.trim();
  }

  /// Listen continuously and call onPartial with interim results.
  /// Completes when user stops speaking or timeout.
  Future<String> listenContinuous({
    Duration timeout = const Duration(seconds: 15),
    void Function(String partial)? onPartial,
  }) async {
    if (!isAvailable.value) return '';

    lastWords.value = '';
    _resultCompleter = Completer<String>();

    await _speech.listen(
      onResult: (result) {
        lastWords.value = result.recognizedWords;
        confidence.value = result.confidence;
        onPartial?.call(result.recognizedWords);

        if (result.finalResult) {
          if (_resultCompleter != null && !_resultCompleter!.isCompleted) {
            _resultCompleter!.complete(result.recognizedWords);
          }
        }
      },
      listenFor: timeout,
      localeId: 'en_US',
      cancelOnError: false,
      partialResults: true,
      listenMode: stt.ListenMode.dictation,
    );
    isListening.value = true;

    return _resultCompleter!.future.timeout(
      timeout + const Duration(seconds: 2),
      onTimeout: () {
        stopListening();
        return lastWords.value;
      },
    );
  }

  void _onResult(SpeechRecognitionResult result) {
    lastWords.value = result.recognizedWords;
    confidence.value = result.confidence;

    if (result.finalResult) {
      if (_resultCompleter != null && !_resultCompleter!.isCompleted) {
        _resultCompleter!.complete(result.recognizedWords);
      }
    }
  }

  Future<void> stopListening() async {
    await _speech.stop();
    isListening.value = false;
  }

  @override
  void onClose() {
    _speech.stop();
    super.onClose();
  }
}
