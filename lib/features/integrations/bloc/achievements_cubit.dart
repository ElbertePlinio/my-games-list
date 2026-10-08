import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:picklog/features/integrations/integrations_models.dart';
import 'package:picklog/features/integrations/integrations_repository.dart';

enum AchievementsStatus { initial, loading, ready, failure }

class AchievementsState extends Equatable {
  const AchievementsState({
    this.status = AchievementsStatus.initial,
    this.summary,
    this.providerFilter,
    this.errorKind,
  });

  final AchievementsStatus status;
  final AchievementSummary? summary;

  /// Null shows every provider.
  final GameProvider? providerFilter;
  final IntegrationErrorKind? errorKind;

  /// Games for the active filter, most recently played first. Games without
  /// a play date go last, by name.
  List<GameProgress> get games {
    final all = summary?.games ?? const <GameProgress>[];
    final filtered = providerFilter == null
        ? [...all]
        : all.where((g) => g.provider == providerFilter).toList();
    filtered.sort((a, b) {
      final ad = a.lastPlayedAt, bd = b.lastPlayedAt;
      if (ad != null && bd != null) return bd.compareTo(ad);
      if (ad != null) return -1;
      if (bd != null) return 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return filtered;
  }

  /// Providers that have at least one game, in enum order.
  List<GameProvider> get providersWithGames {
    final present = {
      for (final g in summary?.games ?? const <GameProgress>[]) g.provider,
    };
    return [
      for (final p in GameProvider.values)
        if (present.contains(p)) p,
    ];
  }

  AchievementsState copyWith({
    AchievementsStatus? status,
    AchievementSummary? summary,
    GameProvider? Function()? providerFilter,
    IntegrationErrorKind? errorKind,
  }) {
    return AchievementsState(
      status: status ?? this.status,
      summary: summary ?? this.summary,
      providerFilter: providerFilter != null
          ? providerFilter()
          : this.providerFilter,
      errorKind: errorKind,
    );
  }

  @override
  List<Object?> get props => [status, summary, providerFilter, errorKind];
}

/// The achievements hub: summary, recent unlocks and the games list.
class AchievementsCubit extends Cubit<AchievementsState> {
  AchievementsCubit({required IntegrationsRepository repository})
    : _repository = repository,
      super(const AchievementsState());

  final IntegrationsRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(status: AchievementsStatus.loading));
    try {
      final summary = await _repository.getSummary();
      if (isClosed) return;
      emit(state.copyWith(status: AchievementsStatus.ready, summary: summary));
    } catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: AchievementsStatus.failure,
          errorKind: IntegrationErrorKind.from(e),
        ),
      );
    }
  }

  void filterProvider(GameProvider? provider) =>
      emit(state.copyWith(providerFilter: () => provider));
}
