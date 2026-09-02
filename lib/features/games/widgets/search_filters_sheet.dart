import 'package:flutter/material.dart';
import 'package:picklog/core/utils/l10n_extensions.dart';
import 'package:picklog/features/games/bloc/game_search_filters.dart';
import 'package:picklog/features/games/search_game_model.dart';

/// Localized label for a [GameSearchSort] option.
String sortLabel(BuildContext context, GameSearchSort sort) {
  switch (sort) {
    case GameSearchSort.relevance:
      return context.l10n.searchSortRelevance;
    case GameSearchSort.nameAsc:
      return context.l10n.searchSortNameAsc;
    case GameSearchSort.yearDesc:
      return context.l10n.searchSortYearDesc;
    case GameSearchSort.yearAsc:
      return context.l10n.searchSortYearAsc;
  }
}

/// Bottom sheet that edits the search [GameSearchFilters] (sort + genre,
/// platform and year facets) over the currently loaded results.
///
/// Facets ([genres], [platforms], [years]) are derived from the loaded results
/// by the caller, so the sheet only ever offers values that can match.
class SearchFiltersSheet extends StatefulWidget {
  const SearchFiltersSheet({
    super.key,
    required this.filters,
    required this.genres,
    required this.platforms,
    required this.years,
  });

  final GameSearchFilters filters;
  final List<GameGenre> genres;
  final List<GamePlatform> platforms;
  final List<int> years;

  /// Shows the sheet and returns the edited filters, or null if dismissed.
  static Future<GameSearchFilters?> show({
    required BuildContext context,
    required GameSearchFilters filters,
    required List<GameGenre> genres,
    required List<GamePlatform> platforms,
    required List<int> years,
  }) {
    return showModalBottomSheet<GameSearchFilters>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SearchFiltersSheet(
        filters: filters,
        genres: genres,
        platforms: platforms,
        years: years,
      ),
    );
  }

  @override
  State<SearchFiltersSheet> createState() => _SearchFiltersSheetState();
}

class _SearchFiltersSheetState extends State<SearchFiltersSheet> {
  late GameSearchSort _sort;
  late Set<int> _genreIds;
  late Set<int> _platformIds;
  int? _year;

  @override
  void initState() {
    super.initState();
    _sort = widget.filters.sort;
    _genreIds = {...widget.filters.genreIds};
    _platformIds = {...widget.filters.platformIds};
    _year = widget.filters.year;
  }

  void _reset() {
    setState(() {
      _sort = GameSearchSort.relevance;
      _genreIds = {};
      _platformIds = {};
      _year = null;
    });
  }

  GameSearchFilters get _result => GameSearchFilters(
    sort: _sort,
    genreIds: _genreIds,
    platformIds: _platformIds,
    year: _year,
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final hasFacets =
        widget.genres.isNotEmpty ||
        widget.platforms.isNotEmpty ||
        widget.years.isNotEmpty;

    return SafeArea(
      top: false,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Header(onReset: _result.isEmpty ? null : _reset),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _SectionCard(
                      theme: theme,
                      title: context.l10n.searchSortLabel,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: GameSearchSort.values.map((sort) {
                          return ChoiceChip(
                            label: Text(sortLabel(context, sort)),
                            selected: _sort == sort,
                            onSelected: (_) => setState(() => _sort = sort),
                          );
                        }).toList(),
                      ),
                    ),
                    if (widget.genres.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _SectionCard(
                        theme: theme,
                        title: context.l10n.searchFilterGenresLabel,
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: widget.genres.map((genre) {
                            return FilterChip(
                              label: Text(genre.name),
                              selected: _genreIds.contains(genre.id),
                              onSelected: (selected) => setState(() {
                                if (selected) {
                                  _genreIds.add(genre.id);
                                } else {
                                  _genreIds.remove(genre.id);
                                }
                              }),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                    if (widget.platforms.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _SectionCard(
                        theme: theme,
                        title: context.l10n.searchFilterPlatformsLabel,
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: widget.platforms.map((platform) {
                            return FilterChip(
                              label: Text(platform.name),
                              selected: _platformIds.contains(platform.id),
                              onSelected: (selected) => setState(() {
                                if (selected) {
                                  _platformIds.add(platform.id);
                                } else {
                                  _platformIds.remove(platform.id);
                                }
                              }),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                    if (widget.years.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _SectionCard(
                        theme: theme,
                        title: context.l10n.searchFilterYearLabel,
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: widget.years.map((year) {
                            return ChoiceChip(
                              label: Text('$year'),
                              selected: _year == year,
                              onSelected: (selected) => setState(
                                () => _year = selected ? year : null,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                    if (!hasFacets)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          context.l10n.searchFilterNoFacets,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    Text(
                      context.l10n.searchFiltersLoadedScopeCaption,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => Navigator.of(context).pop(_result),
                        child: Text(context.l10n.searchFiltersApply),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Header row matching the app's bottom-sheet house style: Cancel on the left,
/// a bold title centered, and a draft-scoped Reset action on the right.
class _Header extends StatelessWidget {
  const _Header({required this.onReset});

  final VoidCallback? onReset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(top: 12, bottom: 8),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(context.l10n.cancel),
              ),
              Text(
                context.l10n.searchFiltersTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: onReset,
                child: Text(context.l10n.searchFiltersReset),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Carded section matching [AddToLibraryBottomSheet]: surfaceContainerLow,
/// 16px radius, a soft shadow and a primary-tinted section title.
class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.theme,
    required this.title,
    required this.child,
  });

  final ThemeData theme;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
