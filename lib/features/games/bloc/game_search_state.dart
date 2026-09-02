import 'package:equatable/equatable.dart';
import 'package:picklog/features/games/bloc/game_search_filters.dart';
import 'package:picklog/features/games/search_game_model.dart';

enum GameSearchStatus { initial, loading, success, failure, loadingMore }

class GameSearchState extends Equatable {
  const GameSearchState({
    this.status = GameSearchStatus.initial,
    this.games = const [],
    this.query = '',
    this.errorMessage,
    this.hasMore = true,
    this.currentOffset = 0,
    this.offsetLimitReached = false,
    this.filters = const GameSearchFilters(),
  });

  final GameSearchStatus status;

  /// Raw, unfiltered results accumulated across pages from the API.
  final List<SearchGame> games;
  final String query;
  final String? errorMessage;
  final bool hasMore;
  final int currentOffset;
  final bool offsetLimitReached;
  final GameSearchFilters filters;

  /// Results after applying the active client-side filters and sort. The UI
  /// renders this; pagination keeps operating over [games].
  List<SearchGame> get visibleGames => filters.apply(games);

  bool get isLoading => status == GameSearchStatus.loading;
  bool get isLoadingMore => status == GameSearchStatus.loadingMore;
  bool get hasGames => visibleGames.isNotEmpty;

  /// True when the search succeeded but nothing is shown — either the API
  /// returned nothing or the active filters narrowed everything out.
  bool get isEmpty =>
      visibleGames.isEmpty && status == GameSearchStatus.success;

  /// Distinguishes "no API results" from "filters hid every result", so the
  /// empty state can guide the user to relax filters instead of the query.
  bool get isEmptyByFilters =>
      visibleGames.isEmpty &&
      games.isNotEmpty &&
      status == GameSearchStatus.success;

  bool get canLoadMore => hasMore && !offsetLimitReached && !isLoadingMore;
  bool get hasActiveFilters => !filters.isEmpty;

  /// Genres present in the loaded results, de-duplicated and name-sorted, so
  /// the filter sheet only offers facets that can actually match.
  List<GameGenre> get availableGenres {
    final byId = <int, GameGenre>{};
    for (final game in games) {
      for (final genre in game.genres) {
        byId[genre.id] = genre;
      }
    }
    final list = byId.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return list;
  }

  /// Platforms present in the loaded results, de-duplicated and name-sorted.
  List<GamePlatform> get availablePlatforms {
    final byId = <int, GamePlatform>{};
    for (final game in games) {
      for (final platform in game.platforms) {
        byId[platform.id] = platform;
      }
    }
    final list = byId.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return list;
  }

  /// Release years present in the loaded results, newest first. The year is
  /// derived in UTC to match how the API reports release timestamps, so a
  /// midnight-UTC release does not slip into the previous year on devices west
  /// of UTC.
  List<int> get availableYears {
    final years = <int>{};
    for (final game in games) {
      final year = game.firstReleaseDate?.toUtc().year;
      if (year != null) years.add(year);
    }
    final list = years.toList()..sort((a, b) => b.compareTo(a));
    return list;
  }

  GameSearchState copyWith({
    GameSearchStatus? status,
    List<SearchGame>? games,
    String? query,
    String? errorMessage,
    bool? hasMore,
    int? currentOffset,
    bool? offsetLimitReached,
    GameSearchFilters? filters,
  }) {
    return GameSearchState(
      status: status ?? this.status,
      games: games ?? this.games,
      query: query ?? this.query,
      errorMessage: errorMessage,
      hasMore: hasMore ?? this.hasMore,
      currentOffset: currentOffset ?? this.currentOffset,
      offsetLimitReached: offsetLimitReached ?? this.offsetLimitReached,
      filters: filters ?? this.filters,
    );
  }

  @override
  List<Object?> get props => [
    status,
    games,
    query,
    errorMessage,
    hasMore,
    currentOffset,
    offsetLimitReached,
    filters,
  ];
}
