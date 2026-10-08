import 'package:flutter/material.dart';
import 'package:picklog/core/theme/pf_tokens.dart';
import 'package:picklog/core/theme/picklog_colors.dart';
import 'package:picklog/core/utils/l10n_extensions.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:picklog/core/widgets/pf_button.dart';
import 'package:picklog/features/games/bloc/filter_options_cubit.dart';
import 'package:picklog/features/games/bloc/game_search_filters.dart';
import 'package:picklog/features/games/widgets/catalog_filter_fields.dart';

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

/// Bottom sheet that edits the search [GameSearchFilters]: the sort of the
/// loaded results plus the genre, platform, year and rating filters that the
/// API applies.
class SearchFiltersSheet extends StatefulWidget {
  const SearchFiltersSheet({super.key, required this.filters});

  final GameSearchFilters filters;

  /// Shows the sheet and returns the edited filters, or null if dismissed.
  /// The sheet reads genres and platforms from [optionsCubit].
  static Future<GameSearchFilters?> show({
    required BuildContext context,
    required GameSearchFilters filters,
    required FilterOptionsCubit optionsCubit,
  }) {
    if (optionsCubit.state.status != FilterOptionsStatus.success) {
      optionsCubit.load();
    }
    return showModalBottomSheet<GameSearchFilters>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: false,
      builder: (_) => BlocProvider.value(
        value: optionsCubit,
        child: SearchFiltersSheet(filters: filters),
      ),
    );
  }

  @override
  State<SearchFiltersSheet> createState() => _SearchFiltersSheetState();
}

class _SearchFiltersSheetState extends State<SearchFiltersSheet> {
  late GameSearchFilters _draft = widget.filters;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          _Header(
            onReset: _draft.isEmpty
                ? null
                : () => setState(() => _draft = const GameSearchFilters()),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: EdgeInsets.fromLTRB(
                PfSpace.lg,
                PfSpace.lg,
                PfSpace.lg,
                PfSpace.lg + bottomPadding,
              ),
              children: [
                FilterSectionCard(
                  title: context.l10n.searchSortLabel,
                  child: Wrap(
                    spacing: PfSpace.sm,
                    runSpacing: PfSpace.sm,
                    children: GameSearchSort.values.map((sort) {
                      return ChoiceChip(
                        label: Text(sortLabel(context, sort)),
                        selected: _draft.sort == sort,
                        onSelected: (_) => setState(
                          () => _draft = _draft.copyWith(sort: sort),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                if (_draft.sort != GameSearchSort.relevance)
                  Padding(
                    padding: const EdgeInsets.only(top: PfSpace.sm),
                    child: Text(
                      context.l10n.searchSortLoadedScopeCaption,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                const SizedBox(height: PfSpace.md),
                BlocBuilder<FilterOptionsCubit, FilterOptionsState>(
                  builder: (context, options) => CatalogFilterFields(
                    value: _draft.catalog,
                    options: options,
                    onRetryOptions: () =>
                        context.read<FilterOptionsCubit>().load(),
                    onChanged: (catalog) => setState(
                      () => _draft = _draft.copyWith(catalog: catalog),
                    ),
                  ),
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
                label: context.l10n.searchFiltersApply,
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
