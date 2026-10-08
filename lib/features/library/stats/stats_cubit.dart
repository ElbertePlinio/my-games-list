import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:picklog/core/domain/models/app_failure.dart';
import 'package:picklog/features/library/stats/library_stats_model.dart';
import 'package:picklog/features/library/stats/stats_repository.dart';

enum StatsStatus { initial, loading, success, failure }

class StatsState extends Equatable {
  const StatsState({
    this.status = StatsStatus.initial,
    this.stats,
    this.year,
    this.errorKind,
  });

  final StatsStatus status;
  final UserStats? stats;

  /// The requested year, or null for all-time stats only.
  final int? year;
  final AppErrorKind? errorKind;

  bool get isLoading => status == StatsStatus.loading;
  bool get hasStats => stats != null;

  StatsState copyWith({
    StatsStatus? status,
    UserStats? stats,
    int? year,
    bool clearStats = false,
    AppErrorKind? errorKind,
  }) {
    return StatsState(
      status: status ?? this.status,
      stats: clearStats ? null : (stats ?? this.stats),
      year: year ?? this.year,
      errorKind: errorKind,
    );
  }

  @override
  List<Object?> get props => [status, stats, year, errorKind];
}

/// Loads `GET /users/me/stats`, optionally for one year.
class StatsCubit extends Cubit<StatsState> {
  StatsCubit({required StatsRepository statsRepository, int? year})
    : _repository = statsRepository,
      super(StatsState(year: year));

  final StatsRepository _repository;
  int _generation = 0;

  /// Loads the stats. A new [year] replaces the shown stats; a reload of the
  /// same year keeps them on screen until the response lands.
  Future<void> load({int? year}) async {
    final targetYear = year ?? state.year;
    final yearChanged = targetYear != state.year;
    final generation = ++_generation;
    emit(
      StatsState(
        status: StatsStatus.loading,
        stats: yearChanged ? null : state.stats,
        year: targetYear,
      ),
    );
    try {
      final stats = await _repository.getStats(year: targetYear);
      if (isClosed || generation != _generation) return;
      emit(
        StatsState(status: StatsStatus.success, stats: stats, year: targetYear),
      );
    } catch (e) {
      if (isClosed || generation != _generation) return;
      emit(
        StatsState(
          status: StatsStatus.failure,
          stats: state.stats,
          year: targetYear,
          errorKind: AppErrorKind.from(e),
        ),
      );
    }
  }
}
