import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:picklog/core/domain/models/app_failure.dart';
import 'package:picklog/core/theme/pf_tokens.dart';
import 'package:picklog/core/theme/picklog_colors.dart';
import 'package:picklog/core/utils/l10n_extensions.dart';
import 'package:picklog/core/utils/messages_extensions.dart';
import 'package:picklog/core/utils/service_locator.dart';
import 'package:picklog/core/widgets/favorite_button.dart';
import 'package:picklog/core/widgets/pf_button.dart';
import 'package:picklog/core/widgets/pf_dialog.dart';
import 'package:picklog/core/widgets/score_badge.dart';
import 'package:picklog/core/widgets/section_header.dart';
import 'package:picklog/features/games/game_detail_model.dart';
import 'package:picklog/features/library/bloc/library_bloc.dart';
import 'package:picklog/features/library/bloc/library_event.dart';
import 'package:picklog/features/library/bloc/library_state.dart';
import 'package:picklog/features/library/collections/bloc/user_collections_bloc.dart';
import 'package:picklog/features/library/collections/bloc/user_collections_event.dart';
import 'package:picklog/features/library/collections/bloc/user_collections_state.dart';
import 'package:picklog/features/library/collections/collection_failure.dart';
import 'package:picklog/features/library/collections/widgets/collection_form_dialog.dart';
import 'package:picklog/features/library/library_entry_model.dart';
import 'package:picklog/features/library/widgets/library_status_pill.dart';

/// Bottom sheet for adding or editing a game in the library
class AddToLibraryBottomSheet extends StatefulWidget {
  const AddToLibraryBottomSheet({
    super.key,
    required this.gameId,
    required this.gameName,
    required this.platforms,
    this.existingEntry,
    this.collectionsBloc,
  });

  final int gameId;
  final String gameName;
  final List<Platform> platforms;
  final LibraryEntry? existingEntry;

  /// Source of the user's collections. Defaults to a provided bloc, then the
  /// shared instance in the service locator. Without one the collections
  /// section is hidden.
  final UserCollectionsBloc? collectionsBloc;

  /// Shows the bottom sheet and returns true if saved successfully
  static Future<bool?> show({
    required BuildContext context,
    required int gameId,
    required String gameName,
    required List<Platform> platforms,
    LibraryEntry? existingEntry,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      builder: (context) => AddToLibraryBottomSheet(
        gameId: gameId,
        gameName: gameName,
        platforms: platforms,
        existingEntry: existingEntry,
      ),
    );
  }

  @override
  State<AddToLibraryBottomSheet> createState() =>
      _AddToLibraryBottomSheetState();
}

class _AddToLibraryBottomSheetState extends State<AddToLibraryBottomSheet> {
  late GameStatus _selectedStatus;
  Platform? _selectedPlatform;
  int? _score;
  int? _playtimeHours;
  int? _playtimeMinutes;
  DateTime? _startDate;
  DateTime? _endDate;
  String? _difficulty;
  bool _isFavorite = false;
  String? _notes;

  final _notesController = TextEditingController();
  final _difficultyController = TextEditingController();
  final _playtimeHoursController = TextEditingController();
  final _playtimeMinutesController = TextEditingController();

  bool get isEditing => widget.existingEntry != null;

  /// Optional details start open when the entry already has some.
  bool _detailsExpanded = false;

  UserCollectionsBloc? _collections;
  bool _collectionsResolved = false;

  /// True once the entry saved, while the collection changes finish.
  bool _finishing = false;

  /// Collections chosen in the sheet. Applied after the entry saves.
  late Set<String> _collectionIds = {...?widget.existingEntry?.collectionIds};

  @override
  void initState() {
    super.initState();
    _initializeFromExisting();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_collectionsResolved) return;
    _collectionsResolved = true;
    _collections = widget.collectionsBloc ?? _lookupCollections(context);
    final bloc = _collections;
    if (bloc != null &&
        (bloc.state.status == UserCollectionsStatus.initial ||
            bloc.state.status == UserCollectionsStatus.failure)) {
      bloc.add(const UserCollectionsLoadRequested());
    }
  }

  static UserCollectionsBloc? _lookupCollections(BuildContext context) {
    try {
      return context.read<UserCollectionsBloc>();
    } on ProviderNotFoundException {
      return sl.isRegistered<UserCollectionsBloc>()
          ? sl<UserCollectionsBloc>()
          : null;
    }
  }

  /// Sends the collection changes for the saved [entry] and publishes only
  /// the memberships the API confirmed. Returns the first failure, if any.
  Future<CollectionFailure?> _applyCollections(
    LibraryBloc library,
    LibraryEntry entry,
  ) async {
    final bloc = _collections;
    if (bloc == null) return null;
    final before = entry.collectionIds.toSet();
    final changes = {
      for (final id in _collectionIds.difference(before)) id: true,
      for (final id in before.difference(_collectionIds)) id: false,
    };
    if (changes.isEmpty) return null;
    final failures = await Future.wait([
      for (final MapEntry(key: id, value: add) in changes.entries)
        _toggleCollection(bloc, entry.id, id, add: add),
    ]);
    final confirmed = {...before};
    for (final (i, MapEntry(key: id, value: add)) in changes.entries.indexed) {
      if (failures[i] != null) continue;
      add ? confirmed.add(id) : confirmed.remove(id);
    }
    if (!setEquals(confirmed, before)) {
      library.add(
        LibraryEntryCollectionsChanged(
          entryId: entry.id,
          collectionIds: confirmed.toList(),
        ),
      );
    }
    return failures.nonNulls.firstOrNull;
  }

  /// Adds or removes one membership and waits for its result.
  static Future<CollectionFailure?> _toggleCollection(
    UserCollectionsBloc bloc,
    String entryId,
    String collectionId, {
    required bool add,
  }) async {
    final requestId = UserCollectionsBloc.newRequestId();
    final result = bloc.stream
        .map((s) => s.mutation)
        .firstWhere((m) => m?.requestId == requestId);
    bloc.add(
      UserCollectionEntryToggled(
        requestId: requestId,
        collectionId: collectionId,
        libraryEntryId: entryId,
        add: add,
      ),
    );
    try {
      return (await result)?.failure;
    } on StateError {
      // The bloc closed before it answered.
      return CollectionFailure.of(
        add ? CollectionAction.addEntry : CollectionAction.removeEntry,
        CollectionErrorKind.other,
        AppErrorKind.unknown,
      );
    }
  }

  Future<void> _createCollection() async {
    final bloc = _collections;
    if (bloc == null) return;
    final created = await showCollectionFormDialog(context, bloc: bloc);
    if (created != null && mounted) {
      setState(() => _collectionIds = {..._collectionIds, created.id});
    }
  }

  void _initializeFromExisting() {
    final entry = widget.existingEntry;
    if (entry != null) {
      _selectedStatus = entry.status;
      _score = entry.score;
      _isFavorite = entry.isFavorite;
      _startDate = entry.startDate;
      _endDate = entry.endDate;
      _difficulty = entry.difficulty;
      _notes = entry.notes;
      _notesController.text = entry.notes ?? '';
      _difficultyController.text = entry.difficulty ?? '';

      if (entry.playtimeMinutes != null) {
        _playtimeHours = entry.playtimeMinutes! ~/ 60;
        _playtimeMinutes = entry.playtimeMinutes! % 60;
        _playtimeHoursController.text = _playtimeHours! > 0
            ? _playtimeHours.toString()
            : '';
        _playtimeMinutesController.text = _playtimeMinutes! > 0
            ? _playtimeMinutes.toString()
            : '';
      }

      // Find matching platform
      if (entry.platform != null) {
        _selectedPlatform = widget.platforms.cast<Platform?>().firstWhere(
          (p) => p?.id == entry.platform!.igdbPlatformId,
          orElse: () => null,
        );
      }
    } else {
      _selectedStatus = GameStatus.planned;
    }
    _detailsExpanded = _hasDetails;
  }

  @override
  void dispose() {
    _notesController.dispose();
    _difficultyController.dispose();
    _playtimeHoursController.dispose();
    _playtimeMinutesController.dispose();
    super.dispose();
  }

  int? get _totalPlaytimeMinutes {
    final hours = _playtimeHours ?? 0;
    final minutes = _playtimeMinutes ?? 0;
    if (hours == 0 && minutes == 0) return null;
    return (hours * 60) + minutes;
  }

  void _save() {
    final bloc = context.read<LibraryBloc>();

    if (isEditing) {
      bloc.add(
        LibraryUpdateEntryRequested(
          entry: widget.existingEntry!,
          status: _selectedStatus,
          igdbPlatformId: _selectedPlatform?.id,
          playtimeMinutes: _totalPlaytimeMinutes,
          isFavorite: _isFavorite,
          // The form shows every detail, so empty fields are cleared.
          details: LibraryEntryDetails(
            score: _score,
            startDate: _startDate,
            endDate: _endDate,
            difficulty: _difficulty?.isNotEmpty == true ? _difficulty : null,
            notes: _notes?.isNotEmpty == true ? _notes : null,
          ),
        ),
      );
    } else {
      bloc.add(
        LibraryAddGameRequested(
          igdbId: widget.gameId,
          status: _selectedStatus,
          igdbPlatformId: _selectedPlatform?.id,
          score: _score,
          playtimeMinutes: _totalPlaytimeMinutes,
          startDate: _startDate?.toIso8601String().split('T').first,
          endDate: _endDate?.toIso8601String().split('T').first,
          difficulty: _difficulty?.isNotEmpty == true ? _difficulty : null,
          isFavorite: _isFavorite,
          notes: _notes?.isNotEmpty == true ? _notes : null,
        ),
      );
    }
  }

  void _delete() {
    if (!isEditing) return;

    showPfDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.removeFromLibrary),
        content: Text(context.l10n.removeFromLibraryConfirm(widget.gameName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(context.l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              context.read<LibraryBloc>().add(
                LibraryDeleteEntryRequested(entryId: widget.existingEntry!.id),
              );
              Navigator.of(dialogContext).pop(); // Close dialog
              Navigator.of(context).pop(true); // Close bottom sheet
            },
            style: TextButton.styleFrom(
              foregroundColor: context.pfColors.errorFg,
            ),
            child: Text(context.l10n.remove),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate(bool isStartDate) async {
    final initialDate = (isStartDate ? _startDate : _endDate) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1970),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  bool get _hasDetails => [
    _totalPlaytimeMinutes != null,
    _startDate != null,
    _endDate != null,
    _difficulty?.isNotEmpty ?? false,
    _notes?.isNotEmpty ?? false,
  ].contains(true);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return BlocListener<LibraryBloc, LibraryState>(
      listener: _onLibraryState,
      child: DraggableScrollableSheet(
        initialChildSize: 0.62,
        minChildSize: 0.3,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return CustomScrollView(
            controller: scrollController,
            slivers: [
              _buildAppBar(context),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    PfSpace.lg,
                    PfSpace.lg,
                    PfSpace.lg,
                    PfSpace.xl + bottomPadding,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        widget.gameName,
                        style: theme.textTheme.headlineMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: PfSpace.lg),

                      // Step 1: the essentials.
                      _buildStatusSection(context),
                      if (widget.platforms.isNotEmpty) ...[
                        const SizedBox(height: PfSpace.md),
                        _buildPlatformSection(context),
                      ],
                      const SizedBox(height: PfSpace.md),
                      _buildRatingSection(context),
                      if (_collections != null) ...[
                        const SizedBox(height: PfSpace.md),
                        _CollectionsSection(
                          bloc: _collections!,
                          selected: _collectionIds,
                          onChanged: (ids) =>
                              setState(() => _collectionIds = ids),
                          onCreate: _createCollection,
                        ),
                      ],
                      const SizedBox(height: PfSpace.md),

                      // Step 2: optional details, collapsed by default.
                      ..._buildOptionalDetails(context),

                      if (isEditing) ...[
                        const SizedBox(height: PfSpace.xl),
                        PfButton(
                          label: l10n.removeFromLibrary,
                          icon: Icons.delete_outline,
                          variant: PfButtonVariant.destructive,
                          onPressed: _delete,
                          expand: true,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _onLibraryState(BuildContext context, LibraryState state) {
    final failure = state.failure;
    if (failure != null &&
        (failure.action == LibraryAction.add ||
            failure.action == LibraryAction.update)) {
      context.showErrorMessage(context.l10n.librarySaveFailed);
    }
    if (state.gameAddedOrUpdated && !_finishing) {
      setState(() => _finishing = true);
      _finishSave(context.read<LibraryBloc>(), state);
    }
  }

  /// Applies the collection changes of the saved entry, then closes.
  Future<void> _finishSave(LibraryBloc library, LibraryState state) async {
    final saved = isEditing
        ? state.entries.where((e) => e.id == widget.existingEntry!.id)
        : state.entries.where((e) => e.game.igdbId == widget.gameId);
    final failure = saved.isEmpty
        ? null
        : await _applyCollections(library, saved.first);
    if (!mounted) return;
    if (failure != null) {
      context.showErrorMessage(failure.message(context));
    } else {
      context.showSuccessMessage(
        isEditing
            ? context.l10n.libraryEntryUpdated
            : context.l10n.gameAddedToLibrary,
      );
    }
    Navigator.of(context).pop(true);
  }

  /// Pinned header with the grabber, close, title and save.
  Widget _buildAppBar(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.pfColors;
    final l10n = context.l10n;
    return SliverAppBar(
      pinned: true,
      automaticallyImplyLeading: false,
      backgroundColor: colors.surface1,
      toolbarHeight: 72,
      titleSpacing: 0,
      flexibleSpace: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: PfSpace.sm + 2),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: colors.hairlineStrong,
              borderRadius: PfRadius.pillAll,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              PfSpace.xs,
              PfSpace.xs,
              PfSpace.lg,
              0,
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: l10n.cancel,
                  color: colors.textMed,
                  icon: const Icon(Icons.close),
                ),
                Expanded(
                  child: Text(
                    isEditing ? l10n.editEntry : l10n.addToLibrary,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                PfButton(
                  label: l10n.save,
                  size: PfButtonSize.sm,
                  onPressed: _finishing ? null : _save,
                ),
              ],
            ),
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(height: 1, color: colors.hairline),
      ),
    );
  }

  /// Status choice chips.
  Widget _buildStatusSection(BuildContext context) {
    final colors = context.pfColors;
    final l10n = context.l10n;
    return _SheetSection(
      title: l10n.statusLabel,
      child: Wrap(
        spacing: PfSpace.sm,
        runSpacing: PfSpace.sm,
        children: GameStatus.values.map((status) {
          final isSelected = _selectedStatus == status;
          return ChoiceChip(
            avatar: Icon(
              status.icon,
              size: 16,
              color: isSelected
                  ? colors.toneForeground(status.tone)
                  : colors.textMed,
            ),
            label: Text(status.localizedName(context)),
            selected: isSelected,
            onSelected: (selected) {
              if (selected) {
                setState(() => _selectedStatus = status);
              }
            },
          );
        }).toList(),
      ),
    );
  }

  /// Optional platform dropdown.
  Widget _buildPlatformSection(BuildContext context) {
    final l10n = context.l10n;
    return _SheetSection(
      title: l10n.platformLabel,
      child: DropdownButtonFormField<Platform>(
        initialValue: _selectedPlatform,
        // Long platform names ellipsize instead of
        // overflowing at large text sizes.
        isExpanded: true,
        decoration: InputDecoration(hintText: l10n.selectPlatformHint),
        items: [
          DropdownMenuItem<Platform>(value: null, child: Text(l10n.noneOption)),
          ...widget.platforms.map((platform) {
            return DropdownMenuItem(
              value: platform,
              child: Text(platform.name, overflow: TextOverflow.ellipsis),
            );
          }),
        ],
        onChanged: (value) {
          setState(() => _selectedPlatform = value);
        },
      ),
    );
  }

  /// Score ring, score slider and favorite toggle.
  Widget _buildRatingSection(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return _SheetSection(
      title: l10n.rating,
      trailing: FavoriteButton(
        isFavorite: _isFavorite,
        addLabel: l10n.addToFavorites,
        removeLabel: l10n.favorited,
        onPressed: () => setState(() => _isFavorite = !_isFavorite),
      ),
      child: Row(
        children: [
          ScoreRing(
            score: _score,
            size: 52,
            semanticLabel: _score == null
                ? l10n.scoreNotSet
                : '${l10n.score} $_score',
          ),
          const SizedBox(width: PfSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: PfSpace.lg),
                  child: Text(
                    _score == null ? l10n.scoreNotSet : l10n.score,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                Slider(
                  value: (_score ?? 0).toDouble(),
                  min: 0,
                  max: 100,
                  divisions: 100,
                  label: _score?.toString(),
                  onChanged: (value) {
                    setState(() {
                      _score = value > 0 ? value.toInt() : null;
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Toggle and animated body for the collapsed optional details.
  List<Widget> _buildOptionalDetails(BuildContext context) {
    return [
      _DetailsToggle(
        expanded: _detailsExpanded,
        onTap: () => setState(() => _detailsExpanded = !_detailsExpanded),
      ),
      AnimatedSize(
        duration: PfMotion.of(context, PfMotion.standard),
        curve: PfMotion.forge,
        alignment: Alignment.topCenter,
        child: !_detailsExpanded
            ? const SizedBox(width: double.infinity)
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: PfSpace.md),
                  _buildDetails(context),
                ],
              ),
      ),
    ];
  }

  Widget _buildDetails(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SheetSection(
          title: l10n.playtime,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _playtimeHoursController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(labelText: l10n.hours),
                  onChanged: (value) {
                    _playtimeHours = value.isNotEmpty
                        ? int.tryParse(value)
                        : null;
                  },
                ),
              ),
              const SizedBox(width: PfSpace.md),
              Expanded(
                child: TextField(
                  controller: _playtimeMinutesController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(2),
                  ],
                  decoration: InputDecoration(labelText: l10n.minutes),
                  onChanged: (value) {
                    _playtimeMinutes = value.isNotEmpty
                        ? int.tryParse(value)
                        : null;
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: PfSpace.md),
        _SheetSection(
          title: l10n.dates,
          child: Row(
            children: [
              Expanded(
                child: _DatePickerButton(
                  label: l10n.startDate,
                  date: _startDate,
                  onTap: () => _pickDate(true),
                  onClear: () => setState(() => _startDate = null),
                ),
              ),
              const SizedBox(width: PfSpace.md),
              Expanded(
                child: _DatePickerButton(
                  label: l10n.endDate,
                  date: _endDate,
                  onTap: () => _pickDate(false),
                  onClear: () => setState(() => _endDate = null),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: PfSpace.md),
        _SheetSection(
          title: l10n.difficulty,
          child: TextField(
            controller: _difficultyController,
            decoration: InputDecoration(hintText: l10n.difficultyHint),
            onChanged: (value) => _difficulty = value,
          ),
        ),
        const SizedBox(height: PfSpace.md),
        _SheetSection(
          title: l10n.notes,
          child: TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: InputDecoration(hintText: l10n.notesHint),
            onChanged: (value) => _notes = value,
          ),
        ),
      ],
    );
  }
}

/// Card grouping one field of the sheet, with a muted eyebrow title.
class _SheetSection extends StatelessWidget {
  const _SheetSection({
    required this.title,
    required this.child,
    this.trailing,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.pfColors;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface2,
        borderRadius: PfRadius.cardAll,
        border: Border.all(color: colors.hairline),
      ),
      padding: const EdgeInsets.fromLTRB(
        PfSpace.lg,
        PfSpace.md,
        PfSpace.md,
        PfSpace.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: trailing == null ? null : 40,
            child: Row(
              children: [
                Expanded(child: Eyebrow(title, muted: true)),
                ?trailing,
              ],
            ),
          ),
          SizedBox(height: trailing == null ? PfSpace.md : PfSpace.xs),
          child,
        ],
      ),
    );
  }
}

/// Collection chips for the entry. The choice is saved with the entry.
class _CollectionsSection extends StatelessWidget {
  const _CollectionsSection({
    required this.bloc,
    required this.selected,
    required this.onChanged,
    required this.onCreate,
  });

  final UserCollectionsBloc bloc;
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocBuilder<UserCollectionsBloc, UserCollectionsState>(
      bloc: bloc,
      builder: (context, state) {
        return _SheetSection(
          title: l10n.librarySegmentCollections,
          child: Wrap(
            spacing: PfSpace.sm,
            runSpacing: PfSpace.sm,
            children: [
              for (final collection in state.collections)
                FilterChip(
                  key: ValueKey('sheet_collection_${collection.id}'),
                  label: Text(collection.name),
                  selected: selected.contains(collection.id),
                  onSelected: (on) => onChanged(
                    on
                        ? {...selected, collection.id}
                        : ({...selected}..remove(collection.id)),
                  ),
                ),
              if (!state.atLimit)
                ActionChip(
                  key: const Key('sheet_new_collection'),
                  avatar: const Icon(Icons.add, size: 16),
                  label: Text(l10n.collectionNewTitle),
                  onPressed: onCreate,
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Row that expands the optional details group.
class _DetailsToggle extends StatelessWidget {
  const _DetailsToggle({required this.expanded, required this.onTap});

  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.pfColors;
    final l10n = context.l10n;
    return Material(
      color: colors.surface1,
      shape: RoundedRectangleBorder(
        borderRadius: PfRadius.cardAll,
        side: BorderSide(color: colors.hairline),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const RoundedRectangleBorder(
          borderRadius: PfRadius.cardAll,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: PfSpace.lg,
            vertical: PfSpace.md,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.libraryDetailsSection,
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.libraryDetailsHint,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              AnimatedRotation(
                turns: expanded ? 0.5 : 0,
                duration: PfMotion.of(context, PfMotion.fast),
                child: Icon(Icons.expand_more, color: colors.textMed),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DatePickerButton extends StatelessWidget {
  const _DatePickerButton({
    required this.label,
    required this.date,
    required this.onTap,
    required this.onClear,
  });

  final String label;
  final DateTime? date;
  final VoidCallback onTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasDate = date != null;

    final locale = Localizations.localeOf(context).toString();
    return InkWell(
      onTap: onTap,
      borderRadius: PfRadius.mdAll,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: context.pfColors.surface1,
          border: Border.all(color: context.pfColors.hairline),
          borderRadius: PfRadius.mdAll,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasDate
                        ? DateFormat.yMMMd(locale).format(date!)
                        : context.l10n.notSet,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: hasDate
                          ? null
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (hasDate)
              IconButton(
                onPressed: onClear,
                tooltip: context.l10n.clearDate,
                iconSize: 18,
                icon: Icon(
                  Icons.close,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else
              ExcludeSemantics(
                child: Icon(
                  Icons.calendar_today,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
