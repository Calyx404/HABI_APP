# Implementation Progress

Updated 2026-11-13 after the consolidated Phase 5C–5E MVP stability sprint.

## Consolidated MVP completion sprint — Phase 5C/5D/5E

- [x] Fixed role-specific JobStore listeners: employer accounts now subscribe only to owned vacancies and employer applications; seeker accounts subscribe only to their applications. Stream failures expose a retryable state instead of leaving the job/application screens loading indefinitely.
- [x] Hardened applications: submission rejects missing, duplicate, closed, unapproved, or unpublished vacancies; application and employer notification commit atomically. Employer status transitions now atomically write an applicant notification, and Firestore rules require that status notification in the same batch. The employer shortlist filter now matches `Shortlisted`.
- [x] Implemented a privacy-limited Admin user directory at `admin_user_directory/{uid}`. Registration and profile updates maintain the projection; existing profiles are added as users next sign in. Admin status changes update the user and directory records together with an append-only audit record. Firestore rules deny protected operations for suspended accounts and the router provides a restricted-account screen. This status flag does not disable Firebase Authentication.
- [x] Removed new PDF/business attachment writes and pickers. Job applications submit the consented professional profile snapshot; employer verification can submit registration/contact details without an attachment. Firestore blocks new `file_uploads` metadata/chunks while retaining authorized legacy reads. No Storage, Base64, or other file service was introduced.
- [x] Added retryable notification stream errors and changed user-facing Firebase failures to avoid exposing raw internal exceptions.
- [x] Extended Firestore Emulator tests for profile-only application writes, paired employer/application notifications, suspension and restoration audit batches, directory privacy/ownership, and denied file creation.
- [x] `flutter pub get` succeeded. `dart format lib test` completed (90 files; final run 0 changes). `flutter analyze` reported no issues. `flutter test` passed all 47 tests. `npm run check` passed. Firestore Emulator authorization tests passed 19/19 against `demo-habi-rules-test`.
- [x] Emulator port 8686 was unavailable during a final rerun despite no listener; the isolated test config now uses verified free port 8691. No production rules/indexes were deployed and no APK was built.
- [ ] USB device app installation/startup and role-by-role manual interaction remain for the user's physical-device debug session. `flutter devices` detected Android device `2409BRN2CA` (Android 16); this sprint did not install or launch the app on it.
- [ ] Connections, persisted Bayanihan Circle operations, trusted quest/XP awards, reports/appeals, thread moderation, directory pagination, and immediate forced logout after suspension remain deferred. Existing accounts receive a directory projection when they sign in; this is not a complete historical bulk backfill.

Updated 2026-11-13 after Phase 5B HABI Threads implementation and validation.

## Phase 5B — Professional feed and HABI Threads

- [x] Added a validated Thread data model covering seven professional content types, optional story sections, bounded skill/topic tags, HTTPS links, and portfolio references.
- [x] Added a Firestore repository for private drafts, publish/edit, owner soft-delete, chronological feed pages, idempotent UID-keyed reactions, paginated comments, and published portfolio references. Author identity is checked against the account profile in Firestore rules.
- [x] Connected Home and Explore to the shared Firestore feed panel. Feed order uses `publishedAt DESC` plus document ID DESC for stable page cursors; Explore supports exact category and skill/topic filters, including combined category/tag filtering.
- [x] Implemented the structured composer, private saved-draft list and empty state, draft deletion, publish/edit navigation, Thread details, paginated comments, comment edit/delete, current-member reaction state, and public author profile navigation.
- [x] Reused the Phase 5A portfolio repository for published project selection and preview. Project IDs are validated as published and owned by the author; previews omit unavailable/archived projects.
- [x] Added Firestore rules for draft privacy, visible published posts, immutable ownership/creation/moderation fields, valid lifecycle transitions, portfolio references, comment ownership, deterministic reactions, Admin read inspection, and inaccessible nested interactions after soft deletion.
- [x] Added feed/tag/draft composite indexes and updated data model, architecture, and Admin security documentation. The isolated test emulator port moved to 8686 because 8586 and 8587 were bound/reserved locally; the test project remains `demo-habi-rules-test`.
- [x] Added Thread model/validation tests. `dart format lib test` completed (91 files, no changes on the final pass); `flutter analyze` reported no issues; `flutter test` passed all 48 tests; `npm run check` passed; Firestore Emulator suite passed all 15 tests.
- [ ] Manual USB-device review of feed scrolling, composer keyboard interaction, navigation, and visual layout remains. No APK was built and no production rules were deployed.
- [ ] Thread replies, reaction aggregates, remote live-feed subscriptions, full-text search, reporting, and Admin moderation workflows are not included. Reactions show the signed-in member's persisted state without expensive aggregate counts; remote posts appear on refresh/subsequent pages.

## Phase 5A.1 — Messaging, UI consistency, and emulator validation

- [x] Restored the Job Seeker five-item navigation to Home, Explore, Create, Messages, and Profile. The Messages badge now reflects unread Firestore conversations; Notifications is opened from a shared top-right bell.
- [x] Added the notification action to the main Job Seeker destinations, employer dashboard/workflows, and job, portfolio, circle, and application screens. The notification list is a secondary page, not a bottom-navigation destination.
- [x] Kept the employer's separate Dashboard, Jobs, Applicants, Messages, and Organization navigation and company-specific workflows. Employer messages no longer display the Job Seeker navigation bar.
- [x] Updated the conversation list and chat surfaces to Material 3 theme tokens; added conversation search and an unread filter, keyboard send, and reliable sender identity checks. Existing Firestore send/read/archive/restore/delete-for-self operations remain in use. New conversations are ensured in Firestore before the first message write; unavailable conversations and signed-out sends now fail visibly instead of reporting success.
- [x] Fixed secondary-screen navigation so selecting a primary destination replaces stale detail/shell routes rather than leaving an earlier dashboard underneath.
- [x] Removed `singleProjectMode: false` from both Firebase configs. The rules script, Firebase CLI `--project`, emulator, and test harness all use `demo-habi-rules-test`; `.firebaserc` continues to point at production only when no explicit test project is supplied.
- [x] Diagnosed port 4400: it was not occupied by another process. In the restricted run, Node could bind to `127.0.0.1:4400` but its local HTTP request failed with `EACCES`; Firebase therefore timed out waiting for its hub. With approved localhost access, the Firestore Emulator started normally and all 9 rules tests passed. No unrelated process was terminated and no production rules were deployed.
- [x] The Firebase CLI update-check warning was suppressed for the test process with its supported `NO_UPDATE_NOTIFIER=1` environment switch. It was separate from the hub failure; no user-level permissions were changed.
- [x] `dart format lib` completed. `flutter analyze` reported no issues. `flutter test --no-pub` passed all 42 tests. `npm run check` passed and `npm run test:rules` passed all 9 Emulator tests. Flutter commands required SDK cache access; the earlier silent sandbox run did not produce test output, while the verbose allowed run completed and showed the SDK cache was usable.
- [x] A later approved SDK run resolved the prior sandbox limitation; the Phase 5B validation above is the fresh Flutter baseline.
- [ ] Visual inspection on the user's USB-connected Android device remains for manual device-specific layout and interaction checks. No APK was built in this phase.

## UI refresh

- [x] Reworked the app theme around Material 3 with explicit light/dark surfaces, accessible teal/terracotta accents, consistent spacing/radii, button/input/navigation themes, and the supplied Kumar One display font for headings.
- [x] Replaced patterned image backgrounds with lightweight custom-painted woven linework. The HABI logo is the only image asset used by the redesigned interface.
- [x] Added one persistent five-destination Job Seeker shell for Home, Explore, Create, Messages, and Profile, preserving page state and making the same navigation available from secondary screens.
- [x] Redesigned Home, Explore, Notifications, Profile, job cards, empty/loading states, and splash presentation. Existing account, jobs, notifications, and portfolio stores remain the source for connected data.
- [x] Labeled preview-only connections, threads, circles, and gamification where their backend actions are not implemented.
- [x] Aligned the rules runner and test harness on `demo-habi-rules-test`; `singleProjectMode` is not used to suppress mismatches.
- [x] The latest Firestore rules suite ran on the isolated demo project and passed all 9 cases; see the Phase 5A.1 entry above for the localhost sandbox diagnosis.

## Phase 5A — Professional identity and portfolio

- [x] Added the `portfolio_projects/{projectId}` schema with project identity, contribution, skills/tools, timeline, HTTPS resource links, status, and server timestamps.
- [x] Added an owner-scoped Firestore repository and connected portfolio list, project details, create/edit, publish/unpublish, archive/delete, and the signed-in profile's published project preview.
- [x] Added Firestore rules for owner-bound writes, owner-only drafts, visible-profile published reads, Admin inspection, immutable ownership/creation time, and archived-project protection.
- [x] Added indexes for owner and published portfolio query forms.
- [x] Removed unused `image_picker`; portfolio thumbnails use HTTPS URLs and alt text with a fallback, without uploads or image bytes in Firestore.
- [x] Added portfolio model tests and Firestore Emulator authorization scenarios. The current regression results, including query-order coverage and the localhost-access diagnosis, are recorded under Phase 5A.1 above. No Android device emulator is required for Firestore Emulator tests.

- [x] Repository and Git status audited; pre-existing changes preserved.
- [x] Existing architecture and current feature boundaries documented.
- [x] Product, architecture, data model, feature matrix, asset, and AI baseline docs added.
- [x] Added centralized teal/ivory design tokens, typography/spacing/radius/shadow/animation foundations, light/dark themes, replaceable asset catalog, and reusable avatar/button/section/empty-state widgets.
- [x] Applied the design theme at app entry while retaining the user's appearance preference.
- [x] Expanded shared UI library with app bar, search/text fields, post/job/portfolio cards, achievements, quests, profile header, tabs/filters, notification tile, skeleton/error, confirmation dialog, and five-item bottom navigation.
- [x] Added seeker Explore, Create Thread preview, Portfolio/Project Details, Quests/XP, Achievements, and Bayanihan Circles/Details screens; linked them from home and profile.
- [x] Added a professional community post and quest preview to the home experience; kept the existing Firebase-backed job recommendation and notification flows.
- [x] Formatted all Dart under `lib/` with Dart 3.13.1.
- [x] `flutter analyze` passes with no issues; `flutter test` passes all 32 tests.
- [x] Employer primary navigation now has Dashboard, Jobs, Applicants, Messages, and Organization destinations while reusing existing authenticated employer routing and messaging.
- [x] Employer dashboard displays job and application counts from loaded Firestore records, plus status breakdowns and a data-backed analytics sheet.
- [x] Added confirmation and owner-checked Firestore status updates for close/reopen/archive/draft removal actions.
- [x] Employer implementation formatted, analyzed cleanly, and all 32 tests passed on 2026-11-12.
- [x] Expanded the claim-guarded Admin screen into Overview, Verification, Jobs, and Activity sections using the HABI component system.
- [x] Reused trusted employer verification review workflow and added Admin repository reads for visible published jobs and existing `admin_audit` records.
- [x] Admin interface formatted and analyzed cleanly; all 32 project tests passed on 2026-11-12.
- [x] Added Firestore-backed job moderation decisions (approve, request changes, reject, hide) with required reasons, separate moderation fields, atomic audit record, and employer in-app notification.
- [x] Added Admin-claim rules for job moderation, append-only job audit creation, and moderation notifications; employers are blocked from changing moderation fields.
- [x] Firestore now denies public reads of listings without explicit approval; legacy published records without moderation evidence are private until the confirmed migration queues them for review.
- [x] Formatted Dart, `flutter analyze` clean, and all 32 tests passed after governance additions on 2026-11-12.
- [x] Job seeker Firestore reads, saved-job creation, applications, and applicant conversations now require published + approved status; employer owners and Admins retain access to their listings.
- [x] New published jobs and draft-to-publish transitions enter `pending_review`; substantive edits to approved content are denied until a revision workflow exists.
- [x] Added confirmed legacy migration preview for up to 200 loaded listings; unreviewed records are moved to pending review with paired audit entries, preserving job content.
- [x] Employer verification callable now writes an in-app notification in the same transaction as status/history/audit; notifications navigate employers to organization settings.
- [x] Added Firestore Emulator harness; its original 6 governance cases pass, with 3 portfolio-specific authorization groups added in Phase 5A (9 total).
- [x] On 2026-11-12, Dart 3.13.1 formatted 70 files (0 changed); `flutter analyze` found no issues; `flutter test` passed all 32 tests; `npm run check` passed; Firestore Emulator suite passed 6/6.
- [x] Added `docs/ADMIN_GOVERNANCE_SECURITY.md` covering moderation lifecycle, migration, audit guarantees, emulator procedure, and security gaps.
- [x] Refreshed Flutter dependencies successfully; patched the vulnerable transitive `@grpc/grpc-js` dependency with an npm override while retaining Firebase 12, and `npm audit` now reports 0 vulnerabilities.
- [x] Revalidated `flutter analyze` (no issues), `flutter test` (32 passing), Functions TypeScript checking, and Firestore Emulator rules tests (6/6 passing) after dependency updates.
- [x] Verified the replacement `android/app/google-services.json` registers `com.habi.app` in Firebase project `habi-71971`; `flutter build apk --debug` now succeeds without a device emulator. The merged Android manifest confirms package `com.habi.app`; USB installation/runtime behavior still requires the user's physical-device check.
- [ ] Review existing resume and application resume chunk storage against the platform's no-file-storage constraint; unused `image_picker` has been removed.
- [ ] Replace remaining legacy screen styling and make the new five-item navigation persistent across all seeker destinations.
- [ ] Add a consolidated employer interview list/timeline; current per-application scheduling remains available.
- [ ] Design Firestore-rules-backed private candidate evaluation notes before implementing them.
- [ ] Add persisted organization mission, values, and accessibility commitments; the current organization model supports name, industry, description, location, website, and verification.
- [ ] Add employer AI interfaces after implementing a shared secure AI service contract.
- [ ] Implement Admin user directory and suspension only through a reviewed least-privilege server operation; current `/users` rules deny listing and there is no trusted suspension function.
- [ ] Add reports, appeals, post/thread/community moderation only after data models, restricted rules, and trusted auditable operations are designed.
- [ ] Run the explicit legacy migration across all job pages and verify discovery in a configured Firebase project.
- [ ] Extend Emulator tests for saved jobs, applications, conversations, notifications, migration, and employer job revision behavior.
- [x] Implemented the Firestore-backed feed and HABI Threads with persistent drafts, publishing, editing, soft deletion, reactions, comments, stable pagination, and public author profile navigation; see Phase 5B above.
- [ ] Implement connections/circles and quests with secure persistence. Gamification presentation is not an XP award backend.
- [ ] Add secure AI endpoint contract and seeker/employer interfaces.
- [ ] Complete moderation, accessibility/localization, rules/index review and emulator validation.
- [ ] Run formatter, analyzer, and tests after implementation changes.

Job moderation is Firestore-enforced locally: job seekers can read only published/approved listings, employers can read their own private records, and Admin moderation must pair an audit record. New postings wait for review. The Admin migration preview is limited to the first 200 loaded jobs and must be run deliberately; it puts ambiguous legacy listings into review. Employer verification notifications are now written transactionally. User directory/suspension, reports, appeals, and content/community moderation remain incomplete: adding client-only screens would not safely enable cross-user directory reads, globally enforce suspension, or moderate content collections that do not exist. Firestore suspension also cannot disable Auth sessions. No production rules were deployed and no production migration was run. Six local emulator authorization tests pass; they do not cover suspension/report/appeal workflows or every collection/rule path. `flutter test` uses the Flutter test runner and does not require an Android/iOS device emulator. The Firebase Emulator suite runs locally on this development machine.
