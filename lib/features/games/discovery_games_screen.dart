import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:picklog/core/theme/pf_tokens.dart';
import 'package:picklog/core/utils/l10n_extensions.dart';
import 'package:picklog/core/widgets/animated_state_switcher.dart';
import 'package:picklog/core/widgets/app_scaffold.dart';
import 'package:picklog/core/widgets/game_card.dart';
import 'package:picklog/core/widgets/responsive_grid.dart';
import 'package:picklog/core/widgets/staggered_reveal.dart';
import 'package:picklog/core/widgets/state_views.dart';
import 'package:picklog/features/games/bloc/discovery_games_bloc.dart';
import 'package:picklog/features/games/bloc/discovery_games_event.dart';
import 'package:picklog/features/games/bloc/discovery_games_state.dart';
import 'package:picklog/features/games/discovery_game_model.dart';
import 'package:picklog/features/games/widgets/discovery_game_tile.dart';
import 'package:picklog/features/games/widgets/skeletons/discovery_grid_skeleton.dart';

/// Full screen for viewing all discovery games with grid/list toggle and infinite scroll
class DiscoveryGamesScreen extends StatefulWidget {
  const DiscoveryGamesScreen({required this.discoveryType, super.key});

  final DiscoveryType discoveryType;

  @override
  State<DiscoveryGamesScreen> createState() => _DiscoveryGamesScreenState();
}

class _DiscoveryGamesScreenState extends State<DiscoveryGamesScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      context.read<DiscoveryGamesBloc>().add(const DiscoveryGamesLoadMore());
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    // Trigger at 90% scroll
    return currentScroll >= (maxScroll * 0.9);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DiscoveryGamesBloc, DiscoveryGamesState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: Text(widget.discoveryType.localizedName(context)),
            actions: [
              IconButton(
                icon: Icon(
                  state.isGridView ? Icons.view_list : Icons.grid_view,
                ),
                tooltip: state.isGridView
                    ? context.l10n.switchToList
                    : context.l10n.switchToGrid,
                onPressed: () => context.read<DiscoveryGamesBloc>().add(
                  const DiscoveryGamesViewModeToggled(),
                ),
              ),
            ],
          ),
          body: SafeArea(top: false, child: _buildBody(context, state)),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, DiscoveryGamesState state) {
    final typeState = state.getStateForType(widget.discoveryType);

    final Widget child;
    final Object key;
    if (typeState.isLoading && !typeState.hasGames) {
      key = 'loading-${state.isGridView}';
      child = state.isGridView
          ? const DiscoveryGridSkeleton()
          : const DiscoveryListSkeleton();
    } else if (typeState.status == DiscoveryGamesStatus.failure &&
        !typeState.hasGames) {
      key = 'error';
      child = ErrorState(
        message: context.l10n.failedToLoadGames,
        onRetry: () => context.read<DiscoveryGamesBloc>().add(
          DiscoveryGamesLoadRequested(widget.discoveryType),
        ),
      );
    } else if (!typeState.hasGames) {
      key = 'empty';
      child = EmptyState(
        icon: Icons.games_outlined,
        title: context.l10n.noGamesFound,
        message: context.l10n.noGamesInCategory,
      );
    } else {
      key = 'content-${state.isGridView}';
      child = RefreshIndicator(
        onRefresh: () async {
          context.read<DiscoveryGamesBloc>().add(
            const DiscoveryGamesRefreshRequested(),
          );
          // Wait for the bloc to finish loading
          await context.read<DiscoveryGamesBloc>().stream.firstWhere(
            (s) => !s.getStateForType(widget.discoveryType).isLoading,
          );
        },
        child: state.isGridView
            ? _buildGridView(context, typeState)
            : _buildListView(context, typeState),
      );
    }

    return AnimatedStateSwitcher(
      stateKey: key,
      child: MaxWidthBox(maxWidth: 1440, child: child),
    );
  }

  String get _heroPrefix => 'discovery-${widget.discoveryType.queryParam}-';

  Widget _buildGridView(BuildContext context, DiscoveryTypeState typeState) {
    return CustomScrollView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(PfSpace.lg),
          sliver: SliverResponsiveGrid(
            itemCount: typeState.games.length,
            childAspectRatio: kGameCardGridAspectRatio,
            itemBuilder: (context, index) => StaggeredReveal(
              index: index % 20,
              child: DiscoveryGameTile(
                game: typeState.games[index],
                heroTagPrefix: _heroPrefix,
              ),
            ),
          ),
        ),
        if (typeState.isLoadingMore)
          const SliverToBoxAdapter(child: _LoadingMore()),
        if (typeState.offsetLimitReached)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(PfSpace.lg),
              child: Center(
                child: Text(
                  context.l10n.reachedEnd,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: PfSpace.lg)),
      ],
    );
  }

  Widget _buildListView(BuildContext context, DiscoveryTypeState typeState) {
    return ListView.separated(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(PfSpace.lg),
      itemCount: typeState.games.length + (typeState.isLoadingMore ? 1 : 0),
      separatorBuilder: (_, _) => const SizedBox(height: PfSpace.sm),
      itemBuilder: (context, index) {
        if (index >= typeState.games.length) return const _LoadingMore();
        return StaggeredReveal(
          index: index % 20,
          child: DiscoveryGameListTile(
            game: typeState.games[index],
            heroTagPrefix: _heroPrefix,
          ),
        );
      },
    );
  }
}

class _LoadingMore extends StatelessWidget {
  const _LoadingMore();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(PfSpace.xl),
      child: Center(
        child: SizedBox.square(
          dimension: 24,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      ),
    );
  }
}
