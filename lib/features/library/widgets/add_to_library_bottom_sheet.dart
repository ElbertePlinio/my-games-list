import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:picklog/core/utils/l10n_extensions.dart';
import 'package:picklog/core/utils/messages_extensions.dart';
import 'package:picklog/features/games/game_detail_model.dart';
import 'package:picklog/features/library/bloc/library_bloc.dart';
import 'package:picklog/features/library/bloc/library_event.dart';
import 'package:picklog/features/library/bloc/library_state.dart';
import 'package:picklog/features/library/library_entry_model.dart';

/// Bottom sheet for adding or editing a game in the library
class AddToLibraryBottomSheet extends StatefulWidget {
  const AddToLibraryBottomSheet({
    super.key,
    required this.gameId,
    required this.gameName,
    required this.platforms,
    this.existingEntry,
  });

  final int gameId;
  final String gameName;
  final List<Platform> platforms;
  final LibraryEntry? existingEntry;

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
      backgroundColor: Colors.transparent,
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

  @override
  void initState() {
    super.initState();
    _initializeFromExisting();
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
          entryId: widget.existingEntry!.id,
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

    showDialog(
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
            style: TextButton.styleFrom(foregroundColor: Colors.red),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return BlocListener<LibraryBloc, LibraryState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          context.showErrorMessage(state.errorMessage!);
        }
        if (state.gameAddedOrUpdated) {
          context.showSuccessMessage(
            isEditing
                ? context.l10n.libraryEntryUpdated
                : context.l10n.gameAddedToLibrary,
          );
          Navigator.of(context).pop(true);
        }
      },
      child: DraggableScrollableSheet(
        initialChildSize: 0.4, // Starts at 40% height
        minChildSize: 0.2, // Cannot go lower than 20%
        maxChildSize: 0.9, // Can be dragged up to 90%
        expand: false,
        builder: (context, scrollController) {
          return Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: CustomScrollView(
              controller: scrollController, // 1. Connects drag gestures
              slivers: [
                // Handle bar
                SliverAppBar(
                  pinned: true,
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  backgroundColor: theme.colorScheme.surface,
                  automaticallyImplyLeading: false,
                  toolbarHeight: 75, // Adjust based on your handle + row height
                  flexibleSpace: Column(
                    children: [
                      // Handle
                      Container(
                        margin: const EdgeInsets.only(top: 12, bottom: 8),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.4,
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      // Header Row
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text(context.l10n.cancel),
                            ),
                            Text(
                              isEditing
                                  ? context.l10n.editEntry
                                  : context.l10n.addToLibrary,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextButton(
                              onPressed: _save,
                              child: Text(
                                context.l10n.save,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  bottom: const PreferredSize(
                    preferredSize: Size.fromHeight(1),
                    child: Divider(height: 1),
                  ),
                ),

                // Content
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottomPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Game name
                        Text(
                          widget.gameName,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),

                        const SizedBox(height: 24),

                        // Status selection
                        _buildSectionCard(
                          theme: theme,
                          title: context.l10n.statusLabel,
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: GameStatus.values.map((status) {
                              final isSelected = _selectedStatus == status;
                              return ChoiceChip(
                                label: Text(status.localizedName(context)),
                                selected: isSelected,
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() => _selectedStatus = status);
                                  }
                                },
                                selectedColor:
                                    theme.colorScheme.primaryContainer,
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? theme.colorScheme.onPrimaryContainer
                                      : null,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : null,
                                ),
                              );
                            }).toList(),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Platform selection
                        if (widget.platforms.isNotEmpty)
                          _buildSectionCard(
                            theme: theme,
                            title: context.l10n.platformLabel,
                            child: DropdownButtonFormField<Platform>(
                              decoration: InputDecoration(
                                border: const OutlineInputBorder(),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                hintText: context.l10n.selectPlatformHint,
                              ),
                              items: [
                                DropdownMenuItem<Platform>(
                                  value: null,
                                  child: Text(context.l10n.noneOption),
                                ),
                                ...widget.platforms.map((platform) {
                                  return DropdownMenuItem(
                                    value: platform,
                                    child: Text(platform.name),
                                  );
                                }),
                              ],
                              onChanged: (value) {
                                setState(() => _selectedPlatform = value);
                              },
                            ),
                          ),

                        const SizedBox(height: 16),

                        // Score and Favorite row
                        _buildSectionCard(
                          theme: theme,
                          title: context.l10n.rating,
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              context.l10n.score,
                                              style: theme.textTheme.bodyMedium,
                                            ),
                                            Text(
                                              _score != null
                                                  ? '$_score/100'
                                                  : '-',
                                              style: theme.textTheme.bodyLarge
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                    color: theme
                                                        .colorScheme
                                                        .primary,
                                                  ),
                                            ),
                                          ],
                                        ),
                                        Slider(
                                          value: (_score ?? 0).toDouble(),
                                          min: 0,
                                          max: 100,
                                          divisions: 100,
                                          label: _score?.toString(),
                                          onChanged: (value) {
                                            setState(() {
                                              _score = value > 0
                                                  ? value.toInt()
                                                  : null;
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Column(
                                    children: [
                                      IconButton.filled(
                                        onPressed: () {
                                          setState(
                                            () => _isFavorite = !_isFavorite,
                                          );
                                        },
                                        tooltip: _isFavorite
                                            ? context.l10n.favorited
                                            : context.l10n.addToFavorites,
                                        icon: Icon(
                                          _isFavorite
                                              ? Icons.favorite
                                              : Icons.favorite_border,
                                          color: _isFavorite
                                              ? Colors.red
                                              : theme
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                          semanticLabel: _isFavorite
                                              ? context.l10n.favorited
                                              : context.l10n.addToFavorites,
                                        ),
                                        style: IconButton.styleFrom(
                                          backgroundColor: _isFavorite
                                              ? Colors.red.withValues(
                                                  alpha: 0.1,
                                                )
                                              : theme
                                                    .colorScheme
                                                    .surfaceContainerHighest,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        context.l10n.favorite,
                                        style: theme.textTheme.labelSmall,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Playtime
                        _buildSectionCard(
                          theme: theme,
                          title: context.l10n.playtime,
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _playtimeHoursController,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  decoration: InputDecoration(
                                    border: const OutlineInputBorder(),
                                    labelText: context.l10n.hours,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                  ),
                                  onChanged: (value) {
                                    _playtimeHours = value.isNotEmpty
                                        ? int.tryParse(value)
                                        : null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _playtimeMinutesController,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(2),
                                  ],
                                  decoration: InputDecoration(
                                    border: const OutlineInputBorder(),
                                    labelText: context.l10n.minutes,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                  ),
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

                        const SizedBox(height: 16),

                        // Dates
                        _buildSectionCard(
                          theme: theme,
                          title: context.l10n.dates,
                          child: Row(
                            children: [
                              Expanded(
                                child: _DatePickerButton(
                                  label: context.l10n.startDate,
                                  date: _startDate,
                                  onTap: () => _pickDate(true),
                                  onClear: () =>
                                      setState(() => _startDate = null),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _DatePickerButton(
                                  label: context.l10n.endDate,
                                  date: _endDate,
                                  onTap: () => _pickDate(false),
                                  onClear: () =>
                                      setState(() => _endDate = null),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Difficulty
                        _buildSectionCard(
                          theme: theme,
                          title: context.l10n.difficulty,
                          child: TextField(
                            controller: _difficultyController,
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              hintText: context.l10n.difficultyHint,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            onChanged: (value) => _difficulty = value,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Notes
                        _buildSectionCard(
                          theme: theme,
                          title: context.l10n.notes,
                          child: TextField(
                            controller: _notesController,
                            maxLines: 3,
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              hintText: context.l10n.notesHint,
                              contentPadding: const EdgeInsets.all(12),
                            ),
                            onChanged: (value) => _notes = value,
                          ),
                        ),

                        // Delete button (only when editing)
                        if (isEditing) ...[
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _delete,
                              icon: const Icon(Icons.delete_outline),
                              label: Text(context.l10n.removeFromLibrary),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionCard({
    required ThemeData theme,
    required String title,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
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

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outline),
          borderRadius: BorderRadius.circular(8),
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
                        ? DateFormat.yMMMd().format(date!)
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
