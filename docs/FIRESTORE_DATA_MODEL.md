# Firestore Data Model

Current collections identified from rules and feature stores include:

| Collection | Purpose / access boundary |
| --- | --- |
| `users` | Authenticated account profile and role; owner-limited updates. |
| `admin_user_directory` | Minimal UID, email, display name, role, and account status projection; custom Admin claim can list, users can maintain only their own identity projection. |
| `seeker_profiles` | Employer-visible professional profile projection; public portfolio requires `visibility == true`. |
| `portfolio_projects` | Job seeker-owned project records; drafts private to owner, published records visible to signed-in users only while owner's profile is visible. |
| `jobs` | Employer-owned job records; published listings discoverable to seekers. |
| `applications` | Applicant/employer scoped application lifecycle and history snapshots. |
| `interviews` | Structured interview schedule, participant scoped. |
| `conversations/{id}/messages` | Two participant messaging, immutable messages. |
| `notifications` | Per-user notification records. |
| `posts/{postId}` | HABI Threads; owner-only drafts and authenticated visible published posts. |
| `posts/{postId}/comments/{commentId}` | Bounded comments whose access follows the visible parent post. |
| `posts/{postId}/reactions/{userUid}` | One immutable reaction per member UID and visible parent post. |
| `file_uploads/{id}/chunks` | Legacy records are retained read-only; Firestore rules deny new metadata and chunk writes. |

## Job moderation update (local, not deployed)
Job publication `status` remains separate from `moderationStatus`. New published jobs use `pending_review`; only `status == published && moderationStatus == approved` is readable by seekers. Employers retain access to their own jobs and cannot edit moderation fields. Approved job content edits are currently denied until a revision workflow exists. Admin changes write `moderationStatus`, `moderationReason`, `moderationBy`, `moderationUpdatedAt`, and `moderationAuditId`; a matching `admin_audit` document and employer notification are written atomically. Legacy published jobs without moderation evidence are explicitly migrated to `pending_review`, never auto-approved. The in-app preview scans at most 200 records per current page; operators must repeat/extend the process to cover more.

## Verification notification
The existing `reviewEmployerVerification` callable now writes `users/{employerId}/notifications/{id}` with `kind: verification`, related employer ID, title/body, server timestamp, and unread state in the same transaction as the verification decision/history/audit.

## User status and directory projection (local rules, not deployed)
`admin_user_directory/{uid}` contains only the minimum account identity/status fields required for Admin review. It is not a listing of private `users` documents. New accounts write the directory projection with their account/profile batch; existing accounts backfill their projection when they sign in. The Admin can change `users/{uid}.accountStatus` and the projection only in a batch paired with an append-only `admin_audit` record. `signedIn()` checks the Firestore status for protected operations. The user can still read their own user document to see the restricted state. This does not disable or revoke Firebase Authentication itself, and the UI directory query is capped at 200 entries without pagination.

## Not yet implemented
There are no `reports` or `appeals` workflows. Bayanihan Circles and gamification do not have trusted persistence/reward operations; keep them clearly deferred. Do not assume these workflows exist.

Employer/admin verification and delivery records are also present in the current implementation; confirm exact paths in `firestore.rules` and Functions before schema migration. Rules and indexes are authoritative. Do not introduce social/gamification collections until ownership, moderation, privacy, and trusted XP award paths are designed. No migration or deployment was performed in this task.

## Professional portfolio (Phase 5A, local rules not deployed)

`portfolio_projects/{projectId}` stores one project with `ownerUid`, `title`, `summary`, `description`, `category`, `role`, `skills`, `technologies`, `responsibilities`, `outcomes`, `reflection`, `startedAt`, nullable `endedAt`, `ongoing`, `demoUrl`, `repositoryUrl`, `thumbnailUrl`, `thumbnailAltText`, `status`, `createdAt`, and `updatedAt`. `status` is `draft`, `published`, or `archived`. Timestamps are server-assigned. Project media is not uploaded; optional thumbnail/demo/repository fields accept HTTPS links only.

The signed-in job seeker owns project writes. Firestore rules bind `ownerUid` to Auth UID, validate the document shape and bounds, preserve owner/creation time, deny administrative fields, and prevent archived records from being republished. Owners can read all their projects. Other authenticated users can read published projects only if `seeker_profiles/{ownerUid}.visibility == true`. Admin custom claims can inspect all project records. Owner queries order by `updatedAt`; public portfolio queries filter `ownerUid` and `status` then order by `updatedAt`. Two `portfolio_projects` composite indexes support those query forms.

## Professional feed and HABI Threads (Phase 5B; local rules, not deployed)

`posts/{postId}` stores `authorUid`, `authorName`, `authorHeadline`, `contentType`, `title`, `content`, `skills`, `topics`, `externalUrl`, nullable `portfolioProjectId`, optional story fields (`challenge`, `approach`, `outcome`, `learning`, `collaboration`), `publicationStatus`, `moderationStatus`, `createdAt`, `updatedAt`, and nullable `publishedAt`. Categories are `projectShowcase`, `learningJourney`, `professionalInsight`, `careerMilestone`, `questionDiscussion`, `collaborationOpportunity`, and `communityContribution`. Optional external links must be HTTPS. Content and tags are bounded by model and rule validation.

Drafts use the same parent document with `publicationStatus: draft` and null `publishedAt`; only its owner and Admin claim can read it. Publication sets a server timestamp and visible moderation state. A post owner can edit supported content and soft-delete by setting `publicationStatus: deleted`; owners cannot change ownership, creation time, or moderation visibility. Hidden and deleted posts are inaccessible to ordinary members. No Admin post-moderation/report workflow is implemented yet.

`posts/{postId}/comments/{commentId}` stores author UID/name, body, and server timestamps. Comments can be added to visible published posts, edited/deleted by their author, and are read through parent visibility checks. Replies are not implemented. `posts/{postId}/reactions/{userUid}` stores the same UID in its ID and body, a fixed `support` type, and creation time; clients cannot update reactions. The client reads only the current user's reaction state and intentionally does not issue per-post aggregate count queries. Soft deletion does not recursively delete Firestore subcollections; rules make comments and reactions inaccessible to ordinary users while Admin inspection remains possible.

Feed query: `publicationStatus == published`, `moderationStatus == visible`, then `publishedAt DESC`, document ID DESC, `limit(20)`. The document ID tie-breaker makes equal timestamps stable. The next page starts after the last returned document. Explore supports exact content type and exact skill/topic tag filters; it is not full-text search. `firestore.indexes.json` includes feed, type, tag, combined type+tag, and owner draft query indexes. Public author profiles expose only the visible `seeker_profiles` projection and published portfolio project query; private profile projects/drafts remain unavailable.

Feed reads are paginated and refresh on pull-to-refresh/local Thread changes; they are not remote real-time subscriptions. Reaction state is fetched per card but aggregate counts are omitted for predictable read cost. Comments are paginated at 30. The portfolio preview cache is bounded to 100 project IDs. No image media, uploads, Storage, Base64 content, external search service, reporting, replies, or XP awards were added in this phase.
