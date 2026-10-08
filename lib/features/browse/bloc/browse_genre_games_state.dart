import 'package:equatable/equatable.dart';
import 'package:picklog/core/domain/models/app_failure.dart';
import 'package:picklog/features/games/discovery_game_model.dart';

enum BrowseGenreGamesStatus { initial, loading, loadingMore, success, failure }

class BrowseGenreGamesState extends Equatable {
  const BrowseGenreGamesState({
    this.status = BrowseGenreGamesStatus.initial,
    this.games = const [],
    this.genreId,
    this.hasMore = false,
    this.nextOffset = 0,
    this.errorKind,
  });

  final BrowseGenreGamesStatus status;
  final List<DiscoveryGame> games;
  final int? genreId;
  final bool hasMore;
  final int nextOffset;

  /// Why the last request failed. With games on screen, a page load failed.
  final AppErrorKind? errorKind;

  bool get isLoading => status == BrowseGenreGamesStatus.loading;
  bool get isLoadingMore => status == BrowseGenreGamesStatus.loadingMore;
  bool get hasGames => games.isNotEmpty;
  bool get canLoadMore => hasMore && !isLoading && !isLoadingMore;
  bool get loadMoreFailed =>
      errorKind != null && status == BrowseGenreGamesStatus.success;

  BrowseGenreGamesState copyWith({
    BrowseGenreGamesStatus? status,
    List<DiscoveryGame>? games,
    int? genreId,
    bool? hasMore,
    int? nextOffset,
    AppErrorKind? errorKind,
  }) {
    return BrowseGenreGamesState(
      status: status ?? this.status,
      games: games ?? this.games,
      genreId: genreId ?? this.genreId,
      hasMore: hasMore ?? this.hasMore,
      nextOffset: nextOffset ?? this.nextOffset,
      errorKind: errorKind,
    );
  }

  @override
  List<Object?> get props => [
    status,
    games,
    genreId,
    hasMore,
    nextOffset,
    errorKind,
  ];
}
