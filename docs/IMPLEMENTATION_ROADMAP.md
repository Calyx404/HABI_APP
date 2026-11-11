# HABI implementation roadmap

This plan is based on the repository audit on 2026-11-10, branch `main` at commit `7a992cf`. It records confirmed implementation gaps; re-audit the code before starting a phase so completed work is not duplicated.

## Audit summary

This roadmap was updated on 2026-11-11 after implementing application resume snapshots/consent, employer verification, structured interview workflows, the first explainable matching baseline, and native FCM delivery. These changes are local and have not been deployed to Firebase. Reporting/moderation queues and several Phase 1 workflows remain outstanding; treat Phase 1 as **in progress**.

| Area | Current state |
| --- | --- |
| Seeker and employer authentication | Implemented with Firebase Authentication and role documents. |
| Profiles and employer documents | Employer verification status, claim-protected review callable, Admin queue, and private document access are implemented locally. Existing records need the documented safe migration. |
| Jobs and applications | New applications preserve consented resume metadata, submitted resume objects, profile disclosure snapshot, and job snapshot. History can render after a listing leaves the public cache. |
| Job discovery | Search, text filters, saved jobs, and text-based nearby filtering exist. A weighted, explainable recommendation baseline is implemented; it still uses text location and legacy free-text requirements. |
| Applicant review | Employer review and messaging exist. Applicant disclosure snapshots and per-application resume download are implemented. |
| Interviews | Structured records, schedule/reschedule/cancel/complete actions, applicant responses, transition checks, and notification triggers are implemented locally. |
| Notifications | In-app notifications remain in Firestore. Native FCM registration and preference-aware push delivery are implemented locally; web push is not configured. |
| Support | A support request is saved to Firestore. There is no staff queue or email delivery. The UI must not promise an email response. |
| Admin and reporting | Admin UI, custom-claim bootstrap/revoke scripts, verification audit history, and callable are implemented locally. Job/employer reporting and report moderation remain missing. |
| Tests | Flutter unit/widget tests exist. Add focused tests for each new repository, rule, Cloud Function, and user flow. |

## Phase 1 — critical functionality, security, recruitment

Phase 1 remains in progress. Resume sharing, verification, and the structured interview workflow are implemented locally; reports and several end-to-end/security checks remain. The user has asked to continue Phases 2 and 3 in parallel with the remaining Phase 1 work.

### 1. Session logout and documentation

- Make seeker and employer logout use one route-reset flow after clearing user-scoped memory.
- Document current functionality and gaps accurately in `README.md`, `FIREBASE_SETUP.md`, and this roadmap.
- Validate with Flutter analysis, tests, and Android debug build.

### 2. Application evaluation and resume sharing

- Extend application models and job application UI to collect explicit consent and select/upload a PDF for that application.
- Store an immutable per-application resume object and metadata (path, submitted name, content type, submitted timestamp, consent timestamp). Never replace a submitted version when the general profile resume changes.
- Extend employer applicant details to show relevant profile fields while honoring beneficiary/accessibility disclosure flags; allow authorized preview/download of the submitted application resume.
- Reuse `application_resumes` in `storage.rules`; tighten writes to applicant-only creation and reads to the applicant or that application's employer. Validate size/type and tie the stored path to the application record.
- Add rules/repository/UI tests and preserve legacy applications without a resume.

### 3. Employer verification and Admin moderation

- Add verification statuses, reviewer history, rejection reasons, and a role-protected Admin review surface.
- Allow employers to publish without verification documents. Record and display whether the employer was verified when the listing was posted; block suspended employers. Preserve currently published jobs and existing employer records during migration; do not silently unpublish existing listings.
- Use Firebase custom claims set only by a trusted Admin SDK operation. Bootstrap the first administrator through a separately authenticated operator tool using Google Cloud/Firebase IAM; never expose self-promotion in the client.
- Restrict private supporting documents to the employer and authorized administrators. Add authorization tests for every Admin operation.

### 4. Recruitment lifecycle and structured interviews

- Introduce the lifecycle: Submitted, Under Review, Shortlisted, Interview Scheduled, Interview Completed, Offer Extended, Hired, Not Selected, Withdrawn.
- Preserve legacy statuses and provide a compatibility mapping; never infer missing interview times from notification text.
- Store interviews as structured records with application/job/employer/applicant IDs, time, format, location or meeting link, instructions, status, creator, and applicant response.
- Separate shortlist from scheduling. Enforce valid transitions and participant authorization in trusted backend operations and rules. Notify both parties on schedule, change, response, and cancellation.

### 5. Reports, history, support follow-up

- Add private job/employer reports with categories, explanation, status, restricted Admin review, and an audit record. Report owners may see only their own submissions.
- Store enough job snapshot fields in each new application to preserve applicant history after a job closes or is archived. Keep archived jobs private; provide migration-safe fallback text for older records.
- Keep support copy accurate: a Firestore submission is not an email follow-up. Add staff workflow or email delivery only when a real backend channel is configured.
- Test visibility, ownership, moderation authorization, migration fallback, and closed/archived application history.

### Phase 1 files and Firebase components

Expected touch points include `lib/backend/logout_flow.dart`, `lib/data/account_store.dart`, `lib/data/job_store.dart`, `lib/data/employer_store.dart`, seeker/employer application and applicant-detail screens, `lib/features/profile/resume_screen.dart`, `firestore.rules`, `storage.rules`, `firestore.indexes.json`, `functions/src/`, Firebase tests, and the docs. Keep existing collections unless a reviewed migration proves a new collection is needed. Document any data migration and deploy rules/functions only after their tests pass.

## Phase 2 — inclusive discovery and access

The first increment is implemented locally: recommendation weights and scoring are centralized in `lib/data/job_matcher.dart`, explanations are shown on the home screen, unknown factors are renormalized, and protected/accessibility traits do not affect ranking. It compares skills from legacy free-text job requirements, so production matching quality depends on employers supplying clear requirement text. Remaining Phase 2 items are listed below.

- Implement deterministic, explainable job matching with centrally defined weights. Do not use protected characteristics as ranking penalties; keep accessibility compatibility out of qualification scoring and share sensitive fields only with explicit consent.
- Add salary structure, richer filters, real coordinate distance, user-selected manual locations, and scalable pagination while reading legacy salary/location fields safely.
- Select and document a credible, properly licensed Philippine location dataset before adding records. Do not fabricate place names or coordinates.
- Improve semantics, dynamic text, contrast, focus order, touch targets, and accessible validation. Add Flutter localization for English, Filipino, and Cebuano rather than hardcoding translated strings in widgets.
- Validate with model/view-model tests, accessibility checks, localization checks, Firestore query/index review, and device-size testing.

## Phase 3 — engagement and employer productivity

The first increment is implemented locally: Android/iOS/macOS FCM registration is opt-in, per-user FIDs are removed at logout, notification category and push preferences are checked server-side, and delivery records prevent duplicate sends. Web push requires a VAPID key and service worker. The following Phase 3 items remain planned.

- Add Firebase Cloud Messaging with secure token lifecycle, idempotent delivery, invalid-token handling, and backend enforcement of notification preferences. Keep push separate from in-app history.
- Add a training catalog only from verified providers and real resources; support saved courses, progress where available, and profile certificates without fabricating endorsements.
- Add employer analytics from validated application/interview records, scoped to the employer's jobs and aggregated to avoid exposing private applicant data.
- Add voluntary first-week, first-month, and third-month check-ins. Keep answers private by default; never create employee surveillance or disclose sensitive responses without explicit consent.
- Validate functions, rules, token lifecycle, aggregate calculations, privacy behavior, and failure/idempotency paths.

## Review gates and dependencies

- Review and approve Phase 1 before Phase 2; review and approve Phase 2 before Phase 3.
- Firebase Storage must be initialized before upload workflows can be exercised against the live project.
- Admin functions require a trusted IAM-based first-admin bootstrap process. Never ship service-account credentials in the app or repository.
- Cloud Function deployment may require the Firebase project to meet current plan/billing requirements.
- Run automated checks for the affected layer and perform an authenticated end-to-end smoke test in a configured Firebase project before calling a Firebase feature production-ready.
