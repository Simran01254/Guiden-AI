import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ultralytics_yolo/models/yolo_task.dart';
import 'package:ultralytics_yolo/yolo_view.dart';

import 'yolo_detection_controller.dart';

/// Full-screen real-time YOLO11n object detection view (GetX).
class YoloDetectionView extends GetView<YoloDetectionController> {
  const YoloDetectionView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Obx(() {
        // ── Loading state ─────────────────────────────────────────────────
        if (controller.isModelLoading.value) {
          return _LoadingOverlay(
            message: controller.loadingMessage.value,
            progress: controller.downloadProgress.value,
          );
        }

        // ── Error state ───────────────────────────────────────────────────
        if (controller.modelPath.value == null) {
          return _ErrorOverlay(message: controller.loadingMessage.value);
        }

        // ── Live detection ────────────────────────────────────────────────
        return Stack(
          children: [
            // YOLOView with reactive thresholds & lens facing.
            // Rebuilds whenever confidence, iou, or lensFacing changes.
            Obx(
              () => YOLOView(
                modelPath: controller.modelPath.value!,
                task: YOLOTask.detect,
                controller: controller.yoloController,
                confidenceThreshold: controller.confidenceThreshold.value,
                iouThreshold: controller.iouThreshold.value,
                lensFacing: controller.lensFacing.value,
                showNativeUI: false,
                showOverlays: true,
                onResult: controller.onDetectionResults,
                onPerformanceMetrics: controller.onPerformanceMetrics,
                onZoomChanged: (z) => controller.currentZoomLevel.value = z,
              ),
            ),

            // ── Top HUD ──────────────────────────────────────────────────
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _HudButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      onTap: () => Get.back(),
                    ),
                    Row(
                      children: [
                        Obx(() => _StatBadge(
                              label: 'FPS',
                              value: controller.currentFps.value
                                  .toStringAsFixed(1),
                              color: Colors.green.shade400,
                            )),
                        const SizedBox(width: 8),
                        Obx(() => _StatBadge(
                              label: 'OBJ',
                              value:
                                  '${controller.detectionCount.value}',
                              color: Colors.blue.shade300,
                            )),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ── Bottom controls ───────────────────────────────────────────
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _BottomControls(controller: controller),
            ),
          ],
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Loading overlay
// ─────────────────────────────────────────────────────────────────────────────

class _LoadingOverlay extends StatelessWidget {
  const _LoadingOverlay(
      {required this.message, required this.progress});
  final String message;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.camera_alt_outlined,
                color: Colors.white54, size: 64),
            const SizedBox(height: 24),
            const Text(
              'YOLO11n',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Real-Time Object Detection',
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 240,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress > 0 ? progress : null,
                  backgroundColor: Colors.white12,
                  valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.blue.shade400),
                  minHeight: 6,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message.isEmpty ? 'Loading…' : message,
              style:
                  const TextStyle(color: Colors.white54, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            if (progress > 0) ...[
              const SizedBox(height: 4),
              Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Error overlay
// ─────────────────────────────────────────────────────────────────────────────

class _ErrorOverlay extends StatelessWidget {
  const _ErrorOverlay({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                color: Colors.redAccent, size: 64),
            const SizedBox(height: 16),
            const Text(
              'Model Load Failed',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                message,
                style:
                    const TextStyle(color: Colors.white54, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: () => Get.back(),
              icon: const Icon(Icons.arrow_back, color: Colors.white70),
              label: const Text('Go back',
                  style: TextStyle(color: Colors.white70)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HUD helpers
// ─────────────────────────────────────────────────────────────────────────────

class _StatBadge extends StatelessWidget {
  const _StatBadge(
      {required this.label,
      required this.value,
      required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.6), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5)),
          const SizedBox(width: 4),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _HudButton extends StatelessWidget {
  const _HudButton(
      {required this.icon, required this.onTap, this.active});
  final IconData icon;
  final VoidCallback onTap;
  final bool? active;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: (active == true)
              ? Colors.blue.withValues(alpha: 0.7)
              : Colors.black54,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white24),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom controls panel
// ─────────────────────────────────────────────────────────────────────────────

class _BottomControls extends StatelessWidget {
  const _BottomControls({required this.controller});
  final YoloDetectionController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black87],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Confidence slider
          _ThresholdRow(
            label: 'Confidence',
            icon: Icons.tune,
            color: Colors.orange.shade300,
            rxValue: controller.confidenceThreshold,
            min: 0.1,
            max: 0.95,
            onChanged: controller.setConfidence,
          ),
          const SizedBox(height: 8),
          // IoU slider
          _ThresholdRow(
            label: 'IoU',
            icon: Icons.crop_free,
            color: Colors.purple.shade300,
            rxValue: controller.iouThreshold,
            min: 0.1,
            max: 0.95,
            onChanged: controller.setIou,
          ),
          const SizedBox(height: 16),
          // Zoom + camera flip
          Row(
            children: [
              const Icon(Icons.zoom_in,
                  color: Colors.white54, size: 18),
              Expanded(
                child: Obx(
                  () => Slider(
                    value: controller.currentZoomLevel.value
                        .clamp(1.0, 5.0),
                    min: 1.0,
                    max: 5.0,
                    divisions: 40,
                    activeColor: Colors.white70,
                    inactiveColor: Colors.white24,
                    onChanged: controller.setZoomLevel,
                  ),
                ),
              ),
              const Icon(Icons.zoom_out,
                  color: Colors.white54, size: 18),
              const SizedBox(width: 12),
              Obx(
                () => _HudButton(
                  icon: Icons.flip_camera_ios_rounded,
                  onTap: controller.flipCamera,
                  active: controller.isFrontCamera,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ThresholdRow extends StatelessWidget {
  const _ThresholdRow({
    required this.label,
    required this.icon,
    required this.color,
    required this.rxValue,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final IconData icon;
  final Color color;
  final RxDouble rxValue;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 6),
        SizedBox(
          width: 72,
          child: Text(label,
              style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ),
        Expanded(
          child: Obx(
            () => Slider(
              value: rxValue.value.clamp(min, max),
              min: min,
              max: max,
              divisions: 85,
              activeColor: color,
              inactiveColor: Colors.white12,
              onChanged: onChanged,
            ),
          ),
        ),
        Obx(
          () => SizedBox(
            width: 36,
            child: Text(
              rxValue.value.toStringAsFixed(2),
              style: const TextStyle(
                  color: Colors.white70, fontSize: 11),
              textAlign: TextAlign.right,
            ),
          ),
        ),
      ],
    );
  }
}
