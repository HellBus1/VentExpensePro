import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Paints a subtle cream-paper texture with faint ruled lines.
class PaperBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // — Paper base —
    final paperPaint = Paint()..color = AppColors.paper;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paperPaint);

    // — Subtle grain texture (tiny dots) —
    final grainPaint = Paint()
      ..color = AppColors.divider.withValues(alpha: 0.15)
      ..strokeWidth = 0.5;

    final random = Random(42); // Fixed seed for deterministic pattern
    for (int i = 0; i < 200; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      canvas.drawCircle(Offset(x, y), 0.3, grainPaint);
    }

    // — Faint ruled lines —
    final linePaint = Paint()
      ..color = AppColors.divider.withValues(alpha: 0.2)
      ..strokeWidth = 0.5;

    const lineSpacing = 32.0;
    for (double y = lineSpacing; y < size.height; y += lineSpacing) {
      canvas.drawLine(
        Offset(24, y),
        Offset(size.width - 24, y),
        linePaint,
      );
    }

    // — Left margin line (like a real ruled page) —
    final marginPaint = Paint()
      ..color = AppColors.stampRed.withValues(alpha: 0.15)
      ..strokeWidth = 1.0;

    canvas.drawLine(
      const Offset(48, 0),
      Offset(48, size.height),
      marginPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// A widget that renders the paper background behind its child.
class PaperBackground extends StatelessWidget {
  final Widget child;

  const PaperBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: PaperBackgroundPainter(),
      child: child,
    );
  }
}
