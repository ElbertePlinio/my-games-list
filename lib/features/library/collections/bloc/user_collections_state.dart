import 'package:equatable/equatable.dart';
import 'package:picklog/features/library/collections/collection_failure.dart';
import 'package:picklog/features/library/collections/user_collection_model.dart';

enum UserCollectionsStatus { initial, loading, success, failure }

/// Result of one create, update, delete or membership request.
class CollectionMutation extends Equatable {
  const CollectionMutation({
    required this.requestId,
    required this.action,
    this.collection,
    this.failure,
  });

  final int requestId;
  final CollectionAction action;

  /// The created or updated collection on success.
  final UserCollection? collection;

  /// Set when the request failed.
  final CollectionFailure? failure;

  bool get succeeded => failure == null;

  @override
  List<Object?> get props => [requestId, action, collection, failure?.kind];
}

class UserCollectionsState extends Equatable {
  const UserCollectionsState({
    this.status = UserCollectionsStatus.initial,
    this.collections = const [],
    this.loadFailure,
    this.mutation,
    this.pendingRequests = const {},
  });

  final UserCollectionsStatus status;
  final List<UserCollection> collections;
  final CollectionFailure? loadFailure;

  /// The latest finished mutation. Widgets match it by request id.
  final CollectionMutation? mutation;

  /// Request ids still in flight.
  final Set<int> pendingRequests;

  bool get isLoading => status == UserCollectionsStatus.loading;
  bool get hasCollections => collections.isNotEmpty;
  bool get atLimit => collections.length >= UserCollection.maxPerUser;

  bool isPending(int requestId) => pendingRequests.contains(requestId);

  UserCollection? byId(String id) {
    for (final c in collections) {
      if (c.id == id) return c;
    }
    return null;
  }

  UserCollectionsState copyWith({
    UserCollectionsStatus? status,
    List<UserCollection>? collections,
    CollectionFailure? loadFailure,
    bool clearLoadFailure = false,
    CollectionMutation? mutation,
    Set<int>? pendingRequests,
  }) {
    return UserCollectionsState(
      status: status ?? this.status,
      collections: collections ?? this.collections,
      loadFailure: clearLoadFailure ? null : (loadFailure ?? this.loadFailure),
      mutation: mutation ?? this.mutation,
      pendingRequests: pendingRequests ?? this.pendingRequests,
    );
  }

  @override
  List<Object?> get props => [
    status,
    collections,
    loadFailure?.kind,
    loadFailure?.appKind,
    mutation,
    pendingRequests,
  ];
}
