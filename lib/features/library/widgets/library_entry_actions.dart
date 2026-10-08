import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:picklog/core/utils/l10n_extensions.dart';
import 'package:picklog/core/utils/service_locator.dart';
import 'package:picklog/features/games/game_detail_model.dart';
import 'package:picklog/features/games/i_games_repository.dart';
import 'package:picklog/features/library/bloc/library_bloc.dart';
import 'package:picklog/features/library/bloc/library_event.dart';
import 'package:picklog/features/library/collections/bloc/user_collections_bloc.dart';
import 'package:picklog/features/library/collections/widgets/collection_picker_sheet.dart';
import 'package:picklog/features/library/library_entry_model.dart';
import 'package:picklog/features/library/widgets/add_to_library_bottom_sheet.dart';
import 'package:picklog/features/library/widgets/status_picker_sheet.dart';
import 'package:picklog/features/library/widgets/undo_snackbar.dart';

/// Quick library actions shared by list rows, grid cards and swipes. All go
/// through the shared LibraryBloc so every screen sees the change.
abstract final class LibraryEntryActions {
  /// Toggles the favorite flag and offers an undo.
  static void toggleFavorite(BuildContext context, LibraryEntry entry) {
    final bloc = context.read<LibraryBloc>();
    final l10n = context.l10n;
    bloc.add(LibraryToggleFavoriteRequested(entryId: entry.id));
    showUndoSnackBar(
      context,
      message: entry.isFavorite
          ? l10n.libraryUnfavorited(entry.game.name)
          : l10n.libraryFavorited(entry.game.name),
      onUndo: () => bloc.add(LibraryToggleFavoriteRequested(entryId: entry.id)),
    );
  }

  /// Asks for a status, saves it and offers an undo.
  static Future<void> changeStatus(
    BuildContext context,
    LibraryEntry entry,
  ) async {
    final next = await showStatusPickerSheet(
      context,
      current: entry.status,
      gameName: entry.game.name,
    );
    if (next == null || next == entry.status || !context.mounted) return;
    if (_editsOnStatus.contains(next)) {
      // The sheet saves the status with the details. Closing it without
      // saving still applies the status.
      final saved = await editEntry(context, entry, initialStatus: next);
      if (saved == true || !context.mounted) return;
    }
    setStatus(context, entry, next);
  }

  /// Statuses that open the edit sheet, so the user can add a score, an end
  /// date or a note while the game is fresh.
  static const _editsOnStatus = {GameStatus.finished, GameStatus.dropped};

  /// Opens the edit sheet for [entry]. Returns true when it saved or removed
  /// the entry.
  static Future<bool?> editEntry(
    BuildContext context,
    LibraryEntry entry, {
    GameStatus? initialStatus,
  }) {
    final library = context.read<LibraryBloc>();
    UserCollectionsBloc? collections;
    try {
      collections = context.read<UserCollectionsBloc>();
    } on ProviderNotFoundException {
      collections = null;
    }
    final platform = entry.platform;
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: false,
      builder: (_) => BlocProvider.value(
        value: library,
        child: AddToLibraryBottomSheet(
          gameId: entry.game.igdbId,
          gameName: entry.game.name,
          platforms: [
            if (platform != null)
              Platform(id: platform.igdbPlatformId, name: platform.name),
          ],
          loadPlatforms: sl.isRegistered<IGamesRepository>()
              ? () async => (await sl<IGamesRepository>().getGameDetails(
                  entry.game.igdbId,
                )).platforms
              : null,
          existingEntry: entry,
          initialStatus: initialStatus,
          collectionsBloc: collections,
        ),
      ),
    );
  }

  /// Saves [status] for [entry] and offers an undo.
  static void setStatus(
    BuildContext context,
    LibraryEntry entry,
    GameStatus status,
  ) {
    final bloc = context.read<LibraryBloc>();
    final previous = entry.status;
    bloc.add(LibraryUpdateEntryRequested(entry: entry, status: status));
    showUndoSnackBar(
      context,
      message: context.l10n.libraryStatusChanged(
        entry.game.name,
        status.localizedName(context),
      ),
      onUndo: () =>
          bloc.add(LibraryUpdateEntryRequested(entry: entry, status: previous)),
    );
  }

  /// Opens the collection picker for [entry].
  static Future<void> editCollections(
    BuildContext context,
    LibraryEntry entry,
  ) {
    return CollectionPickerSheet.show(
      context,
      entry: entry,
      collectionsBloc: context.read<UserCollectionsBloc>(),
      libraryBloc: context.read<LibraryBloc>(),
    );
  }
}

/// Row and card overflow menu items.
enum LibraryEntryMenuAction { edit, changeStatus, collections, favorite }

/// Overflow menu for one entry.
class LibraryEntryMenuButton extends StatelessWidget {
  const LibraryEntryMenuButton({
    required this.entry,
    this.color,
    this.includeFavorite = false,
    this.includeEdit = false,
    this.iconSize,
    super.key,
  });

  final LibraryEntry entry;
  final Color? color;
  final double? iconSize;
  final bool includeFavorite;
  final bool includeEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return PopupMenuButton<LibraryEntryMenuAction>(
      tooltip: l10n.libraryEntryActions,
      iconSize: iconSize,
      padding: iconSize == null ? const EdgeInsets.all(8) : EdgeInsets.zero,
      icon: Icon(Icons.more_vert, color: color),
      onSelected: (action) {
        switch (action) {
          case LibraryEntryMenuAction.edit:
            LibraryEntryActions.editEntry(context, entry);
          case LibraryEntryMenuAction.changeStatus:
            LibraryEntryActions.changeStatus(context, entry);
          case LibraryEntryMenuAction.collections:
            LibraryEntryActions.editCollections(context, entry);
          case LibraryEntryMenuAction.favorite:
            LibraryEntryActions.toggleFavorite(context, entry);
        }
      },
      itemBuilder: (context) => [
        if (includeEdit)
          PopupMenuItem(
            value: LibraryEntryMenuAction.edit,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.edit_outlined),
              title: Text(l10n.editEntry),
            ),
          ),
        PopupMenuItem(
          value: LibraryEntryMenuAction.changeStatus,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.swap_horiz),
            title: Text(l10n.libraryChangeStatus),
          ),
        ),
        PopupMenuItem(
          value: LibraryEntryMenuAction.collections,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.collections_bookmark_outlined),
            title: Text(l10n.collectionPickerTitle),
          ),
        ),
        if (includeFavorite)
          PopupMenuItem(
            value: LibraryEntryMenuAction.favorite,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                entry.isFavorite ? Icons.favorite : Icons.favorite_border,
              ),
              title: Text(
                entry.isFavorite ? l10n.favorited : l10n.addToFavorites,
              ),
            ),
          ),
      ],
    );
  }
}
