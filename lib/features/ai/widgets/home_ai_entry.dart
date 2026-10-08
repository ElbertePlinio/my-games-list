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
    return Padding(
      padding: const EdgeInsets.fromLTRB(PfSpace.lg, 0, PfSpace.lg, PfSpace.lg),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= PfBreakpoints.twoPane) {
            return const IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 3, child: _PlayNextCard()),
                  SizedBox(width: PfSpace.md),
                  Expanded(flex: 2, child: _DiscoverEntry(vertical: true)),
                ],
              ),
            );
          }
          return const Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _PlayNextCard(),
              SizedBox(height: PfSpace.sm),
              _DiscoverEntry(vertical: false),
            ],
          );
        },
      ),
    );
  }
}

/// The prominent "What should I play tonight?" card.
class _PlayNextCard extends StatelessWidget {
  const _PlayNextCard();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = context.pfColors;
    void open() => context.pushNamed(AppRouter.aiPlayNextName);

    return PressScale(
      scale: 0.985,
      semanticLabel: l10n.aiPlayNextHeadline,
      onTap: open,
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
                colors.ember.withValues(alpha: colors.isDark ? 0.09 : 0.06),
                colors.surface1,
              ],
              stops: const [0, 0.6],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
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
                onPressed: open,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The smaller "Discover with AI" entry: a row on phones, a card on wide
/// screens next to the play next card.
class _DiscoverEntry extends StatelessWidget {
  const _DiscoverEntry({required this.vertical});

  final bool vertical;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = context.pfColors;
    final icon = Icon(Icons.travel_explore, color: colors.textMed);
    final texts = [
      Text(l10n.aiDiscoverTitle, style: theme.textTheme.titleMedium),
      const SizedBox(height: 2),
      Text(l10n.aiHomeDiscoverSubtitle, style: theme.textTheme.bodySmall),
    ];

    return Material(
      color: colors.surface1,
      shape: RoundedRectangleBorder(
        borderRadius: PfRadius.cardAll,
        side: BorderSide(color: colors.hairline),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.pushNamed(AppRouter.aiDiscoverName),
        child: Padding(
          padding: const EdgeInsets.all(PfSpace.lg),
          child: vertical
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        icon,
                        const Spacer(),
                        Icon(Icons.chevron_right, color: colors.textLow),
                      ],
                    ),
                    const Spacer(),
                    ...texts,
                  ],
                )
              : Row(
                  children: [
                    icon,
                    const SizedBox(width: PfSpace.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: texts,
                      ),
                    ),
                    Icon(Icons.chevron_right, color: colors.textLow),
                  ],
                ),
        ),
      ),
    );
  }
}
