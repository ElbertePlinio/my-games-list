import 'dart:math' as math;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:picklog/core/data/services/storage/local_storage_service.dart';
import 'package:picklog/core/domain/models/app_failure.dart';
import 'package:picklog/features/library/browse/library_browse_event.dart';
import 'package:picklog/features/library/browse/library_browse_state.dart';
import 'package:picklog/features/library/library_entry_model.dart';
import 'package:picklog/features/library/library_repository.dart';
import 'package:stream_transform/stream_transform.dart';

/// Server-side filtered, sorted and paged library list for the Library tab.
///
/// The shared LibraryBloc keeps the whole library for membership checks on
/// other screens. This bloc only shows what the API matched, and follows the
/// shared bloc's mutations through [LibraryBrowseSourceChanged].
class LibraryBrowseBloc extends Bloc<LibraryBrowseEvent, LibraryBrowseState> {
  LibraryBrowseBloc({
    required LibraryRepository libraryRepository,
    required LocalStorageService storage,
    Duration queryDebounce = const Duration(milliseconds: 350),
  }) : _repository = libraryRepository,
       _storage = storage,
       super(const LibraryBrowseState()) {
    on<LibraryBrowseStarted>(_onStarted);
    on<LibraryBrowseFiltersChanged>(_onFiltersChanged);
    on<LibraryBrowseQueryChanged>(
      _onQueryChanged,
      // Drop a query that only differs in whitespace before switchMap, so it
      // never cancels the request that is still loading.
      transformer: (events, mapper) => events
          .debounce(queryDebounce)
          .where((e) => e.query.trim() != state.filters.query)
          .switchMap(mapper),
    );
    on<LibraryBrowseSortChanged>(_onSortChanged);
    on<LibraryBrowseLoadMore>(_onLoadMore);
    on<LibraryBrowseRefreshRequested>(_onRefresh);
    on<LibraryBrowseViewModeChanged>(_onViewModeChanged);
    on<LibraryBrowseSourceChanged>(_onSourceChanged);
  }

  final LibraryRepository _repository;
  final LocalStorageService _storage;

  /// Page size for `limit`.
  static const int pageSize = 50;

  /// SharedPreferences key of the list or grid choice.
  static const String viewModeKey = 'library_view_mode';

  /// Bumped on every first-page request so a slow older response never
  /// replaces a newer one.
  int _generation = 0;
  Set<String>? _sourceIds;

  Future<void> _onStarted(
    LibraryBrowseStarted event,
    Emitter<LibraryBrowseState> emit,
  ) async {
    if (state.userId == event.userId &&
        state.status != LibraryBrowseStatus.initial) {
      return;
    }
    LibraryViewMode mode = state.viewMode;
    try {
      mode = LibraryViewMode.fromName(await _storage.getString(viewModeKey));
    } catch (_) {
      // Preferences can be unavailable; keep the default list.
    }
    emit(state.copyWith(userId: event.userId, viewMode: mode));
    await _loadFirstPage(emit);
  }

  Future<void> _onFiltersChanged(
    LibraryBrowseFiltersChanged event,
    Emitter<LibraryBrowseState> emit,
  ) async {
    if (event.filters == state.filters) return;
    emit(state.copyWith(filters: event.filters));
    await _loadFirstPage(emit);
  }

  Future<void> _onQueryChanged(
    LibraryBrowseQueryChanged event,
    Emitter<LibraryBrowseState> emit,
  ) async {
    final query = event.query.trim();
    if (query == state.filters.query) return;
    emit(state.copyWith(filters: state.filters.copyWith(query: query)));
    await _loadFirstPage(emit);
  }

  Future<void> _onSortChanged(
    LibraryBrowseSortChanged event,
    Emitter<LibraryBrowseState> emit,
  ) async {
    if (event.sort == state.filters.sort) return;
    emit(state.copyWith(filters: state.filters.copyWith(sort: event.sort)));
    await _loadFirstPage(emit);
  }

  Future<void> _onRefresh(
    LibraryBrowseRefreshRequested event,
    Emitter<LibraryBrowseState> emit,
  ) => _loadFirstPage(emit, keepEntries: true);

  Future<void> _loadFirstPage(
    Emitter<LibraryBrowseState> emit, {
    bool keepEntries = false,
  }) async {
    final userId = state.userId;
    if (userId == null || userId.isEmpty) return;
    final generation = ++_generation;
    final filters = state.filters;
    emit(
      state.copyWith(
        status: LibraryBrowseStatus.loading,
        entries: keepEntries ? null : const [],
        hasMore: false,
      ),
    );
    try {
      final response = await _repository.queryLibrary(
        userId,
        filters,
        limit: pageSize,
      );
      if (generation != _generation) return;
      emit(
        state.copyWith(
          status: LibraryBrowseStatus.success,
          entries: response.entries,
          totalCount: response.totalCount,
          nextOffset: response.entries.length,
          hasMore: response.entries.length < response.totalCount,
        ),
      );
    } catch (e) {
      if (generation != _generation) return;
      emit(
        state.copyWith(
          status: state.hasEntries
              ? LibraryBrowseStatus.success
              : LibraryBrowseStatus.failure,
          errorKind: AppErrorKind.from(e),
        ),
      );
    }
  }

  Future<void> _onLoadMore(
    LibraryBrowseLoadMore event,
    Emitter<LibraryBrowseState> emit,
  ) async {
    final userId = state.userId;
    if (userId == null || !state.canLoadMore) return;
    final generation = _generation;
    final offset = state.nextOffset;
    emit(state.copyWith(status: LibraryBrowseStatus.loadingMore));
    try {
      final response = await _repository.queryLibrary(
        userId,
        state.filters,
        limit: pageSize,
        offset: offset,
      );
      if (generation != _generation) return;
      final seen = {for (final e in state.entries) e.id};
      final entries = [
        ...state.entries,
        ...response.entries.where((e) => !seen.contains(e.id)),
      ];
      final nextOffset = offset + response.entries.length;
      emit(
        state.copyWith(
          status: LibraryBrowseStatus.success,
          entries: entries,
          totalCount: response.totalCount,
          nextOffset: nextOffset,
          hasMore:
              response.entries.isNotEmpty && nextOffset < response.totalCount,
        ),
      );
    } catch (e) {
      if (generation != _generation) return;
      // Keep the loaded entries; the list offers a retry at the end.
      emit(
        state.copyWith(
          status: LibraryBrowseStatus.success,
          errorKind: AppErrorKind.from(e),
        ),
      );
    }
  }

  Future<void> _onViewModeChanged(
    LibraryBrowseViewModeChanged event,
    Emitter<LibraryBrowseState> emit,
  ) async {
    if (event.mode == state.viewMode) return;
    emit(state.copyWith(viewMode: event.mode, status: state.status));
    try {
      await _storage.setString(viewModeKey, event.mode.name);
    } catch (_) {
      // Not saved; the choice still applies for this session.
    }
  }

  Future<void> _onSourceChanged(
    LibraryBrowseSourceChanged event,
    Emitter<LibraryBrowseState> emit,
  ) async {
    final ids = {for (final e in event.entries) e.id};
    final previous = _sourceIds;
    _sourceIds = ids;
    if (previous == null) return;

    final added = ids.difference(previous);
    if (added.isNotEmpty) {
      await _loadFirstPage(emit, keepEntries: true);
      return;
    }

    final removed = previous.difference(ids);
    final byId = {for (final e in event.entries) e.id: e};
    final patched = <LibraryEntry>[
      for (final entry in state.entries)
        if (!removed.contains(entry.id)) byId[entry.id] ?? entry,
    ];
    final dropped = state.entries.length - patched.length;
    emit(
      state.copyWith(
        status: state.status,
        entries: patched,
        totalCount: math.max(0, state.totalCount - dropped),
        nextOffset: math.max(0, state.nextOffset - dropped),
        errorKind: state.errorKind,
      ),
    );
  }
}
