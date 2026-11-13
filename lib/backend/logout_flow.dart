import 'package:flutter/material.dart';

import 'package:habi/backend/session_controller.dart';
import 'package:habi/features/auth/login_screen.dart';

/// Ends the authenticated session and clears every authenticated route.
Future<void> logoutAndReturnToLogin(
  BuildContext context, {
  Future<void> Function()? signOut,
}) async {
  try {
    await (signOut ?? HabiSessionController.instance.signOut)();
  } catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Could not log out. Please try again.')),
      );
    return;
  }

  if (!context.mounted) return;
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
    (_) => false,
  );
}
