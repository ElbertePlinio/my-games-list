# MyGamesList app

Flutter client for Android, iOS and web. Package name is `picklog`, so imports are `package:picklog/...`. BLoC, GoRouter, get_it. Flutter is pinned with FVM.

```
fvm flutter pub get
fvm flutter gen-l10n            # after editing ARB files; CI fails if the output isn't committed
make run-staging                # or run-production. These copy the right Firebase config and pass the flavor and dart-defines. Plain flutter run silently uses the default env.
fvm flutter analyze && fvm flutter test
```

Worth knowing:

- CI also runs `dart format --set-exit-if-changed lib test`, enforces a 38% line coverage floor, and runs `tool/check_hardcoded_strings.sh`, which rejects capitalized literals in `Text(...)`. User-facing text goes through `context.l10n.*` in both `app_en.arb` and `app_pt.arb`.
- BLoC providers and repository registration live in `app_router.dart`, not in screens.
- `make setup-*` uses macOS PlistBuddy, so it doesn't run on Linux.
- Legal texts under `assets/legal/` and the branding art are placeholders. Bump `kConsentVersion` when the legal text changes; the API requires `consent_version` on signup.
