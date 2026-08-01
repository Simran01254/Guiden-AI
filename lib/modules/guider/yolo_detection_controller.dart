import 'package:get/get.dart';
import 'package:ultralytics_yolo/models/yolo_result.dart';
import 'package:ultralytics_yolo/yolo_performance_metrics.dart';
import 'package:ultralytics_yolo/widgets/yolo_controller.dart';
import 'package:ultralytics_yolo/yolo_view.dart';

import '../../services/yolo_model_manager.dart';

/// GetX controller that manages real-time YOLO11n object detection state.
class YoloDetectionController extends GetxController {
  // ─── Detection state ──────────────────────────────────────────────────────
  final RxInt detectionCount = 0.obs;
  final RxDouble currentFps = 0.0.obs;
  final RxList<YOLOResult> detections = <YOLOResult>[].obs;

  // ─── Thresholds (also passed directly into YOLOView widget props) ─────────
  final RxDouble confidenceThreshold = 0.5.obs;
  final RxDouble iouThreshold = 0.45.obs;
  final RxInt numItemsThreshold = 30.obs;

  // ─── Model state ──────────────────────────────────────────────────────────
  final RxBool isModelLoading = true.obs;
  final RxnString modelPath = RxnString();
  final RxString loadingMessage = 'Initializing…'.obs;
  final RxDouble downloadProgress = 0.0.obs;

  // ─── Camera state ─────────────────────────────────────────────────────────
  final Rx<LensFacing> lensFacing = LensFacing.back.obs;
  final RxDouble currentZoomLevel = 1.0.obs;

  bool get isFrontCamera => lensFacing.value == LensFacing.front;

  // ─── YOLO view controller (talks to native layer) ─────────────────────────
  final yoloController = YOLOViewController();

  // ─── Internals ────────────────────────────────────────────────────────────
  late final YoloModelManager _modelManager;

  @override
  void onInit() {
    super.onInit();
    _modelManager = YoloModelManager(
      onDownloadProgress: (p) => downloadProgress.value = p,
      onStatusUpdate: (msg) => loadingMessage.value = msg,
    );
    _loadModel();
  }

  // ─── Model loading ────────────────────────────────────────────────────────

  Future<void> _loadModel() async {
    isModelLoading.value = true;
    downloadProgress.value = 0.0;
    detectionCount.value = 0;
    currentFps.value = 0.0;

    try {
      final path = await _modelManager.getModelPath();
      modelPath.value = path;
      loadingMessage.value = path == null ? 'Failed to load yolo11n model' : '';
    } catch (e) {
      loadingMessage.value = 'Error loading model: $e';
    } finally {
      isModelLoading.value = false;
    }
  }

  // ─── Detection callbacks ──────────────────────────────────────────────────

  /// Called by YOLOView on each inference frame.
  void onDetectionResults(List<YOLOResult> results) {
    detections.value = results;
    detectionCount.value = results.length;
  }

  /// Called by YOLOView with native performance metrics.
  void onPerformanceMetrics(YOLOPerformanceMetrics metrics) {
    final fps = metrics.fps;
    if ((currentFps.value - fps).abs() > 0.1) {
      currentFps.value = fps;
    }
  }

  // ─── Camera controls ──────────────────────────────────────────────────────

  void flipCamera() {
    lensFacing.value =
        lensFacing.value == LensFacing.back ? LensFacing.front : LensFacing.back;
    if (isFrontCamera) currentZoomLevel.value = 1.0;
    yoloController.switchCamera();
  }

  void setZoomLevel(double zoom) {
    if ((currentZoomLevel.value - zoom).abs() > 0.01) {
      currentZoomLevel.value = zoom;
      yoloController.setZoomLevel(zoom);
    }
  }

  // ─── Threshold controls ───────────────────────────────────────────────────
  // Note: since these are passed as widget props to YOLOView, the parent
  // Obx rebuild automatically sends them to native when they change.

  void setConfidence(double value) {
    if ((confidenceThreshold.value - value).abs() > 0.005) {
      confidenceThreshold.value = value;
    }
  }

  void setIou(double value) {
    if ((iouThreshold.value - value).abs() > 0.005) {
      iouThreshold.value = value;
    }
  }

  void setNumItems(int value) {
    if (numItemsThreshold.value != value) {
      numItemsThreshold.value = value;
      yoloController.setNumItemsThreshold(value);
    }
  }
}
