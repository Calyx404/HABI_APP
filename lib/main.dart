import 'package:flutter/material.dart';

import 'package:habi/backend/auth_gate.dart';
import 'package:habi/backend/firebase_config.dart';
import 'package:habi/backend/firebase_services.dart';
import 'package:habi/backend/firebase_setup_screen.dart';
import 'package:habi/shared/theme/habi_appearance.dart';
import 'package:habi/shared/theme/habi_colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Object? firebaseError;
  if (HabiFirebaseConfig.isConfigured) {
    try {
      await HabiFirebaseServices.instance.initialize();
    } catch (error) {
      firebaseError = error;
    }
  }
  runApp(HabiApp(firebaseError: firebaseError));
}

class HabiApp extends StatelessWidget {
  const HabiApp({super.key, this.firebaseError});

  final Object? firebaseError;

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
            scaffoldBackgroundColor: isDark
                ? HabiColors.navy
                : Color(0xFFE8D5B9),
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
          home: firebaseError != null || !HabiFirebaseConfig.isConfigured
              ? FirebaseSetupScreen(error: firebaseError)
              : const HabiAuthGate(),
        );
      },
    );
  }
}
