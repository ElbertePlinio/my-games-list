import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:picklog/features/games/bloc/featured_banners_event.dart';
import 'package:picklog/features/games/bloc/featured_banners_state.dart';
import 'package:picklog/features/games/i_games_repository.dart';

class FeaturedBannersBloc
    extends Bloc<FeaturedBannersEvent, FeaturedBannersState> {
  FeaturedBannersBloc({required IGamesRepository gamesRepository})
    : _gamesRepository = gamesRepository,
      super(const FeaturedBannersState()) {
    on<FeaturedBannersLoadRequested>(_onLoadRequested);
    on<FeaturedBannersRefreshRequested>(_onRefreshRequested);
  }

  final IGamesRepository _gamesRepository;

  Future<void> _onLoadRequested(
    FeaturedBannersLoadRequested event,
    Emitter<FeaturedBannersState> emit,
  ) async {
    if (state.status == FeaturedBannersStatus.loading) return;

    emit(state.copyWith(status: FeaturedBannersStatus.loading));
    try {
      final banners = await _gamesRepository.getFeaturedBanners();
      emit(
        state.copyWith(status: FeaturedBannersStatus.success, banners: banners),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: FeaturedBannersStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onRefreshRequested(
    FeaturedBannersRefreshRequested event,
    Emitter<FeaturedBannersState> emit,
  ) async {
    try {
      final banners = await _gamesRepository.getFeaturedBanners();
      emit(
        state.copyWith(status: FeaturedBannersStatus.success, banners: banners),
      );
    } catch (e) {
      // Keep existing banners on refresh failure.
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }
}
