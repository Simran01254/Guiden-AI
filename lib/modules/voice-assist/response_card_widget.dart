// lib/app/modules/voice_assist/widgets/response_card.dart

import 'package:flutter/material.dart';

class ResponseCard extends StatelessWidget {
  final String text;
  final String? label;
  final IconData icon;
  final Color accentColor;
  final int? processingTimeMs;

  const ResponseCard({
    super.key,
    required this.text,
    this.label,
    this.icon = Icons.smart_toy_outlined,
    this.accentColor = Colors.blueAccent,
    this.processingTimeMs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: accentColor, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                label ?? 'Response',
                style: TextStyle(
                  color: accentColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              if (processingTimeMs != null)
                Text(
                  '${(processingTimeMs! / 1000).toStringAsFixed(1)}s',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 11,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Response text
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
