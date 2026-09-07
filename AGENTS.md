Use `fvm flutter` and `fvm dart` with the version pinned in `.fvmrc`. Derive package imports from `pubspec.yaml`, which declares `picklog`; do not sweep unrelated imports.

Run `fvm flutter pub get` for dependencies. Use `make run-staging` or `make run-production` to copy Firebase config and pass the flavor and dart-defines; plain Flutter run uses the default environment. The `make setup-*` prerequisites use macOS PlistBuddy and do not run on Linux.

For code changes, run `fvm flutter analyze` and relevant `fvm flutter test` checks. CI checks localization generation drift, runs `fvm dart format --output=none --set-exit-if-changed lib test`, enforces a 38% line coverage floor and runs `tool/check_hardcoded_strings.sh`, which rejects capitalized literals in `Text(...)`.

Keep feature business logic under `lib/features/` and reusable infrastructure under `lib/core/`. Follow the existing UI to BLoC to repository to HTTP client separation. Use dependency interfaces where they provide a substitution boundary; do not add an interface to every concrete repository by default.

Keep route-scoped BLoC providers and lazy feature repository registration in `lib/core/utils/app_router.dart`, not screen widgets. Global services and BLoCs belong in `lib/core/utils/service_locator.dart`. Preserve the shared LibraryBloc lifecycle and the independent tab stacks in `StatefulShellRoute.indexedStack`. Use GoRouter navigation, preferably named routes, rather than direct Navigator pushes.

Use `context.l10n` for user-facing text. Update both `lib/l10n/app_en.arb` and `lib/l10n/app_pt.arb`, then run `fvm flutter gen-l10n`. Commit generated localization changes. Use placeholders for dynamic text. Long legal text belongs in locale assets rather than ARB strings. Legal text under `assets/legal/` and branding art are placeholders, not release approval. Bump `kConsentVersion` when legal text changes; signup requires `consent_version`.

Use `IHttpClient` and the shared `ApiError` mapping for API access and user-facing errors. Keep tokens behind `TokenStorage`, not general preferences. Logout and account deletion must use the central session teardown so the next account cannot inherit user state or consent.

Keep first-load skeletons aligned with their real cards when dimensions change. Focus validation on the behavior being changed; documentation-only edits do not require app tests.
