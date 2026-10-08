import 'package:flutter/material.dart';
import 'package:picklog/core/theme/pf_tokens.dart';
import 'package:picklog/core/theme/picklog_colors.dart';
import 'package:picklog/core/utils/l10n_extensions.dart';
import 'package:picklog/core/widgets/section_header.dart';
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
      showDragHandle: false,
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
        decoration: const BoxDecoration(),
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
            color: context.pfColors.hairlineStrong,
            borderRadius: PfRadius.pillAll,
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
                style: theme.textTheme.titleMedium,
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

/// Carded section matching the add-to-library sheet: surface-2 card with a
/// hairline border and a muted eyebrow title.
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
        color: context.pfColors.surface2,
        borderRadius: PfRadius.cardAll,
        border: Border.all(color: context.pfColors.hairline),
      ),
      padding: const EdgeInsets.all(PfSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Eyebrow(title, muted: true),
          const SizedBox(height: PfSpace.md),
          child,
        ],
      ),
    );
  }
}
