import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:picklog/core/utils/app_router.dart';
import 'package:picklog/core/utils/l10n_extensions.dart';
import 'package:picklog/features/games/bloc/discovery_games_bloc.dart';
import 'package:picklog/features/games/bloc/discovery_games_event.dart';
import 'package:picklog/features/games/bloc/discovery_games_state.dart';
import 'package:picklog/features/games/discovery_game_model.dart';
import 'package:picklog/features/games/widgets/discovery_game_tile.dart';
import 'package:picklog/features/games/widgets/skeletons/discovery_tile_skeleton.dart';
import 'package:visibility_detector/visibility_detector.dart';

/// A horizontal scrollable widget displaying discovery games on the home screen
class DiscoveryGamesWidget extends StatelessWidget {
  const DiscoveryGamesWidget({
    required this.discoveryType,
    this.icon,
    this.heroTagPrefix = '',
    super.key,
  });

  final DiscoveryType discoveryType;
  final IconData? icon;

  /// Namespaces the cover Hero tags of this row's tiles so the same game shown
  /// in another simultaneously-alive row (e.g. the Home tab) doesn't collide.
  final String heroTagPrefix;

  IconData get _defaultIcon {
    switch (discoveryType) {
      case DiscoveryType.trending:
        return Icons.trending_up;
      case DiscoveryType.indie:
        return Icons.lightbulb_outline;
      case DiscoveryType.upcoming:
        return Icons.schedule;
      case DiscoveryType.newReleases:
        return Icons.fiber_new_outlined;
      case DiscoveryType.comingSoon:
        return Icons.upcoming_outlined;
    }
  }

  Color get _iconColor {
    switch (discoveryType) {
      case DiscoveryType.trending:
        return Colors.orange;
      case DiscoveryType.indie:
        return Colors.purple;
      case DiscoveryType.upcoming:
        return Colors.blue;
      case DiscoveryType.newReleases:
        return Colors.green;
      case DiscoveryType.comingSoon:
        return Colors.teal;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DiscoveryGamesBloc, DiscoveryGamesState>(
      buildWhen: (previous, current) {
        // Only rebuild when the state for this specific discovery type changes
        final prevTypeState = previous.getStateForType(discoveryType);
        final currTypeState = current.getStateForType(discoveryType);
        return prevTypeState != currTypeState;
      },
      builder: (context, state) {
        final typeState = state.getStateForType(discoveryType);

        if (typeState.isLoading && !typeState.hasGames) {
          return _WidgetLoading(
            title: discoveryType.localizedName(context),
            icon: icon ?? _defaultIcon,
            iconColor: _iconColor,
          );
        }

        if (typeState.status == DiscoveryGamesStatus.failure &&
            !typeState.hasGames) {
          return _WidgetError(
            title: discoveryType.localizedName(context),
            icon: icon ?? _defaultIcon,
            iconColor: _iconColor,
            message: context.l10n.failedToLoadGames,
            onRetry: () => context.read<DiscoveryGamesBloc>().add(
              DiscoveryGamesLoadRequested(discoveryType),
            ),
          );
        }

        if (!typeState.hasGames) {
          return const SizedBox.shrink();
        }

        return _WidgetContent(
          title: discoveryType.localizedName(context),
          icon: icon ?? _defaultIcon,
          iconColor: _iconColor,
          games: typeState.games,
          discoveryType: discoveryType,
          heroTagPrefix: heroTagPrefix,
        );
      },
    );
  }
}

/// A lazy-loading wrapper for DiscoveryGamesWidget that only triggers
/// data loading when the widget becomes visible in the viewport.
class LazyDiscoveryGamesWidget extends StatefulWidget {
  const LazyDiscoveryGamesWidget({
    required this.discoveryType,
    this.icon,
    this.heroTagPrefix = '',
    this.visibilityThreshold = 0.1,
    super.key,
  });

  final DiscoveryType discoveryType;
  final IconData? icon;

  /// Namespaces the cover Hero tags of this row's tiles so the same game shown
  /// in another simultaneously-alive row (e.g. the Home tab) doesn't collide.
  final String heroTagPrefix;

  /// The fraction of the widget that must be visible to trigger loading (0.0 to 1.0)
  final double visibilityThreshold;

  @override
  State<LazyDiscoveryGamesWidget> createState() =>
      _LazyDiscoveryGamesWidgetState();
}

class _LazyDiscoveryGamesWidgetState extends State<LazyDiscoveryGamesWidget> {
  bool _hasTriggeredLoad = false;

  IconData get _defaultIcon {
    switch (widget.discoveryType) {
      case DiscoveryType.trending:
        return Icons.trending_up;
      case DiscoveryType.indie:
        return Icons.lightbulb_outline;
      case DiscoveryType.upcoming:
        return Icons.schedule;
      case DiscoveryType.newReleases:
        return Icons.fiber_new_outlined;
      case DiscoveryType.comingSoon:
        return Icons.upcoming_outlined;
    }
  }

  Color get _iconColor {
    switch (widget.discoveryType) {
      case DiscoveryType.trending:
        return Colors.orange;
      case DiscoveryType.indie:
        return Colors.purple;
      case DiscoveryType.upcoming:
        return Colors.blue;
      case DiscoveryType.newReleases:
        return Colors.green;
      case DiscoveryType.comingSoon:
        return Colors.teal;
    }
  }

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
      key: Key(
        'lazy_discovery_${widget.heroTagPrefix}${widget.discoveryType.queryParam}',
      ),
      onVisibilityChanged: _onVisibilityChanged,
      child: BlocBuilder<DiscoveryGamesBloc, DiscoveryGamesState>(
        buildWhen: (previous, current) {
          // Only rebuild when the state for this specific discovery type changes
          final prevTypeState = previous.getStateForType(widget.discoveryType);
          final currTypeState = current.getStateForType(widget.discoveryType);
          return prevTypeState != currTypeState;
        },
        builder: (context, state) {
          final typeState = state.getStateForType(widget.discoveryType);

          // Show placeholder if load hasn't been triggered yet
          if (!_hasTriggeredLoad) {
            return _WidgetLoading(
              title: widget.discoveryType.localizedName(context),
              icon: widget.icon ?? _defaultIcon,
              iconColor: _iconColor,
            );
          }

          if (typeState.isLoading && !typeState.hasGames) {
            return _WidgetLoading(
              title: widget.discoveryType.localizedName(context),
              icon: widget.icon ?? _defaultIcon,
              iconColor: _iconColor,
            );
          }

          if (typeState.status == DiscoveryGamesStatus.failure &&
              !typeState.hasGames) {
            return _WidgetError(
              title: widget.discoveryType.localizedName(context),
              icon: widget.icon ?? _defaultIcon,
              iconColor: _iconColor,
              message: context.l10n.failedToLoadGames,
              onRetry: () => context.read<DiscoveryGamesBloc>().add(
                DiscoveryGamesLoadRequested(widget.discoveryType),
              ),
            );
          }

          if (!typeState.hasGames) {
            return const SizedBox.shrink();
          }

          return _WidgetContent(
            title: widget.discoveryType.localizedName(context),
            icon: widget.icon ?? _defaultIcon,
            iconColor: _iconColor,
            games: typeState.games,
            discoveryType: widget.discoveryType,
            heroTagPrefix: widget.heroTagPrefix,
          );
        },
      ),
    );
  }
}

class _WidgetContent extends StatelessWidget {
  const _WidgetContent({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.games,
    required this.discoveryType,
    this.heroTagPrefix = '',
  });

  final String title;
  final IconData icon;
  final Color iconColor;
  final List<DiscoveryGame> games;
  final DiscoveryType discoveryType;
  final String heroTagPrefix;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row with title and see all arrow
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 8, 12),
          child: Row(
            children: [
              Icon(icon, color: iconColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () => context.pushNamed(
                  AppRouter.discoveryName,
                  pathParameters: {'type': discoveryType.queryParam},
                ),
                icon: Text(context.l10n.seeAll),
                label: const Icon(Icons.arrow_forward_ios, size: 14),
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
        // Horizontal scrollable grid
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: games.length > 20 ? 20 : games.length,
            itemBuilder: (context, index) {
              final game = games[index];
              return Padding(
                padding: EdgeInsets.only(
                  right: index < games.length - 1 ? 12 : 0,
                ),
                child: AspectRatio(
                  aspectRatio: 0.7,
                  child: DiscoveryGameTile(
                    game: game,
                    isCompact: true,
                    heroTagPrefix: heroTagPrefix,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _WidgetLoading extends StatelessWidget {
  const _WidgetLoading({
    required this.title,
    required this.icon,
    required this.iconColor,
  });

  final String title;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Row(
            children: [
              Icon(icon, color: iconColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const DiscoveryRowSkeleton(),
      ],
    );
  }
}

class _WidgetError extends StatelessWidget {
  const _WidgetError({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.message,
    required this.onRetry,
  });

  final String title;
  final IconData icon;
  final Color iconColor;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Row(
            children: [
              Icon(icon, color: iconColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(message, style: theme.textTheme.bodyMedium),
                  ),
                  TextButton(
                    onPressed: onRetry,
                    child: Text(context.l10n.browseRetry),
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
