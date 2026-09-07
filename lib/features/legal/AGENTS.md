Keep legal document bodies in per-locale files under `assets/legal/` at the app root; localize UI labels through l10n. Bump `kConsentVersion` in `legal_constants.dart` when the legal text materially changes. Signup and social auth send that version as `consent_version`.

Keep privacy and terms routes reachable before authentication. Preserve the signup acceptance check in SignUpBloc as well as the disabled submit button; the widget alone is not the gate. Do not treat placeholder legal text or a draft banner as published legal approval.
