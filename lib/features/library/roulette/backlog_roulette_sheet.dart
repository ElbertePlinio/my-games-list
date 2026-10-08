import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:picklog/core/theme/pf_tokens.dart';
import 'package:picklog/core/theme/pf_typography.dart';
import 'package:picklog/core/theme/picklog_colors.dart';
import 'package:picklog/core/utils/l10n_extensions.dart';
import 'package:picklog/core/utils/messages_extensions.dart';
import 'package:picklog/core/widgets/game_card.dart';
import 'package:picklog/core/widgets/game_cover.dart';
import 'package:picklog/core/widgets/pf_button.dart';
import 'package:picklog/core/widgets/section_header.dart';
import 'package:picklog/core/widgets/state_views.dart';
import 'package:picklog/features/library/bloc/library_bloc.dart';
import 'package:picklog/features/library/bloc/library_event.dart';
import 'package:picklog/features/library/library_entry_model.dart';
import 'package:picklog/features/library/library_formatters.dart';
import 'package:picklog/features/library/roulette/roulette_cubit.dart';
import 'package:picklog/features/library/widgets/library_status_pill.dart';

/// "Pick for me": spins over the backlog (planned and on hold) and offers to
/// start the picked game.
class BacklogRouletteSheet extends StatelessWidget {
  const BacklogRouletteSheet({super.key});

  /// Opens the sheet over the shared library in [context].
  static Future<void> show(BuildContext context, {Random? random}) {
    final library = context.read<LibraryBloc>();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: library),
          BlocProvider(
            create: (_) =>
                RouletteCubit(library: library.state.entries, random: random),
          ),
        ],
        child: const BacklogRouletteSheet(),
      ),
    );
  }

  /// Hours-played limits offered as chips.
  static const List<int> hourOptions = [1, 5, 10];

  void _start(BuildContext context, LibraryEntry entry) {
    final l10n = context.l10n;
    context.read<LibraryBloc>().add(
      LibraryUpdateEntryRequested(entry: entry, status: GameStatus.playing),
    );
    context.showSuccessMessage(l10n.rouletteStarted(entry.game.name));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return BlocBuilder<RouletteCubit, RouletteState>(
      builder: (context, state) {
        if (state.backlog.isEmpty) {
          return Padding(
            padding: const EdgeInsets.only(bottom: PfSpace.xxl),
            child: EmptyState(
              icon: Icons.inbox_outlined,
              title: l10n.rouletteEmptyTitle,
              message: l10n.rouletteEmptyHint,
            ),
          );
        }

        final candidates = state.candidates;
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            PfSpace.xl,
            0,
            PfSpace.xl,
            PfSpace.xl,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Eyebrow(l10n.rouletteEyebrow),
                  const SizedBox(height: PfSpace.xs),
                  Text(
                    l10n.rouletteTitle,
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: PfSpace.xs),
                  Text(
                    l10n.rouletteCandidates(candidates.length),
                    style: PfTypography.monoStyle(context.pfColors.textMed),
                  ),
                  const SizedBox(height: PfSpace.lg),
                  ..._buildFilters(context, state),
                  const SizedBox(height: PfSpace.xl),
                  Center(
                    child: _SpinReel(
                      candidates: candidates,
                      picked: state.picked,
                      spins: state.spins,
                    ),
                  ),
                  const SizedBox(height: PfSpace.lg),
                  _buildResult(context, state),
                  const SizedBox(height: PfSpace.xl),
                  ..._buildActions(context, state),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Platform chips (only with more than one platform) and length chips.
  List<Widget> _buildFilters(BuildContext context, RouletteState state) {
    final l10n = context.l10n;
    final cubit = context.read<RouletteCubit>();
    final platforms = state.platforms;
    return [
      if (platforms.length > 1) ...[
        _ChipRow(
          children: [
            ChoiceChip(
              label: Text(l10n.rouletteAnyPlatform),
              selected: state.platformId == null,
              onSelected: (_) => cubit.setPlatform(null),
            ),
            for (final p in platforms)
              ChoiceChip(
                label: Text(p.displayName),
                selected: state.platformId == p.igdbPlatformId,
                onSelected: (v) =>
                    cubit.setPlatform(v ? p.igdbPlatformId : null),
              ),
          ],
        ),
        const SizedBox(height: PfSpace.sm),
      ],
      _ChipRow(
        children: [
          ChoiceChip(
            label: Text(l10n.rouletteAnyLength),
            selected: state.maxHoursPlayed == null,
            onSelected: (_) => cubit.setMaxHoursPlayed(null),
          ),
          for (final h in hourOptions)
            ChoiceChip(
              label: Text(l10n.rouletteMaxHours(h)),
              selected: state.maxHoursPlayed == h,
              onSelected: (v) => cubit.setMaxHoursPlayed(v ? h : null),
            ),
        ],
      ),
    ];
  }

  /// The pick, a no-match note, or the spin hint.
  Widget _buildResult(BuildContext context, RouletteState state) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    if (state.candidates.isEmpty) {
      return Text(
        l10n.rouletteNoMatch,
        textAlign: TextAlign.center,
        style: theme.textTheme.bodyMedium,
      );
    }
    if (state.picked != null) return _PickDetails(entry: state.picked!);
    return Text(
      l10n.rouletteHint,
      textAlign: TextAlign.center,
      style: theme.textTheme.bodyMedium!.copyWith(
        color: context.pfColors.textMed,
      ),
    );
  }

  /// Start and spin again after a pick, else a single spin button.
  List<Widget> _buildActions(BuildContext context, RouletteState state) {
    final l10n = context.l10n;
    final cubit = context.read<RouletteCubit>();
    final candidates = state.candidates;
    if (state.picked == null || candidates.isEmpty) {
      return [
        PfButton(
          key: const Key('roulette_spin_button'),
          label: l10n.rouletteSpin,
          icon: Icons.casino_outlined,
          expand: true,
          onPressed: candidates.isEmpty ? null : cubit.spin,
        ),
      ];
    }
    return [
      PfButton(
        key: const Key('roulette_start_button'),
        label: l10n.rouletteStartPlaying,
        icon: Icons.play_arrow_rounded,
        expand: true,
        onPressed: () => _start(context, state.picked!),
      ),
      const SizedBox(height: PfSpace.sm),
      PfButton(
        key: const Key('roulette_spin_button'),
        label: l10n.rouletteSpinAgain,
        icon: Icons.casino_outlined,
        variant: PfButtonVariant.secondary,
        expand: true,
        onPressed: candidates.length > 1 ? cubit.spin : null,
      ),
    ];
  }
}

class _ChipRow extends StatelessWidget {
  const _ChipRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(width: PfSpace.sm),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _PickDetails extends StatelessWidget {
  const _PickDetails({required this.entry});

  final LibraryEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      liveRegion: true,
      child: Column(
        children: [
          Text(
            entry.game.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: PfSpace.sm),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: PfSpace.sm,
            runSpacing: PfSpace.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              LibraryStatusPill(status: entry.status, dense: true),
              Text(
                [
                  if (entry.platform != null) entry.platform!.displayName,
                  formatPlaytime(context, entry.playtimeMinutes),
                ].join(' · '),
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Cover "reel" that flips through random covers and lands on the pick.
/// Under reduced motion it shows the pick at once.
class _SpinReel extends StatefulWidget {
  const _SpinReel({
    required this.candidates,
    required this.picked,
    required this.spins,
  });

  final List<LibraryEntry> candidates;
  final LibraryEntry? picked;
  final int spins;

  static const double width = 168;
  static const Duration duration = Duration(milliseconds: 1400);

  @override
  State<_SpinReel> createState() => _SpinReelState();
}

class _SpinReelState extends State<_SpinReel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _SpinReel.duration,
  );
  final Random _random = Random();
  List<LibraryEntry> _reel = const [];

  @override
  void didUpdateWidget(covariant _SpinReel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.spins != oldWidget.spins && widget.picked != null) {
      _startSpin();
    }
  }

  void _startSpin() {
    final picked = widget.picked!;
    final pool = widget.candidates;
    if (PfMotion.reduced(context) || pool.length < 2) {
      _controller.value = 1;
      setState(() => _reel = [picked]);
      return;
    }
    setState(() {
      _reel = [
        for (var i = 0; i < 14; i++) pool[_random.nextInt(pool.length)],
        picked,
      ];
    });
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.pfColors;
    const height = _SpinReel.width / kCoverAspectRatio;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        LibraryEntry? shown;
        if (_reel.isNotEmpty) {
          final eased = Curves.easeOutCubic.transform(_controller.value);
          shown = _reel[(eased * (_reel.length - 1)).round()];
        } else {
          shown = widget.picked;
        }
        final landed = !_controller.isAnimating && shown != null;
        return Container(
          width: _SpinReel.width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: PfRadius.cardAll,
            border: Border.all(color: colors.hairlineStrong),
            boxShadow: landed ? colors.shadowRaised : null,
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.all(
              Radius.circular(PfRadius.card - 1),
            ),
            child: shown == null
                ? _ReelPlaceholder(count: widget.candidates.length)
                : GameCover(
                    key: ValueKey(shown.id),
                    url: shown.game.coverUrl,
                    borderRadius: 0,
                    semanticLabel: landed
                        ? context.l10n.gameCoverLabel(shown.game.name)
                        : null,
                  ),
          ),
        );
      },
    );
  }
}

class _ReelPlaceholder extends StatelessWidget {
  const _ReelPlaceholder({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = context.pfColors;
    return ColoredBox(
      color: colors.surface2,
      child: Center(
        child: Icon(Icons.casino_outlined, size: 48, color: colors.textLow),
      ),
    );
  }
}
