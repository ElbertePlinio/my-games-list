import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:picklog/core/theme/pf_tokens.dart';
import 'package:picklog/core/theme/picklog_colors.dart';
import 'package:picklog/core/utils/app_router.dart';
import 'package:picklog/core/utils/l10n_extensions.dart';
import 'package:picklog/core/utils/messages_extensions.dart';
import 'package:picklog/core/widgets/pf_button.dart';
import 'package:picklog/core/widgets/pf_dialog.dart';
import 'package:picklog/features/ai/bloc/ai_status_cubit.dart';

/// What the user chose in [AiConsentDialog].
enum AiConsentChoice { accept, decline, readPolicy }

/// Explicit opt-in for AI suggestions. Pops with an [AiConsentChoice].
///
/// It says in plain words what Picklog sends to OpenAI and what it never
/// sends. Nothing is sent before the user accepts.
class AiConsentDialog extends StatelessWidget {
  const AiConsentDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = context.pfColors;

    Widget point(IconData icon, String text, {Color? iconColor}) => Padding(
      padding: const EdgeInsets.only(top: PfSpace.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: iconColor ?? colors.textMed),
          const SizedBox(width: PfSpace.md),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium!.copyWith(color: colors.textHi),
            ),
          ),
        ],
      ),
    );

    return AlertDialog(
      icon: Center(
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: colors.surface2,
            borderRadius: PfRadius.mdAll,
            border: Border.all(color: colors.hairlineStrong),
          ),
          child: Icon(Icons.auto_awesome_outlined, color: colors.textHi),
        ),
      ),
      title: Text(l10n.aiConsentTitle),
      scrollable: true,
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            point(Icons.upload_outlined, l10n.aiConsentBody),
            point(
              Icons.shield_outlined,
              l10n.aiConsentNever,
              iconColor: colors.connectedFg,
            ),
            point(Icons.toggle_off_outlined, l10n.aiConsentRevoke),
            const SizedBox(height: PfSpace.sm),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton(
                // The dialog sits on a Navigator above the Router, so a
                // route pushed from here would open under it. Close first;
                // ensureAiConsent opens the policy and asks again.
                onPressed: () =>
                    Navigator.of(context).pop(AiConsentChoice.readPolicy),
                style: TextButton.styleFrom(
                  foregroundColor: colors.textMed,
                  padding: EdgeInsets.zero,
                ),
                child: Text(l10n.privacyPolicyTitle),
              ),
            ),
          ],
        ),
      ),
      actions: [
        PfButton(
          label: l10n.aiConsentDecline,
          variant: PfButtonVariant.ghost,
          onPressed: () => Navigator.of(context).pop(AiConsentChoice.decline),
        ),
        PfButton(
          label: l10n.aiConsentAccept,
          onPressed: () => Navigator.of(context).pop(AiConsentChoice.accept),
        ),
      ],
    );
  }
}

/// Returns true when the user has AI consent, asking first if needed.
///
/// Reads the route's [AiStatusCubit]. When the user accepts, consent is
/// stored through the API before this returns. When the user opens the
/// privacy policy, the dialog shows again after they come back.
Future<bool> ensureAiConsent(BuildContext context) async {
  final cubit = context.read<AiStatusCubit>();
  if (cubit.state.isConsented) return true;
  if (await _askAiConsent(context) != AiConsentChoice.accept) return false;
  final saved = await cubit.setConsent(true);
  if (!saved && context.mounted) {
    context.showErrorMessage(context.l10n.aiConsentSaveError);
  }
  return saved;
}

Future<AiConsentChoice?> _askAiConsent(BuildContext context) async {
  while (true) {
    if (!context.mounted) return null;
    final choice = await showPfDialog<AiConsentChoice>(
      context: context,
      builder: (_) => const AiConsentDialog(),
    );
    if (choice != AiConsentChoice.readPolicy || !context.mounted) {
      return choice;
    }
    await context.pushNamed<void>(AppRouter.privacyPolicyName);
  }
}
