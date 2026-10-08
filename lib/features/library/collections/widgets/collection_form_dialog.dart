import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:picklog/core/theme/pf_tokens.dart';
import 'package:picklog/core/theme/picklog_colors.dart';
import 'package:picklog/core/utils/l10n_extensions.dart';
import 'package:picklog/core/widgets/pf_button.dart';
import 'package:picklog/core/widgets/pf_dialog.dart';
import 'package:picklog/features/library/collections/bloc/user_collections_bloc.dart';
import 'package:picklog/features/library/collections/bloc/user_collections_event.dart';
import 'package:picklog/features/library/collections/bloc/user_collections_state.dart';
import 'package:picklog/features/library/collections/user_collection_model.dart';

/// Opens the create or edit dialog. Returns the saved collection, or null
/// when cancelled. With [addEntryId] a new collection also gets that entry.
Future<UserCollection?> showCollectionFormDialog(
  BuildContext context, {
  required UserCollectionsBloc bloc,
  UserCollection? existing,
  String? addEntryId,
}) {
  return showPfDialog<UserCollection>(
    context: context,
    builder: (_) => BlocProvider.value(
      value: bloc,
      child: CollectionFormDialog(existing: existing, addEntryId: addEntryId),
    ),
  );
}

/// Name and description form for a collection.
class CollectionFormDialog extends StatefulWidget {
  const CollectionFormDialog({this.existing, this.addEntryId, super.key});

  final UserCollection? existing;
  final String? addEntryId;

  @override
  State<CollectionFormDialog> createState() => _CollectionFormDialogState();
}

class _CollectionFormDialogState extends State<CollectionFormDialog> {
  late final TextEditingController _name = TextEditingController(
    text: widget.existing?.name ?? '',
  );
  late final TextEditingController _description = TextEditingController(
    text: widget.existing?.description ?? '',
  );
  int? _requestId;
  String? _error;

  bool get _editing => widget.existing != null;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  void _submit() {
    final l10n = context.l10n;
    final name = _name.text.trim();
    if (name.isEmpty || name.length > UserCollection.maxNameLength) {
      setState(() => _error = l10n.collectionErrorNameInvalid);
      return;
    }
    final description = _description.text.trim();
    final bloc = context.read<UserCollectionsBloc>();
    final requestId = UserCollectionsBloc.newRequestId();
    setState(() {
      _error = null;
      _requestId = requestId;
    });
    final existing = widget.existing;
    if (existing == null) {
      bloc.add(
        UserCollectionCreateRequested(
          requestId: requestId,
          name: name,
          description: description.isEmpty ? null : description,
          addEntryId: widget.addEntryId,
        ),
      );
    } else {
      bloc.add(
        UserCollectionUpdateRequested(
          requestId: requestId,
          collectionId: existing.id,
          name: name == existing.name ? null : name,
          // An empty string clears the description on the server.
          description: description == (existing.description ?? '')
              ? null
              : description,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.pfColors;
    final busy = _requestId != null;

    return BlocListener<UserCollectionsBloc, UserCollectionsState>(
      listenWhen: (p, c) =>
          c.mutation != p.mutation && c.mutation?.requestId == _requestId,
      listener: (context, state) {
        final mutation = state.mutation!;
        if (mutation.succeeded) {
          Navigator.of(context).pop(mutation.collection);
        } else {
          setState(() {
            _requestId = null;
            _error = mutation.failure!.message(context);
          });
        }
      },
      child: AlertDialog(
        title: Text(
          _editing ? l10n.collectionEditTitle : l10n.collectionNewTitle,
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                key: const Key('collection_name_field'),
                controller: _name,
                autofocus: true,
                enabled: !busy,
                textCapitalization: TextCapitalization.sentences,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(
                    UserCollection.maxNameLength,
                  ),
                ],
                decoration: InputDecoration(
                  labelText: l10n.collectionNameLabel,
                ),
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: PfSpace.md),
              TextField(
                key: const Key('collection_description_field'),
                controller: _description,
                enabled: !busy,
                maxLines: 3,
                minLines: 2,
                textCapitalization: TextCapitalization.sentences,
                maxLength: UserCollection.maxDescriptionLength,
                decoration: InputDecoration(
                  labelText: l10n.collectionDescriptionLabel,
                ),
              ),
              if (_error != null)
                Semantics(
                  liveRegion: true,
                  child: Padding(
                    padding: const EdgeInsets.only(top: PfSpace.xs),
                    child: Text(
                      _error!,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall!.copyWith(color: colors.errorFg),
                    ),
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: busy ? null : () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          PfButton(
            key: const Key('collection_save_button'),
            label: _editing ? l10n.save : l10n.collectionCreateAction,
            size: PfButtonSize.sm,
            isBusy: busy,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}

/// Asks before deleting [collection]; on confirm sends the delete and returns
/// true when it succeeded.
Future<bool> confirmDeleteCollection(
  BuildContext context, {
  required UserCollectionsBloc bloc,
  required UserCollection collection,
}) async {
  final l10n = context.l10n;
  final confirmed = await showPfDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.collectionDeleteTitle),
      content: Text(l10n.collectionDeleteConfirm(collection.name)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(l10n.cancel),
        ),
        TextButton(
          key: const Key('collection_delete_confirm'),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          style: TextButton.styleFrom(
            foregroundColor: dialogContext.pfColors.errorFg,
          ),
          child: Text(l10n.collectionDeleteAction),
        ),
      ],
    ),
  );
  if (confirmed != true) return false;
  final requestId = UserCollectionsBloc.newRequestId();
  bloc.add(
    UserCollectionDeleteRequested(
      requestId: requestId,
      collectionId: collection.id,
    ),
  );
  final result = await bloc.stream
      .map((s) => s.mutation)
      .firstWhere((m) => m?.requestId == requestId);
  return result!.succeeded;
}
