import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:picklog/features/ai/ai_models.dart';
import 'package:picklog/features/ai/ai_repository.dart';
import 'package:picklog/features/library/library_entry_model.dart';
import 'package:picklog/features/library/library_repository.dart';

/// Slider stops for "time available", in minutes. The last stop means
/// "4 h or more" and sends the API maximum.
const List<int> kPlayNextMinuteStops = [15, 30, 45, 60, 90, 120, 180, 240, 600];

/// Default stop: one hour.
const int kPlayNextDefaultStop = 3;

/// Longest note the API accepts.
const int kPlayNextNoteMax = 200;

enum PlayNextStatus { initial, loading, success, failure }

/// One platform from the user's library, offered as a filter.
class LibraryPlatformOption extends Equatable {
  const LibraryPlatformOption({required this.id, required this.label});

  final int id;
  final String label;

  @override
  List<Object?> get props => [id, label];
}

class PlayNextState extends Equatable {
  const PlayNextState({
    this.status = PlayNextStatus.initial,
    this.mood,
    this.minutesStop = kPlayNextDefaultStop,
    this.platformId,
    this.note = '',
    this.platforms = const [],
    this.backlogCount,
    this.picks = const [],
    this.remainingToday,
    this.errorKind,
    this.startingIds = const {},
    this.startedIds = const {},
    this.startFailureCount = 0,
  });

  final PlayNextStatus status;
  final AiMood? mood;
  final int minutesStop;
  final int? platformId;
  final String note;
  final List<LibraryPlatformOption> platforms;

  /// Planned, playing and on-hold entries. Null until the library loads.
  final int? backlogCount;
  final List<PlayNextPick> picks;
  final int? remainingToday;
  final AiErrorKind? errorKind;

  /// Library entries with a "start playing" update in flight.
  final Set<String> startingIds;

  /// Library entries already moved to playing from this screen.
  final Set<String> startedIds;

  /// Bumped on each failed "start playing" so listeners can react.
  final int startFailureCount;

  int get minutesAvailable => kPlayNextMinuteStops[minutesStop];
  bool get isLoading => status == PlayNextStatus.loading;

  /// True when the library is known to have nothing to pick from, or the API
  /// answered with no picks.
  bool get isBacklogEmpty =>
      backlogCount == 0 || (status == PlayNextStatus.success && picks.isEmpty);

  PlayNextState copyWith({
    PlayNextStatus? status,
    AiMood? Function()? mood,
    int? minutesStop,
    int? Function()? platformId,
    String? note,
    List<LibraryPlatformOption>? platforms,
    int? backlogCount,
    List<PlayNextPick>? picks,
    int? remainingToday,
    AiErrorKind? Function()? errorKind,
    Set<String>? startingIds,
    Set<String>? startedIds,
    int? startFailureCount,
  }) {
    return PlayNextState(
      status: status ?? this.status,
      mood: mood != null ? mood() : this.mood,
      minutesStop: minutesStop ?? this.minutesStop,
      platformId: platformId != null ? platformId() : this.platformId,
      note: note ?? this.note,
      platforms: platforms ?? this.platforms,
      backlogCount: backlogCount ?? this.backlogCount,
      picks: picks ?? this.picks,
      remainingToday: remainingToday ?? this.remainingToday,
      errorKind: errorKind != null ? errorKind() : this.errorKind,
      startingIds: startingIds ?? this.startingIds,
      startedIds: startedIds ?? this.startedIds,
      startFailureCount: startFailureCount ?? this.startFailureCount,
    );
  }

  @override
  List<Object?> get props => [
    status,
    mood,
    minutesStop,
    platformId,
    note,
    platforms,
    backlogCount,
    picks,
    remainingToday,
    errorKind,
    startingIds,
    startedIds,
    startFailureCount,
  ];
}

/// Form, generation and "start playing" for the Play next screen.
class PlayNextCubit extends Cubit<PlayNextState> {
  PlayNextCubit({
    required AiRepository aiRepository,
    required LibraryRepository libraryRepository,
    required String userId,
  }) : _ai = aiRepository,
       _library = libraryRepository,
       _userId = userId,
       super(const PlayNextState());

  final AiRepository _ai;
  final LibraryRepository _library;
  final String _userId;

  static const Set<GameStatus> _backlogStatuses = {
    GameStatus.planned,
    GameStatus.playing,
    GameStatus.onHold,
  };

  /// Loads the library to offer its platforms and detect an empty backlog.
  /// A failure here is silent: the form still works without the filter.
  Future<void> loadLibrary() async {
    if (_userId.isEmpty) return;
    try {
      final entries = await _library.getLibrary(_userId);
      final byId = <int, String>{};
      for (final entry in entries) {
        final platform = entry.platform;
        if (platform != null) {
          byId[platform.igdbPlatformId] = platform.displayName;
        }
      }
      final platforms = [
        for (final e in byId.entries)
          LibraryPlatformOption(id: e.key, label: e.value),
      ]..sort((a, b) => a.label.compareTo(b.label));
      final backlog = entries
          .where((e) => _backlogStatuses.contains(e.status))
          .length;
      if (isClosed) return;
      emit(state.copyWith(platforms: platforms, backlogCount: backlog));
    } catch (_) {
      // Keep the form usable; the API still validates the backlog.
    }
  }

  void selectMood(AiMood? mood) =>
      emit(state.copyWith(mood: () => mood == state.mood ? null : mood));

  void setMinutesStop(int stop) => emit(
    state.copyWith(minutesStop: stop.clamp(0, kPlayNextMinuteStops.length - 1)),
  );

  void selectPlatform(int? platformId) =>
      emit(state.copyWith(platformId: () => platformId));

  void setNote(String note) => emit(
    state.copyWith(
      note: note.length > kPlayNextNoteMax
          ? note.substring(0, kPlayNextNoteMax)
          : note,
    ),
  );

  Future<void> generate() async {
    if (state.isLoading) return;
    emit(state.copyWith(status: PlayNextStatus.loading, errorKind: () => null));
    try {
      final result = await _ai.playNext(
        PlayNextRequest(
          minutesAvailable: state.minutesAvailable,
          mood: state.mood,
          platformId: state.platformId,
          note: state.note,
        ),
      );
      if (isClosed) return;
      emit(
        state.copyWith(
          status: PlayNextStatus.success,
          picks: result.picks,
          remainingToday: result.remainingToday,
          startedIds: const {},
        ),
      );
    } catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: PlayNextStatus.failure,
          errorKind: () => AiErrorKind.from(e),
        ),
      );
    }
  }

  /// Sets the pick's library entry to playing.
  Future<void> startPlaying(PlayNextPick pick) async {
    final id = pick.libraryEntryId;
    if (state.startingIds.contains(id) || state.startedIds.contains(id)) {
      return;
    }
    emit(state.copyWith(startingIds: {...state.startingIds, id}));
    try {
      // The pick only carries the entry id. Read the entry first so the
      // update sends back its score, dates, difficulty and notes.
      final current = await _library.getLibraryEntry(id);
      await _library.updateLibraryEntry(current, status: GameStatus.playing);
      if (isClosed) return;
      emit(
        state.copyWith(
          startingIds: {...state.startingIds}..remove(id),
          startedIds: {...state.startedIds, id},
        ),
      );
    } catch (_) {
      if (isClosed) return;
      emit(
        state.copyWith(
          startingIds: {...state.startingIds}..remove(id),
          startFailureCount: state.startFailureCount + 1,
        ),
      );
    }
  }
}
