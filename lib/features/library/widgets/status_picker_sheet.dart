import 'package:flutter/material.dart';
import 'package:picklog/core/theme/pf_tokens.dart';
import 'package:picklog/core/theme/picklog_colors.dart';
import 'package:picklog/core/utils/l10n_extensions.dart';
import 'package:picklog/features/library/library_entry_model.dart';
import 'package:picklog/features/library/widgets/library_status_pill.dart';

/// Asks for a new status. Returns null when dismissed.
Future<GameStatus?> showStatusPickerSheet(
  BuildContext context, {
  required GameStatus current,
  required String gameName,
}) {
  return showModalBottomSheet<GameStatus>(
    context: context,
    useSafeArea: true,
    showDragHandle: true,
    builder: (sheetContext) {
      final colors = sheetContext.pfColors;
      final theme = Theme.of(sheetContext);
      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(bottom: PfSpace.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  PfSpace.xl,
                  0,
                  PfSpace.xl,
                  PfSpace.sm,
                ),
                child: Text(
                  sheetContext.l10n.libraryChangeStatusTitle(gameName),
                  style: theme.textTheme.titleMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final status in GameStatus.values)
                      ListTile(
                        leading: Icon(
                          status.icon,
                          color: colors.toneForeground(status.tone),
                        ),
                        title: Text(status.localizedName(sheetContext)),
                        trailing: status == current
                            ? Icon(Icons.check, color: colors.textHi)
                            : null,
                        selected: status == current,
                        onTap: () => Navigator.of(sheetContext).pop(status),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
