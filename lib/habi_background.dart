import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import 'habi_appearance.dart';
import 'habi_colors.dart';

/// Responsive patterned backdrop with corner art placed independently of it.
class HabiBackground extends StatelessWidget {
  const HabiBackground({super.key});

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: HabiAppearance.instance,
        builder: (context, _) {
          final isDark = HabiAppearance.instance.isDarkMode;
          return LayoutBuilder(
            builder: (context, constraints) {
              final shortestSide = math.min(
                constraints.maxWidth,
                constraints.maxHeight,
              );
              final cornerWidth =
                  (shortestSide * 0.30).clamp(118.0, 430.0).toDouble();
              final cornerHeight = cornerWidth * 1.48;
              return Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(
                    color: isDark
                        ? HabiColors.navy
                        : Color(0xFFE8D5B9),
                  ),
                  Opacity(
                    opacity: 0.3,
                    child: ImageFiltered(
                      imageFilter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                      child: Image.asset(
                        isDark
                            ? 'assets/habi_tile_dark.jpg'
                            : 'assets/habi_tile_light.jpg',
                        fit: BoxFit.none,
                        alignment: Alignment.topLeft,
                        repeat: ImageRepeat.repeat,
                      ),
                    ),
                  ),
                  IgnorePointer(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Positioned(
                          top: 0,
                          left: 0,
                          width: cornerWidth,
                          height: cornerHeight,
                          child: Opacity(
                            opacity: 0.3,
                            child: ImageFiltered(
                              imageFilter: ImageFilter.blur(
                                sigmaX: 2,
                                sigmaY: 2,
                              ),
                              child: RotatedBox(
                                quarterTurns: 2,
                                child: Image.asset(
                                  'assets/habi_corner_top_left.png',
                                  fit: BoxFit.fill,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          width: cornerWidth,
                          height: cornerHeight,
                          child: Opacity(
                            opacity: 0.3,
                            child: ImageFiltered(
                              imageFilter: ImageFilter.blur(
                                sigmaX: 2,
                                sigmaY: 2,
                              ),
                              child: RotatedBox(
                                quarterTurns: 2,
                                child: Image.asset(
                                  'assets/habi_corner_bottom_right.png',
                                  fit: BoxFit.fill,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      );
}
