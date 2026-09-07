Keep shared infrastructure generic; feature business logic belongs under `lib/features/`. Routing, dependency wiring and session teardown are deliberate integration points that reference features, not a reason to move feature logic into core.

ConsentService owns consent persistence and collector side effects. Categories default to denied; load consent before collection starts. Push registration requires both consent and authentication. Keep session teardown in SessionResetService, including consent revocation before credentials are cleared and resetting user-scoped singletons.
