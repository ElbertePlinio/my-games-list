import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:picklog/core/utils/app_router.dart';
import 'package:picklog/core/utils/l10n_extensions.dart';
import 'package:picklog/core/widgets/animated_state_switcher.dart';
import 'package:picklog/core/widgets/section_header.dart';
import 'package:picklog/core/widgets/state_views.dart';
import 'package:picklog/features/games/bloc/discovery_games_bloc.dart';
import 'package:picklog/features/games/bloc/discovery_games_event.dart';
import 'package:picklog/features/games/bloc/discovery_games_state.dart';
import 'package:picklog/features/games/discovery_game_model.dart';
import 'package:picklog/features/games/widgets/discovery_game_tile.dart';
import 'package:picklog/features/games/widgets/game_rail.dart';
import 'package:picklog/features/games/widgets/skeletons/discovery_tile_skeleton.dart';
import 'package:visibility_detector/visibility_detector.dart';

/// Max cards shown in one home rail; "see all" opens the full list.
const int _maxRailItems = 20;

/// A horizontal rail of discovery games with a section header and "see all".
class DiscoveryGamesWidget extends StatelessWidget {
  const DiscoveryGamesWidget({
    required this.discoveryType,
    this.heroTagPrefix,
    super.key,
  });

  final DiscoveryType discoveryType;

  /// Namespaces the cover Hero tags of this row's tiles so the same game shown
  /// in another simultaneously-alive row doesn't collide. Defaults to a
  /// prefix unique to the discovery type.
  final String? heroTagPrefix;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DiscoveryGamesBloc, DiscoveryGamesState>(
      buildWhen: (previous, current) =>
          previous.getStateForType(discoveryType) !=
          current.getStateForType(discoveryType),
      builder: (context, state) => _DiscoveryRow(
        type: discoveryType,
        typeState: state.getStateForType(discoveryType),
        heroTagPrefix: heroTagPrefix ?? '${discoveryType.queryParam}-',
      ),
    );
  }
}

/// A lazy-loading wrapper for [DiscoveryGamesWidget] that only triggers
/// data loading when the widget becomes visible in the viewport.
class LazyDiscoveryGamesWidget extends StatefulWidget {
  const LazyDiscoveryGamesWidget({
    required this.discoveryType,
    this.heroTagPrefix,
    this.visibilityThreshold = 0.1,
    super.key,
  });

  final DiscoveryType discoveryType;

  /// See [DiscoveryGamesWidget.heroTagPrefix].
  final String? heroTagPrefix;

  /// The fraction of the widget that must be visible to trigger loading (0.0 to 1.0)
  final double visibilityThreshold;

  @override
  State<LazyDiscoveryGamesWidget> createState() =>
      _LazyDiscoveryGamesWidgetState();
}

class _LazyDiscoveryGamesWidgetState extends State<LazyDiscoveryGamesWidget> {
  bool _hasTriggeredLoad = false;

  String get _prefix =>
      widget.heroTagPrefix ?? '${widget.discoveryType.queryParam}-';

  void _onVisibilityChanged(VisibilityInfo info) {
    if (!_hasTriggeredLoad &&
        info.visibleFraction >= widget.visibilityThreshold) {
      setState(() {
        _hasTriggeredLoad = true;
      });
      context.read<DiscoveryGamesBloc>().add(
        DiscoveryGamesLoadRequested(widget.discoveryType),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key('lazy_discovery_$_prefix${widget.discoveryType.queryParam}'),
      onVisibilityChanged: _onVisibilityChanged,
      child: BlocBuilder<DiscoveryGamesBloc, DiscoveryGamesState>(
        buildWhen: (previous, current) =>
            previous.getStateForType(widget.discoveryType) !=
            current.getStateForType(widget.discoveryType),
        builder: (context, state) {
          final typeState = state.getStateForType(widget.discoveryType);
          return _DiscoveryRow(
            type: widget.discoveryType,
            typeState: typeState,
            heroTagPrefix: _prefix,
            // Before the first load the row shows its skeleton.
            forceLoading: !_hasTriggeredLoad,
          );
        },
      ),
    );
  }
}

enum _RowView { loading, error, content }

class _DiscoveryRow extends StatelessWidget {
  const _DiscoveryRow({
    required this.type,
    required this.typeState,
    required this.heroTagPrefix,
    this.forceLoading = false,
  });

  final DiscoveryType type;
  final DiscoveryTypeState typeState;
  final String heroTagPrefix;
  final bool forceLoading;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final title = type.localizedName(context);

    final _RowView view;
    if (forceLoading || (typeState.isLoading && !typeState.hasGames)) {
      view = _RowView.loading;
    } else if (typeState.status == DiscoveryGamesStatus.failure &&
        !typeState.hasGames) {
      view = _RowView.error;
    } else if (!typeState.hasGames) {
      return const SizedBox.shrink();
    } else {
      view = _RowView.content;
    }

    final games = typeState.games;
    final count = games.length > _maxRailItems ? _maxRailItems : games.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: title,
          seeAllLabel: l10n.seeAll,
          onSeeAll: view == _RowView.content
              ? () => context.pushNamed(
                  AppRouter.discoveryName,
                  pathParameters: {'type': type.queryParam},
                )
              : null,
        ),
        AnimatedStateSwitcher(
          stateKey: view,
          child: switch (view) {
            _RowView.loading => const DiscoveryRowSkeleton(),
            _RowView.error => ErrorState(
              compact: true,
              message: l10n.failedToLoadGames,
              onRetry: () => context.read<DiscoveryGamesBloc>().add(
                DiscoveryGamesLoadRequested(type),
              ),
            ),
            _RowView.content => GameRail(
              itemCount: count,
              itemBuilder: (context, index) => DiscoveryGameTile(
                game: games[index],
                isCompact: true,
                heroTagPrefix: heroTagPrefix,
              ),
            ),
          },
        ),
      ],
    );
  }
}
