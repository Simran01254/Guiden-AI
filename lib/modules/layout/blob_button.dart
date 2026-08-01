import 'dart:math';
import 'dart:ui';

import 'package:blobs/blobs.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

const List<List<Color>> _neoPalettes = [
  [Color(0xFF7C7CFF), Color(0xFF00FFD1), Color(0xFF4D9DE0)],
  [Color(0xFFFF4ECD), Color(0xFFCF7987), Color(0xFFB5179E)],
  [Color(0xFF2AF598), Color(0xFF08AEEA), Color(0xFF00C896)],
  [Color(0xFFFF8A00), Color(0xFFFF3D00), Color(0xFFD7263D)],
  [Color(0xFF9D4EDD), Color(0xFF5A4FCF), Color(0xFF3A0CA3)],
];

class NeoButton extends StatefulWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const NeoButton({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  State<NeoButton> createState() => _NeoButtonState();
}

class _NeoButtonState extends State<NeoButton> {
  late final List<_BlobConfig> _blobs;

  @override
  void initState() {
    super.initState();

    final rand = Random();
    final palette = _neoPalettes[rand.nextInt(_neoPalettes.length)];

    _blobs = [
      _BlobConfig(
        top: rand.nextDouble() * 40,
        left: rand.nextDouble() * 40,
        size: 420,
        color: palette[0],
      ),
      _BlobConfig(
        top: rand.nextDouble() * 50,
        right: rand.nextDouble() * 40,
        size: 320,
        color: palette[1],
      ),
      _BlobConfig(
        bottom: rand.nextDouble() * 40,
        left: rand.nextDouble() * 50,
        size: 220,
        color: palette[2],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.title,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.heavyImpact();
          widget.onTap();
        },
        child: Container(
          width: 130.w,
          height: 90.h,
          decoration: BoxDecoration(
            color: Colors.grey.shade900,
            borderRadius: BorderRadius.zero,
          ),
          clipBehavior: Clip.hardEdge,
          child: Stack(
            children: [
              // 🔥 BLURRED BLOBS (NO BACKDROP FILTER)
              ClipRect(
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                  child: Stack(children: _blobs.map(_buildBlob).toList()),
                ),
              ),

              // Slight dark overlay to deepen contrast
              Positioned.fill(
                child: Container(color: Colors.black.withOpacity(0.25)),
              ),

              // CONTENT
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(widget.icon, color: Colors.white, size: 26.sp),
                    SizedBox(height: 8.h),
                    Text(
                      widget.title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBlob(_BlobConfig config) {
    return Positioned(
      top: config.top,
      left: config.left,
      right: config.right,
      bottom: config.bottom,
      child: Blob.animatedRandom(
        size: config.size,
        loop: true,
        edgesCount: 6,
        minGrowth: 3,
        duration: const Duration(milliseconds: 1200),
        styles: BlobStyles(color: config.color.withOpacity(0.9)),
      ),
    );
  }
}

class _BlobConfig {
  final double? top;
  final double? left;
  final double? right;
  final double? bottom;
  final double size;
  final Color color;

  _BlobConfig({
    this.top,
    this.left,
    this.right,
    this.bottom,
    required this.size,
    required this.color,
  });
}
