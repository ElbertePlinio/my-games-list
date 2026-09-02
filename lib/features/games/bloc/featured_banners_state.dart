import 'package:equatable/equatable.dart';
import 'package:picklog/features/games/featured_banner_model.dart';

enum FeaturedBannersStatus { initial, loading, success, failure }

class FeaturedBannersState extends Equatable {
  const FeaturedBannersState({
    this.status = FeaturedBannersStatus.initial,
    this.banners = const [],
    this.errorMessage,
  });

  final FeaturedBannersStatus status;
  final List<FeaturedBanner> banners;
  final String? errorMessage;

  bool get isLoading => status == FeaturedBannersStatus.loading;
  bool get hasBanners => banners.isNotEmpty;

  FeaturedBannersState copyWith({
    FeaturedBannersStatus? status,
    List<FeaturedBanner>? banners,
    String? errorMessage,
  }) {
    return FeaturedBannersState(
      status: status ?? this.status,
      banners: banners ?? this.banners,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, banners, errorMessage];
}
