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
The working tree contains pre-existing uncommitted changes across application code, rules, configuration, tests, and docs. Treat them as user-owned. The current app has no central named-route registry; flows navigate with Material routes. Theme tokens currently use a navy/gold/beige palette rather than the approved teal/ivory palette. Social feed, portfolio, circles, quests, and AI are not yet first-class implemented features. `image_picker` and a Firestore chunk file store exist in the current dirty tree and must be reviewed against the no-media-upload product constraint before release.
