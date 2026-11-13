import 'package:flutter/material.dart';

import 'package:habi/backend/auth_gate.dart';
import 'package:habi/backend/firebase_config.dart';
import 'package:habi/backend/firebase_services.dart';
import 'package:habi/backend/firebase_setup_screen.dart';
import 'package:habi/shared/theme/habi_appearance.dart';
import 'package:habi/shared/theme/habi_design_system.dart';

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
          theme: HabiTheme.light,
          darkTheme: HabiTheme.dark,
          themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
          home: firebaseError != null || !HabiFirebaseConfig.isConfigured
              ? FirebaseSetupScreen(error: firebaseError)
              : const HabiAuthGate(),
        );
      },
    );
  }
}
