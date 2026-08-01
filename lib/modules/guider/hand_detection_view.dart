import 'dart:async';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart' hide GestureDetector;
import 'package:hand_landmarker/hand_landmarker.dart';

import '../../main.dart';
import '../../services/hand_detector.dart';

final List<CameraDescription> _cameras = cameras;

class HandDetectionView extends StatefulWidget {
  const HandDetectionView({super.key});

  @override
  State<HandDetectionView> createState() => _HandDetectionViewState();
}

class _HandDetectionViewState extends State<HandDetectionView> {
  CameraController? _controller;
  HandLandmarkerPlugin? _plugin;
  List<Hand> _landmarks = [];
  bool _isInitialized = false;
  bool _isDetecting = false;

  // Add gesture state
  HandGesture _currentGesture = HandGesture.unknown;

  // For gesture smoothing (optional but recommended)
  final List<HandGesture> _gestureHistory = [];
  static const int _historySize = 5;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final camera = _cameras.firstWhere(
      (cam) => cam.lensDirection == CameraLensDirection.front,
      orElse: () => _cameras.first,
    );

    _controller = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    _plugin = HandLandmarkerPlugin.create(
      numHands: 1,
      minHandDetectionConfidence: 0.5,
      delegate: HandLandmarkerDelegate.gpu,
    );

    await _controller!.initialize();
    await _controller!.startImageStream(_processCameraImage);

    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  @override
  void dispose() {
    _controller?.stopImageStream();
    _controller?.dispose();
    _plugin?.dispose();
    super.dispose();
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isDetecting || !_isInitialized || _plugin == null) return;

    _isDetecting = true;

    try {
      final hands = _plugin!.detect(
        image,
        _controller!.description.sensorOrientation,
      );

      // Detect gesture
      HandGesture detectedGesture = HandGesture.unknown;
      if (hands.isNotEmpty) {
        detectedGesture = GestureDetector.detectGesture(hands.first);
      }

      // Smooth gesture detection
      final smoothedGesture = _smoothGesture(detectedGesture);

      if (mounted) {
        setState(() {
          _landmarks = hands;
          _currentGesture = smoothedGesture;
        });
      }
    } catch (e) {
      debugPrint('Error detecting landmarks: $e');
    } finally {
      _isDetecting = false;
    }
  }

  /// Smooth gesture detection to avoid flickering
  HandGesture _smoothGesture(HandGesture gesture) {
    _gestureHistory.add(gesture);
    if (_gestureHistory.length > _historySize) {
      _gestureHistory.removeAt(0);
    }

    // Count occurrences of each gesture
    final counts = <HandGesture, int>{};
    for (final g in _gestureHistory) {
      counts[g] = (counts[g] ?? 0) + 1;
    }

    // Return the most common gesture
    HandGesture mostCommon = HandGesture.unknown;
    int maxCount = 0;
    counts.forEach((gesture, count) {
      if (count > maxCount) {
        maxCount = count;
        mostCommon = gesture;
      }
    });

    return mostCommon;
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    final controller = _controller!;
    final previewSize = controller.value.previewSize!;
    final previewAspectRatio = previewSize.height / previewSize.width;

    final size = MediaQuery.of(context).size;
    final deviceRatio = size.width / size.height;

    return Stack(
      children: [
        Center(
          child: Transform.scale(
            scale: previewAspectRatio / deviceRatio,
            child: AspectRatio(
              aspectRatio: previewAspectRatio,
              child: Stack(
                children: [
                  CameraPreview(controller),
                  CustomPaint(
                    size: Size.infinite,
                    painter: LandmarkPainter(
                      hands: _landmarks,
                      previewSize: previewSize,
                      lensDirection: controller.description.lensDirection,
                      sensorOrientation:
                          controller.description.sensorOrientation,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Gesture display overlay
        Positioned(
          top: 50,
          left: 0,
          right: 0,
          child: Material(
            color: Colors.transparent,
            child: Center(child: GestureDisplay(gesture: _currentGesture)),
          ),
        ),
      ],
    );
  }
}

/// Widget to display the detected gesture
class GestureDisplay extends StatelessWidget {
  const GestureDisplay({super.key, required this.gesture});

  final HandGesture gesture;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_getEmoji(), style: const TextStyle(fontSize: 32)),
          const SizedBox(width: 12),
          Text(
            _getGestureName(),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Color _getBackgroundColor() {
    switch (gesture) {
      case HandGesture.peace:
        return Colors.blue;
      case HandGesture.openHand:
        return Colors.orange;
      case HandGesture.fist:
        return Colors.purple;
      case HandGesture.unknown:
        return Colors.grey;
    }
  }

  String _getEmoji() {
    switch (gesture) {
      case HandGesture.peace:
        return '✌️';
      case HandGesture.openHand:
        return '🖐️';
      case HandGesture.fist:
        return '✊';
      case HandGesture.unknown:
        return '❓';
    }
  }

  String _getGestureName() {
    switch (gesture) {
      case HandGesture.peace:
        return 'Peace';
      case HandGesture.openHand:
        return 'Open Hand';
      case HandGesture.fist:
        return 'Fist';
      case HandGesture.unknown:
        return 'No Gesture';
    }
  }
}

/// A custom painter that renders the hand landmarks and connections.
class LandmarkPainter extends CustomPainter {
  LandmarkPainter({
    required this.hands,
    required this.previewSize,
    required this.lensDirection,
    required this.sensorOrientation,
  });

  final List<Hand> hands;
  final Size previewSize;
  final CameraLensDirection lensDirection;
  final int sensorOrientation;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / previewSize.height;

    final paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 8 / scale
      ..strokeCap = StrokeCap.round;

    final linePaint = Paint()
      ..color = Colors.lightBlueAccent
      ..strokeWidth = 4 / scale;

    canvas.save();

    final center = Offset(size.width / 2, size.height / 2);
    canvas.translate(center.dx, center.dy);
    canvas.rotate(sensorOrientation * math.pi / 180);

    if (lensDirection == CameraLensDirection.front) {
      canvas.scale(-1, 1);
      canvas.rotate(math.pi);
    }

    canvas.scale(scale);

    // Assign logicalWidth to the sensor's width and logicalHeight to the sensor's height.
    final logicalWidth = previewSize.width;
    final logicalHeight = previewSize.height;

    for (final hand in hands) {
      for (final landmark in hand.landmarks) {
        // Now dx is scaled by width, and dy is scaled by height.
        final dx = (landmark.x - 0.5) * logicalWidth;
        final dy = (landmark.y - 0.5) * logicalHeight;
        canvas.drawCircle(Offset(dx, dy), 8 / scale, paint);
      }
      for (final connection in HandLandmarkConnections.connections) {
        final start = hand.landmarks[connection[0]];
        final end = hand.landmarks[connection[1]];
        final startDx = (start.x - 0.5) * logicalWidth;
        final startDy = (start.y - 0.5) * logicalHeight;
        final endDx = (end.x - 0.5) * logicalWidth;
        final endDy = (end.y - 0.5) * logicalHeight;
        canvas.drawLine(
          Offset(startDx, startDy),
          Offset(endDx, endDy),
          linePaint,
        );
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Helper class.
class HandLandmarkConnections {
  static const List<List<int>> connections = [
    [0, 1], [1, 2], [2, 3], [3, 4], // Thumb
    [0, 5], [5, 6], [6, 7], [7, 8], // Index finger
    [5, 9], [9, 10], [10, 11], [11, 12], // Middle finger
    [9, 13], [13, 14], [14, 15], [15, 16], // Ring finger
    [13, 17], [0, 17], [17, 18], [18, 19], [19, 20], // Pinky
  ];
}
