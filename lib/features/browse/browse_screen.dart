import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:picklog/core/utils/app_router.dart';
import 'package:picklog/core/utils/l10n_extensions.dart';
import 'package:picklog/core/theme/pf_tokens.dart';
import 'package:picklog/core/theme/picklog_colors.dart';
import 'package:picklog/core/widgets/app_scaffold.dart';
import 'package:picklog/core/widgets/press_scale.dart';
import 'package:picklog/core/widgets/section_header.dart';
import 'package:picklog/core/widgets/skeleton_box.dart';
import 'package:picklog/core/widgets/staggered_reveal.dart';
import 'package:picklog/core/widgets/state_views.dart';
import 'package:picklog/features/browse/bloc/browse_genres_bloc.dart';
import 'package:picklog/features/browse/bloc/browse_genres_event.dart';
import 'package:picklog/features/browse/bloc/browse_genres_state.dart';
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
        child: MaxWidthBox(
          maxWidth: 1440,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  PfSpace.lg,
                  PfSpace.xs,
                  PfSpace.lg,
                  0,
                ),
                child: Eyebrow(context.l10n.browseEyebrow),
              ),
              const _GenresSection(),
              const _ReleasesSection(),
              const _CollectionsSection(),
              const SizedBox(height: PfSpace.xxl),
            ],
          ),
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

class _GenresSection extends StatelessWidget {
  const _GenresSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BrowseGenresBloc, BrowseGenresState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: context.l10n.browseGenresSection,
              padding: const EdgeInsets.fromLTRB(
                PfSpace.lg,
                PfSpace.md,
                PfSpace.lg,
                PfSpace.md,
              ),
            ),
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
      return ErrorState(
        compact: true,
        message: context.l10n.browseGenresError,
        onRetry: () => context.read<BrowseGenresBloc>().add(
          const BrowseGenresLoadRequested(),
        ),
      );
    }

    if (!state.hasGenres) {
      return EmptyState(
        compact: true,
        icon: Icons.category_outlined,
        title: context.l10n.browseGenresEmpty,
      );
    }

    return _GenresGrid(genres: state.genres);
  }
}

int _genresCrossAxisCount(double width) {
  if (width >= 1200) return 5;
  if (width >= 900) return 4;
  if (width >= 600) return 3;
  return 2;
}

const double _genreAspectRatio = 2.6;

class _GenresGrid extends StatelessWidget {
  const _GenresGrid({required this.genres});

  final List<Genre> genres;

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = _genresCrossAxisCount(
      MediaQuery.sizeOf(context).width.clamp(0, 1440).toDouble(),
    );

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: PfSpace.lg),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: _genreAspectRatio,
        crossAxisSpacing: PfSpace.md,
        mainAxisSpacing: PfSpace.md,
      ),
      itemCount: genres.length,
      itemBuilder: (context, index) => StaggeredReveal(
        index: index,
        child: _GenreCard(genre: genres[index]),
      ),
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
      MediaQuery.sizeOf(context).width.clamp(0, 1440).toDouble(),
    );

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: PfSpace.lg),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: _genreAspectRatio,
        crossAxisSpacing: PfSpace.md,
        mainAxisSpacing: PfSpace.md,
      ),
      itemCount: _itemCount,
      itemBuilder: (context, index) =>
          const SkeletonBox(borderRadius: PfRadius.card),
    );
  }
}

/// Icon for an IGDB genre id, with a neutral fallback.
IconData genreIcon(int id) => switch (id) {
  2 => Icons.ads_click,
  4 => Icons.sports_mma,
  5 => Icons.gps_fixed,
  7 => Icons.music_note_outlined,
  8 => Icons.stairs_outlined,
  9 => Icons.extension_outlined,
  10 => Icons.speed,
  11 || 15 || 16 => Icons.castle_outlined,
  12 => Icons.auto_fix_high_outlined,
  13 => Icons.flight_outlined,
  14 => Icons.sports_soccer,
  24 => Icons.grid_view,
  25 => Icons.bolt_outlined,
  26 => Icons.quiz_outlined,
  30 => Icons.blur_circular,
  31 => Icons.explore_outlined,
  32 => Icons.lightbulb_outline,
  33 => Icons.videogame_asset_outlined,
  34 => Icons.menu_book_outlined,
  35 => Icons.style_outlined,
  36 => Icons.groups_outlined,
  _ => Icons.category_outlined,
};

/// Tint for a genre card. Ember is reserved for accents, so genres cycle
/// through the status tones.
PfTone genreTone(int id) => const [
  PfTone.info,
  PfTone.connected,
  PfTone.warning,
  PfTone.error,
  PfTone.neutral,
][id % 5];

class _GenreCard extends StatelessWidget {
  const _GenreCard({required this.genre});

  final Genre genre;

  void _open(BuildContext context) => context.pushNamed(
    AppRouter.genreGamesName,
    pathParameters: {'genreId': genre.id.toString()},
    queryParameters: {'name': genre.name},
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.pfColors;
    final tone = genreTone(genre.id);

    return PressScale(
      onTap: () => _open(context),
      semanticLabel: context.l10n.genreCardLabel(genre.name),
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: PfSpace.md),
          decoration: BoxDecoration(
            color: colors.surface1,
            borderRadius: PfRadius.cardAll,
            border: Border.all(color: colors.hairline),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: colors.toneBackground(tone),
                  borderRadius: PfRadius.mdAll,
                ),
                child: Icon(
                  genreIcon(genre.id),
                  size: 20,
                  color: colors.toneForeground(tone),
                ),
              ),
              const SizedBox(width: PfSpace.md),
              Expanded(
                child: Text(
                  genre.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall,
                ),
              ),
            ],
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
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LazyDiscoveryGamesWidget(
          discoveryType: DiscoveryType.newReleases,
          heroTagPrefix: BrowseScreen._newReleasesHeroPrefix,
        ),
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
