# HABI Architecture

## Current structure (repository audit, 2026-11-11)
- `lib/backend/`: Firebase initialization, auth/session gate, and Firebase service adapters.
- `lib/data/`: account, employer, job, message, and notification stores plus repositories.
- `lib/features/`: auth, seeker home/profile/jobs, employer, messaging, notifications, settings, support, and admin screens.
- `lib/shared/`: appearance/colors, widgets, pickers, and location data.
- `functions/src/`: trusted Firebase callable/trigger operations.
- `firestore.rules` and `firestore.indexes.json`: database access and query configuration.

Authentication routes by Firebase custom admin claim, then account role. Existing feature stores are the persistence boundary; new UI should not issue Firestore queries directly. Current state is a hybrid of singleton stores, view models, and Firebase repositories; retain these boundaries and migrate only feature by feature.

## Target direction
Keep feature-oriented modules. Each feature should separate presentation, typed domain data, repository contract, and Firebase data source where useful. Shared theme and widgets belong in `lib/shared`. Inject or pass repositories at feature boundaries. Keep admin and employer operations constrained by trusted claims/rules.

## Current risks
The working tree contains pre-existing uncommitted changes across application code, rules, configuration, tests, and docs. Treat them as user-owned. The current app has no central named-route registry; flows navigate with Material routes. Circles, quests, and AI are not yet backed by trusted first-class persistence. New file uploads are disabled; `HabiFirestoreFileStore` is read-only compatibility for legacy file records. `admin_user_directory` is a minimal projection separate from private user profiles.

## Professional feed and Threads (Phase 5B)
`lib/data/habi_thread.dart` owns the bounded Thread/comment model and validation; `HabiThreadRepository` is the Firestore boundary. `ThreadFeedController` loads pages of 20, ordered by `publishedAt DESC` plus document ID DESC, and de-duplicates IDs across cursor pages. Home and Explore reuse the same feed panel and controller, while Create, detail, public-profile, and project routes remain nested feature pages inside the persistent seeker shell. Feed refreshes on pull-to-refresh and after same-device writes; remote additions are not live-streamed and appear on refresh or subsequent reads. Thread reactions store one deterministic record per UID; cards fetch only the current member's state and do not issue aggregate count reads. Comment lists are paginated (30 per request).

Thread drafts and published posts share `posts/{postId}`. Publication status (`draft`, `published`, `deleted`) is distinct from moderation visibility (`visible`, `hidden`). Authenticated member access, owner checks, immutable creation/ownership, and nested interaction visibility are enforced in `firestore.rules`. Project references resolve from `portfolio_projects` and are accepted only for currently published projects owned by the Thread author. See the Firestore data model and Admin governance security documentation for details and limits.
