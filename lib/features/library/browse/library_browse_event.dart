import 'package:equatable/equatable.dart';
import 'package:picklog/features/library/browse/library_browse_state.dart';
import 'package:picklog/features/library/library_entry_model.dart';
import 'package:picklog/features/library/library_query.dart';

abstract class LibraryBrowseEvent extends Equatable {
  const LibraryBrowseEvent();

  @override
  List<Object?> get props => [];
}

/// Restores the saved view mode and loads the first page for [userId].
class LibraryBrowseStarted extends LibraryBrowseEvent {
  const LibraryBrowseStarted({required this.userId});

  final String userId;

  @override
  List<Object?> get props => [userId];
}

/// Replaces every filter and the sort, then reloads from the first page.
class LibraryBrowseFiltersChanged extends LibraryBrowseEvent {
  const LibraryBrowseFiltersChanged(this.filters);

  final LibraryFilters filters;

  @override
  List<Object?> get props => [filters];
}

/// The search text changed. Debounced before it reaches the API.
class LibraryBrowseQueryChanged extends LibraryBrowseEvent {
  const LibraryBrowseQueryChanged(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

class LibraryBrowseSortChanged extends LibraryBrowseEvent {
  const LibraryBrowseSortChanged(this.sort);

  final LibrarySort sort;

  @override
  List<Object?> get props => [sort];
}

/// Fetches the next page when more matches exist.
class LibraryBrowseLoadMore extends LibraryBrowseEvent {
  const LibraryBrowseLoadMore();
}

/// Reloads the first page with the current filters.
class LibraryBrowseRefreshRequested extends LibraryBrowseEvent {
  const LibraryBrowseRefreshRequested();
}

class LibraryBrowseViewModeChanged extends LibraryBrowseEvent {
  const LibraryBrowseViewModeChanged(this.mode);

  final LibraryViewMode mode;

  @override
  List<Object?> get props => [mode];
}

/// The shared library changed (favorite, status, delete, add). Patches the
/// loaded page in place and reloads when an entry was added.
class LibraryBrowseSourceChanged extends LibraryBrowseEvent {
  const LibraryBrowseSourceChanged(this.entries);

  final List<LibraryEntry> entries;

  @override
  List<Object?> get props => [entries];
}
