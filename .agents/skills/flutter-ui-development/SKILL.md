---
name: flutter-ui-development
description: Develop, review, and validate HABI's inclusive Flutter frontend, and manage its related Git changes.
---

# HABI Flutter Project Workflow

Use this skill for frontend implementation, code review and validation, and version control tasks in HABI.

## Product context

HABI serves youth, people with disabilities, single parents, and other marginalized job seekers, as well as employers committed to inclusive hiring. Design application and selection flows to reduce friction for both groups. Keep accessibility needs, accommodations, and disclosure choices under the user's control; do not imply sensitive information must be disclosed to apply.

## Development

- Inspect nearby screens and shared components before adding another pattern. Reuse the app's colors, navigation, form widgets, and stores where they fit.
- Prefer clear labels, sensible focus and keyboard behavior, scalable layouts, adequate touch targets, and semantic controls. Avoid relying on color or icons alone to convey status.
- Keep transient UI state local and persistence behind the existing store boundary so a future backend can replace in-memory behavior.
- Treat demo data and frontend-only actions as such. Do not suggest that an application, message, or account was sent to a backend when it was not.
- Preserve platform-specific picker handling. Do not hand-edit generated Flutter plugin registrants.

## Review and validation

- Trace affected flows through screens, navigation, stores, and form validation. Check empty, invalid, and success states and mounted checks around async state updates.
- Check keyboard and screen-reader labels, text scaling/layout constraints, touch targets, contrast, and optional user-controlled disclosure of sensitive information.
- Report concrete defects first with file and line references, impact, and a practical fix. Separate observed issues from unverified risks.
- When asked to validate, use `flutter analyze`; run focused tests or platform builds when requested or needed to verify a specific change. Do not add tests just to satisfy this skill.
- If tooling hangs or is unavailable, report the exact command and limitation; do not claim a clean result without output.

## Git

- Inspect `git status` and the relevant diff before editing or staging. Treat existing user changes as theirs and preserve them.
- Stage only files belonging to the requested change, and review the staged diff before committing. Keep commits focused and plainly described.
- Do not discard, reset, clean, or overwrite user changes. Ask before force-pushing, rewriting shared history, or changing remote state.
- Keep credentials, local configuration, and generated build output out of commits.
