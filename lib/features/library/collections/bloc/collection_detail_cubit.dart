import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:picklog/core/domain/models/app_failure.dart';
import 'package:picklog/features/library/collections/collection_failure.dart';
import 'package:picklog/features/library/collections/user_collection_model.dart';
import 'package:picklog/features/library/collections/user_collections_repository.dart';
import 'package:picklog/features/library/library_entry_model.dart';

enum CollectionDetailStatus { initial, loading, success, failure }

class CollectionDetailState extends Equatable {
  const CollectionDetailState({
    this.status = CollectionDetailStatus.initial,
    this.detail,
    this.errorKind,
    this.notFound = false,
  });

  final CollectionDetailStatus status;
  final UserCollectionDetail? detail;
  final AppErrorKind? errorKind;

  /// The collection does not exist (or belongs to someone else).
  final bool notFound;

  List<LibraryEntry> get entries => detail?.entries ?? const [];

  @override
  List<Object?> get props => [status, detail, errorKind, notFound];
}

/// Loads one collection and its entries for the collection screen.
class CollectionDetailCubit extends Cubit<CollectionDetailState> {
  CollectionDetailCubit({
    required UserCollectionsRepository repository,
    required this.collectionId,
  }) : _repository = repository,
       super(const CollectionDetailState());

  final UserCollectionsRepository _repository;
  final String collectionId;

  Future<void> load() async {
    emit(
      CollectionDetailState(
        status: CollectionDetailStatus.loading,
        detail: state.detail,
      ),
    );
    try {
      final detail = await _repository.getCollection(collectionId);
      if (isClosed) return;
      emit(
        CollectionDetailState(
          status: CollectionDetailStatus.success,
          detail: detail,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      emit(
        CollectionDetailState(
          status: CollectionDetailStatus.failure,
          detail: state.detail,
          errorKind: AppErrorKind.from(e),
          notFound:
              CollectionErrorKind.fromError(e) ==
                  CollectionErrorKind.notFound ||
              AppErrorKind.from(e) == AppErrorKind.notFound,
        ),
      );
    }
  }

  /// Drops an entry after it was removed from the collection.
  void removeLocal(String libraryEntryId) {
    final detail = state.detail;
    if (detail == null) return;
    final entries = detail.entries
        .where((e) => e.id != libraryEntryId)
        .toList();
    emit(
      CollectionDetailState(
        status: state.status,
        detail: UserCollectionDetail(
          collection: detail.collection.copyWith(gameCount: entries.length),
          entries: entries,
        ),
      ),
    );
  }

  /// Applies a newer copy of a library entry (status or favorite changes).
  void patchEntries(List<LibraryEntry> library) {
    final detail = state.detail;
    if (detail == null || library.isEmpty) return;
    final byId = {for (final e in library) e.id: e};
    final patched = [for (final e in detail.entries) byId[e.id] ?? e];
    emit(
      CollectionDetailState(
        status: state.status,
        detail: UserCollectionDetail(
          collection: detail.collection,
          entries: patched,
        ),
        errorKind: state.errorKind,
      ),
    );
  }
}
