Consume ConsentService rather than reimplementing gating in widgets or ConsentCubit. The cubit mirrors the service stream so revocation elsewhere updates the banner and settings together. Keep the shared answered flag in the service; revokeAll clears it so another account is prompted again.

For consent widget harness placement and async-zone pitfalls, see `../../../docs/ui-reference.md`.
