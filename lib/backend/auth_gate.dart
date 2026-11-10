import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:habi/data/account_store.dart';
import 'package:habi/features/employer/employer_profile_setup_screen.dart';
import 'package:habi/features/employer/employer_screen.dart';
import 'package:habi/data/employer_store.dart';
import 'package:habi/features/home/home_screen.dart';
import 'package:habi/data/job_store.dart';
import 'package:habi/data/message_store.dart';
import 'package:habi/data/notification_store.dart';
import 'package:habi/features/profile/profile_setup_screen.dart';
import 'package:habi/features/auth/splash_screen.dart';
import 'package:habi/backend/auth_service.dart';
import 'package:habi/backend/session_controller.dart';
import 'package:habi/data/repositories/user_settings_repository.dart';
import 'package:habi/shared/theme/habi_appearance.dart';

class HabiAuthGate extends StatelessWidget {
  const HabiAuthGate({super.key});

  @override
  Widget build(BuildContext context) => StreamBuilder<User?>(
    stream: HabiAuthService.instance.authStateChanges,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const SplashScreen();
      }
      final user = snapshot.data;
      if (user == null) return const SplashScreen();
      return _SignedInRouter(key: ValueKey(user.uid), user: user);
    },
  );
}

class _SignedInRouter extends StatefulWidget {
  const _SignedInRouter({super.key, required this.user});

  final User user;

  @override
  State<_SignedInRouter> createState() => _SignedInRouterState();
}

class _SignedInRouterState extends State<_SignedInRouter> {
  late final Future<Widget> _destination = _loadDestination();

  Future<Widget> _loadDestination() async {
    final snapshot = await HabiAuthService.instance.userDocument(
      widget.user.uid,
    );
    final data = snapshot.data();
    if (data == null) {
      await HabiSessionController.instance.signOut();
      return const SplashScreen();
    }
    try {
      final preferences = await FirestoreUserSettingsRepository().load(
        widget.user.uid,
      );
      final darkMode = preferences['darkMode'];
      if (darkMode is bool) HabiAppearance.instance.setDarkMode(darkMode);
    } catch (error) {
      debugPrint('Could not load saved app settings: $error');
    }
    final role = data['role'] as String?;
    JobStore.instance.bindUser(widget.user.uid);
    MessageStore.instance.bindUser(widget.user.uid);
    NotificationStore.instance.bindUser(widget.user.uid);

    if (role == HabiAccountRole.jobSeeker.name) {
      await AccountStore.instance.load(widget.user.uid);
      final account = AccountStore.instance.current!;
      JobStore.instance.bindUser(
        widget.user.uid,
        displayName: account.displayName,
      );
      MessageStore.instance.bindUser(
        widget.user.uid,
        displayName: account.displayName,
      );
      if (!account.profileDone) {
        return ProfileSetupScreen(
          userName: account.displayName,
          firstTime: true,
        );
      }
      return HomeScreen(userName: account.displayName);
    }
    if (role == HabiAccountRole.employer.name) {
      await EmployerStore.instance.load(widget.user.uid);
      final employer = EmployerStore.instance.byCompanyName(
        data['displayName'] as String? ?? '',
      );
      if (employer == null) {
        throw StateError('Could not load the employer profile.');
      }
      JobStore.instance.bindUser(
        widget.user.uid,
        displayName: employer.companyName,
      );
      MessageStore.instance.bindUser(
        widget.user.uid,
        displayName: employer.companyName,
      );
      if (!(employer.profileComplete ?? false)) {
        return EmployerProfileSetupScreen(
          companyName: employer.companyName,
          isOnboarding: true,
        );
      }
      return EmployerScreen(companyName: employer.companyName);
    }
    throw StateError('The Firebase user profile has an invalid account role.');
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Widget>(
    future: _destination,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return _SessionError(error: snapshot.error.toString());
      }
      if (!snapshot.hasData) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      return snapshot.data!;
    },
  );
}

class _SessionError extends StatelessWidget {
  const _SessionError({required this.error});

  final String error;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(error, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () async {
                await HabiSessionController.instance.signOut();
              },
              child: const Text('Sign out'),
            ),
          ],
        ),
      ),
    ),
  );
}
