import 'package:get/get.dart';

class DetectionSettings {
  // ── Presence ──
  final presenceThreshold = 0.65.obs;

  // ── Processing ──
  final processingIntervalMs = 100.obs; // lower = faster but more CPU
  final useGpuDelegate = true.obs;
  final resolutionIndex = 1.obs; // 0=low, 1=medium, 2=high

  // ── Smoothing ──
  final smoothingWindow = 4.obs;
  final noHandFrameThreshold = 3.obs;

  // ── Finger Thresholds ──
  final fingerExtendThreshold = 0.50.obs;
  final fingerFoldThreshold = 0.35.obs;
  final thumbExtendThreshold = 0.55.obs;
  final thumbDirectionThreshold = 0.20.obs;

  // ── Fist Validation ──
  final fistPalmRatio = 0.65.obs;

  // ── Display ──
  final showLandmarks = true.obs;
  final showDebugPanel = true.obs;
  final showFPS = true.obs;
  final showConfidenceBar = true.obs;
  final landmarkDotSize = 5.0.obs;
  final landmarkLineWidth = 3.0.obs;

  // ── Advanced ──
  final minLandmarkSpread = 0.05.obs;
  final imageRotationAngle = (-90.0).obs; // iOS default

  String get resolutionName {
    switch (resolutionIndex.value) {
      case 0:
        return 'Low (352×288)';
      case 1:
        return 'Medium (640×480)';
      case 2:
        return 'High (1280×720)';
      default:
        return 'Medium';
    }
  }

  // Presets
  void applyFastPreset() {
    processingIntervalMs.value = 150;
    smoothingWindow.value = 3;
    resolutionIndex.value = 0;
    showLandmarks.value = false;
    showDebugPanel.value = false;
  }

  void applyBalancedPreset() {
    processingIntervalMs.value = 100;
    smoothingWindow.value = 4;
    resolutionIndex.value = 1;
    showLandmarks.value = true;
    showDebugPanel.value = true;
  }

  void applyAccuratePreset() {
    processingIntervalMs.value = 80;
    smoothingWindow.value = 5;
    resolutionIndex.value = 1;
    presenceThreshold.value = 0.6;
    fingerExtendThreshold.value = 0.45;
    fingerFoldThreshold.value = 0.30;
    thumbExtendThreshold.value = 0.50;
    thumbDirectionThreshold.value = 0.15;
    showLandmarks.value = true;
    showDebugPanel.value = true;
  }

  void resetDefaults() {
    presenceThreshold.value = 0.65;
    processingIntervalMs.value = 100;
    smoothingWindow.value = 4;
    noHandFrameThreshold.value = 3;
    fingerExtendThreshold.value = 0.50;
    fingerFoldThreshold.value = 0.35;
    thumbExtendThreshold.value = 0.55;
    thumbDirectionThreshold.value = 0.20;
    fistPalmRatio.value = 0.65;
    showLandmarks.value = true;
    showDebugPanel.value = true;
    showFPS.value = true;
    showConfidenceBar.value = true;
    minLandmarkSpread.value = 0.05;
    landmarkDotSize.value = 5.0;
    landmarkLineWidth.value = 3.0;
    resolutionIndex.value = 1;
  }
}
