import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:picklog/core/utils/l10n_extensions.dart';
import 'package:picklog/features/library/library_entry_model.dart';

/// Server-side sort keys of `GET /users/{id}/library`.
enum LibrarySort {
  updatedDesc('updated_desc'),
  addedDesc('added_desc'),
  nameAsc('name_asc'),
  scoreDesc('score_desc'),
  playtimeDesc('playtime_desc'),
  releaseDesc('release_desc'),
  ratingDesc('rating_desc');

  const LibrarySort(this.apiValue);

  /// Value of the `sort` query parameter.
  final String apiValue;

  /// Localized menu label.
  String localizedName(BuildContext context) {
    final l10n = context.l10n;
    return switch (this) {
      LibrarySort.updatedDesc => l10n.librarySortUpdated,
      LibrarySort.addedDesc => l10n.librarySortAdded,
      LibrarySort.nameAsc => l10n.librarySortName,
      LibrarySort.scoreDesc => l10n.librarySortScore,
      LibrarySort.playtimeDesc => l10n.librarySortPlaytime,
      LibrarySort.releaseDesc => l10n.librarySortRelease,
      LibrarySort.ratingDesc => l10n.librarySortRating,
    };
  }
}

/// Filters and sort for the library list. The API applies all of them.
class LibraryFilters extends Equatable {
  const LibraryFilters({
    this.statuses = const {},
    this.favoritesOnly = false,
    this.query = '',
    this.genreIds = const {},
    this.platformIds = const {},
    this.minScore,
    this.collectionId,
    this.sort = LibrarySort.updatedDesc,
  });

  /// The API caps `q` at this many characters.
  static const int maxQueryLength = 100;

  final Set<GameStatus> statuses;
  final bool favoritesOnly;
  final String query;
  final Set<int> genreIds;
  final Set<int> platformIds;

  /// Minimum entry score, 0-100. Null means no minimum.
  final int? minScore;
  final String? collectionId;
  final LibrarySort sort;

  /// True when any filter narrows the list. Sort does not count.
  /// Every filter except the search text shows a chip, so the chip count
  /// covers them.
  bool get hasActiveFilters => activeChipCount > 0 || query.trim().isNotEmpty;

  /// Number of filter chips shown (the search text is excluded).
  int get activeChipCount =>
      statuses.length +
      (favoritesOnly ? 1 : 0) +
      genreIds.length +
      platformIds.length +
      (minScore != null ? 1 : 0) +
      (collectionId != null ? 1 : 0);

  LibraryFilters copyWith({
    Set<GameStatus>? statuses,
    bool? favoritesOnly,
    String? query,
    Set<int>? genreIds,
    Set<int>? platformIds,
    int? minScore,
    bool clearMinScore = false,
    String? collectionId,
    bool clearCollection = false,
    LibrarySort? sort,
  }) {
    return LibraryFilters(
      statuses: statuses ?? this.statuses,
      favoritesOnly: favoritesOnly ?? this.favoritesOnly,
      query: query ?? this.query,
      genreIds: genreIds ?? this.genreIds,
      platformIds: platformIds ?? this.platformIds,
      minScore: clearMinScore ? null : (minScore ?? this.minScore),
      collectionId: clearCollection
          ? null
          : (collectionId ?? this.collectionId),
      sort: sort ?? this.sort,
    );
  }

  /// Clears every filter but keeps the sort.
  LibraryFilters cleared() => LibraryFilters(sort: sort);

  /// Query parameters for the library endpoint. Lists are sorted so the same
  /// filters always build the same URL.
  Map<String, String> toQueryParameters({int? limit, int? offset}) {
    final params = <String, String>{};
    if (statuses.isNotEmpty) {
      params['status'] = GameStatus.values
          .where(statuses.contains)
          .map((s) => s.toApiString())
          .join(',');
    }
    if (favoritesOnly) params['favorites_only'] = 'true';
    final q = query.trim();
    if (q.isNotEmpty) {
      params['q'] = q.length > maxQueryLength
          ? q.substring(0, maxQueryLength)
          : q;
    }
    if (genreIds.isNotEmpty) params['genre_ids'] = _join(genreIds);
    if (platformIds.isNotEmpty) params['platform_ids'] = _join(platformIds);
    if (minScore != null) {
      params['min_score'] = minScore!.clamp(0, 100).toString();
    }
    if (collectionId != null) params['collection_id'] = collectionId!;
    if (sort != LibrarySort.updatedDesc) params['sort'] = sort.apiValue;
    if (limit != null) params['limit'] = limit.toString();
    if (offset != null && offset > 0) params['offset'] = offset.toString();
    return params;
  }

  static String _join(Set<int> ids) => (ids.toList()..sort()).join(',');

  @override
  List<Object?> get props => [
    statuses,
    favoritesOnly,
    query,
    genreIds,
    platformIds,
    minScore,
    collectionId,
    sort,
  ];
}
