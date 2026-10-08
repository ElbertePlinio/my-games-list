import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:picklog/core/domain/models/app_failure.dart';
import 'package:picklog/core/theme/pf_tokens.dart';
import 'package:picklog/core/theme/pf_typography.dart';
import 'package:picklog/core/theme/picklog_colors.dart';
import 'package:picklog/core/utils/app_router.dart';
import 'package:picklog/core/utils/error_l10n.dart';
import 'package:picklog/core/utils/l10n_extensions.dart';
import 'package:picklog/core/utils/messages_extensions.dart';
import 'package:picklog/core/widgets/animated_state_switcher.dart';
import 'package:picklog/core/widgets/app_scaffold.dart';
import 'package:picklog/core/widgets/game_card.dart';
import 'package:picklog/core/widgets/section_header.dart';
import 'package:picklog/core/widgets/staggered_reveal.dart';
import 'package:picklog/core/widgets/state_views.dart';
import 'package:picklog/features/games/widgets/discovery_game_tile.dart';
import 'package:picklog/features/games/widgets/skeletons/library_entry_skeleton.dart';
import 'package:picklog/features/library/bloc/library_bloc.dart';
import 'package:picklog/features/library/bloc/library_event.dart';
import 'package:picklog/features/library/bloc/library_state.dart';
import 'package:picklog/features/library/collections/bloc/collection_detail_cubit.dart';
import 'package:picklog/features/library/collections/bloc/user_collections_bloc.dart';
import 'package:picklog/features/library/collections/bloc/user_collections_event.dart';
import 'package:picklog/features/library/collections/bloc/user_collections_state.dart';
import 'package:picklog/features/library/collections/user_collection_model.dart';
import 'package:picklog/features/library/collections/widgets/collection_form_dialog.dart';
import 'package:picklog/features/library/collections/widgets/collection_mosaic.dart';
import 'package:picklog/features/library/library_entry_model.dart';
import 'package:picklog/features/library/widgets/library_status_pill.dart';
import 'package:picklog/features/library/widgets/undo_snackbar.dart';

/// Hero prefix for covers on the collection screen.
const String kCollectionHeroPrefix = 'collection-';

enum _DetailMenu { edit, delete }

/// One collection: mosaic header, description and its games. The menu edits
/// or deletes it; each row can leave the collection.
class CollectionDetailScreen extends StatelessWidget {
  const CollectionDetailScreen({required this.collectionId, super.key});

  final String collectionId;

  UserCollection? _collection(BuildContext context) {
    final fromList = context.watch<UserCollectionsBloc>().state.byId(
      collectionId,
    );
    return fromList ??
        context.watch<CollectionDetailCubit>().state.detail?.collection;
  }

  Future<void> _onMenu(
    BuildContext context,
    _DetailMenu action,
    UserCollection collection,
  ) async {
    final bloc = context.read<UserCollectionsBloc>();
    switch (action) {
      case _DetailMenu.edit:
        await showCollectionFormDialog(
          context,
          bloc: bloc,
          existing: collection,
        );
      case _DetailMenu.delete:
        final library = context.read<LibraryBloc>();
        final l10n = context.l10n;
        final deleted = await confirmDeleteCollection(
          context,
          bloc: bloc,
          collection: collection,
        );
        if (!context.mounted) return;
        if (deleted) {
          library.add(LibraryCollectionRemoved(collectionId: collection.id));
          context.showSuccessMessage(l10n.collectionDeleted);
          if (context.canPop()) {
            context.pop();
          } else {
            context.goNamed(AppRouter.gamesName);
          }
        } else if (bloc.state.mutation?.failure != null) {
          context.showErrorMessage(
            bloc.state.mutation!.failure!.message(context),
          );
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final collection = _collection(context);

    return MultiBlocListener(
      listeners: [
        // Status and favorite changes made elsewhere show here too.
        BlocListener<LibraryBloc, LibraryState>(
          listenWhen: (p, c) => p.entries != c.entries,
          listener: (context, state) =>
              context.read<CollectionDetailCubit>().patchEntries(state.entries),
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: Text(collection?.name ?? l10n.librarySegmentCollections),
          actions: [
            if (collection != null)
              PopupMenuButton<_DetailMenu>(
                key: const Key('collection_detail_menu'),
                tooltip: l10n.collectionActions,
                onSelected: (a) => _onMenu(context, a, collection),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: _DetailMenu.edit,
                    child: Text(l10n.collectionEditTitle),
                  ),
                  PopupMenuItem(
                    value: _DetailMenu.delete,
                    child: Text(l10n.collectionDeleteAction),
                  ),
                ],
              ),
            const SizedBox(width: PfSpace.xs),
          ],
        ),
        body: BlocBuilder<CollectionDetailCubit, CollectionDetailState>(
          builder: (context, state) {
            final Object key;
            final Widget child;
            if (state.detail == null &&
                (state.status == CollectionDetailStatus.loading ||
                    state.status == CollectionDetailStatus.initial)) {
              key = 'loading';
              child = const LibraryListSkeleton(itemCount: 6);
            } else if (state.detail == null) {
              key = 'error';
              child = state.notFound
                  ? EmptyState(
                      icon: Icons.collections_bookmark_outlined,
                      title: l10n.collectionErrorNotFound,
                    )
                  : ErrorState(
                      message: (state.errorKind ?? AppErrorKind.unknown)
                          .message(context),
                      onRetry: () =>
                          context.read<CollectionDetailCubit>().load(),
                    );
            } else {
              key = 'content';
              child = _CollectionContent(
                collection: collection ?? state.detail!.collection,
                entries: state.entries,
              );
            }
            return AnimatedStateSwitcher(
              stateKey: key,
              child: MaxWidthBox(child: child),
            );
          },
        ),
      ),
    );
  }
}

class _CollectionContent extends StatelessWidget {
  const _CollectionContent({required this.collection, required this.entries});

  final UserCollection collection;
  final List<LibraryEntry> entries;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = context.pfColors;
    final wide = MediaQuery.sizeOf(context).width >= PfBreakpoints.twoPane;

    return RefreshIndicator(
      onRefresh: () async {
        context.read<UserCollectionsBloc>().add(
          const UserCollectionsLoadRequested(),
        );
        await context.read<CollectionDetailCubit>().load();
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: _CollectionHeader(
              collection: collection,
              entries: entries,
              wide: wide,
            ),
          ),
          if ((collection.description ?? '').isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  PfSpace.lg,
                  0,
                  PfSpace.lg,
                  PfSpace.lg,
                ),
                child: Text(
                  collection.description!,
                  style: theme.textTheme.bodyLarge!.copyWith(
                    color: colors.textMed,
                  ),
                ),
              ),
            ),
          if (entries.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                icon: Icons.playlist_add,
                title: l10n.collectionEmptyTitle,
                message: l10n.collectionEmptyHint,
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                PfSpace.lg,
                0,
                PfSpace.lg,
                PfSpace.xxl,
              ),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: wide ? 560 : 800,
                  mainAxisExtent: 100,
                  crossAxisSpacing: PfSpace.md,
                  mainAxisSpacing: PfSpace.sm,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => StaggeredReveal(
                    index: index,
                    child: _CollectionEntryRow(
                      collection: collection,
                      entry: entries[index],
                    ),
                  ),
                  childCount: entries.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Cover mosaic, name and game count.
class _CollectionHeader extends StatelessWidget {
  const _CollectionHeader({
    required this.collection,
    required this.entries,
    required this.wide,
  });

  final UserCollection collection;
  final List<LibraryEntry> entries;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = context.pfColors;
    final mosaicSize = wide ? 200.0 : 132.0;
    final covers = collection.coverUrls.isNotEmpty
        ? collection.coverUrls
        : [
            for (final e in entries.take(4))
              if (e.game.coverUrl != null) e.game.coverUrl!,
          ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        PfSpace.lg,
        PfSpace.sm,
        PfSpace.lg,
        PfSpace.lg,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          SizedBox.square(
            dimension: mosaicSize,
            child: CollectionMosaic(
              coverUrls: covers,
              borderRadius: PfRadius.card,
            ),
          ),
          const SizedBox(width: PfSpace.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Eyebrow(l10n.collectionEyebrow),
                const SizedBox(height: PfSpace.xs),
                Text(
                  collection.name,
                  style: theme.textTheme.headlineMedium,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: PfSpace.xs),
                Text(
                  l10n.collectionGameCount(entries.length),
                  style: PfTypography.monoStyle(colors.textMed),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CollectionEntryRow extends StatefulWidget {
  const _CollectionEntryRow({required this.collection, required this.entry});

  final UserCollection collection;
  final LibraryEntry entry;

  @override
  State<_CollectionEntryRow> createState() => _CollectionEntryRowState();
}

class _CollectionEntryRowState extends State<_CollectionEntryRow> {
  int? _requestId;

  void _remove() {
    final bloc = context.read<UserCollectionsBloc>();
    final requestId = UserCollectionsBloc.newRequestId();
    setState(() => _requestId = requestId);
    bloc.add(
      UserCollectionEntryToggled(
        requestId: requestId,
        collectionId: widget.collection.id,
        libraryEntryId: widget.entry.id,
        add: false,
      ),
    );
  }

  void _onResult(BuildContext context, UserCollectionsState state) {
    final mutation = state.mutation!;
    final entry = widget.entry;
    final collection = widget.collection;
    setState(() => _requestId = null);
    if (!mutation.succeeded) {
      context.showErrorMessage(mutation.failure!.message(context));
      return;
    }
    final ids = entry.collectionIds.where((id) => id != collection.id).toList();
    final library = context.read<LibraryBloc>()
      ..add(
        LibraryEntryCollectionsChanged(entryId: entry.id, collectionIds: ids),
      );
    final bloc = context.read<UserCollectionsBloc>();
    final detail = context.read<CollectionDetailCubit>();
    detail.removeLocal(entry.id);
    showUndoSnackBar(
      context,
      message: context.l10n.collectionEntryRemoved(entry.game.name),
      onUndo: () {
        final undoId = UserCollectionsBloc.newRequestId();
        bloc.add(
          UserCollectionEntryToggled(
            requestId: undoId,
            collectionId: collection.id,
            libraryEntryId: entry.id,
            add: true,
          ),
        );
        // Reload once the server confirms so the entry returns to its place.
        bloc.stream.firstWhere((s) => s.mutation?.requestId == undoId).then((
          s,
        ) {
          if (s.mutation!.succeeded) {
            library.add(
              LibraryEntryCollectionsChanged(
                entryId: entry.id,
                collectionIds: [...ids, collection.id],
              ),
            );
            detail.load();
          }
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final entry = widget.entry;
    return BlocListener<UserCollectionsBloc, UserCollectionsState>(
      listenWhen: (p, c) =>
          _requestId != null &&
          p.mutation != c.mutation &&
          c.mutation?.requestId == _requestId,
      listener: _onResult,
      child: GameTile(
        title: entry.game.name,
        coverUrl: entry.game.coverUrl,
        heroTag: gameCoverHeroTag(kCollectionHeroPrefix, entry.game.igdbId),
        semanticLabel: l10n.libraryEntryLabel(
          entry.game.name,
          entry.status.localizedName(context),
        ),
        meta: [LibraryStatusPill(status: entry.status, dense: true)],
        onTap: () => openGameDetails(
          context,
          entry.game.igdbId,
          heroPrefix: kCollectionHeroPrefix,
        ),
        trailing: _requestId != null
            ? const Padding(
                padding: EdgeInsets.all(PfSpace.md),
                child: SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : IconButton(
                key: ValueKey('collection_remove_${entry.id}'),
                icon: const Icon(Icons.remove_circle_outline),
                tooltip: l10n.collectionRemoveEntry,
                onPressed: _remove,
              ),
      ),
    );
  }
}
