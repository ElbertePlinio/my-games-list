import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:picklog/core/domain/models/app_failure.dart';
import 'package:picklog/core/theme/pf_tokens.dart';
import 'package:picklog/core/utils/error_l10n.dart';
import 'package:picklog/core/utils/l10n_extensions.dart';
import 'package:picklog/core/widgets/animated_state_switcher.dart';
import 'package:picklog/core/widgets/app_scaffold.dart';
import 'package:picklog/core/widgets/game_card.dart';
import 'package:picklog/core/widgets/responsive_grid.dart';
import 'package:picklog/core/widgets/staggered_reveal.dart';
import 'package:picklog/core/widgets/state_views.dart';
import 'package:picklog/features/browse/bloc/browse_genre_games_bloc.dart';
import 'package:picklog/features/browse/bloc/browse_genre_games_event.dart';
import 'package:picklog/features/browse/bloc/browse_genre_games_state.dart';
import 'package:picklog/features/games/widgets/discovery_game_tile.dart';
import 'package:picklog/features/games/widgets/skeletons/discovery_grid_skeleton.dart';

/// Top-rated games for a single genre, reached from the Browse hub. Pages in
/// more games as the user nears the end of the grid.
class BrowseGenreGamesScreen extends StatelessWidget {
  const BrowseGenreGamesScreen({
    required this.genreId,
    required this.genreName,
    super.key,
  });

  final int genreId;
  final String genreName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(genreName)),
      body: SafeArea(
        top: false,
        child: BlocBuilder<BrowseGenreGamesBloc, BrowseGenreGamesState>(
          builder: (context, state) {
            final Widget child;
            if (state.isLoading && !state.hasGames) {
              child = const DiscoveryGridSkeleton();
            } else if (state.status == BrowseGenreGamesStatus.failure &&
                !state.hasGames) {
              child = ErrorState(
                message: context.l10n.browseGenreGamesError,
                onRetry: () => context.read<BrowseGenreGamesBloc>().add(
                  BrowseGenreGamesLoadRequested(genreId),
                ),
              );
            } else if (!state.hasGames) {
              child = EmptyState(
                icon: Icons.videogame_asset_off_outlined,
                title: context.l10n.browseGenreEmpty,
              );
            } else {
              child = _GenreGrid(state: state, genreId: genreId);
            }
            return AnimatedStateSwitcher(
              stateKey: state.hasGames ? 'grid' : state.status,
              child: MaxWidthBox(maxWidth: 1440, child: child),
            );
          },
        ),
      ),
    );
  }
}

class _GenreGrid extends StatelessWidget {
  const _GenreGrid({required this.state, required this.genreId});

  final BrowseGenreGamesState state;
  final int genreId;

  bool _onScroll(BuildContext context, ScrollNotification notification) {
    final metrics = notification.metrics;
    if (metrics.axis == Axis.vertical &&
        metrics.pixels >= metrics.maxScrollExtent - 600 &&
        state.canLoadMore &&
        !state.loadMoreFailed) {
      context.read<BrowseGenreGamesBloc>().add(
        const BrowseGenreGamesLoadMore(),
      );
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final games = state.games;
    final prefix = 'browse-genre-$genreId-';

    return NotificationListener<ScrollNotification>(
      onNotification: (n) => _onScroll(context, n),
      child: RefreshIndicator(
        onRefresh: () async {
          final bloc = context.read<BrowseGenreGamesBloc>()
            ..add(BrowseGenreGamesLoadRequested(genreId));
          await bloc.stream.firstWhere((s) => !s.isLoading);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(PfSpace.lg),
              sliver: SliverResponsiveGrid(
                itemCount: games.length,
                childAspectRatio: kGameCardGridAspectRatio,
                itemBuilder: (context, index) => StaggeredReveal(
                  index: index % BrowseGenreGamesBloc.pageSize,
                  child: DiscoveryGameTile(
                    game: games[index],
                    heroTagPrefix: prefix,
                  ),
                ),
              ),
            ),
            if (state.isLoadingMore)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(bottom: PfSpace.xl),
                  child: Center(
                    child: SizedBox.square(
                      dimension: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                  ),
                ),
              )
            else if (state.loadMoreFailed)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: PfSpace.xl),
                  child: ErrorState(
                    compact: true,
                    message: (state.errorKind ?? AppErrorKind.unknown).message(
                      context,
                    ),
                    onRetry: () => context.read<BrowseGenreGamesBloc>().add(
                      const BrowseGenreGamesLoadMore(),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
