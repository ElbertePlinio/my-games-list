import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:picklog/features/integrations/integrations_models.dart';
import 'package:picklog/features/integrations/integrations_repository.dart';

enum AchievementGameStatus { initial, loading, ready, failure }

class AchievementGameState extends Equatable {
  const AchievementGameState({
    this.status = AchievementGameStatus.initial,
    this.game,
    this.errorKind,
  });

  final AchievementGameStatus status;
  final GameAchievements? game;
  final IntegrationErrorKind? errorKind;

  @override
  List<Object?> get props => [status, game, errorKind];
}

/// One game's full achievement list for the per-game screen.
class AchievementGameCubit extends Cubit<AchievementGameState> {
  AchievementGameCubit({
    required IntegrationsRepository repository,
    required this.provider,
    required this.externalGameId,
  }) : _repository = repository,
       super(const AchievementGameState());

  final IntegrationsRepository _repository;
  final GameProvider provider;
  final String externalGameId;

  Future<void> load() async {
    emit(
      AchievementGameState(
        status: AchievementGameStatus.loading,
        game: state.game,
      ),
    );
    try {
      final game = await _repository.getGameAchievements(
        provider,
        externalGameId,
      );
      if (isClosed) return;
      emit(
        AchievementGameState(status: AchievementGameStatus.ready, game: game),
      );
    } catch (e) {
      if (isClosed) return;
      emit(
        AchievementGameState(
          status: AchievementGameStatus.failure,
          errorKind: IntegrationErrorKind.from(e),
        ),
      );
    }
  }
}

class GameAchievementsState extends Equatable {
  const GameAchievementsState({this.loaded = false, this.games = const []});

  /// True once the request finished. Failures count as loaded with no data.
  final bool loaded;
  final List<GameAchievements> games;

  bool get hasData => games.any((g) => g.game.total > 0);

  @override
  List<Object?> get props => [loaded, games];
}

/// Achievement data for one IGDB game, shown inside game details. It stays
/// quiet on errors: the section simply does not appear.
class GameAchievementsCubit extends Cubit<GameAchievementsState> {
  GameAchievementsCubit({required IntegrationsRepository repository})
    : _repository = repository,
      super(const GameAchievementsState());

  final IntegrationsRepository _repository;

  Future<void> load(int igdbId) async {
    try {
      final games = await _repository.getAchievementsForGame(igdbId);
      if (isClosed) return;
      emit(GameAchievementsState(loaded: true, games: games));
    } catch (_) {
      if (isClosed) return;
      emit(const GameAchievementsState(loaded: true));
    }
  }
}
