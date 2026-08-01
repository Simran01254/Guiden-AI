// lib/app/modules/voice_assist/widgets/pulsating_mic.dart

import 'package:flutter/material.dart';

class PulsatingMic extends StatefulWidget {
  final bool isActive;
  final Color color;
  final double size;
  final VoidCallback? onTap;

  const PulsatingMic({
    super.key,
    this.isActive = false,
    this.color = Colors.blueAccent,
    this.size = 80,
    this.onTap,
  });

  @override
  State<PulsatingMic> createState() => _PulsatingMicState();
}

class _PulsatingMicState extends State<PulsatingMic>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.6,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _opacityAnimation = Tween<double>(
      begin: 0.6,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    if (widget.isActive) _controller.repeat();
  }

  @override
  void didUpdateWidget(PulsatingMic oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.isActive && _controller.isAnimating) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: SizedBox(
        width: widget.size * 2,
        height: widget.size * 2,
        child: Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Pulse rings
              if (widget.isActive) ...[
                // AnimatedBuilder(
                //   animation: _controller,
                //   builder: (_, __) => Transform.scale(
                //     scale: _scaleAnimation.value,
                //     child: Container(
                //       width: widget.size,
                //       height: widget.size,
                //       decoration: BoxDecoration(
                //         shape: BoxShape.circle,
                //         color: widget.color
                //             .withOpacity(_opacityAnimation.value * 0.3),
                //       ),
                //     ),
                //   ),
                // ),
                // AnimatedBuilder(
                //   animation: _controller,
                //   builder: (_, __) => Transform.scale(
                //     scale: _scaleAnimation.value * 0.8,
                //     child: Container(
                //       width: widget.size,
                //       height: widget.size,
                //       decoration: BoxDecoration(
                //         shape: BoxShape.circle,
                //         color: widget.color
                //             .withOpacity(_opacityAnimation.value * 0.5),
                //       ),
                //     ),
                //   ),
                // ),
              ],
              // Main button
              Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.isActive
                      ? widget.color
                      : widget.color.withOpacity(0.5),
                  boxShadow: widget.isActive
                      ? [
                          BoxShadow(
                            color: widget.color.withOpacity(0.4),
                            blurRadius: 20,
                            spreadRadius: 4,
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  widget.isActive ? Icons.mic : Icons.mic_none,
                  color: Colors.white,
                  size: widget.size * 0.45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Helper widget used by PulsatingMic
class AnimatedBuilder extends AnimatedWidget {
  final Widget Function(BuildContext, Widget?) builder;

  const AnimatedBuilder({
    super.key,
    required super.listenable,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) => builder(context, null);

  Animation get animation => listenable as Animation;
}
