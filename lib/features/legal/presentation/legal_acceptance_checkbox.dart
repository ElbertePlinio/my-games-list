import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:picklog/core/utils/app_router.dart';
import 'package:picklog/core/utils/l10n_extensions.dart';

/// Required Privacy Policy / Terms acceptance control used at sign-up.
///
/// Renders a checkbox next to a label whose "Privacy Policy" and "Terms of
/// Service" fragments are tappable and push the corresponding legal screens.
/// The label text is composed from localized fragments so it reads naturally in
/// each language without needing rich-text placeholders in the ARB.
class LegalAcceptanceCheckbox extends StatefulWidget {
  const LegalAcceptanceCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  State<LegalAcceptanceCheckbox> createState() =>
      _LegalAcceptanceCheckboxState();
}

class _LegalAcceptanceCheckboxState extends State<LegalAcceptanceCheckbox> {
  late final TapGestureRecognizer _privacyRecognizer;
  late final TapGestureRecognizer _termsRecognizer;

  @override
  void initState() {
    super.initState();
    _privacyRecognizer = TapGestureRecognizer()
      ..onTap = () => context.pushNamed(AppRouter.privacyPolicyName);
    _termsRecognizer = TapGestureRecognizer()
      ..onTap = () => context.pushNamed(AppRouter.termsName);
  }

  @override
  void dispose() {
    _privacyRecognizer.dispose();
    _termsRecognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final linkStyle = TextStyle(
      color: theme.colorScheme.primary,
      decoration: TextDecoration.underline,
      fontWeight: FontWeight.w600,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: widget.value,
          onChanged: (next) => widget.onChanged(next ?? false),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text.rich(
              TextSpan(
                style: theme.textTheme.bodyMedium,
                children: [
                  TextSpan(text: context.l10n.signUpAcceptPrefix),
                  TextSpan(
                    text: context.l10n.signUpAcceptPrivacyLink,
                    style: linkStyle,
                    recognizer: _privacyRecognizer,
                  ),
                  TextSpan(text: context.l10n.signUpAcceptConjunction),
                  TextSpan(
                    text: context.l10n.signUpAcceptTermsLink,
                    style: linkStyle,
                    recognizer: _termsRecognizer,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
