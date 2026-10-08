import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:picklog/core/utils/l10n_extensions.dart';

/// Localized playtime: "No playtime", "45 min", or "12,5 h" with the
/// locale's decimal separator.
String formatPlaytime(BuildContext context, int? minutes) {
  final l10n = context.l10n;
  if (minutes == null || minutes <= 0) return l10n.playtimeNone;
  if (minutes < 60) return l10n.playtimeMinutesShort(minutes);
  final locale = Localizations.localeOf(context).toString();
  final hours = NumberFormat('#,##0.#', locale).format(minutes / 60);
  return l10n.playtimeHoursShort(hours);
}
