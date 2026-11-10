import 'package:flutter/material.dart';

class FirebaseSetupScreen extends StatelessWidget {
  const FirebaseSetupScreen({super.key, this.error});

  final Object? error;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.cloud_off_outlined, size: 44),
                const SizedBox(height: 20),
                Text(
                  error == null
                      ? 'Firebase configuration required'
                      : 'Firebase could not start',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                Text(
                  error == null
                      ? 'Copy config/firebase_options.example.json to '
                            'config/firebase_options.json, add your Firebase client '
                            'settings, enable Email/Password Authentication, create a '
                            'Cloud Firestore database and Storage bucket, then run HABI '
                            'with --dart-define-from-file=config/firebase_options.json.'
                      : 'Firebase returned an initialization error: $error\n\n'
                            'Check that the client settings match the selected Firebase '
                            'project and that Authentication, Firestore, and Storage '
                            'are enabled.',
                ),
                const SizedBox(height: 12),
                const Text(
                  'These are Firebase client identifiers. Never put a '
                  'service-account key in the Flutter app.',
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
