import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:picklog/core/theme/pf_tokens.dart';
import 'package:picklog/core/theme/picklog_colors.dart';
import 'package:picklog/core/utils/app_router.dart';
import 'package:picklog/core/utils/l10n_extensions.dart';
import 'package:picklog/core/widgets/animated_state_switcher.dart';
import 'package:picklog/core/widgets/pf_button.dart';
import 'package:picklog/core/widgets/press_scale.dart';
import 'package:picklog/core/widgets/section_header.dart';
import 'package:picklog/features/ai/bloc/ai_status_cubit.dart';

/// Home entry points for AI: a "What should I play tonight?" card and a
/// smaller "Discover with AI" row.
///
/// Both stay hidden until `GET /ai/status` says AI is enabled, and when the
/// route provides no [AiStatusCubit].
class HomeAiEntry extends StatelessWidget {
  const HomeAiEntry({super.key});

  @override
  Widget build(BuildContext context) {
    final AiStatusCubit cubit;
    try {
      cubit = context.read<AiStatusCubit>();
    } on ProviderNotFoundException {
      return const SizedBox.shrink();
    }
    return BlocBuilder<AiStatusCubit, AiStatusState>(
      bloc: cubit,
      buildWhen: (p, c) => p.isEnabled != c.isEnabled,
      builder: (context, state) => AnimatedSize(
        duration: PfMotion.of(context, PfMotion.standard),
        curve: PfMotion.forge,
        alignment: Alignment.topCenter,
        child: AnimatedStateSwitcher(
          stateKey: state.isEnabled,
          child: state.isEnabled
              ? const _Entries()
              : const SizedBox(width: double.infinity),
        ),
      ),
    );
  }
}

class _Entries extends StatelessWidget {
  const _Entries();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = context.pfColors;

    return Padding(
      padding: const EdgeInsets.fromLTRB(PfSpace.lg, 0, PfSpace.lg, PfSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PressScale(
            scale: 0.985,
            semanticLabel: l10n.aiPlayNextHeadline,
            onTap: () => context.pushNamed(AppRouter.aiPlayNextName),
            child: ExcludeSemantics(
              child: Container(
                padding: const EdgeInsets.all(PfSpace.lg),
                decoration: BoxDecoration(
                  color: colors.surface1,
                  borderRadius: PfRadius.cardAll,
                  border: Border.all(color: colors.hairlineStrong),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colors.ember.withValues(
                        alpha: colors.isDark ? 0.10 : 0.07,
                      ),
                      colors.surface1,
                    ],
                    stops: const [0, 0.6],
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Eyebrow(l10n.aiEyebrowPlayNext, muted: true),
                          const SizedBox(height: PfSpace.sm),
                          Text(
                            l10n.aiPlayNextHeadline,
                            style: theme.textTheme.headlineSmall,
                          ),
                          const SizedBox(height: PfSpace.xs),
                          Text(
                            l10n.aiHomeCardSubtitle,
                            style: theme.textTheme.bodyMedium!.copyWith(
                              color: colors.textMed,
                            ),
                          ),
                          const SizedBox(height: PfSpace.md),
                          PfButton(
                            label: l10n.aiHomeCardAction,
                            icon: Icons.auto_awesome_outlined,
                            size: PfButtonSize.sm,
                            onPressed: () =>
                                context.pushNamed(AppRouter.aiPlayNextName),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: PfSpace.sm),
          Material(
            color: Colors.transparent,
            child: ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: PfRadius.cardAll,
                side: BorderSide(color: colors.hairline),
              ),
              tileColor: colors.surface1,
              leading: Icon(Icons.travel_explore, color: colors.textMed),
              title: Text(l10n.aiDiscoverTitle),
              subtitle: Text(l10n.aiHomeDiscoverSubtitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.pushNamed(AppRouter.aiDiscoverName),
            ),
          ),
        ],
      ),
    );
  }
}
