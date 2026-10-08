import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:picklog/features/library/library_entry_model.dart';

/// Statuses the roulette picks from.
const Set<GameStatus> kBacklogStatuses = {
  GameStatus.planned,
  GameStatus.onHold,
};

class RouletteState extends Equatable {
  const RouletteState({
    this.backlog = const [],
    this.platformId,
    this.maxHoursPlayed,
    this.picked,
    this.spins = 0,
  });

  /// Planned and on-hold entries.
  final List<LibraryEntry> backlog;

  /// IGDB platform id filter, or null for any platform.
  final int? platformId;

  /// Only games with at most this many hours played, or null for any.
  final int? maxHoursPlayed;
  final LibraryEntry? picked;

  /// Number of spins so far. The widget animates when it grows.
  final int spins;

  /// Backlog entries that pass the filters.
  List<LibraryEntry> get candidates => backlog.where(_matches).toList();

  bool _matches(LibraryEntry entry) {
    if (platformId != null && entry.platform?.igdbPlatformId != platformId) {
      return false;
    }
    final max = maxHoursPlayed;
    if (max != null && (entry.playtimeMinutes ?? 0) > max * 60) return false;
    return true;
  }

  /// Platforms present in the backlog, for the filter chips.
  List<CachedPlatform> get platforms {
    final byId = <int, CachedPlatform>{};
    for (final entry in backlog) {
      final platform = entry.platform;
      if (platform != null) byId[platform.igdbPlatformId] = platform;
    }
    return byId.values.toList()
      ..sort((a, b) => a.displayName.compareTo(b.displayName));
  }

  @override
  List<Object?> get props => [
    backlog,
    platformId,
    maxHoursPlayed,
    picked,
    spins,
  ];
}

/// Picks a random game from the backlog with optional platform and
/// hours-played filters.
class RouletteCubit extends Cubit<RouletteState> {
  RouletteCubit({required List<LibraryEntry> library, Random? random})
    : _random = random ?? Random(),
      super(
        RouletteState(
          backlog: library
              .where((e) => kBacklogStatuses.contains(e.status))
              .toList(),
        ),
      );

  final Random _random;

  void setPlatform(int? platformId) => _emitFilters(
    platformId: platformId,
    maxHoursPlayed: state.maxHoursPlayed,
  );

  void setMaxHoursPlayed(int? hours) =>
      _emitFilters(platformId: state.platformId, maxHoursPlayed: hours);

  void _emitFilters({int? platformId, int? maxHoursPlayed}) {
    final next = RouletteState(
      backlog: state.backlog,
      platformId: platformId,
      maxHoursPlayed: maxHoursPlayed,
      spins: state.spins,
    );
    // Keep the current pick only when it still matches.
    final picked = state.picked;
    final keep = picked != null && next.candidates.contains(picked);
    emit(
      RouletteState(
        backlog: next.backlog,
        platformId: platformId,
        maxHoursPlayed: maxHoursPlayed,
        picked: keep ? picked : null,
        spins: state.spins,
      ),
    );
  }

  /// Picks a candidate, never the current pick when another one exists.
  /// Returns the pick, or null when nothing matches.
  LibraryEntry? spin() {
    final candidates = state.candidates;
    if (candidates.isEmpty) return null;
    var pool = candidates;
    if (candidates.length > 1 && state.picked != null) {
      pool = candidates.where((e) => e.id != state.picked!.id).toList();
    }
    final picked = pool[_random.nextInt(pool.length)];
    emit(
      RouletteState(
        backlog: state.backlog,
        platformId: state.platformId,
        maxHoursPlayed: state.maxHoursPlayed,
        picked: picked,
        spins: state.spins + 1,
      ),
    );
    return picked;
  }
}
