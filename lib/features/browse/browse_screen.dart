import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:picklog/core/utils/app_router.dart';
import 'package:picklog/core/utils/l10n_extensions.dart';
import 'package:picklog/core/widgets/skeleton_box.dart';
import 'package:picklog/features/browse/bloc/browse_genres_bloc.dart';
import 'package:picklog/features/browse/bloc/browse_genres_event.dart';
import 'package:picklog/features/browse/bloc/browse_genres_state.dart';
import 'package:picklog/features/browse/widgets/browse_status_views.dart';
import 'package:picklog/features/games/bloc/collections_bloc.dart';
import 'package:picklog/features/games/bloc/collections_event.dart';
import 'package:picklog/features/games/bloc/discovery_games_bloc.dart';
import 'package:picklog/features/games/bloc/discovery_games_event.dart';
import 'package:picklog/features/games/discovery_game_model.dart';
import 'package:picklog/features/games/game_detail_model.dart';
import 'package:picklog/features/games/widgets/collections_widget.dart';
import 'package:picklog/features/games/widgets/discovery_games_widget.dart';

/// Public discovery hub: browse the catalogue by genre, then explore new
/// releases and curated collections. Genres, releases and collections each
/// render as their own section in a single scroll view.
class BrowseScreen extends StatelessWidget {
  const BrowseScreen({super.key});

  /// Hero namespaces distinct from the Home tab's rows. Both the Home and
  /// Browse branches live in the same [StatefulShellRoute.indexedStack] and are
  /// kept alive simultaneously, so the same game appearing on both tabs would
  /// throw a duplicate Hero tag without these prefixes. The two release rows
  /// also stay alive together, so each gets its own prefix to avoid colliding
  /// with the other when a game shows up in both.
  static const String _newReleasesHeroPrefix = 'browse-new-releases-';
  static const String _comingSoonHeroPrefix = 'browse-coming-soon-';
  static const String _collectionsHeroPrefix = 'browse-';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.browseTitle)),
      body: RefreshIndicator(
        onRefresh: () => _refreshAll(context),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            _GenresSection(),
            SizedBox(height: 8),
            _ReleasesSection(),
            SizedBox(height: 8),
            _CollectionsSection(),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// Reloads every section of the hub and resolves once all of them have
  /// settled so the pull-to-refresh indicator stays up until the data lands.
  Future<void> _refreshAll(BuildContext context) async {
    final genresBloc = context.read<BrowseGenresBloc>()
      ..add(const BrowseGenresLoadRequested());
    final discoveryBloc = context.read<DiscoveryGamesBloc>()
      ..add(const DiscoveryGamesLoadRequested(DiscoveryType.newReleases))
      ..add(const DiscoveryGamesLoadRequested(DiscoveryType.comingSoon));
    final collectionsBloc = context.read<CollectionsBloc>()
      ..add(const CollectionsLoadRequested());

    await Future.wait([
      genresBloc.stream.firstWhere((s) => !s.isLoading),
      discoveryBloc.stream.firstWhere(
        (s) =>
            !s.getStateForType(DiscoveryType.newReleases).isLoading &&
            !s.getStateForType(DiscoveryType.comingSoon).isLoading,
      ),
      collectionsBloc.stream.firstWhere((s) => !s.isLoading),
    ]);
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Semantics(
        header: true,
        child: Text(
          title,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _GenresSection extends StatelessWidget {
  const _GenresSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BrowseGenresBloc, BrowseGenresState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(title: context.l10n.browseGenresSection),
            _GenresBody(state: state),
          ],
        );
      },
    );
  }
}

class _GenresBody extends StatelessWidget {
  const _GenresBody({required this.state});

  final BrowseGenresState state;

  @override
  Widget build(BuildContext context) {
    if (state.isLoading && !state.hasGenres) {
      return const _GenresGridSkeleton();
    }

    if (state.status == BrowseGenresStatus.failure && !state.hasGenres) {
      return BrowseErrorView(
        message: context.l10n.browseGenresError,
        onRetry: () => context.read<BrowseGenresBloc>().add(
          const BrowseGenresLoadRequested(),
        ),
      );
    }

    if (!state.hasGenres) {
      return BrowseEmptyView(
        icon: Icons.category_outlined,
        message: context.l10n.browseGenresEmpty,
      );
    }

    return _GenresGrid(genres: state.genres);
  }
}

int _genresCrossAxisCount(double width) {
  if (width >= 900) return 4;
  if (width >= 600) return 3;
  return 2;
}

class _GenresGrid extends StatelessWidget {
  const _GenresGrid({required this.genres});

  final List<Genre> genres;

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = _genresCrossAxisCount(
      MediaQuery.sizeOf(context).width,
    );

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 2.4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: genres.length,
      itemBuilder: (context, index) => _GenreCard(genre: genres[index]),
    );
  }
}

/// Shimmer placeholder for the genre grid's first load, matching the real grid
/// (same responsive column count, aspect ratio and spacing) so tiles drop in
/// without a layout jump.
class _GenresGridSkeleton extends StatelessWidget {
  const _GenresGridSkeleton();

  static const int _itemCount = 8;

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = _genresCrossAxisCount(
      MediaQuery.sizeOf(context).width,
    );

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 2.4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _itemCount,
      itemBuilder: (context, index) => const SkeletonBox(),
    );
  }
}

class _GenreCard extends StatelessWidget {
  const _GenreCard({required this.genre});

  final Genre genre;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Semantics(
        label: context.l10n.genreCardLabel(genre.name),
        button: true,
        onTap: () => context.pushNamed(
          AppRouter.genreGamesName,
          pathParameters: {'genreId': genre.id.toString()},
          queryParameters: {'name': genre.name},
        ),
        child: InkWell(
          onTap: () => context.pushNamed(
            AppRouter.genreGamesName,
            pathParameters: {'genreId': genre.id.toString()},
            queryParameters: {'name': genre.name},
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Text(
                genre.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// New releases + coming soon rows, reusing the Home discovery widgets but with
/// a distinct Browse-only Hero namespace per row so a game appearing in both
/// rows (or on the Home tab) doesn't collide. The rows self-label, so the
/// section has no group header of its own; it collapses to nothing when both
/// rows are empty.
class _ReleasesSection extends StatelessWidget {
  const _ReleasesSection();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LazyDiscoveryGamesWidget(
          discoveryType: DiscoveryType.newReleases,
          heroTagPrefix: BrowseScreen._newReleasesHeroPrefix,
        ),
        SizedBox(height: 8),
        LazyDiscoveryGamesWidget(
          discoveryType: DiscoveryType.comingSoon,
          heroTagPrefix: BrowseScreen._comingSoonHeroPrefix,
        ),
      ],
    );
  }
}

/// Curated collections rows, reusing the Home collections widget with a
/// Browse-only Hero namespace. The widget self-labels each collection and hides
/// entirely when there is nothing to show, so the section has no group header.
class _CollectionsSection extends StatelessWidget {
  const _CollectionsSection();

  @override
  Widget build(BuildContext context) {
    return const CollectionsWidget(
      heroTagPrefix: BrowseScreen._collectionsHeroPrefix,
      maxCollections: CollectionsWidget.unbounded,
    );
  }
}
