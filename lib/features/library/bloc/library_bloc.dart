import 'package:bloc/bloc.dart';
import 'package:picklog/features/library/bloc/library_event.dart';
import 'package:picklog/features/library/bloc/library_state.dart';
import 'package:picklog/features/library/library_repository.dart';

/// BLoC for managing user's game library state
class LibraryBloc extends Bloc<LibraryEvent, LibraryState> {
  LibraryBloc({required LibraryRepository libraryRepository})
    : _libraryRepository = libraryRepository,
      super(const LibraryState()) {
    on<LibraryLoadRequested>(_onLoadRequested);
    on<LibraryRefreshRequested>(_onRefreshRequested);
    on<LibraryAddGameRequested>(_onAddGameRequested);
    on<LibraryUpdateEntryRequested>(_onUpdateEntryRequested);
    on<LibraryDeleteEntryRequested>(_onDeleteEntryRequested);
    on<LibraryToggleFavoriteRequested>(_onToggleFavoriteRequested);
    on<LibraryFilterToggled>(_onFilterToggled);
    on<LibraryStatusFilterChanged>(_onStatusFilterChanged);
  }

  final LibraryRepository _libraryRepository;

  Future<void> _onLoadRequested(
    LibraryLoadRequested event,
    Emitter<LibraryState> emit,
  ) async {
    if (state.status == LibraryStatus.loading) return;

    emit(state.copyWith(status: LibraryStatus.loading, userId: event.userId));

    try {
      final entries = await _libraryRepository.getLibrary(event.userId);
      emit(
        state.copyWith(
          status: LibraryStatus.success,
          entries: entries,
          lastUpdated: DateTime.now(),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: LibraryStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onRefreshRequested(
    LibraryRefreshRequested event,
    Emitter<LibraryState> emit,
  ) async {
    try {
      final entries = await _libraryRepository.getLibrary(event.userId);
      emit(
        state.copyWith(
          status: LibraryStatus.success,
          entries: entries,
          lastUpdated: DateTime.now(),
        ),
      );
    } catch (e) {
      // On refresh failure, keep existing entries but show error
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> _onAddGameRequested(
    LibraryAddGameRequested event,
    Emitter<LibraryState> emit,
  ) async {
    emit(state.copyWith(isAddingGame: true));

    try {
      final newEntry = await _libraryRepository.addToLibrary(
        igdbId: event.igdbId,
        status: event.status,
        igdbPlatformId: event.igdbPlatformId,
        score: event.score,
        playtimeMinutes: event.playtimeMinutes,
        startDate: event.startDate,
        endDate: event.endDate,
        difficulty: event.difficulty,
        isFavorite: event.isFavorite,
        notes: event.notes,
      );

      // Add to the beginning of the list
      final updatedEntries = [newEntry, ...state.entries];
      emit(
        state.copyWith(
          entries: updatedEntries,
          isAddingGame: false,
          gameAddedOrUpdated: true,
        ),
      );

      emit(state.copyWith(gameAddedOrUpdated: false));
    } catch (e) {
      emit(state.copyWith(isAddingGame: false, errorMessage: e.toString()));
    }
  }

  Future<void> _onUpdateEntryRequested(
    LibraryUpdateEntryRequested event,
    Emitter<LibraryState> emit,
  ) async {
    emit(state.copyWith(isUpdatingEntry: true));

    try {
      final updatedEntry = await _libraryRepository.updateLibraryEntry(
        entryId: event.entryId,
        igdbPlatformId: event.igdbPlatformId,
        status: event.status,
        score: event.score,
        playtimeMinutes: event.playtimeMinutes,
        startDate: event.startDate,
        endDate: event.endDate,
        difficulty: event.difficulty,
        isFavorite: event.isFavorite,
        notes: event.notes,
      );

      // Update the entry in the list
      final updatedEntries = state.entries.map((entry) {
        return entry.id == event.entryId ? updatedEntry : entry;
      }).toList();

      emit(
        state.copyWith(
          entries: updatedEntries,
          isUpdatingEntry: false,
          gameAddedOrUpdated: true,
        ),
      );

      emit(state.copyWith(gameAddedOrUpdated: false));
    } catch (e) {
      emit(state.copyWith(isUpdatingEntry: false, errorMessage: e.toString()));
    }
  }

  Future<void> _onDeleteEntryRequested(
    LibraryDeleteEntryRequested event,
    Emitter<LibraryState> emit,
  ) async {
    // Optimistic delete - remove from list immediately
    final originalEntries = List.of(state.entries);
    final updatedEntries = state.entries
        .where((entry) => entry.id != event.entryId)
        .toList();

    emit(state.copyWith(entries: updatedEntries));

    try {
      await _libraryRepository.deleteLibraryEntry(event.entryId);
    } catch (e) {
      // Rollback on failure
      emit(
        state.copyWith(entries: originalEntries, errorMessage: e.toString()),
      );
    }
  }

  Future<void> _onToggleFavoriteRequested(
    LibraryToggleFavoriteRequested event,
    Emitter<LibraryState> emit,
  ) async {
    // Optimistic UI update - toggle favorite immediately
    final originalEntries = List.of(state.entries);
    final updatedEntries = state.entries.map((entry) {
      if (entry.id == event.entryId) {
        return entry.copyWith(isFavorite: !entry.isFavorite);
      }
      return entry;
    }).toList();

    emit(state.copyWith(entries: updatedEntries));

    try {
      await _libraryRepository.toggleFavorite(event.entryId);
    } catch (e) {
      // Rollback on failure
      emit(
        state.copyWith(entries: originalEntries, errorMessage: e.toString()),
      );
    }
  }

  void _onFilterToggled(
    LibraryFilterToggled event,
    Emitter<LibraryState> emit,
  ) {
    emit(state.copyWith(showFavoritesOnly: event.showFavoritesOnly));
  }

  void _onStatusFilterChanged(
    LibraryStatusFilterChanged event,
    Emitter<LibraryState> emit,
  ) {
    if (event.status == null) {
      emit(state.copyWith(clearStatusFilter: true));
    } else {
      emit(state.copyWith(statusFilter: event.status));
    }
  }
}
