import 'package:equatable/equatable.dart';
import 'package:picklog/features/library/library_entry_model.dart';

/// Enum representing the status of library loading
enum LibraryStatus { initial, loading, success, failure }

/// State class for library
class LibraryState extends Equatable {
  const LibraryState({
    this.status = LibraryStatus.initial,
    this.entries = const [],
    this.errorMessage,
    this.userId,
    this.showFavoritesOnly = false,
    this.statusFilter,
    this.lastUpdated,
    this.isAddingGame = false,
    this.isUpdatingEntry = false,
    this.gameAddedOrUpdated = false,
  });

  final LibraryStatus status;
  final List<LibraryEntry> entries;
  final String? errorMessage;
  final String? userId;
  final bool showFavoritesOnly;
  final GameStatus? statusFilter;
  final DateTime? lastUpdated;
  final bool isAddingGame;
  final bool isUpdatingEntry;
  final bool gameAddedOrUpdated;

  /// Returns true if the state is in loading status
  bool get isLoading => status == LibraryStatus.loading;

  /// Returns true if entries have been loaded successfully
  bool get hasEntries => entries.isNotEmpty;

  /// Returns the filtered entries based on current filters
  List<LibraryEntry> get filteredEntries {
    var result = entries;

    if (showFavoritesOnly) {
      result = result.where((e) => e.isFavorite).toList();
    }

    if (statusFilter != null) {
      result = result.where((e) => e.status == statusFilter).toList();
    }

    return result;
  }

  /// Returns the count of favorites
  int get favoritesCount => entries.where((e) => e.isFavorite).length;

  /// Returns the count of games by status
  Map<GameStatus, int> get statusCounts {
    final counts = <GameStatus, int>{};
    for (final status in GameStatus.values) {
      counts[status] = entries.where((e) => e.status == status).length;
    }
    return counts;
  }

  LibraryState copyWith({
    LibraryStatus? status,
    List<LibraryEntry>? entries,
    String? errorMessage,
    String? userId,
    bool? showFavoritesOnly,
    GameStatus? statusFilter,
    bool clearStatusFilter = false,
    DateTime? lastUpdated,
    bool? isAddingGame,
    bool? isUpdatingEntry,
    bool? gameAddedOrUpdated,
  }) {
    return LibraryState(
      status: status ?? this.status,
      entries: entries ?? this.entries,
      errorMessage: errorMessage,
      userId: userId ?? this.userId,
      showFavoritesOnly: showFavoritesOnly ?? this.showFavoritesOnly,
      statusFilter: clearStatusFilter
          ? null
          : (statusFilter ?? this.statusFilter),
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isAddingGame: isAddingGame ?? this.isAddingGame,
      isUpdatingEntry: isUpdatingEntry ?? this.isUpdatingEntry,
      gameAddedOrUpdated: gameAddedOrUpdated ?? this.gameAddedOrUpdated,
    );
  }

  @override
  List<Object?> get props => [
    status,
    entries,
    errorMessage,
    userId,
    showFavoritesOnly,
    statusFilter,
    lastUpdated,
    isAddingGame,
    isUpdatingEntry,
    gameAddedOrUpdated,
  ];
}
