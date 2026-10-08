import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:picklog/core/theme/pf_tokens.dart';
import 'package:picklog/core/theme/pf_typography.dart';
import 'package:picklog/core/theme/picklog_colors.dart';
import 'package:picklog/core/utils/app_router.dart';
import 'package:picklog/core/utils/l10n_extensions.dart';
import 'package:picklog/core/widgets/animated_state_switcher.dart';
import 'package:picklog/core/widgets/app_scaffold.dart';
import 'package:picklog/core/widgets/game_cover.dart';
import 'package:picklog/core/widgets/pf_button.dart';
import 'package:picklog/core/widgets/score_badge.dart';
import 'package:picklog/core/widgets/section_header.dart';
import 'package:picklog/core/widgets/staggered_reveal.dart';
import 'package:picklog/core/widgets/state_views.dart';
import 'package:picklog/features/ai/ai_l10n.dart';
import 'package:picklog/features/ai/ai_models.dart';
import 'package:picklog/features/ai/ai_repository.dart';
import 'package:picklog/features/ai/bloc/ai_status_cubit.dart';
import 'package:picklog/features/ai/bloc/discover_cubit.dart';
import 'package:picklog/features/ai/widgets/ai_feature_gate.dart';
import 'package:picklog/features/ai/widgets/ai_loading_view.dart';
import 'package:picklog/features/library/bloc/library_bloc.dart';
import 'package:picklog/features/library/widgets/add_to_library_bottom_sheet.dart';

/// Prompt-based discovery: describe a mood, get games you do not own yet.
class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.aiDiscoverTitle)),
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
  late final TextEditingController _prompt = TextEditingController(
    text: context.read<DiscoverCubit>().state.prompt,
  );

  @override
  void dispose() {
    _prompt.dispose();
    super.dispose();
  }

  void _submit([String? text]) {
    if (text != null) _prompt.text = text;
    FocusScope.of(context).unfocus();
    context.read<DiscoverCubit>().discover(_prompt.text);
  }

  void _onStateChanged(BuildContext context, DiscoverState state) {
    final aiStatus = context.read<AiStatusCubit>();
    if (state.status == DiscoverStatus.success &&
        state.remainingToday != null) {
      aiStatus.updateRemaining(state.remainingToday!);
    } else if (state.status == DiscoverStatus.failure) {
      if (state.errorKind == AiErrorKind.consentRequired) {
        aiStatus.markConsentMissing();
      } else if (state.errorKind == AiErrorKind.quotaExceeded) {
        aiStatus.updateRemaining(0);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = context.pfColors;
    final suggestions = [
      l10n.aiDiscoverSuggestion1,
      l10n.aiDiscoverSuggestion2,
      l10n.aiDiscoverSuggestion3,
    ];

    return BlocListener<DiscoverCubit, DiscoverState>(
      listenWhen: (p, c) => p.status != c.status,
      listener: _onStateChanged,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          PfSpace.lg,
          PfSpace.sm,
          PfSpace.lg,
          PfSpace.xxl,
        ),
        child: MaxWidthBox(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Eyebrow(l10n.aiEyebrowDiscover),
              const SizedBox(height: PfSpace.sm),
              Semantics(
                header: true,
                child: Text(
                  l10n.aiDiscoverHeadline,
                  style: theme.textTheme.headlineMedium,
                ),
              ),
              const SizedBox(height: PfSpace.xs),
              Text(
                l10n.aiDiscoverSubtitle,
                style: theme.textTheme.bodyMedium!.copyWith(
                  color: colors.textMed,
                ),
              ),
              const SizedBox(height: PfSpace.xl),
              BlocBuilder<DiscoverCubit, DiscoverState>(
                buildWhen: (p, c) => p.isLoading != c.isLoading,
                builder: (context, state) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _prompt,
                        maxLength: kDiscoverPromptMax,
                        maxLengthEnforcement: MaxLengthEnforcement.enforced,
                        minLines: 1,
                        maxLines: 3,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) => _submit(),
                        decoration: InputDecoration(
                          labelText: l10n.aiDiscoverPromptLabel,
                          hintText: l10n.aiDiscoverPromptHint,
                        ),
                      ),
                      const SizedBox(height: PfSpace.sm),
                      Eyebrow(l10n.aiDiscoverSuggestionsLabel, muted: true),
                      const SizedBox(height: PfSpace.sm),
                      Wrap(
                        spacing: PfSpace.sm,
                        runSpacing: PfSpace.sm,
                        children: [
                          for (final s in suggestions)
                            ActionChip(
                              avatar: const Icon(Icons.north_east, size: 14),
                              label: Text(s),
                              onPressed: state.isLoading
                                  ? null
                                  : () => _submit(s),
                            ),
                        ],
                      ),
                      const SizedBox(height: PfSpace.lg),
                      Row(
                        children: [
                          PfButton(
                            label: l10n.aiDiscoverSubmit,
                            icon: Icons.auto_awesome_outlined,
                            isBusy: state.isLoading,
                            onPressed: _submit,
                          ),
                          const SizedBox(width: PfSpace.md),
                          const Expanded(child: _RemainingCounter()),
                        ],
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: PfSpace.xl),
              const _Results(),
            ],
          ),
        ),
      ),
    );
  }
}

class _RemainingCounter extends StatelessWidget {
  const _RemainingCounter();

  @override
  Widget build(BuildContext context) {
    final status = context.select((AiStatusCubit c) => c.state.status);
    if (status == null || status.dailyLimit <= 0) {
      return const SizedBox.shrink();
    }
    return Text(
      context.l10n.aiRemainingToday(status.remainingToday, status.dailyLimit),
      maxLines: 2,
      style: PfTypography.monoStyle(context.pfColors.textMed, size: 12),
    );
  }
}

class _Results extends StatelessWidget {
  const _Results();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocBuilder<DiscoverCubit, DiscoverState>(
      builder: (context, state) {
        final Widget child;
        final Object key;
        switch (state.status) {
          case DiscoverStatus.initial:
            key = 'idle';
            child = const SizedBox.shrink();
          case DiscoverStatus.loading:
            key = 'loading';
            child = AiLoadingView(
              lines: [
                l10n.aiLoadingDiscover1,
                l10n.aiLoadingDiscover2,
                l10n.aiLoadingDiscover3,
                l10n.aiLoadingPlayNext4,
              ],
            );
          case DiscoverStatus.failure:
            key = 'failure-${state.errorKind}';
            child = switch (state.errorKind) {
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
              final kind => ErrorState(
                message: (kind ?? AiErrorKind.unknown).message(context),
                onRetry: () => context.read<DiscoverCubit>().retry(),
              ),
            };
          case DiscoverStatus.success:
            key = state.picks;
            child = state.picks.isEmpty
                ? EmptyState(
                    icon: Icons.travel_explore,
                    title: l10n.aiDiscoverEmptyTitle,
                    message: l10n.aiDiscoverEmptyMessage,
                  )
                : _PickGrid(picks: state.picks);
        }
        return AnimatedStateSwitcher(stateKey: key, child: child);
      },
    );
  }
}

class _PickGrid extends StatelessWidget {
  const _PickGrid({required this.picks});

  final List<DiscoverPick> picks;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            context.l10n.aiResultsTitle,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        const SizedBox(height: PfSpace.md),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= PfBreakpoints.twoPane
                ? 2
                : 1;
            final width =
                (constraints.maxWidth - PfSpace.md * (columns - 1)) / columns;
            return Wrap(
              spacing: PfSpace.md,
              runSpacing: PfSpace.md,
              children: [
                for (var i = 0; i < picks.length; i++)
                  SizedBox(
                    width: width,
                    child: StaggeredReveal(
                      index: i,
                      child: DiscoverPickCard(pick: picks[i]),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

/// A discover result: cover, name, year, rating, reason and actions.
class DiscoverPickCard extends StatelessWidget {
  const DiscoverPickCard({required this.pick, super.key});

  final DiscoverPick pick;

  Future<void> _addToLibrary(BuildContext context) async {
    LibraryBloc? libraryBloc;
    try {
      libraryBloc = context.read<LibraryBloc>();
    } on ProviderNotFoundException {
      libraryBloc = null;
    }
    if (libraryBloc == null) return;
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: false,
      builder: (_) => BlocProvider.value(
        value: libraryBloc!,
        child: AddToLibraryBottomSheet(
          gameId: pick.game.id,
          gameName: pick.game.name,
          platforms: const [],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = context.pfColors;
    final game = pick.game;
    final score = normalizeScore(game.totalRating);
    final year = game.firstReleaseDate?.year;

    return Semantics(
      container: true,
      child: AiPickCardFrame(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GameCover(
              url: game.coverUrl,
              width: kAiPickCoverWidth,
              height: kAiPickCoverWidth * 4 / 3,
              borderRadius: PfRadius.sm + 2,
              semanticLabel: l10n.gameCoverLabel(game.name),
            ),
            const SizedBox(width: PfSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    game.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleLarge,
                  ),
                  if (year != null || score != null) ...[
                    const SizedBox(height: PfSpace.xs + 2),
                    Wrap(
                      spacing: PfSpace.sm,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (year != null)
                          Text(
                            '$year',
                            style: PfTypography.monoStyle(colors.textMed),
                          ),
                        if (score != null)
                          ScoreBadge(
                            score: score,
                            semanticLabel: l10n.aiRatingLabel(score),
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: PfSpace.sm),
                  Text(
                    pick.reason,
                    style: theme.textTheme.bodyMedium!.copyWith(
                      color: colors.textMed,
                    ),
                  ),
                  const SizedBox(height: PfSpace.md),
                  Wrap(
                    spacing: PfSpace.sm,
                    runSpacing: PfSpace.sm,
                    children: [
                      PfButton(
                        label: l10n.addToLibrary,
                        icon: Icons.add,
                        size: PfButtonSize.sm,
                        variant: PfButtonVariant.secondary,
                        onPressed: () => _addToLibrary(context),
                      ),
                      PfButton(
                        label: l10n.aiOpenGame,
                        size: PfButtonSize.sm,
                        variant: PfButtonVariant.ghost,
                        onPressed: () => context.pushNamed(
                          AppRouter.gameDetailsName,
                          pathParameters: {'id': '${game.id}'},
                        ),
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
