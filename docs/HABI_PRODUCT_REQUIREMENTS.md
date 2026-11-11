# HABI Product Requirements

## Product
HABI is an inclusive professional social network for underserved Filipino talent and inclusive employers. Its cycle is identity and portfolio → community and skill growth → opportunity discovery → application and hiring.

## Product priorities
- Make professional identity, skills, projects, and stories central alongside jobs.
- Keep accessibility needs and sensitive disclosures optional and user controlled.
- Support seeker, employer, and administrator experiences with role-specific access.
- Treat quests, progress, and achievements as part of growth; never let clients grant themselves authoritative rewards.
- Provide AI interfaces only through a secure server endpoint or an unmistakably labeled demo.

## Constraints
Firebase Authentication and Cloud Firestore are the approved Firebase services. Do not initialize Firebase Storage or store media/Base64 in Firestore. External portfolio links and bundled placeholders are acceptable. Never ship AI credentials in the client. Preserve existing data and functionality during incremental migration.

## Acceptance
Every feature must state whether it is backed by Firebase, local/demo-only, partial, or planned. Role authorization belongs in Firestore rules or trusted server operations, not just hidden UI. See `FEATURE_IMPLEMENTATION_MATRIX.md` for the current boundary.
