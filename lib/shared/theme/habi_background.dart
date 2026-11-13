import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Lightweight woven linework painted in code so the app uses only its logo art.
class HabiBackground extends StatelessWidget {
  const HabiBackground({super.key, this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).scaffoldBackgroundColor,
                scheme.surfaceContainerLowest,
              ],
            ),
          ),
        ),
        IgnorePointer(
          child: CustomPaint(
            painter: _WovenBackdropPainter(
              color: scheme.primary.withAlpha(
                Theme.of(context).brightness == Brightness.dark ? 15 : 11,
              ),
            ),
          ),
        ),
        ?child,
      ],
    );
  }
}

class _WovenBackdropPainter extends CustomPainter {
  const _WovenBackdropPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    const spacing = 48.0;
    final extent = math.max(size.width, size.height) + spacing;

    for (var offset = -extent; offset < extent; offset += spacing) {
      final path = Path()
        ..moveTo(offset, 0)
        ..cubicTo(
          offset + size.width * .30,
          size.height * .35,
          offset - size.width * .16,
          size.height * .62,
          offset + size.width * .10,
          size.height,
        );
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WovenBackdropPainter oldDelegate) =>
      oldDelegate.color != color;
}
