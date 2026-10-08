import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:picklog/core/theme/pf_tokens.dart';
import 'package:picklog/core/theme/picklog_colors.dart';
import 'package:picklog/core/utils/l10n_extensions.dart';
import 'package:picklog/core/widgets/skeleton_box.dart';
import 'package:picklog/features/library/bloc/library_bloc.dart';
import 'package:picklog/features/library/bloc/library_event.dart';
import 'package:picklog/features/library/collections/bloc/user_collections_bloc.dart';
import 'package:picklog/features/library/collections/bloc/user_collections_event.dart';
import 'package:picklog/features/library/collections/bloc/user_collections_state.dart';
import 'package:picklog/features/library/collections/user_collection_model.dart';
import 'package:picklog/features/library/collections/widgets/collection_form_dialog.dart';
import 'package:picklog/features/library/collections/widgets/collection_mosaic.dart';
import 'package:picklog/features/library/library_entry_model.dart';

/// Multi-select sheet that adds a library entry to collections or removes it.
///
/// Each tap is saved at once. A "New collection" action creates one with the
/// entry already in it. Confirmed changes update the shared LibraryBloc.
class CollectionPickerSheet extends StatefulWidget {
  const CollectionPickerSheet({required this.entry, super.key});

  final LibraryEntry entry;

  static Future<void> show(
    BuildContext context, {
    required LibraryEntry entry,
    required UserCollectionsBloc collectionsBloc,
    required LibraryBloc libraryBloc,
  }) {
    if (collectionsBloc.state.status == UserCollectionsStatus.initial ||
        collectionsBloc.state.status == UserCollectionsStatus.failure) {
      collectionsBloc.add(const UserCollectionsLoadRequested());
    }
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: collectionsBloc),
          BlocProvider.value(value: libraryBloc),
        ],
        child: CollectionPickerSheet(entry: entry),
      ),
    );
  }

  @override
  State<CollectionPickerSheet> createState() => _CollectionPickerSheetState();
}

class _CollectionPickerSheetState extends State<CollectionPickerSheet> {
  late Set<String> _selected = {...widget.entry.collectionIds};

  /// requestId -> (collectionId, add).
  final Map<int, (String, bool)> _pending = {};
  String? _error;

  void _publish() {
    context.read<LibraryBloc>().add(
      LibraryEntryCollectionsChanged(
        entryId: widget.entry.id,
        collectionIds: _selected.toList(),
      ),
    );
  }

  void _toggle(UserCollection collection, bool add) {
    if (_pending.values.any((p) => p.$1 == collection.id)) return;
    final requestId = UserCollectionsBloc.newRequestId();
    setState(() {
      _error = null;
      _pending[requestId] = (collection.id, add);
      _selected = add
          ? {..._selected, collection.id}
          : ({..._selected}..remove(collection.id));
    });
    context.read<UserCollectionsBloc>().add(
      UserCollectionEntryToggled(
        requestId: requestId,
        collectionId: collection.id,
        libraryEntryId: widget.entry.id,
        add: add,
      ),
    );
  }

  Future<void> _create() async {
    final created = await showCollectionFormDialog(
      context,
      bloc: context.read<UserCollectionsBloc>(),
      addEntryId: widget.entry.id,
    );
    if (created == null || !mounted) return;
    setState(() => _selected = {..._selected, created.id});
    _publish();
  }

  void _onMutation(BuildContext context, UserCollectionsState state) {
    final mutation = state.mutation;
    if (mutation == null) return;
    final pending = _pending.remove(mutation.requestId);
    if (pending == null) return;
    if (mutation.succeeded) {
      setState(() {});
      _publish();
      return;
    }
    final (collectionId, add) = pending;
    setState(() {
      _selected = add
          ? ({..._selected}..remove(collectionId))
          : {..._selected, collectionId};
      _error = mutation.failure!.message(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocConsumer<UserCollectionsBloc, UserCollectionsState>(
      listenWhen: (p, c) => p.mutation != c.mutation,
      listener: _onMutation,
      builder: (context, state) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.35,
          maxChildSize: 0.92,
          expand: false,
          builder: (context, controller) => ListView(
            controller: controller,
            padding: const EdgeInsets.only(bottom: PfSpace.xl),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  PfSpace.xl,
                  0,
                  PfSpace.xl,
                  PfSpace.xs,
                ),
                child: Text(
                  context.l10n.collectionPickerTitle,
                  style: theme.textTheme.titleLarge,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: PfSpace.xl),
                child: Text(
                  widget.entry.game.name,
                  style: theme.textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: PfSpace.sm),
              _NewCollectionTile(atLimit: state.atLimit, onTap: _create),
              if (_error != null) _buildError(context),
              ..._buildCollections(context, state),
            ],
          ),
        );
      },
    );
  }

  /// Save error, announced to screen readers.
  Widget _buildError(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: PfSpace.xl,
        vertical: PfSpace.xs,
      ),
      child: Semantics(
        liveRegion: true,
        child: Text(
          _error!,
          style: Theme.of(
            context,
          ).textTheme.bodySmall!.copyWith(color: context.pfColors.errorFg),
        ),
      ),
    );
  }

  /// Collection rows, or the loading, failure or empty state.
  List<Widget> _buildCollections(
    BuildContext context,
    UserCollectionsState state,
  ) {
    final l10n = context.l10n;
    if (state.isLoading && !state.hasCollections) {
      return [
        for (var i = 0; i < 3; i++)
          const Padding(
            padding: EdgeInsets.symmetric(
              horizontal: PfSpace.lg,
              vertical: PfSpace.sm,
            ),
            child: SkeletonBox(height: 44),
          ),
      ];
    }
    if (state.loadFailure != null && !state.hasCollections) {
      return [
        ListTile(
          title: Text(state.loadFailure!.message(context)),
          trailing: TextButton(
            onPressed: () => context.read<UserCollectionsBloc>().add(
              const UserCollectionsLoadRequested(),
            ),
            child: Text(l10n.browseRetry),
          ),
        ),
      ];
    }
    if (!state.hasCollections) {
      return [
        Padding(
          padding: const EdgeInsets.all(PfSpace.xl),
          child: Text(
            l10n.collectionPickerEmpty,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium!.copyWith(color: context.pfColors.textMed),
          ),
        ),
      ];
    }
    final pendingIds = {for (final p in _pending.values) p.$1};
    return [
      for (final collection in state.collections)
        CheckboxListTile(
          key: ValueKey('collection_picker_${collection.id}'),
          value: _selected.contains(collection.id),
          onChanged: pendingIds.contains(collection.id)
              ? null
              : (checked) => _toggle(collection, checked ?? false),
          secondary: SizedBox.square(
            dimension: 44,
            child: CollectionMosaic(
              coverUrls: collection.coverUrls,
              borderRadius: PfRadius.sm,
              gap: 1,
            ),
          ),
          title: Text(
            collection.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(l10n.collectionGameCount(collection.gameCount)),
        ),
    ];
  }
}

/// "New collection" row. Disabled at the collection limit.
class _NewCollectionTile extends StatelessWidget {
  const _NewCollectionTile({required this.atLimit, required this.onTap});

  final bool atLimit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.pfColors;
    return ListTile(
      key: const Key('collection_picker_new'),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: colors.surface2,
          borderRadius: PfRadius.mdAll,
          border: Border.all(color: colors.hairline),
        ),
        child: Icon(Icons.add, color: colors.textHi),
      ),
      title: Text(l10n.collectionNewTitle),
      enabled: !atLimit,
      subtitle: atLimit ? Text(l10n.collectionErrorLimit) : null,
      onTap: onTap,
    );
  }
}
