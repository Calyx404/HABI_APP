# Firebase setup

HABI uses Firebase Authentication, Cloud Firestore, and Cloud Functions. Resumes and employer verification documents use private, chunked Firestore byte records, so current uploads do not require Cloud Storage or a Storage bucket. The Android app reads Firebase options from `android/app/google-services.json` through the Google Services Gradle plugin. Other configured targets use Dart defines. Firebase client configuration identifies an app; never put service-account keys or other server credentials in Flutter code or source control.

## Required Firebase Console setup

Do these steps in the Firebase Console for the intended HABI project. Android's application ID is `com.habi.app`; the current `android/app/google-services.json` has been verified for that package and project `habi-71971`. If you change Firebase projects, replace the config with the matching Android app file before building.

1. **Authentication:** open **Build → Authentication → Get started → Sign-in method**, enable **Email/Password**, and save. HABI account creation and sign-in use this provider.
2. **Firestore:** open **Build → Firestore Database → Create database**. Choose the production mode; client access is controlled by the repository rules. Select a location near your users and record it. Do not publish test-mode rules.
3. **Android app registration:** under **Project settings → General → Your apps**, confirm the Android app package exactly matches `applicationId` in `android/app/build.gradle.kts`. Download its `google-services.json` into `android/app/`. Confirm the config's `project_id` matches the project. Firebase may include a `storage_bucket` field in this JSON; this app ignores it.
4. **Cloud Messaging on Android:** use a device or emulator image with Google Play services. No Android runtime storage permission should be required for the file picker; it uses the system document picker. The user must opt in to push notifications in HABI settings.
5. **Firestore rules and indexes:** from the repository root, select the intended Firebase project and deploy the current access rules and indexes:

   ```powershell
   firebase login
   firebase use --add
   firebase deploy --only firestore:rules,firestore:indexes
   ```

   Check the CLI's selected project before deploying. Do not switch rules to public/test access. If deploying manually in the Console instead, copy `firestore.rules` into **Firestore Database → Rules** and publish it. Deploy indexes from the CLI; manual console index creation must exactly match `firestore.indexes.json`. HABI no longer initializes or calls Cloud Storage; `storage.rules` is not part of the configured deployment.

6. **Firestore capacity:** no Cloud Storage bucket or billing upgrade is required for the current upload flow while the project stays within its Firestore quota. Files are limited to 10 MiB and split into 256 KiB Firestore documents. Uploads consume Firestore writes and stored data; downloads consume reads and network egress, in addition to normal app usage. Check **Firestore → Usage** regularly, set budget alerts, and review [Firestore quotas](https://firebase.google.com/docs/firestore/quotas) and [pricing](https://firebase.google.com/docs/firestore/pricing). If usage exceeds the free quota, Firebase may require billing to continue service. Avoid large or high-volume files with this design.

7. **Other platforms:** register each iOS, macOS, web, Windows, or Linux Firebase app separately. Copy `config/firebase_options.example.json` to ignored `config/firebase_options.json`, add the matching public client config values for the target, and run with:

   ```powershell
   flutter run --dart-define-from-file=config/firebase_options.json
   ```

   Android uses its native Firebase configuration and normally runs without Dart defines:

   ```powershell
   flutter run -d android
   ```

8. **Cloud Functions and Admin review:** install Node.js 22 and the Firebase CLI. Cloud Functions require the project's billing/plan setup. Before allowing employer verification decisions, an authorized project operator must assign the Admin custom claim using the trusted Admin SDK script described below; never edit a user's role in Firestore to grant Admin access.

   ```powershell
   firebase login
   firebase use <project-id>
   cd functions
   npm ci
   npm run check
   npm run build
   cd ..
   firebase deploy --only functions
   ```

Deploying rules and deploying Functions are separate steps above. Do not deploy to a production project until the project ID, rules, and impact of the deployment have been reviewed.

### Grant the first Admin reviewer

Do this only for a trusted operator account. In **Firebase Console → Authentication → Users**, create/sign in the intended admin user and copy its Firebase Auth UID. In **Google Cloud Console → IAM**, grant the operator account the Firebase Authentication Admin role (`roles/firebaseauth.admin`) on the same project. Then, in PowerShell, authenticate Application Default Credentials and run the trusted script from the repository:

```powershell
gcloud auth application-default login
$env:GOOGLE_CLOUD_PROJECT = "your-project-id"
cd functions
npm ci
npm run set-admin -- "firebase-auth-uid"
```

The Admin must sign out and sign in again so the ID token receives the claim. To remove this claim later, use `npm run revoke-admin -- "firebase-auth-uid"`. Never grant Admin by editing the Firestore user role; client role fields do not grant Admin access.

Official reference: [enable password authentication](https://firebase.google.com/docs/auth/flutter/password-auth).

### Verify resume upload setup

After deploying Firestore rules and indexes:

1. Sign in to HABI as a job seeker and choose a small, valid PDF from **Profile → Resume** or **Settings → Edit Profile → Manage resume**.
2. In **Firebase Console → Firestore Database → Data**, confirm metadata appears in `file_uploads` and byte documents under its `chunks` subcollection.
3. Confirm a different user cannot read the private resume or its chunks. Do not make files public.
4. For `permission-denied`, verify the app project matches Firebase Console, deploy the current Firestore rules, and check the user's role and file/application references.

## Local emulators

Start the configured Auth, Firestore, and Functions emulators from the repository root:

```powershell
firebase emulators:start
```

Run Flutter with local Firebase client options and the emulator flag:

```powershell
flutter run --dart-define-from-file=config/firebase_options.json --dart-define=FIREBASE_USE_EMULATOR=true --dart-define=FIREBASE_EMULATOR_HOST=10.0.2.2
```

Use `127.0.0.1` on desktop or a simulator that shares the host network. Android emulators use `10.0.2.2` to reach the host. Ensure Firebase is initialized for that target before enabling emulator use.

## Current data paths and access

- `users/{uid}` stores account and role data. A user may access only their own user document.
- `seeker_profiles/{uid}` contains employer-visible profile fields; employers can read profiles only when the seeker has enabled visibility. Beneficiary and accessibility details are shared only according to their explicit disclosure flags.
- `employer_profiles/{uid}` stores organization profile details and the private supporting-document file ID.
- `jobs/{jobId}` stores job listings. Signed-in users can read published jobs; employers manage their own listings.
- `applications/{jobId}_{applicantUid}` stores submitted profile/job snapshots and recruitment status. If an applicant chooses to attach a resume, the application also records its immutable file reference and explicit consent time; a resume is optional.
- `users/{uid}/saved_jobs/{jobId}` stores saved listings.
- `conversations/{jobId}_{applicantUid}/messages/{messageId}` stores participant-only messages. Cloud Functions write in-app notification records and send preference-aware push notifications for supported application, interview, and message events.
- `users/{uid}/devices/{fid}` stores that user's Firebase Installation ID (FID) for FCM delivery. IDs are registered only after push opt-in, refreshed securely, and removed at logout where connectivity permits.
- `users/{uid}/settings/preferences` stores notification and appearance preferences, including `pushEnabled`.
- `interviews/{interviewId}` stores structured interview schedules and applicant responses.
- `portfolio_projects/{projectId}` stores job-seeker-owned case studies. Drafts are owner-only; published projects are readable by signed-in users only while the owner's seeker profile is visible. Portfolio thumbnails and resource links are validated HTTPS URLs; media is not uploaded.
- `admin_audit/{auditId}` and `employer_profiles/{uid}/verification_history/{entryId}` store Admin verification decisions. Admin operations require the trusted `admin` custom claim.
- `push_delivery_events/{eventId}` stores server-side idempotency and delivery outcomes; client access is denied by default.
- `support_requests/{requestId}` stores a support request for its author. Submission currently does not trigger an email or guarantee a follow-up response.
- `file_uploads/{fileId}` stores private file metadata; its `chunks/{000...}` subcollection stores immutable 256 KiB bytes. Profile resumes are owner-only. Application resumes are immutable per application and readable only by the applicant and the employer responsible for that application. Employer verification files are readable by the employer and authorized Admin reviewers. Firestore rules enforce these relationships.

## Push notification setup

FCM device registration is opt-in through **Settings → Notifications → Push Notifications**. Cloud Functions deliver only when `pushEnabled` and the matching category preference are enabled. In-app notification history remains in Firestore independently of push delivery.

Android requires the registered Firebase Android app and Google Play services on the device. For iOS/macOS, enable **Push Notifications** capability in Xcode; on iOS also enable **Background Modes → Remote notifications**. In **Firebase Console → Project settings → Cloud Messaging**, upload an APNs authentication key (`.p8`) and enter its Key ID and Apple Team ID for the Apple app. Test on a physical Apple device. Web push is not wired yet because it needs a VAPID public key and a Firebase Messaging service worker; token registration is currently disabled on web. See the [Flutter FCM setup guide](https://firebase.google.com/docs/cloud-messaging/flutter/get-started).

## Security notes

Firestore rules are part of the backend, not a substitute for application testing. The verification and interview features are implemented locally; do not deploy rules or Functions until they have passed emulator authorization tests. Use the documented dry-run migration before applying verification defaults. Do not assign Admin roles through client documents; Admin access uses trusted Firebase Admin SDK custom claims. Existing records that only contain Cloud Storage paths cannot be downloaded by this version; their owners must upload those files again so they receive Firestore file IDs.

Firebase App Check is not currently initialized in the client. Firebase may log a placeholder-token warning when App Check is not configured. If App Check enforcement is enabled in the Firebase Console, install and test the appropriate provider for each platform before enabling enforcement.

## Local validation

From the repository root:

```powershell
flutter analyze
flutter test
flutter build apk --debug
```

For Cloud Functions, from `functions/`:

```powershell
npm run check
npm run build
```

See [README.md](README.md) for the project structure and [the implementation roadmap](docs/IMPLEMENTATION_ROADMAP.md) for audited feature gaps and phase gates.
