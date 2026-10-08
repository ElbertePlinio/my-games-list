import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:picklog/core/theme/pf_tokens.dart';
import 'package:picklog/core/theme/pf_typography.dart';
import 'package:picklog/core/theme/picklog_colors.dart';
import 'package:picklog/core/utils/l10n_extensions.dart';
import 'package:picklog/core/widgets/pf_button.dart';
import 'package:picklog/features/games/bloc/filter_options_cubit.dart';
import 'package:picklog/features/games/widgets/catalog_filter_fields.dart';
import 'package:picklog/features/library/collections/bloc/user_collections_bloc.dart';
import 'package:picklog/features/library/collections/bloc/user_collections_state.dart';
import 'package:picklog/features/library/library_entry_model.dart';
import 'package:picklog/features/library/library_query.dart';
import 'package:picklog/features/library/widgets/library_status_pill.dart';

/// Bottom sheet for every library filter. Edits a draft and returns it.
class LibraryFiltersSheet extends StatefulWidget {
  const LibraryFiltersSheet({required this.filters, super.key});

  final LibraryFilters filters;

  static Future<LibraryFilters?> show(
    BuildContext context, {
    required LibraryFilters filters,
    required FilterOptionsCubit options,
    required UserCollectionsBloc collections,
  }) {
    if (options.state.status != FilterOptionsStatus.success) options.load();
    return showModalBottomSheet<LibraryFilters>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: false,
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: options),
          BlocProvider.value(value: collections),
        ],
        child: LibraryFiltersSheet(filters: filters),
      ),
    );
  }

  @override
  State<LibraryFiltersSheet> createState() => _LibraryFiltersSheetState();
}

class _LibraryFiltersSheetState extends State<LibraryFiltersSheet> {
  late LibraryFilters _draft = widget.filters;
  double? _score;

  void _toggleIds(Set<int> ids, int id, bool on, bool genre) {
    final next = {...ids};
    on ? next.add(id) : next.remove(id);
    setState(() {
      _draft = genre
          ? _draft.copyWith(genreIds: next)
          : _draft.copyWith(platformIds: next);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.pfColors;
    final options = context.watch<FilterOptionsCubit>().state;
    final collections = context.watch<UserCollectionsBloc>().state;
    final score = _score ?? (_draft.minScore ?? 0).toDouble();

    Widget chips(List<Widget> children) => children.isEmpty
        ? Text(
            options.status == FilterOptionsStatus.failure
                ? l10n.filterOptionsFailed
                : l10n.loadingLabel,
            style: Theme.of(context).textTheme.bodySmall,
          )
        : Wrap(spacing: PfSpace.sm, runSpacing: PfSpace.sm, children: children);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, controller) => Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: PfSpace.md, bottom: PfSpace.sm),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colors.hairlineStrong,
              borderRadius: PfRadius.pillAll,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: PfSpace.sm),
            child: Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.cancel),
                ),
                Expanded(
                  child: Text(
                    l10n.libraryFiltersTitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                TextButton(
                  onPressed: _draft.hasActiveFilters
                      ? () => setState(() {
                          _draft = _draft.cleared().copyWith(
                            query: _draft.query,
                          );
                          _score = null;
                        })
                      : null,
                  child: Text(l10n.searchFiltersReset),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: colors.hairline),
          Expanded(
            child: ListView(
              controller: controller,
              padding: const EdgeInsets.all(PfSpace.lg),
              children: [
                FilterSectionCard(
                  title: l10n.statusLabel,
                  child: Wrap(
                    spacing: PfSpace.sm,
                    runSpacing: PfSpace.sm,
                    children: [
                      FilterChip(
                        avatar: Icon(
                          _draft.favoritesOnly
                              ? Icons.favorite
                              : Icons.favorite_border,
                          size: 16,
                        ),
                        label: Text(l10n.libraryFavoritesFilter),
                        selected: _draft.favoritesOnly,
                        onSelected: (v) => setState(
                          () => _draft = _draft.copyWith(favoritesOnly: v),
                        ),
                      ),
                      for (final status in GameStatus.values)
                        FilterChip(
                          avatar: Icon(status.icon, size: 16),
                          label: Text(status.localizedName(context)),
                          selected: _draft.statuses.contains(status),
                          onSelected: (v) => setState(() {
                            final next = {..._draft.statuses};
                            v ? next.add(status) : next.remove(status);
                            _draft = _draft.copyWith(statuses: next);
                          }),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: PfSpace.md),
                FilterSectionCard(
                  title: l10n.libraryFilterMinScore,
                  trailing: Text(
                    score <= 0
                        ? l10n.filterAnyRating
                        : l10n.filterRatingValue(score.round()),
                    style: PfTypography.monoStyle(colors.textMed),
                  ),
                  child: Slider(
                    value: score,
                    max: 100,
                    divisions: 20,
                    label: '${score.round()}',
                    onChanged: (v) => setState(() => _score = v),
                    onChangeEnd: (v) => setState(() {
                      _draft = v <= 0
                          ? _draft.copyWith(clearMinScore: true)
                          : _draft.copyWith(minScore: v.round());
                    }),
                  ),
                ),
                if (collections.hasCollections) ...[
                  const SizedBox(height: PfSpace.md),
                  FilterSectionCard(
                    title: l10n.libraryFilterCollection,
                    child: Wrap(
                      spacing: PfSpace.sm,
                      runSpacing: PfSpace.sm,
                      children: [
                        for (final c in collections.collections)
                          ChoiceChip(
                            label: Text(c.name),
                            selected: _draft.collectionId == c.id,
                            onSelected: (v) => setState(
                              () => _draft = v
                                  ? _draft.copyWith(collectionId: c.id)
                                  : _draft.copyWith(clearCollection: true),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: PfSpace.md),
                FilterSectionCard(
                  title: l10n.searchFilterGenresLabel,
                  child: chips([
                    for (final g in options.genres)
                      FilterChip(
                        label: Text(g.name),
                        selected: _draft.genreIds.contains(g.id),
                        onSelected: (v) =>
                            _toggleIds(_draft.genreIds, g.id, v, true),
                      ),
                  ]),
                ),
                const SizedBox(height: PfSpace.md),
                FilterSectionCard(
                  title: l10n.searchFilterPlatformsLabel,
                  child: chips([
                    for (final p in options.platforms)
                      FilterChip(
                        label: Text(p.label),
                        tooltip: p.name,
                        selected: _draft.platformIds.contains(p.id),
                        onSelected: (v) =>
                            _toggleIds(_draft.platformIds, p.id, v, false),
                      ),
                  ]),
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                PfSpace.lg,
                PfSpace.sm,
                PfSpace.lg,
                PfSpace.lg,
              ),
              child: PfButton(
                key: const Key('library_filters_apply'),
                label: l10n.searchFiltersApply,
                expand: true,
                onPressed: () => Navigator.of(context).pop(_draft),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Chips for the active library filters (search text excluded).
List<ActiveFilterChipData> libraryFilterChips(
  BuildContext context, {
  required LibraryFilters filters,
  required FilterOptionsState options,
  required UserCollectionsState collections,
  required ValueChanged<LibraryFilters> onChanged,
}) {
  final l10n = context.l10n;
  return [
    if (filters.favoritesOnly)
      ActiveFilterChipData(
        label: l10n.libraryFavoritesFilter,
        onRemoved: () => onChanged(filters.copyWith(favoritesOnly: false)),
      ),
    for (final status in GameStatus.values)
      if (filters.statuses.contains(status))
        ActiveFilterChipData(
          label: status.localizedName(context),
          onRemoved: () => onChanged(
            filters.copyWith(statuses: {...filters.statuses}..remove(status)),
          ),
        ),
    if (filters.collectionId != null)
      ActiveFilterChipData(
        label:
            collections.byId(filters.collectionId!)?.name ??
            l10n.libraryFilterCollection,
        onRemoved: () => onChanged(filters.copyWith(clearCollection: true)),
      ),
    for (final id in filters.genreIds)
      ActiveFilterChipData(
        label: options.genreName(id) ?? l10n.filterGenreFallback,
        onRemoved: () => onChanged(
          filters.copyWith(genreIds: {...filters.genreIds}..remove(id)),
        ),
      ),
    for (final id in filters.platformIds)
      ActiveFilterChipData(
        label: options.platformLabel(id) ?? l10n.filterPlatformFallback,
        onRemoved: () => onChanged(
          filters.copyWith(platformIds: {...filters.platformIds}..remove(id)),
        ),
      ),
    if (filters.minScore != null)
      ActiveFilterChipData(
        label: l10n.libraryScoreChip(filters.minScore!),
        onRemoved: () => onChanged(filters.copyWith(clearMinScore: true)),
      ),
  ];
}
