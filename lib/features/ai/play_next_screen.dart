import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:picklog/core/theme/pf_tokens.dart';
import 'package:picklog/core/theme/pf_typography.dart';
import 'package:picklog/core/theme/picklog_colors.dart';
import 'package:picklog/core/utils/app_router.dart';
import 'package:picklog/core/utils/l10n_extensions.dart';
import 'package:picklog/core/utils/messages_extensions.dart';
import 'package:picklog/core/widgets/animated_state_switcher.dart';
import 'package:picklog/core/widgets/app_scaffold.dart';
import 'package:picklog/core/widgets/game_cover.dart';
import 'package:picklog/core/widgets/pf_button.dart';
import 'package:picklog/core/widgets/section_header.dart';
import 'package:picklog/core/widgets/staggered_reveal.dart';
import 'package:picklog/core/widgets/state_views.dart';
import 'package:picklog/core/widgets/status_pill.dart';
import 'package:picklog/features/ai/ai_l10n.dart';
import 'package:picklog/features/ai/ai_models.dart';
import 'package:picklog/features/ai/ai_repository.dart';
import 'package:picklog/features/ai/bloc/ai_status_cubit.dart';
import 'package:picklog/features/ai/bloc/play_next_cubit.dart';
import 'package:picklog/features/ai/widgets/ai_feature_gate.dart';
import 'package:picklog/features/ai/widgets/ai_loading_view.dart';

/// "What should I play tonight?": mood, time, platform and a note in, up to
/// five picks from the user's backlog out.
class PlayNextScreen extends StatelessWidget {
  const PlayNextScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.aiPlayNextTitle)),
      body: const SafeArea(top: false, child: AiFeatureGate(child: _Body())),
    );
  }
}

class _Body extends StatefulWidget {
  const _Body();

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  final _resultsKey = GlobalKey();

  void _onStateChanged(BuildContext context, PlayNextState state) {
    final aiStatus = context.read<AiStatusCubit>();
    if (state.status == PlayNextStatus.success) {
      final remaining = state.remainingToday;
      if (remaining != null) aiStatus.updateRemaining(remaining);
      _revealResults();
    } else if (state.status == PlayNextStatus.failure) {
      if (state.errorKind == AiErrorKind.consentRequired) {
        aiStatus.markConsentMissing();
      } else if (state.errorKind == AiErrorKind.quotaExceeded) {
        aiStatus.updateRemaining(0);
      }
    } else if (state.status == PlayNextStatus.loading) {
      _revealResults();
    }
  }

  /// On phones the results sit under the form; bring them into view.
  void _revealResults() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = _resultsKey.currentContext;
      if (target == null || !mounted) return;
      Scrollable.ensureVisible(
        target,
        duration: PfMotion.of(context, PfMotion.slow),
        curve: PfMotion.forge,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<PlayNextCubit, PlayNextState>(
          listenWhen: (p, c) => p.status != c.status,
          listener: _onStateChanged,
        ),
        BlocListener<PlayNextCubit, PlayNextState>(
          listenWhen: (p, c) => p.startFailureCount != c.startFailureCount,
          listener: (context, _) =>
              context.showErrorMessage(context.l10n.aiStartPlayingError),
        ),
      ],
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Nothing to pick from: lead with the way out instead of a form
          // that cannot work.
          final libraryEmpty = context.select(
            (PlayNextCubit c) => c.state.backlogCount == 0,
          );
          if (libraryEmpty) return const _EmptyBacklog();
          final wide = constraints.maxWidth >= PfBreakpoints.twoPane;
          if (wide) {
            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: PfBreakpoints.content,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(
                      width: 400,
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(PfSpace.xl),
                        child: _PlayNextForm(),
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(
                          PfSpace.lg,
                          PfSpace.xl,
                          PfSpace.xl,
                          PfSpace.xxl,
                        ),
                        child: _PlayNextResults(
                          key: _resultsKey,
                          showIdleHint: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              PfSpace.lg,
              PfSpace.sm,
              PfSpace.lg,
              PfSpace.xxl,
            ),
            child: MaxWidthBox(
              maxWidth: PfBreakpoints.narrow,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _PlayNextForm(),
                  const SizedBox(height: PfSpace.xl),
                  _PlayNextResults(key: _resultsKey, showIdleHint: false),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text, {this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: PfSpace.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.titleSmall),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class _PlayNextForm extends StatefulWidget {
  const _PlayNextForm();

  @override
  State<_PlayNextForm> createState() => _PlayNextFormState();
}

class _PlayNextFormState extends State<_PlayNextForm> {
  late final TextEditingController _note = TextEditingController(
    text: context.read<PlayNextCubit>().state.note,
  );

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  String _stopLabel(BuildContext context, int stop) {
    final l10n = context.l10n;
    if (stop == kPlayNextMinuteStops.length - 1) return l10n.aiDurationFourPlus;
    return formatAiDuration(l10n, kPlayNextMinuteStops[stop]);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = context.pfColors;
    final cubit = context.read<PlayNextCubit>();

    return BlocBuilder<PlayNextCubit, PlayNextState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Eyebrow(l10n.aiEyebrowPlayNext),
            const SizedBox(height: PfSpace.sm),
            Semantics(
              header: true,
              child: Text(
                l10n.aiPlayNextHeadline,
                style: theme.textTheme.headlineMedium,
              ),
            ),
            const SizedBox(height: PfSpace.xs),
            Text(
              l10n.aiPlayNextSubtitle,
              style: theme.textTheme.bodyMedium!.copyWith(
                color: colors.textMed,
              ),
            ),
            const SizedBox(height: PfSpace.xl),
            _FieldLabel(l10n.aiMoodLabel),
            Wrap(
              spacing: PfSpace.sm,
              runSpacing: PfSpace.sm,
              children: [
                for (final mood in AiMood.values)
                  ChoiceChip(
                    label: Text(mood.label(context)),
                    selected: state.mood == mood,
                    onSelected: (_) => cubit.selectMood(mood),
                  ),
              ],
            ),
            const SizedBox(height: PfSpace.xl),
            _FieldLabel(
              l10n.aiTimeLabel,
              trailing: Text(
                _stopLabel(context, state.minutesStop),
                style: PfTypography.monoStyle(colors.textHi, size: 13),
              ),
            ),
            Slider(
              value: state.minutesStop.toDouble(),
              max: (kPlayNextMinuteStops.length - 1).toDouble(),
              divisions: kPlayNextMinuteStops.length - 1,
              label: _stopLabel(context, state.minutesStop),
              semanticFormatterCallback: (v) => _stopLabel(context, v.round()),
              onChanged: (v) => cubit.setMinutesStop(v.round()),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: PfSpace.sm),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _stopLabel(context, 0),
                    style: PfTypography.monoStyle(colors.textMed, size: 11),
                  ),
                  Text(
                    _stopLabel(context, kPlayNextMinuteStops.length - 1),
                    style: PfTypography.monoStyle(colors.textMed, size: 11),
                  ),
                ],
              ),
            ),
            if (state.platforms.isNotEmpty) ...[
              const SizedBox(height: PfSpace.xl),
              _FieldLabel(l10n.aiPlatformLabel),
              Wrap(
                spacing: PfSpace.sm,
                runSpacing: PfSpace.sm,
                children: [
                  ChoiceChip(
                    label: Text(l10n.aiPlatformAny),
                    selected: state.platformId == null,
                    onSelected: (_) => cubit.selectPlatform(null),
                  ),
                  for (final p in state.platforms)
                    ChoiceChip(
                      label: Text(p.label),
                      selected: state.platformId == p.id,
                      onSelected: (_) => cubit.selectPlatform(
                        state.platformId == p.id ? null : p.id,
                      ),
                    ),
                ],
              ),
            ],
            const SizedBox(height: PfSpace.xl),
            TextField(
              controller: _note,
              maxLength: kPlayNextNoteMax,
              maxLengthEnforcement: MaxLengthEnforcement.enforced,
              minLines: 1,
              maxLines: 3,
              textInputAction: TextInputAction.done,
              onChanged: cubit.setNote,
              decoration: InputDecoration(
                labelText: l10n.aiNoteLabel,
                hintText: l10n.aiNoteHint,
              ),
            ),
            const SizedBox(height: PfSpace.lg),
            PfButton(
              label: state.status == PlayNextStatus.success
                  ? l10n.aiRegenerateButton
                  : l10n.aiGenerateButton,
              icon: state.status == PlayNextStatus.success
                  ? Icons.refresh
                  : Icons.auto_awesome_outlined,
              size: PfButtonSize.lg,
              expand: true,
              isBusy: state.isLoading,
              onPressed: state.backlogCount == 0 ? null : cubit.generate,
            ),
            const SizedBox(height: PfSpace.sm),
            const Center(child: _RemainingCounter()),
          ],
        );
      },
    );
  }
}

/// "12 of 20 left today", from the freshest source.
class _RemainingCounter extends StatelessWidget {
  const _RemainingCounter();

  @override
  Widget build(BuildContext context) {
    final colors = context.pfColors;
    final status = context.select((AiStatusCubit c) => c.state.status);
    if (status == null || status.dailyLimit <= 0) {
      return const SizedBox.shrink();
    }
    return Text(
      context.l10n.aiRemainingToday(status.remainingToday, status.dailyLimit),
      style: PfTypography.monoStyle(colors.textMed, size: 12),
    );
  }
}

class _PlayNextResults extends StatelessWidget {
  const _PlayNextResults({required this.showIdleHint, super.key});

  /// Shows a quiet hint before the first run (wide layout only).
  final bool showIdleHint;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocBuilder<PlayNextCubit, PlayNextState>(
      builder: (context, state) {
        final Widget child;
        final Object key;
        if (state.isLoading) {
          key = 'loading';
          child = AiLoadingView(
            lines: [
              l10n.aiLoadingPlayNext1,
              l10n.aiLoadingPlayNext2,
              l10n.aiLoadingPlayNext3,
              l10n.aiLoadingPlayNext4,
            ],
          );
        } else if (state.isBacklogEmpty) {
          key = 'empty';
          child = const _EmptyBacklog();
        } else if (state.status == PlayNextStatus.failure) {
          key = 'failure-${state.errorKind}';
          child = _Failure(kind: state.errorKind ?? AiErrorKind.unknown);
        } else if (state.status == PlayNextStatus.success) {
          key = state.picks;
          child = _PickList(state: state);
        } else {
          key = 'idle';
          child = showIdleHint
              ? EmptyState(
                  icon: Icons.auto_awesome_outlined,
                  title: l10n.aiResultsTitle,
                  message: l10n.aiPlayNextSubtitle,
                )
              : const SizedBox.shrink();
        }
        return AnimatedStateSwitcher(stateKey: key, child: child);
      },
    );
  }
}

class _Failure extends StatelessWidget {
  const _Failure({required this.kind});

  final AiErrorKind kind;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return switch (kind) {
      AiErrorKind.quotaExceeded => EmptyState(
        icon: Icons.hourglass_empty,
        title: l10n.aiQuotaTitle,
        message: l10n.aiErrorQuotaExceeded,
      ),
      AiErrorKind.unavailable => EmptyState(
        icon: Icons.cloud_off_outlined,
        title: l10n.aiUnavailableTitle,
        message: l10n.aiErrorUnavailable,
      ),
      _ => ErrorState(
        message: kind.message(context),
        onRetry: () => context.read<PlayNextCubit>().generate(),
      ),
    };
  }
}

class _EmptyBacklog extends StatelessWidget {
  const _EmptyBacklog();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return EmptyState(
      icon: Icons.inventory_2_outlined,
      title: l10n.aiEmptyBacklogTitle,
      message: l10n.aiEmptyBacklogMessage,
      action: Wrap(
        alignment: WrapAlignment.center,
        spacing: PfSpace.sm,
        runSpacing: PfSpace.sm,
        children: [
          PfButton(
            label: l10n.aiGoExplore,
            icon: Icons.explore_outlined,
            variant: PfButtonVariant.secondary,
            onPressed: () => context.pushNamed(AppRouter.exploreName),
          ),
          PfButton(
            label: l10n.aiGoSearch,
            icon: Icons.search,
            variant: PfButtonVariant.secondary,
            onPressed: () => context.pushNamed(AppRouter.searchName),
          ),
        ],
      ),
    );
  }
}

class _PickList extends StatelessWidget {
  const _PickList({required this.state});

  final PlayNextState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<PlayNextCubit>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  l10n.aiResultsTitle,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
            ),
            PfButton(
              label: l10n.aiRegenerateButton,
              icon: Icons.refresh,
              size: PfButtonSize.sm,
              variant: PfButtonVariant.ghost,
              onPressed: cubit.generate,
            ),
          ],
        ),
        const SizedBox(height: PfSpace.md),
        for (var i = 0; i < state.picks.length; i++) ...[
          if (i > 0) const SizedBox(height: PfSpace.md),
          StaggeredReveal(
            index: i,
            child: PlayNextPickCard(
              pick: state.picks[i],
              isTopPick: i == 0,
              isStarting: state.startingIds.contains(
                state.picks[i].libraryEntryId,
              ),
              isStarted: state.startedIds.contains(
                state.picks[i].libraryEntryId,
              ),
              onStart: () => cubit.startPlaying(state.picks[i]),
              onOpen: () => context.pushNamed(
                AppRouter.gameDetailsName,
                pathParameters: {'id': '${state.picks[i].game.igdbId}'},
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// A rich play-next result: cover, name, reason, session length, actions.
class PlayNextPickCard extends StatelessWidget {
  const PlayNextPickCard({
    required this.pick,
    required this.onStart,
    required this.onOpen,
    this.isTopPick = false,
    this.isStarting = false,
    this.isStarted = false,
    super.key,
  });

  final PlayNextPick pick;
  final bool isTopPick;
  final bool isStarting;
  final bool isStarted;
  final VoidCallback onStart;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = context.pfColors;

    return Semantics(
      container: true,
      child: AiPickCardFrame(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GameCover(
              url: pick.game.coverUrl,
              width: kAiPickCoverWidth,
              height: kAiPickCoverWidth * 4 / 3,
              borderRadius: PfRadius.sm + 2,
              semanticLabel: l10n.gameCoverLabel(pick.game.name),
            ),
            const SizedBox(width: PfSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isTopPick) ...[
                    Eyebrow(l10n.aiTopPick, muted: true),
                    const SizedBox(height: PfSpace.xs),
                  ],
                  Text(
                    pick.game.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: PfSpace.xs + 2),
                  Text(
                    pick.reason,
                    style: theme.textTheme.bodyMedium!.copyWith(
                      color: colors.textMed,
                    ),
                  ),
                  if (pick.estimatedSessionMinutes > 0) ...[
                    const SizedBox(height: PfSpace.sm),
                    StatusPill(
                      label: l10n.aiSessionLength(
                        formatAiDuration(l10n, pick.estimatedSessionMinutes),
                      ),
                      tone: PfTone.neutral,
                      icon: Icons.schedule,
                    ),
                  ],
                  const SizedBox(height: PfSpace.md),
                  Wrap(
                    spacing: PfSpace.sm,
                    runSpacing: PfSpace.sm,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (isStarted)
                        StatusPill(
                          label: l10n.aiNowPlaying,
                          tone: PfTone.connected,
                          icon: Icons.play_arrow_rounded,
                        )
                      else
                        PfButton(
                          label: l10n.aiStartPlaying,
                          icon: Icons.play_arrow_rounded,
                          size: PfButtonSize.sm,
                          variant: PfButtonVariant.secondary,
                          isBusy: isStarting,
                          onPressed: onStart,
                        ),
                      PfButton(
                        label: l10n.aiOpenGame,
                        size: PfButtonSize.sm,
                        variant: PfButtonVariant.ghost,
                        onPressed: onOpen,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
