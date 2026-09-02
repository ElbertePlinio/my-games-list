import 'package:equatable/equatable.dart';
import 'package:picklog/features/games/collection_model.dart';

enum CollectionsStatus { initial, loading, success, failure }

class CollectionsState extends Equatable {
  const CollectionsState({
    this.status = CollectionsStatus.initial,
    this.collections = const [],
    this.errorMessage,
  });

  final CollectionsStatus status;
  final List<GameCollection> collections;
  final String? errorMessage;

  bool get isLoading => status == CollectionsStatus.loading;
  bool get hasCollections => collections.isNotEmpty;

  CollectionsState copyWith({
    CollectionsStatus? status,
    List<GameCollection>? collections,
    String? errorMessage,
  }) {
    return CollectionsState(
      status: status ?? this.status,
      collections: collections ?? this.collections,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, collections, errorMessage];
}
