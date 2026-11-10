# Firebase setup

The app uses Firebase Authentication, Cloud Firestore, and Cloud Storage. Android is configured from `android/app/google-services.json` through the Google Services Gradle plugin; the app initializes Android Firebase from those native resources. Other platforms still need client options supplied at build time. Client settings are identifiers; never add service account credentials to the Flutter app.

## Configure a project

1. Create or select a Firebase project. Register an app for each platform you will run (Android, iOS, macOS, Web, and desktop as needed).
2. In **Authentication**, click **Get started** if Firebase Authentication is not initialized. Then enable Email/Password in **Sign-in method** and save.
3. Create a Firestore database. Cloud Storage for Firebase and Cloud Functions require the pay-as-you-go Blaze plan; creating the default Storage bucket or deploying functions may require billing to be enabled. Review Firebase pricing and usage before upgrading.
4. For Android, use the matching `google-services.json` at `android/app/google-services.json`; its package name must match `applicationId` in `android/app/build.gradle.kts`. The Google Services Gradle plugin is already configured. Run without Dart defines:

   ```powershell
   flutter run -d android
   ```

5. For other platforms, copy `config/firebase_options.example.json` to `config/firebase_options.json` and replace its values with that platform’s Firebase client settings. This local file is ignored by Git. Run the Flutter app with:

   ```powershell
   flutter run --dart-define-from-file=config/firebase_options.json
   ```

6. Install Node.js 22 and the Firebase CLI, authenticate, then deploy the checked-in rules, indexes, Storage rules, and notification functions to the project from the Android config. Storage must be initialized and the project must meet Firebase billing requirements first:

   ```powershell
   firebase login
   cd functions
   npm install
   npm run build
   cd ..
   firebase deploy --only firestore:rules,firestore:indexes,storage,functions
   ```

The web build uses `FIREBASE_APP_ID_WEB`; Windows/Linux builds use `FIREBASE_APP_ID_DESKTOP`. Supply app IDs for the platforms you registered. The Android app uses the native options generated from `google-services.json`.

## Local emulators

Start the configured Auth, Firestore, Functions, and Storage emulators with `firebase emulators:start`. Run Flutter with both the config file and:

```powershell
flutter run --dart-define-from-file=config/firebase_options.json --dart-define=FIREBASE_USE_EMULATOR=true --dart-define=FIREBASE_EMULATOR_HOST=10.0.2.2
```

Use `127.0.0.1` instead of `10.0.2.2` on desktop or a simulator that shares the host network. The Android emulator uses `10.0.2.2` to reach the host machine.

## Data model and privacy

- `users/{uid}` stores private account data and role; `seeker_profiles/{uid}` contains only profile fields intended for employer review. Beneficiary categories and accessibility needs are included in the public document only when the seeker opts in.
- `jobs/{jobId}`, `applications/{jobId}_{applicantUid}`, and `users/{uid}/saved_jobs/{jobId}` support job discovery, applications, and saved jobs.
- `conversations/{jobId}_{applicantUid}/messages/{messageId}` stores participant-only messages. Cloud Functions create per-user notification documents for applications, status changes, and messages.
- Resume and employer verification uploads are stored under private Storage paths. The current resume upload is visible only to its owner; sharing it with an employer requires a separate explicit consent flow before enabling employer access.

Firestore and Storage rules deny access unless the signed-in user’s role and record relationship permit it. Deploy rules before using a production project and review them against any later schema changes.
