# AI Integration

AI is not currently configured. The Flutter client must call a configurable HTTPS endpoint that verifies Firebase ID tokens, applies rate limits, and returns a typed response. The endpoint URL may be supplied with `--dart-define=HABI_AI_ENDPOINT=...`; this is configuration, not a secret. Never embed provider keys in Flutter or Firestore.

Until a secure endpoint exists, AI features must be labeled unavailable or demo. Demo output must not be represented as generated advice. Define request/response schemas, error handling, consent/privacy copy, and employer/seeker use cases before enabling the production interface. No provider or credential is assumed.
