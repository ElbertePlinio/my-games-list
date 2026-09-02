import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:picklog/core/utils/l10n_extensions.dart';
import 'package:picklog/features/browse/bloc/browse_genre_games_bloc.dart';
import 'package:picklog/features/browse/bloc/browse_genre_games_event.dart';
import 'package:picklog/features/browse/bloc/browse_genre_games_state.dart';
import 'package:picklog/features/browse/widgets/browse_status_views.dart';
import 'package:picklog/features/games/widgets/discovery_game_tile.dart';
import 'package:picklog/features/games/widgets/skeletons/discovery_grid_skeleton.dart';

/// Top-rated games for a single genre, reached from the Browse hub.
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
            if (state.isLoading && !state.hasGames) {
              return const DiscoveryGridSkeleton();
            }

            if (state.status == BrowseGenreGamesStatus.failure &&
                !state.hasGames) {
              return BrowseErrorView(
                message: context.l10n.browseGenreGamesError,
                onRetry: () => context.read<BrowseGenreGamesBloc>().add(
                  BrowseGenreGamesLoadRequested(genreId),
                ),
              );
            }

            if (!state.hasGames) {
              return BrowseEmptyView(
                icon: Icons.videogame_asset_off_outlined,
                message: context.l10n.browseGenreEmpty,
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                final bloc = context.read<BrowseGenreGamesBloc>()
                  ..add(BrowseGenreGamesLoadRequested(genreId));
                await bloc.stream.firstWhere((s) => !s.isLoading);
              },
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                physics: const AlwaysScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.65,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: state.games.length,
                itemBuilder: (context, index) => DiscoveryGameTile(
                  game: state.games[index],
                  heroTagPrefix: 'browse-genre-$genreId-',
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
