import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:picklog/features/library/collections/bloc/user_collections_event.dart';
import 'package:picklog/features/library/collections/bloc/user_collections_state.dart';
import 'package:picklog/features/library/collections/collection_failure.dart';
import 'package:picklog/features/library/collections/user_collection_model.dart';
import 'package:picklog/features/library/collections/user_collections_repository.dart';

/// The caller's collections. A shared lazy singleton (like LibraryBloc) so the
/// Library tab, the collection screen and the picker sheet stay in sync. The
/// session teardown resets it.
class UserCollectionsBloc
    extends Bloc<UserCollectionsEvent, UserCollectionsState> {
  UserCollectionsBloc({required UserCollectionsRepository repository})
    : _repository = repository,
      super(const UserCollectionsState()) {
    on<UserCollectionsLoadRequested>(_onLoad);
    on<UserCollectionCreateRequested>(_onCreate);
    on<UserCollectionUpdateRequested>(_onUpdate);
    on<UserCollectionDeleteRequested>(_onDelete);
    on<UserCollectionEntryToggled>(_onEntryToggled);
  }

  final UserCollectionsRepository _repository;
  static int _nextRequestId = 0;

  /// A fresh id for a mutation event.
  static int newRequestId() => ++_nextRequestId;

  Future<void> _onLoad(
    UserCollectionsLoadRequested event,
    Emitter<UserCollectionsState> emit,
  ) async {
    emit(state.copyWith(status: UserCollectionsStatus.loading));
    try {
      final collections = await _repository.getCollections();
      emit(
        state.copyWith(
          status: UserCollectionsStatus.success,
          collections: collections,
          clearLoadFailure: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: UserCollectionsStatus.failure,
          loadFailure: CollectionFailure(CollectionAction.load, e),
        ),
      );
    }
  }

  Set<int> _with(int id) => {...state.pendingRequests, id};
  Set<int> _without(int id) => {...state.pendingRequests}..remove(id);

  /// Moves [collection] to the top (the API orders by `updated_at desc`).
  List<UserCollection> _upsertFirst(UserCollection collection) => [
    collection,
    ...state.collections.where((c) => c.id != collection.id),
  ];

  Future<void> _onCreate(
    UserCollectionCreateRequested event,
    Emitter<UserCollectionsState> emit,
  ) async {
    emit(state.copyWith(pendingRequests: _with(event.requestId)));
    try {
      var created = await _repository.createCollection(
        name: event.name.trim(),
        description: event.description?.trim(),
      );
      final entryId = event.addEntryId;
      if (entryId != null) {
        created = await _repository.addEntry(created.id, entryId);
      }
      emit(
        state.copyWith(
          status: UserCollectionsStatus.success,
          collections: _upsertFirst(created),
          pendingRequests: _without(event.requestId),
          mutation: CollectionMutation(
            requestId: event.requestId,
            action: CollectionAction.create,
            collection: created,
          ),
        ),
      );
    } catch (e) {
      _emitFailure(emit, event.requestId, CollectionAction.create, e);
    }
  }

  Future<void> _onUpdate(
    UserCollectionUpdateRequested event,
    Emitter<UserCollectionsState> emit,
  ) async {
    emit(state.copyWith(pendingRequests: _with(event.requestId)));
    try {
      final updated = await _repository.updateCollection(
        event.collectionId,
        name: event.name?.trim(),
        description: event.description?.trim(),
      );
      emit(
        state.copyWith(
          collections: _upsertFirst(updated),
          pendingRequests: _without(event.requestId),
          mutation: CollectionMutation(
            requestId: event.requestId,
            action: CollectionAction.update,
            collection: updated,
          ),
        ),
      );
    } catch (e) {
      _emitFailure(emit, event.requestId, CollectionAction.update, e);
    }
  }

  Future<void> _onDelete(
    UserCollectionDeleteRequested event,
    Emitter<UserCollectionsState> emit,
  ) async {
    emit(state.copyWith(pendingRequests: _with(event.requestId)));
    try {
      await _repository.deleteCollection(event.collectionId);
      emit(
        state.copyWith(
          collections: state.collections
              .where((c) => c.id != event.collectionId)
              .toList(),
          pendingRequests: _without(event.requestId),
          mutation: CollectionMutation(
            requestId: event.requestId,
            action: CollectionAction.delete,
          ),
        ),
      );
    } catch (e) {
      _emitFailure(emit, event.requestId, CollectionAction.delete, e);
    }
  }

  Future<void> _onEntryToggled(
    UserCollectionEntryToggled event,
    Emitter<UserCollectionsState> emit,
  ) async {
    emit(state.copyWith(pendingRequests: _with(event.requestId)));
    final action = event.add
        ? CollectionAction.addEntry
        : CollectionAction.removeEntry;
    try {
      UserCollection? updated;
      if (event.add) {
        updated = await _repository.addEntry(
          event.collectionId,
          event.libraryEntryId,
        );
      } else {
        await _repository.removeEntry(event.collectionId, event.libraryEntryId);
        // The remove response has no body; refresh the list so the count and
        // cover mosaic stay right.
        try {
          final collections = await _repository.getCollections();
          emit(state.copyWith(collections: collections));
        } catch (_) {
          final current = state.byId(event.collectionId);
          if (current != null) {
            updated = current.copyWith(
              gameCount: current.gameCount > 0 ? current.gameCount - 1 : 0,
            );
          }
        }
      }
      emit(
        state.copyWith(
          collections: updated == null ? null : _upsertFirst(updated),
          pendingRequests: _without(event.requestId),
          mutation: CollectionMutation(
            requestId: event.requestId,
            action: action,
            collection: updated ?? state.byId(event.collectionId),
          ),
        ),
      );
    } catch (e) {
      _emitFailure(emit, event.requestId, action, e);
    }
  }

  void _emitFailure(
    Emitter<UserCollectionsState> emit,
    int requestId,
    CollectionAction action,
    Object error,
  ) {
    emit(
      state.copyWith(
        pendingRequests: _without(requestId),
        mutation: CollectionMutation(
          requestId: requestId,
          action: action,
          failure: CollectionFailure(action, error),
        ),
      ),
    );
  }
}
