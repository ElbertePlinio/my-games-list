import 'package:equatable/equatable.dart';
import 'package:picklog/features/library/library_entry_model.dart';

/// Base class for library events
abstract class LibraryEvent extends Equatable {
  const LibraryEvent();

  @override
  List<Object?> get props => [];
}

/// Event triggered when the library should be loaded
class LibraryLoadRequested extends LibraryEvent {
  const LibraryLoadRequested({required this.userId});

  final String userId;

  @override
  List<Object?> get props => [userId];
}

/// Event triggered when the user requests a refresh
class LibraryRefreshRequested extends LibraryEvent {
  const LibraryRefreshRequested({required this.userId});

  final String userId;

  @override
  List<Object?> get props => [userId];
}

/// Event triggered when a game should be added to the library
class LibraryAddGameRequested extends LibraryEvent {
  const LibraryAddGameRequested({
    required this.igdbId,
    required this.status,
    this.igdbPlatformId,
    this.score,
    this.playtimeMinutes,
    this.startDate,
    this.endDate,
    this.difficulty,
    this.isFavorite = false,
    this.notes,
  });

  final int igdbId;
  final GameStatus status;
  final int? igdbPlatformId;
  final int? score;
  final int? playtimeMinutes;
  final String? startDate;
  final String? endDate;
  final String? difficulty;
  final bool isFavorite;
  final String? notes;

  @override
  List<Object?> get props => [
    igdbId,
    status,
    igdbPlatformId,
    score,
    playtimeMinutes,
    startDate,
    endDate,
    difficulty,
    isFavorite,
    notes,
  ];
}

/// Event triggered when a library entry should be updated
class LibraryUpdateEntryRequested extends LibraryEvent {
  const LibraryUpdateEntryRequested({
    required this.entryId,
    this.igdbPlatformId,
    this.status,
    this.score,
    this.playtimeMinutes,
    this.startDate,
    this.endDate,
    this.difficulty,
    this.isFavorite,
    this.notes,
  });

  final String entryId;
  final int? igdbPlatformId;
  final GameStatus? status;
  final int? score;
  final int? playtimeMinutes;
  final String? startDate;
  final String? endDate;
  final String? difficulty;
  final bool? isFavorite;
  final String? notes;

  @override
  List<Object?> get props => [
    entryId,
    igdbPlatformId,
    status,
    score,
    playtimeMinutes,
    startDate,
    endDate,
    difficulty,
    isFavorite,
    notes,
  ];
}

/// Event triggered when a library entry should be deleted
class LibraryDeleteEntryRequested extends LibraryEvent {
  const LibraryDeleteEntryRequested({required this.entryId});

  final String entryId;

  @override
  List<Object?> get props => [entryId];
}

/// Event triggered when a favorite toggle is requested (optimistic UI)
class LibraryToggleFavoriteRequested extends LibraryEvent {
  const LibraryToggleFavoriteRequested({required this.entryId});

  final String entryId;

  @override
  List<Object?> get props => [entryId];
}

/// Event triggered when the favorites filter is toggled
class LibraryFilterToggled extends LibraryEvent {
  const LibraryFilterToggled({required this.showFavoritesOnly});

  final bool showFavoritesOnly;

  @override
  List<Object?> get props => [showFavoritesOnly];
}

/// Event triggered when status filter changes
class LibraryStatusFilterChanged extends LibraryEvent {
  const LibraryStatusFilterChanged({this.status});

  final GameStatus? status;

  @override
  List<Object?> get props => [status];
}
