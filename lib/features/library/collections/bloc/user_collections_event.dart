import 'package:equatable/equatable.dart';

abstract class UserCollectionsEvent extends Equatable {
  const UserCollectionsEvent();

  @override
  List<Object?> get props => [];
}

/// Loads the collection list. A reload keeps the shown list until it lands.
class UserCollectionsLoadRequested extends UserCollectionsEvent {
  const UserCollectionsLoadRequested();
}

/// Base for events whose result a widget waits for through [requestId].
abstract class UserCollectionsMutationEvent extends UserCollectionsEvent {
  const UserCollectionsMutationEvent(this.requestId);

  /// Echoed in [CollectionMutation.requestId] so the caller can find its result.
  final int requestId;
}

/// Creates a collection, and adds [addEntryId] to it when set.
class UserCollectionCreateRequested extends UserCollectionsMutationEvent {
  const UserCollectionCreateRequested({
    required int requestId,
    required this.name,
    this.description,
    this.addEntryId,
  }) : super(requestId);

  final String name;
  final String? description;
  final String? addEntryId;

  @override
  List<Object?> get props => [requestId, name, description, addEntryId];
}

/// Renames a collection or edits its description. An empty description
/// clears it.
class UserCollectionUpdateRequested extends UserCollectionsMutationEvent {
  const UserCollectionUpdateRequested({
    required int requestId,
    required this.collectionId,
    this.name,
    this.description,
  }) : super(requestId);

  final String collectionId;
  final String? name;
  final String? description;

  @override
  List<Object?> get props => [requestId, collectionId, name, description];
}

class UserCollectionDeleteRequested extends UserCollectionsMutationEvent {
  const UserCollectionDeleteRequested({
    required int requestId,
    required this.collectionId,
  }) : super(requestId);

  final String collectionId;

  @override
  List<Object?> get props => [requestId, collectionId];
}

/// Adds ([add] true) or removes a library entry from a collection.
class UserCollectionEntryToggled extends UserCollectionsMutationEvent {
  const UserCollectionEntryToggled({
    required int requestId,
    required this.collectionId,
    required this.libraryEntryId,
    required this.add,
  }) : super(requestId);

  final String collectionId;
  final String libraryEntryId;
  final bool add;

  @override
  List<Object?> get props => [requestId, collectionId, libraryEntryId, add];
}
