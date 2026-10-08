import 'package:flutter/material.dart';
import 'package:picklog/core/theme/pf_tokens.dart';
import 'package:picklog/core/theme/pf_typography.dart';
import 'package:picklog/core/theme/picklog_colors.dart';
import 'package:picklog/core/utils/l10n_extensions.dart';
import 'package:picklog/core/widgets/section_header.dart';
import 'package:picklog/core/widgets/skeleton_box.dart';
import 'package:picklog/features/games/bloc/filter_options_cubit.dart';
import 'package:picklog/features/games/catalog_filters.dart';

/// Carded filter section: surface-2 card, hairline border, muted eyebrow.
class FilterSectionCard extends StatelessWidget {
  const FilterSectionCard({
    required this.title,
    required this.child,
    this.trailing,
    super.key,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.pfColors;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface2,
        borderRadius: PfRadius.cardAll,
        border: Border.all(color: colors.hairline),
      ),
      padding: const EdgeInsets.all(PfSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Eyebrow(title, muted: true)),
              ?trailing,
            ],
          ),
          const SizedBox(height: PfSpace.md),
          child,
        ],
      ),
    );
  }
}

/// Genre, platform, release year and rating fields for [CatalogFilters].
///
/// Chips apply at once. Sliders report on release so a drag sends one change.
class CatalogFilterFields extends StatefulWidget {
  const CatalogFilterFields({
    required this.value,
    required this.options,
    required this.onChanged,
    this.onRetryOptions,
    this.maxYear,
    super.key,
  });

  final CatalogFilters value;
  final FilterOptionsState options;
  final ValueChanged<CatalogFilters> onChanged;
  final VoidCallback? onRetryOptions;

  /// Upper bound of the year slider. Defaults to [catalogMaxYear].
  final int? maxYear;

  @override
  State<CatalogFilterFields> createState() => _CatalogFilterFieldsState();
}

class _CatalogFilterFieldsState extends State<CatalogFilterFields> {
  RangeValues? _years;
  double? _rating;

  int get _maxYear => widget.maxYear ?? catalogMaxYear();

  RangeValues get _committedYears => RangeValues(
    (widget.value.yearFrom ?? kCatalogMinYear).toDouble(),
    (widget.value.yearTo ?? _maxYear).toDouble(),
  );

  @override
  void didUpdateWidget(covariant CatalogFilterFields oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _years = null;
      _rating = null;
    }
  }

  void _toggle(Set<int> current, int id, bool selected, bool genres) {
    final next = {...current};
    if (selected) {
      if (next.length >= CatalogFilters.maxIds) return;
      next.add(id);
    } else {
      next.remove(id);
    }
    widget.onChanged(
      genres
          ? widget.value.copyWith(genreIds: next)
          : widget.value.copyWith(platformIds: next),
    );
  }

  /// Chips when there are options, else a skeleton, retry row or hint.
  Widget _chipsOrState(BuildContext context, List<Widget> chips) {
    final l10n = context.l10n;
    final status = widget.options.status;
    if (chips.isNotEmpty) {
      return Wrap(spacing: PfSpace.sm, runSpacing: PfSpace.sm, children: chips);
    }
    if (status == FilterOptionsStatus.loading ||
        status == FilterOptionsStatus.initial) {
      return const _ChipsSkeleton();
    }
    if (status == FilterOptionsStatus.failure) {
      return Row(
        children: [
          Expanded(
            child: Text(
              l10n.filterOptionsFailed,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          if (widget.onRetryOptions != null)
            TextButton(
              onPressed: widget.onRetryOptions,
              child: Text(l10n.browseRetry),
            ),
        ],
      );
    }
    return Text(
      l10n.searchFilterNoFacets,
      style: Theme.of(context).textTheme.bodySmall,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final value = widget.value;
    final options = widget.options;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilterSectionCard(
          title: l10n.searchFilterGenresLabel,
          child: _chipsOrState(context, [
            for (final genre in options.genres)
              FilterChip(
                label: Text(genre.name),
                selected: value.genreIds.contains(genre.id),
                onSelected: (selected) =>
                    _toggle(value.genreIds, genre.id, selected, true),
              ),
          ]),
        ),
        const SizedBox(height: PfSpace.md),
        FilterSectionCard(
          title: l10n.searchFilterPlatformsLabel,
          child: _chipsOrState(context, [
            for (final platform in options.platforms)
              FilterChip(
                label: Text(platform.label),
                tooltip: platform.name,
                selected: value.platformIds.contains(platform.id),
                onSelected: (selected) =>
                    _toggle(value.platformIds, platform.id, selected, false),
              ),
          ]),
        ),
        const SizedBox(height: PfSpace.md),
        _buildYearsCard(context),
        const SizedBox(height: PfSpace.md),
        _buildRatingCard(context),
      ],
    );
  }

  /// Release year range. Commits on release.
  Widget _buildYearsCard(BuildContext context) {
    final l10n = context.l10n;
    final years = _years ?? _committedYears;
    return FilterSectionCard(
      title: l10n.filterReleaseYears,
      trailing: Text(
        l10n.filterYearRangeValue(years.start.round(), years.end.round()),
        style: PfTypography.monoStyle(context.pfColors.textMed),
      ),
      child: RangeSlider(
        values: years,
        min: kCatalogMinYear.toDouble(),
        max: _maxYear.toDouble(),
        divisions: _maxYear - kCatalogMinYear,
        labels: RangeLabels('${years.start.round()}', '${years.end.round()}'),
        semanticFormatterCallback: (v) => '${v.round()}',
        onChanged: (v) => setState(() => _years = v),
        onChangeEnd: (v) => widget.onChanged(
          widget.value.withYearRange(
            v.start.round(),
            v.end.round(),
            maxYear: _maxYear,
          ),
        ),
      ),
    );
  }

  /// Minimum rating. Zero means any rating. Commits on release.
  Widget _buildRatingCard(BuildContext context) {
    final l10n = context.l10n;
    final value = widget.value;
    final rating = _rating ?? (value.minRating ?? 0).toDouble();
    return FilterSectionCard(
      title: l10n.filterMinRating,
      trailing: Text(
        rating <= 0
            ? l10n.filterAnyRating
            : l10n.filterRatingValue(rating.round()),
        style: PfTypography.monoStyle(context.pfColors.textMed),
      ),
      child: Slider(
        value: rating,
        min: 0,
        max: 100,
        divisions: 20,
        label: '${rating.round()}',
        onChanged: (v) => setState(() => _rating = v),
        onChangeEnd: (v) => widget.onChanged(
          v <= 0
              ? value.copyWith(clearMinRating: true)
              : value.copyWith(minRating: v.round()),
        ),
      ),
    );
  }
}

class _ChipsSkeleton extends StatelessWidget {
  const _ChipsSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      spacing: PfSpace.sm,
      runSpacing: PfSpace.sm,
      children: [
        SkeletonBox(width: 72, height: 32, borderRadius: PfRadius.pill),
        SkeletonBox(width: 96, height: 32, borderRadius: PfRadius.pill),
        SkeletonBox(width: 64, height: 32, borderRadius: PfRadius.pill),
        SkeletonBox(width: 88, height: 32, borderRadius: PfRadius.pill),
      ],
    );
  }
}

/// One removable chip in an active-filter row.
class ActiveFilterChipData {
  const ActiveFilterChipData({required this.label, required this.onRemoved});

  final String label;
  final VoidCallback onRemoved;
}

/// Chips for the active catalog filters. Each removes its own constraint.
List<ActiveFilterChipData> catalogFilterChips(
  BuildContext context,
  CatalogFilters filters,
  FilterOptionsState options,
  ValueChanged<CatalogFilters> onChanged,
) {
  final l10n = context.l10n;
  return [
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
    if (filters.hasYearRange)
      ActiveFilterChipData(
        label: l10n.filterYearRangeValue(
          filters.yearFrom ?? kCatalogMinYear,
          filters.yearTo ?? catalogMaxYear(),
        ),
        onRemoved: () => onChanged(filters.copyWith(clearYears: true)),
      ),
    if (filters.hasMinRating)
      ActiveFilterChipData(
        label: l10n.filterRatingValue(filters.minRating!),
        onRemoved: () => onChanged(filters.copyWith(clearMinRating: true)),
      ),
  ];
}

/// Horizontal row of removable filter chips with a "clear all" action.
class ActiveFilterChipsRow extends StatelessWidget {
  const ActiveFilterChipsRow({
    required this.chips,
    required this.onClearAll,
    this.padding = const EdgeInsets.symmetric(horizontal: PfSpace.lg),
    super.key,
  });

  final List<ActiveFilterChipData> chips;
  final VoidCallback onClearAll;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    if (chips.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: padding,
        itemCount: chips.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: PfSpace.sm),
        itemBuilder: (context, index) {
          if (index == chips.length) {
            return Center(
              child: TextButton(
                onPressed: onClearAll,
                child: Text(context.l10n.searchFiltersClearAll),
              ),
            );
          }
          final chip = chips[index];
          return Center(
            child: InputChip(
              label: Text(chip.label),
              onDeleted: chip.onRemoved,
              deleteButtonTooltipMessage: context.l10n.filterRemoveChip(
                chip.label,
              ),
            ),
          );
        },
      ),
    );
  }
}
