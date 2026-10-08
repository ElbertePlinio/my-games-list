import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:picklog/core/theme/pf_tokens.dart';
import 'package:picklog/core/theme/pf_typography.dart';
import 'package:picklog/core/theme/picklog_colors.dart';
import 'package:picklog/core/utils/l10n_extensions.dart';
import 'package:picklog/core/utils/messages_extensions.dart';
import 'package:picklog/core/widgets/section_header.dart';
import 'package:picklog/features/ai/bloc/ai_status_cubit.dart';
import 'package:picklog/features/ai/widgets/ai_consent_dialog.dart';

/// Settings group "AI suggestions": the consent switch and today's usage.
///
/// Granting opens the same explicit opt-in dialog as the AI screens.
/// Revoking takes effect at once. Renders nothing when the route provides no
/// [AiStatusCubit].
class AiSettingsSection extends StatelessWidget {
  const AiSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final AiStatusCubit cubit;
    try {
      cubit = context.read<AiStatusCubit>();
    } on ProviderNotFoundException {
      return const SizedBox.shrink();
    }
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: PfSpace.xs, bottom: PfSpace.sm),
          child: Semantics(
            header: true,
            child: Eyebrow(l10n.aiSettingsTitle, muted: true),
          ),
        ),
        BlocConsumer<AiStatusCubit, AiStatusState>(
          bloc: cubit,
          listenWhen: (p, c) =>
              c.consentErrorKind != null &&
              p.consentErrorKind != c.consentErrorKind,
          listener: (context, _) =>
              context.showErrorMessage(l10n.aiConsentSaveError),
          builder: (context, state) => Card(child: _content(context, state)),
        ),
      ],
    );
  }

  Widget _content(BuildContext context, AiStatusState state) {
    final l10n = context.l10n;
    final cubit = context.read<AiStatusCubit>();
    switch (state.load) {
      case AiStatusLoad.failure:
        return ListTile(
          leading: const Icon(Icons.error_outline),
          title: Text(l10n.aiSettingsLoadError),
          trailing: IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: l10n.browseRetry,
            onPressed: cubit.load,
          ),
        );
      case AiStatusLoad.initial:
      case AiStatusLoad.loading:
        return SwitchListTile(
          secondary: const Icon(Icons.auto_awesome_outlined),
          title: Text(l10n.aiSettingsSwitch),
          value: false,
          onChanged: null,
        );
      case AiStatusLoad.ready:
        break;
    }
    final status = state.status!;
    if (!status.enabled) {
      return ListTile(
        leading: const Icon(Icons.cloud_off_outlined),
        title: Text(l10n.aiSettingsTitle),
        subtitle: Text(l10n.aiSettingsUnavailable),
      );
    }

    return Column(
      children: [
        SwitchListTile(
          secondary: const Icon(Icons.auto_awesome_outlined),
          title: Text(l10n.aiSettingsSwitch),
          subtitle: Text(
            status.consented
                ? l10n.aiSettingsSwitchOn
                : l10n.aiSettingsSwitchOff,
          ),
          value: status.consented,
          onChanged: state.isSavingConsent
              ? null
              : (value) =>
                    value ? ensureAiConsent(context) : cubit.setConsent(false),
        ),
        if (status.dailyLimit > 0) ...[
          const Divider(height: 1),
          _Usage(used: status.usedToday, limit: status.dailyLimit),
        ],
      ],
    );
  }
}

class _Usage extends StatelessWidget {
  const _Usage({required this.used, required this.limit});

  final int used;
  final int limit;

  @override
  Widget build(BuildContext context) {
    final colors = context.pfColors;
    final fraction = (used / limit).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        PfSpace.lg,
        PfSpace.md,
        PfSpace.lg,
        PfSpace.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.aiSettingsUsage(used, limit),
            style: PfTypography.monoStyle(colors.textMed),
          ),
          const SizedBox(height: PfSpace.sm),
          ClipRRect(
            borderRadius: PfRadius.pillAll,
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 4,
              color: fraction >= 1 ? colors.warning : colors.textMed,
              backgroundColor: colors.surface3,
            ),
          ),
        ],
      ),
    );
  }
}
