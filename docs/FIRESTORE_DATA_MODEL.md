# Firestore Data Model

Current collections identified from rules and feature stores include:

| Collection | Purpose / access boundary |
| --- | --- |
| `users` | Authenticated account profile and role; owner-limited updates. |
| `jobs` | Employer-owned job records; published listings discoverable to seekers. |
| `applications` | Applicant/employer scoped application lifecycle and history snapshots. |
| `interviews` | Structured interview schedule, participant scoped. |
| `conversations/{id}/messages` | Two participant messaging, immutable messages. |
| `notifications` | Per-user notification records. |
| `file_uploads/{id}/chunks` | Present in current working tree for private chunked documents; conflicts with product's no-upload constraint and needs a release decision/removal plan. |

Employer/admin verification and delivery records are also present in the current implementation; confirm exact paths in `firestore.rules` and Functions before schema migration. Rules and indexes are authoritative. Do not introduce social/gamification collections until ownership, moderation, privacy, and trusted XP award paths are designed. No migration or deployment was performed in this task.
