# Admin Governance and Security Status

Updated 2026-11-13. These are local changes only; production Firestore rules have not been deployed. The Firestore Emulator authorization suite passes 19 cases; the Flutter suite passes 47 tests.

## Job moderation lifecycle

- Publication `status` and `moderationStatus` are separate fields.
- New published listings and draft-to-publish transitions enter `pending_review`.
- Public job reads, saved-job creation, application creation, and applicant-initiated conversations require `status == published` and `moderationStatus == approved`.
- Employers can read their own private listings; Admins can inspect all listings. Employer writes cannot change moderation fields.
- Substantive edits to approved listings are denied until a revision workflow exists. Employers can still change supported publication lifecycle fields.
- Admin moderation updates the job, creates an append-only `admin_audit` record, and creates an in-app employer notification atomically.

## Legacy migration

Admin Jobs shows up to the first 200 loaded job documents. Published records without a moderation status are counted in that loaded set. On explicit confirmation, the operation marks them `pending_review`, preserves their job content, and writes an audit entry for each record in batches of at most 200 jobs (400 writes per batch). It does not auto-approve records. The current UI does not paginate through all jobs, so an Admin must not treat this page preview as a complete project-wide count. Complete pagination before running a full migration on a large collection.

After migration, seekers can read only explicitly approved published listings. Legacy documents are not publicly readable while missing approval evidence.

## Employer verification notifications

The existing `reviewEmployerVerification` callable now writes a `verification` notification in the same transaction as employer status, verification history, and audit. The notification excludes internal reviewer text except the employer-facing decision reason already supplied to the employer. Tapping it opens employer organization settings. In-app notifications remain recipient-scoped; the callable uses Admin SDK authorization.

## Audit guarantees

Job moderation is an Admin-claim-authenticated client batch constrained by Firestore rules: the job update must reference an audit record created in the same atomic batch, with matching actor, target, and resulting status. Audit records cannot be updated/deleted by clients. Employer verification uses the existing trusted callable transaction. These records are access-controlled and append-only through this application, but are not described as tamper-proof server logs against privileged project operators.

## Emulator tests

Install the development test dependencies in `functions/`, then run:

```powershell
cd functions
npm run test:rules
```

The test config uses a dedicated local Firestore port (`8691`) and only the Firestore Emulator. The 19 passing cases cover seeker listing visibility, employer ownership, employer moderation-field protection, application submission and paired status notifications, Admin atomic audit pairing, audit immutability, suspension and restoration, directory privacy, blocked new file writes, unauthenticated access, role self-escalation, portfolio rules, Thread draft/publication privacy, stable paginated feed and filter queries, reaction ownership, comment ownership, Admin Thread reads, and soft-delete interaction privacy.

The emulator runs on the development computer and does not require an Android or iOS device emulator. The Flutter test suite also runs without a mobile device emulator. Latest validation: 19 Emulator cases, 47 Flutter tests, `flutter analyze` with no issues, and `npm run check` passing. No production rules were deployed. A physical Android device is detected over USB, but no app install or device smoke test was performed.

## Known security and feature gaps

- `admin_user_directory/{uid}` is a minimal projection for registered users. New accounts are added at registration; legacy accounts are backfilled as they sign in. The Admin UI reads at most 200 records and does not yet paginate.
- Firestore `accountStatus` suspension is enforced on protected operations and paired with an audit record. It does not disable or revoke the Firebase Authentication account/session. The restricted screen appears at login/session restoration; already-open screens may first encounter permission-denied states until they reload.
- Reports and appeals collections/workflows do not exist.
- HABI Threads and comments now have Firestore persistence and moderation visibility fields. However, reports, appeals, Admin moderation actions/auditing for Threads, and user-facing reporting are still not implemented. Circles still have no persisted backend.
- Employer job revisions are not implemented; approved listing content is deliberately immutable to employers for now.
- Verification notification navigation, migration across all pages, and all other governance workflows still need product/emulator integration checks.
- New file metadata/chunk creation is denied; old private file records remain read-only. Resume attachments and employer verification attachments are temporarily unavailable.
- No production deployment was performed. Emulator tests cover the listed scenarios, not the entire rules file or the live Firebase project. Reports and appeals remain deferred.

## HABI Threads rules (Phase 5B, local only)

Thread rules use `posts/{postId}` with an explicit publication lifecycle (`draft`, `published`, `deleted`) and moderation visibility (`visible`, `hidden`). Signed-in owners can read their own drafts; other members can read only published and visible posts. Owners can update content while author UID, creation time, and moderation state remain immutable. A custom `admin == true` claim may inspect hidden posts and drafts, but no Thread moderation mutation is permitted from the client and no Thread audit/report/appeal workflow exists.

Comments and reactions inherit parent visibility checks. Comment create/edit/delete is tied to the authenticated author, with author identity and creation time immutable. Reaction IDs must equal the authenticated UID and reactions cannot be updated. A soft-deleted parent becomes unreadable to ordinary members, including direct nested comment/reaction reads; Firestore subcollections are not physically cascaded. Admin claims can inspect those records for future governance tooling. The emulator suite includes draft privacy, visible/hidden reads, owner immutability, reaction impersonation, comment ownership, Admin inspection, soft-delete interaction privacy, and chronological feed query/pagination authorization. Passing those tests does not constitute a production deployment or a complete moderation system.

Feed queries require the published/visible filters, order by publication timestamp then document ID, and use bounded cursor pages. Explore uses exact category and array tag filters backed by the declared indexes; unrestricted full-text search is not supported. Profile visibility is enforced on the public profile projection and portfolio query.
