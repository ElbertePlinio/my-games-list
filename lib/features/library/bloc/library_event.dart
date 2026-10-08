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

/// Saves changes to [entry]. Fields left null keep their current values.
///
/// Set [details] only from the full edit form. Without it the current score,
/// dates, difficulty and notes of [entry] are sent back, because the API
/// clears any of them that a request leaves out.
class LibraryUpdateEntryRequested extends LibraryEvent {
  const LibraryUpdateEntryRequested({
    required this.entry,
    this.igdbPlatformId,
    this.status,
    this.playtimeMinutes,
    this.isFavorite,
    this.details,
  });

  final LibraryEntry entry;
  final int? igdbPlatformId;
  final GameStatus? status;
  final int? playtimeMinutes;
  final bool? isFavorite;
  final LibraryEntryDetails? details;

  String get entryId => entry.id;

  @override
  List<Object?> get props => [
    entry,
    igdbPlatformId,
    status,
    playtimeMinutes,
    isFavorite,
    details,
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

/// Applies a new collection membership to one entry after the collections
/// API confirmed it. Local only; no request is sent.
class LibraryEntryCollectionsChanged extends LibraryEvent {
  const LibraryEntryCollectionsChanged({
    required this.entryId,
    required this.collectionIds,
  });

  final String entryId;
  final List<String> collectionIds;

  @override
  List<Object?> get props => [entryId, collectionIds];
}

/// Drops a deleted collection id from every entry. Local only.
class LibraryCollectionRemoved extends LibraryEvent {
  const LibraryCollectionRemoved({required this.collectionId});

  final String collectionId;

  @override
  List<Object?> get props => [collectionId];
}
