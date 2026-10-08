import 'package:flutter/widgets.dart';
import 'package:picklog/core/domain/models/app_failure.dart';
import 'package:picklog/core/utils/error_l10n.dart';
import 'package:picklog/core/utils/l10n_extensions.dart';

/// Why a collection request failed. Collection-specific API error codes get
/// their own kind; everything else falls back to [AppErrorKind].
enum CollectionErrorKind {
  duplicateName,
  limitReached,
  entriesLimitReached,
  nameInvalid,
  descriptionTooLong,
  notFound,
  other;

  static const _byCode = {
    'error.collection.duplicate_name': CollectionErrorKind.duplicateName,
    'error.collection.limit_reached': CollectionErrorKind.limitReached,
    'error.collection.entries_limit_reached':
        CollectionErrorKind.entriesLimitReached,
    'error.validation.collection.name.invalid': CollectionErrorKind.nameInvalid,
    'error.validation.collection.description.too_long':
        CollectionErrorKind.descriptionTooLong,
    'error.collection.not_found': CollectionErrorKind.notFound,
  };

  static CollectionErrorKind fromError(Object error) {
    final code = error is ApiException ? error.error?.errorCode : null;
    return _byCode[code] ?? CollectionErrorKind.other;
  }
}

/// Which collection action failed.
enum CollectionAction { load, create, update, delete, addEntry, removeEntry }

/// One-shot failure report for the collections UI.
class CollectionFailure {
  CollectionFailure(this.action, Object error)
    : kind = CollectionErrorKind.fromError(error),
      appKind = AppErrorKind.from(error);

  const CollectionFailure.of(this.action, this.kind, this.appKind);

  final CollectionAction action;
  final CollectionErrorKind kind;
  final AppErrorKind appKind;

  /// Localized message for the failure.
  String message(BuildContext context) {
    final l10n = context.l10n;
    return switch (kind) {
      CollectionErrorKind.duplicateName => l10n.collectionErrorDuplicateName,
      CollectionErrorKind.limitReached => l10n.collectionErrorLimit,
      CollectionErrorKind.entriesLimitReached =>
        l10n.collectionErrorEntriesLimit,
      CollectionErrorKind.nameInvalid => l10n.collectionErrorNameInvalid,
      CollectionErrorKind.descriptionTooLong =>
        l10n.collectionErrorDescriptionTooLong,
      CollectionErrorKind.notFound => l10n.collectionErrorNotFound,
      CollectionErrorKind.other => appKind.message(context),
    };
  }
}
