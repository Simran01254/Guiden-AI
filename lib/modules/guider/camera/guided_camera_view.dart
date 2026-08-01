import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hand_landmarker/hand_landmarker.dart';

import '../../../services/hand_detector.dart' hide GestureDetector;
import 'guider_camera_controller.dart';

class GuidedCameraView extends GetView<MergedDetectionController> {
  const GuidedCameraView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Obx(() {
        if (controller.isModelLoading.value) {
          return _LoadingOverlay(
            message: controller.loadingMessage.value,
            progress: controller.downloadProgress.value,
          );
        }
        if (!controller.isCameraReady.value) {
          return const _LoadingOverlay(
            message: 'Starting camera…',
            progress: 0,
          );
        }
        final cam = controller.cameraController;
        if (cam == null || !cam.value.isInitialized) {
          return const _LoadingOverlay(
            message: 'Starting camera…',
            progress: 0,
          );
        }

        final previewSize = cam.value.previewSize!;
        final portraitSize = Size(previewSize.height, previewSize.width);
        final aspectRatio = portraitSize.width / portraitSize.height;

        return Stack(
          fit: StackFit.expand,
          children: [
            // ── Camera + overlays ──────────────────────────────────────────
            Center(
              child: AspectRatio(
                aspectRatio: aspectRatio,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CameraPreview(cam),

                    // YOLO boxes
                    Obx(
                      () => CustomPaint(
                        size: Size.infinite,
                        painter: _YoloPainter(
                          boxes: controller.yoloBoxes,
                          isFront: controller.isFrontCamera.value,
                        ),
                      ),
                    ),

                    // Hand landmarks
                    Obx(() {
                      if (!controller.isHandDetectionEnabled.value ||
                          controller.handLandmarks.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return CustomPaint(
                        size: Size.infinite,
                        painter: _HandPainter(
                          hands: controller.handLandmarks,
                          isFront: controller.isFrontCamera.value,
                        ),
                      );
                    }),

                    // Gesture hint overlay
                    Obx(
                      () => _GestureHintOverlay(
                        gesture: controller.currentGesture.value,
                        status: controller.assistStatus.value,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Urgency flash border ───────────────────────────────────────
            Obx(() {
              final urgency = controller.urgencyLevel.value;
              if (urgency != 'critical' && urgency != 'high') {
                return const SizedBox.shrink();
              }
              return _UrgencyBorder(urgency: urgency);
            }),

            // ── Top HUD ────────────────────────────────────────────────────
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _HudBtn(
                          icon: Icons.arrow_back_ios_new_rounded,
                          onTap: () => Get.back(),
                        ),
                        // Goal pill
                        Obx(() {
                          final goal = controller.currentGoal.value;
                          if (goal.isEmpty) return const SizedBox.shrink();
                          return _GoalPill(goal: goal);
                        }),
                        Row(
                          children: [
                            Obx(
                              () => _Badge(
                                label: 'FPS',
                                value: controller.currentFps.value
                                    .toStringAsFixed(1),
                                color: Colors.green.shade400,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Obx(
                              () => _Badge(
                                label: 'OBJ',
                                value: '${controller.detectionCount.value}',
                                color: Colors.blue.shade300,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Gesture chip
                    Obx(() {
                      if (!controller.isHandDetectionEnabled.value) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: _GestureChip(
                          gesture: controller.currentGesture.value,
                          count: controller.handLandmarks.length,
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

            // ── Assist overlay ─────────────────────────────────────────────
            Obx(() {
              final status = controller.assistStatus.value;
              if (status == AssistStatus.idle) return const SizedBox.shrink();
              return Positioned(
                left: 16,
                right: 16,
                top: MediaQuery.of(context).padding.top + 80,
                child: _AssistOverlay(
                  status: status,
                  transcript: controller.assistTranscript.value,
                  response: controller.assistResponse.value,
                  urgency: controller.urgencyLevel.value,
                ),
              );
            }),

            Obx(() {
              if (controller.taskSteps.isEmpty) return const SizedBox.shrink();
              return Positioned(
                left: 16,
                right: 16,
                top: MediaQuery.of(context).padding.top + 200,
                child: _TaskProgressBar(c: controller),
              );
            }),
            // ── Bottom panel ───────────────────────────────────────────────
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _BottomPanel(c: controller),
            ),
          ],
        );
      }),
    );
  }
}

class _TaskProgressBar extends StatelessWidget {
  const _TaskProgressBar({required this.c});
  final MergedDetectionController c;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final steps = c.taskSteps;
      if (steps.isEmpty) return const SizedBox.shrink();

      final idx = c.currentStepIndex.value;
      final total = steps.length;
      final progress = c.taskProgress.value;

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.85),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.cyanAccent.withOpacity(0.4),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.flag_rounded,
                  color: Colors.cyanAccent,
                  size: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  'STEP ${idx + 1} OF $total',
                  style: const TextStyle(
                    color: Colors.cyanAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                  ),
                ),
                const Spacer(),
                Text(
                  '${(progress * 100).toInt()}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.white12,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Colors.cyanAccent,
                ),
                minHeight: 4,
              ),
            ),
            const SizedBox(height: 8),
            // Current step
            if (idx < steps.length)
              Text(
                steps[idx],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      );
    });
  }
}
// ─── Gesture Hint Overlay ─────────────────────────────────────────────────────

class _GestureHintOverlay extends StatelessWidget {
  const _GestureHintOverlay({required this.gesture, required this.status});
  final HandGesture gesture;
  final AssistStatus status;

  @override
  Widget build(BuildContext context) {
    String? hint;
    Color color = Colors.white;

    if (gesture == HandGesture.fist && status != AssistStatus.stopped) {
      hint = '✊ STOPPING…';
      color = Colors.redAccent;
    } else if (gesture == HandGesture.openHand && status == AssistStatus.idle) {
      hint = '🖐 LISTENING…';
      color = Colors.greenAccent;
    } else if (gesture == HandGesture.peace) {
      hint = '✌ RESUME / CLEAR GOAL';
      color = Colors.cyanAccent;
    }

    if (hint == null) return const SizedBox.shrink();

    return Positioned(
      bottom: 120,
      left: 0,
      right: 0,
      child: Center(
        child: AnimatedOpacity(
          opacity: 1.0,
          duration: const Duration(milliseconds: 200),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.75),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: color.withOpacity(0.8), width: 2),
            ),
            child: Text(
              hint,
              style: TextStyle(
                color: color,
                fontSize: 15,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Urgency Border Flash ─────────────────────────────────────────────────────

class _UrgencyBorder extends StatefulWidget {
  const _UrgencyBorder({required this.urgency});
  final String urgency;

  @override
  State<_UrgencyBorder> createState() => _UrgencyBorderState();
}

class _UrgencyBorderState extends State<_UrgencyBorder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
    _anim = Tween<double>(
      begin: 0.3,
      end: 0.9,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.urgency == 'critical'
        ? Colors.redAccent
        : Colors.orangeAccent;

    return FadeTransition(
      opacity: _anim,
      child: Container(
        decoration: BoxDecoration(border: Border.all(color: color, width: 4)),
      ),
    );
  }
}

// ─── Goal Pill ────────────────────────────────────────────────────────────────

class _GoalPill extends StatelessWidget {
  const _GoalPill({required this.goal});
  final String goal;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.blue.shade900.withOpacity(0.9),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.cyanAccent.withOpacity(0.6), width: 1.5),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.flag_rounded, color: Colors.cyanAccent, size: 14),
        const SizedBox(width: 6),
        Text(
          goal.length > 20 ? '${goal.substring(0, 18)}…' : goal,
          style: const TextStyle(
            color: Colors.cyanAccent,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
      ],
    ),
  );
}

// ─── Assist Overlay ───────────────────────────────────────────────────────────

class _AssistOverlay extends StatelessWidget {
  const _AssistOverlay({
    required this.status,
    required this.transcript,
    required this.response,
    required this.urgency,
  });
  final AssistStatus status;
  final String transcript, response, urgency;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.82),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor.withOpacity(0.7), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _borderColor.withOpacity(0.2),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _PulsingDot(color: _borderColor),
              const SizedBox(width: 8),
              Text(
                _label,
                style: TextStyle(
                  color: _borderColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              if (urgency == 'critical') ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    '⚠ CRITICAL',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (transcript.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '"$transcript"',
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (response.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              response,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.45,
              ),
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Color get _borderColor => switch (status) {
    AssistStatus.listening => Colors.redAccent,
    AssistStatus.thinking => Colors.orangeAccent,
    AssistStatus.speaking => Colors.cyanAccent,
    AssistStatus.stopped => Colors.grey,
    AssistStatus.error => Colors.red,
    _ => Colors.white38,
  };

  String get _label => switch (status) {
    AssistStatus.listening => 'LISTENING…',
    AssistStatus.thinking => 'THINKING…',
    AssistStatus.speaking => 'GUIDEN SPEAKING',
    AssistStatus.stopped => 'PAUSED  ✊ show palm to resume',
    AssistStatus.error => 'ERROR',
    _ => '',
  };
}

// ─── Gesture Chip ─────────────────────────────────────────────────────────────

class _GestureChip extends StatelessWidget {
  const _GestureChip({required this.gesture, required this.count});
  final HandGesture gesture;
  final int count;

  @override
  Widget build(BuildContext context) {
    final (color, emoji, label, hint) = switch (gesture) {
      HandGesture.peace => (Colors.blue, '✌️', 'Peace', 'Clear goal'),
      HandGesture.openHand => (
        Colors.orange,
        '🖐️',
        'Open Hand',
        'Tap to listen',
      ),
      HandGesture.fist => (Colors.red, '✊', 'Fist', 'Stop'),
      _ => (Colors.grey, '❓', 'No Gesture', ''),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
              if (hint.isNotEmpty)
                Text(
                  hint,
                  style: const TextStyle(color: Colors.white70, fontSize: 10),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Pulsing Dot ──────────────────────────────────────────────────────────────

class _PulsingDot extends StatefulWidget {
  const _PulsingDot({required this.color});
  final Color color;

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _anim = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _anim,
    child: Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
    ),
  );
}

// ─── Loading Overlay ──────────────────────────────────────────────────────────

class _LoadingOverlay extends StatelessWidget {
  const _LoadingOverlay({required this.message, required this.progress});
  final String message;
  final double progress;

  @override
  Widget build(BuildContext context) => Container(
    color: Colors.black,
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.navigation_rounded,
            color: Colors.cyanAccent,
            size: 72,
          ),
          const SizedBox(height: 24),
          const Text(
            'GUIDEN',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'AI Navigation for Everyone',
            style: TextStyle(color: Colors.white38, fontSize: 13),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: 260,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress > 0 ? progress : null,
                backgroundColor: Colors.white12,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.cyanAccent),
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            message.isEmpty ? 'Initializing…' : message,
            style: const TextStyle(color: Colors.white54, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          if (progress > 0) ...[
            const SizedBox(height: 8),
            Text(
              '${(progress * 100).toStringAsFixed(0)}%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

// ─── HUD Widgets ──────────────────────────────────────────────────────────────

class _HudBtn extends StatelessWidget {
  const _HudBtn({required this.icon, required this.onTap, this.active});
  final IconData icon;
  final VoidCallback onTap;
  final bool? active;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: (active == true) ? Colors.blue.withOpacity(0.8) : Colors.black45,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white24, width: 1.5),
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    ),
  );
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.value, required this.color});
  final String label, value;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: Colors.black54,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withOpacity(0.6), width: 1.5),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );
}

// ─── Assist Button ────────────────────────────────────────────────────────────

class _AssistButton extends StatefulWidget {
  const _AssistButton({required this.status, required this.onTap});
  final AssistStatus status;
  final VoidCallback onTap;

  @override
  State<_AssistButton> createState() => _AssistButtonState();
}

class _AssistButtonState extends State<_AssistButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 1.22,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    _updateAnimation();
  }

  @override
  void didUpdateWidget(_AssistButton old) {
    super.didUpdateWidget(old);
    if (old.status != widget.status) _updateAnimation();
  }

  void _updateAnimation() {
    if (widget.status == AssistStatus.listening ||
        widget.status == AssistStatus.speaking) {
      _ctrl.repeat(reverse: true);
    } else {
      _ctrl.stop();
      _ctrl.value = 0;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isActive = widget.status != AssistStatus.idle;
    final color = switch (widget.status) {
      AssistStatus.listening => Colors.redAccent,
      AssistStatus.thinking => Colors.orangeAccent,
      AssistStatus.speaking => Colors.cyanAccent,
      AssistStatus.stopped => Colors.grey,
      _ => Colors.white,
    };

    return GestureDetector(
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _scale,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? color.withOpacity(0.2) : Colors.black45,
            border: Border.all(
              color: isActive ? color : Colors.white38,
              width: 2.5,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ]
                : [],
          ),
          child: Icon(
            _iconFor(widget.status),
            color: isActive ? color : Colors.white70,
            size: 28,
          ),
        ),
      ),
    );
  }

  IconData _iconFor(AssistStatus s) => switch (s) {
    AssistStatus.listening => Icons.mic,
    AssistStatus.thinking => Icons.hourglass_top_rounded,
    AssistStatus.speaking => Icons.volume_up_rounded,
    AssistStatus.stopped => Icons.pause_circle_rounded,
    AssistStatus.error => Icons.error_outline,
    _ => Icons.mic_none_rounded,
  };
}

// ─── YOLO bounding-box painter ────────────────────────────────────────────────

class _YoloPainter extends CustomPainter {
  _YoloPainter({required this.boxes, required this.isFront});
  final List<BBox> boxes;
  final bool isFront;

  static const _palette = [
    Colors.redAccent,
    Colors.cyanAccent,
    Colors.orangeAccent,
    Colors.lightGreenAccent,
    Colors.purpleAccent,
    Colors.pinkAccent,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (boxes.isEmpty) return;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    for (var i = 0; i < boxes.length; i++) {
      final b = boxes[i];
      paint.color = _palette[i % _palette.length];

      double left = b.left * size.width;
      double top = b.top * size.height;
      double right = b.right * size.width;
      double bottom = b.bottom * size.height;

      // Front camera mirroring
      if (isFront) {
        final tmp = left;
        left = size.width - right;
        right = size.width - tmp;
      }

      canvas.drawRect(Rect.fromLTRB(left, top, right, bottom), paint);

      // Label
      final tp = TextPainter(
        text: TextSpan(
          text: ' ${b.label} ${(b.confidence * 100).toStringAsFixed(0)}% ',
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            backgroundColor: paint.color.withValues(alpha: 0.8),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      tp.paint(canvas, Offset(left, (top - tp.height).clamp(0, size.height)));
    }
  }

  @override
  bool shouldRepaint(_YoloPainter old) =>
      old.boxes != boxes || old.isFront != isFront;
}

// ─── Hand landmark painter ────────────────────────────────────────────────────

class _HandPainter extends CustomPainter {
  _HandPainter({required this.hands, required this.isFront});
  final List<Hand> hands;
  final bool isFront;

  static const _conn = [
    [0, 1],
    [1, 2],
    [2, 3],
    [3, 4],
    [0, 5],
    [5, 6],
    [6, 7],
    [7, 8],
    [5, 9],
    [9, 10],
    [10, 11],
    [11, 12],
    [9, 13],
    [13, 14],
    [14, 15],
    [15, 16],
    [13, 17],
    [0, 17],
    [17, 18],
    [18, 19],
    [19, 20],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final dot = Paint()
      ..color = Colors.greenAccent
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final line = Paint()
      ..color = Colors.lightBlueAccent.withValues(alpha: 0.8)
      ..strokeWidth = 2.5;

    for (final hand in hands) {
      for (final c in _conn) {
        canvas.drawLine(
          _pt(hand.landmarks[c[0]], size),
          _pt(hand.landmarks[c[1]], size),
          line,
        );
      }
      for (final lm in hand.landmarks) {
        canvas.drawCircle(_pt(lm, size), 6, dot);
      }
    }
  }

  Offset _pt(Landmark lm, Size size) {
    final x = isFront ? (1 - lm.x) * size.width : lm.x * size.width;
    return Offset(x, lm.y * size.height);
  }

  @override
  bool shouldRepaint(_HandPainter old) =>
      old.hands != hands || old.isFront != isFront;
}

// ─── Bottom Panel ─────────────────────────────────────────────────────────────

class _BottomPanel extends StatelessWidget {
  const _BottomPanel({required this.c});
  final MergedDetectionController c;

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
          // ── ASSIST row ─────────────────────────────────────────────────
          Obx(
            () => Row(
              children: [
                Icon(
                  Icons.assistant_rounded,
                  color: c.assistStatus.value != AssistStatus.idle
                      ? Colors.cyanAccent
                      : Colors.white24,
                  size: 18,
                ),
                const SizedBox(width: 10),
                const Text(
                  'AI ASSIST',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                  ),
                ),
                const Spacer(),
                _AssistButton(
                  status: c.assistStatus.value,
                  onTap: c.toggleAssist,
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── HAND TRACKING row ──────────────────────────────────────────
          // Obx(
          //   () => Row(
          //     children: [
          //       Icon(
          //         Icons.back_hand_rounded,
          //         color: c.isHandDetectionEnabled.value
          //             ? Colors.greenAccent
          //             : Colors.white24,
          //         size: 18,
          //       ),
          //       const SizedBox(width: 10),
          //       const Text(
          //         'HAND TRACKING',
          //         style: TextStyle(
          //           color: Colors.white,
          //           fontSize: 11,
          //           fontWeight: FontWeight.w900,
          //           letterSpacing: 1.0,
          //         ),
          //       ),
          //       const Spacer(),
          //       Switch(
          //         value: c.isHandDetectionEnabled.value,
          //         onChanged: (_) => c.toggleHandDetection(),
          //         activeTrackColor: Colors.greenAccent.withValues(alpha: 0.4),
          //         activeThumbColor: Colors.greenAccent,
          //       ),
          //     ],
          //   ),
          // ),
          // const SizedBox(height: 12),
          // _Slider(
          //   label: 'CONFIDENCE',
          //   icon: Icons.tune,
          //   color: Colors.orange.shade400,
          //   rx: c.confidenceThreshold,
          //   min: 0.1,
          //   max: 0.9,
          //   onChange: c.setConfidence,
          // ),
          // const SizedBox(height: 8),
          // _Slider(
          //   label: 'IOU FILTER',
          //   icon: Icons.filter_center_focus_rounded,
          //   color: Colors.purple.shade300,
          //   rx: c.iouThreshold,
          //   min: 0.1,
          //   max: 0.9,
          //   onChange: c.setIou,
          // ),
          // const SizedBox(height: 20),
          // Row(
          //   children: [
          //     const Icon(Icons.zoom_in, color: Colors.white38, size: 18),
          //     Expanded(
          //       child: Obx(
          //         () => Slider(
          //           value: c.currentZoomLevel.value.clamp(1.0, 5.0),
          //           min: 1.0,
          //           max: 5.0,
          //           divisions: 40,
          //           activeColor: Colors.white,
          //           inactiveColor: Colors.white12,
          //           onChanged: c.setZoomLevel,
          //         ),
          //       ),
          //     ),
          //     const Icon(Icons.zoom_out, color: Colors.white38, size: 18),
          //     const SizedBox(width: 16),
          //     Obx(
          //       () => _HudBtn(
          //         icon: Icons.flip_camera_ios_rounded,
          //         onTap: c.flipCamera,
          //         active: c.isFrontCamera.value,
          //       ),
          //     ),
          //   ],
          // ),
        ],
      ),
    );
  }
}

class _Slider extends StatelessWidget {
  const _Slider({
    required this.label,
    required this.icon,
    required this.color,
    required this.rx,
    required this.min,
    required this.max,
    required this.onChange,
  });
  final String label;
  final IconData icon;
  final Color color;
  final RxDouble rx;
  final double min, max;
  final ValueChanged<double> onChange;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: color, size: 16),
      const SizedBox(width: 8),
      SizedBox(
        width: 80,
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
      ),
      Expanded(
        child: Obx(
          () => Slider(
            value: rx.value.clamp(min, max),
            min: min,
            max: max,
            divisions: 80,
            activeColor: color,
            inactiveColor: Colors.white12,
            onChanged: onChange,
          ),
        ),
      ),
      Obx(
        () => SizedBox(
          width: 40,
          child: Text(
            rx.value.toStringAsFixed(2),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ),
    ],
  );
}
