import 'package:flutter/material.dart';

import 'habi_appearance.dart';
import 'habi_colors.dart';
import 'splash_screen.dart';

void main() {
  runApp(HabiApp());
}

class HabiApp extends StatelessWidget {
  HabiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: HabiAppearance.instance,
      builder: (context, _) {
        final isDark = HabiAppearance.instance.isDarkMode;
        return MaterialApp(
          title: 'HABI',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            brightness: isDark ? Brightness.dark : Brightness.light,
            scaffoldBackgroundColor:
                isDark ? HabiColors.navy : Color(0xFFE8D5B9),
            colorScheme: isDark
                ? ColorScheme.dark(
                    primary: HabiColors.gold,
                    surface: HabiColors.navy,
                  )
                : ColorScheme.light(
                    primary: HabiColors.goldDark,
                    surface: Color(0xFFF1E3CE),
                  ),
            useMaterial3: true,
          ),
          home: SplashScreen(),
        );
      },
    );
  }
}
