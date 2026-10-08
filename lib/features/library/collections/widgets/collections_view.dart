import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:picklog/core/theme/pf_tokens.dart';
import 'package:picklog/core/theme/pf_typography.dart';
import 'package:picklog/core/theme/picklog_colors.dart';
import 'package:picklog/core/utils/app_router.dart';
import 'package:picklog/core/utils/l10n_extensions.dart';
import 'package:picklog/core/utils/messages_extensions.dart';
import 'package:picklog/core/widgets/press_scale.dart';
import 'package:picklog/core/widgets/skeleton_box.dart';
import 'package:picklog/core/widgets/staggered_reveal.dart';
import 'package:picklog/core/widgets/state_views.dart';
import 'package:picklog/features/library/bloc/library_bloc.dart';
import 'package:picklog/features/library/bloc/library_event.dart';
import 'package:picklog/features/library/collections/bloc/user_collections_bloc.dart';
import 'package:picklog/features/library/collections/bloc/user_collections_event.dart';
import 'package:picklog/features/library/collections/bloc/user_collections_state.dart';
import 'package:picklog/features/library/collections/user_collection_model.dart';
import 'package:picklog/features/library/collections/widgets/collection_form_dialog.dart';
import 'package:picklog/features/library/collections/widgets/collection_mosaic.dart';

/// Opens the collection screen.
void openCollection(BuildContext context, UserCollection collection) {
  context.pushNamed(
    AppRouter.collectionDetailName,
    pathParameters: {'id': collection.id},
  );
}

/// Column count for the collections grid.
int collectionColumnsFor(double width) {
  if (width >= PfBreakpoints.expanded) return 5;
  if (width >= 900) return 4;
  if (width >= PfBreakpoints.compact) return 3;
  return 2;
}

/// Grid of the user's collections with create, edit and delete.
class CollectionsView extends StatelessWidget {
  const CollectionsView({this.onCreate, super.key});

  /// Opens the create dialog. Shown in the empty state.
  final VoidCallback? onCreate;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserCollectionsBloc, UserCollectionsState>(
      builder: (context, state) {
        final bloc = context.read<UserCollectionsBloc>();
        if ((state.isLoading ||
                state.status == UserCollectionsStatus.initial) &&
            !state.hasCollections) {
          return const _CollectionsGridSkeleton();
        }
        if (state.loadFailure != null && !state.hasCollections) {
          return ErrorState(
            message: state.loadFailure!.message(context),
            onRetry: () => bloc.add(const UserCollectionsLoadRequested()),
          );
        }
        if (!state.hasCollections) {
          return EmptyState(
            icon: Icons.collections_bookmark_outlined,
            title: context.l10n.collectionsEmptyTitle,
            message: context.l10n.collectionsEmptyHint,
            action: onCreate == null
                ? null
                : FilledButton.icon(
                    onPressed: onCreate,
                    icon: const Icon(Icons.add),
                    label: Text(context.l10n.collectionNewTitle),
                  ),
          );
        }
        return RefreshIndicator(
          onRefresh: () async {
            bloc.add(const UserCollectionsLoadRequested());
            await bloc.stream.firstWhere((s) => !s.isLoading);
          },
          child: LayoutBuilder(
            builder: (context, constraints) => GridView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                PfSpace.lg,
                PfSpace.sm,
                PfSpace.lg,
                96,
              ),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: collectionColumnsFor(constraints.maxWidth),
                mainAxisSpacing: PfSpace.lg,
                crossAxisSpacing: PfSpace.md,
                childAspectRatio: 0.78,
              ),
              itemCount: state.collections.length,
              itemBuilder: (context, index) => StaggeredReveal(
                index: index,
                child: CollectionCard(collection: state.collections[index]),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Mosaic card for one collection with an edit and delete menu.
class CollectionCard extends StatelessWidget {
  const CollectionCard({required this.collection, super.key});

  final UserCollection collection;

  Future<void> _onMenu(BuildContext context, _CollectionMenu action) async {
    final bloc = context.read<UserCollectionsBloc>();
    switch (action) {
      case _CollectionMenu.edit:
        await showCollectionFormDialog(
          context,
          bloc: bloc,
          existing: collection,
        );
      case _CollectionMenu.delete:
        final libraryBloc = context.read<LibraryBloc?>();
        final l10n = context.l10n;
        final deleted = await confirmDeleteCollection(
          context,
          bloc: bloc,
          collection: collection,
        );
        if (!context.mounted) return;
        if (deleted) {
          libraryBloc?.add(
            LibraryCollectionRemoved(collectionId: collection.id),
          );
          context.showSuccessMessage(l10n.collectionDeleted);
        } else if (bloc.state.mutation?.failure != null) {
          context.showErrorMessage(
            bloc.state.mutation!.failure!.message(context),
          );
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.pfColors;
    final l10n = context.l10n;
    return Stack(
      children: [
        PressScale(
          onTap: () => openCollection(context, collection),
          semanticLabel: l10n.collectionCardLabel(
            collection.name,
            collection.gameCount,
          ),
          child: ExcludeSemantics(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: CollectionMosaic(coverUrls: collection.coverUrls),
                ),
                const SizedBox(height: PfSpace.sm),
                Text(
                  collection.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.collectionGameCount(collection.gameCount),
                  maxLines: 1,
                  style: PfTypography.monoStyle(colors.textMed, size: 11),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: PfSpace.xs,
          right: PfSpace.xs,
          child: Material(
            color: PicklogColors.imageScrim.withValues(alpha: 0.6),
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: SizedBox.square(
              dimension: 36,
              child: PopupMenuButton<_CollectionMenu>(
                tooltip: l10n.collectionActions,
                iconSize: 18,
                padding: EdgeInsets.zero,
                icon: const Icon(
                  Icons.more_horiz,
                  color: PicklogColors.onImage,
                ),
                onSelected: (action) => _onMenu(context, action),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: _CollectionMenu.edit,
                    child: Text(l10n.collectionEditTitle),
                  ),
                  PopupMenuItem(
                    value: _CollectionMenu.delete,
                    child: Text(l10n.collectionDeleteAction),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

enum _CollectionMenu { edit, delete }

class _CollectionsGridSkeleton extends StatelessWidget {
  const _CollectionsGridSkeleton();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          PfSpace.lg,
          PfSpace.sm,
          PfSpace.lg,
          PfSpace.lg,
        ),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: collectionColumnsFor(constraints.maxWidth),
          mainAxisSpacing: PfSpace.lg,
          crossAxisSpacing: PfSpace.md,
          childAspectRatio: 0.78,
        ),
        itemCount: 4,
        itemBuilder: (context, index) => const Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: SkeletonBox()),
            SizedBox(height: PfSpace.sm),
            SkeletonBox(height: 14, width: 100),
            SizedBox(height: 4),
            SkeletonBox(height: 10, width: 50),
          ],
        ),
      ),
    );
  }
}
