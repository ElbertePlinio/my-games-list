import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:picklog/core/utils/l10n_extensions.dart';
import 'package:picklog/features/integrations/integrations_models.dart';
import 'package:picklog/features/integrations/integrations_repository.dart';

extension GameProviderUi on GameProvider {
  /// Service names are trademarks and stay the same in every language.
  String get displayName => switch (this) {
    GameProvider.steam => 'Steam',
    GameProvider.xbox => 'Xbox',
    GameProvider.retroAchievements => 'RetroAchievements',
    GameProvider.psn => 'PlayStation',
  };

  /// Brand-neutral icons. Picklog never shows third-party logos.
  IconData get icon => switch (this) {
    GameProvider.steam => Icons.desktop_windows_outlined,
    GameProvider.xbox => Icons.sports_esports_outlined,
    GameProvider.retroAchievements => Icons.videogame_asset_outlined,
    GameProvider.psn => Icons.gamepad_outlined,
  };

  String fieldLabel(BuildContext context) {
    final l10n = context.l10n;
    return switch (this) {
      GameProvider.steam => l10n.accountsSteamFieldLabel,
      GameProvider.xbox => l10n.accountsXboxFieldLabel,
      GameProvider.retroAchievements => l10n.accountsRaFieldLabel,
      GameProvider.psn => l10n.accountsPsnFieldLabel,
    };
  }

  String help(BuildContext context) {
    final l10n = context.l10n;
    return switch (this) {
      GameProvider.steam => l10n.accountsSteamHelp,
      GameProvider.xbox => l10n.accountsXboxHelp,
      GameProvider.retroAchievements => l10n.accountsRaHelp,
      GameProvider.psn => l10n.accountsPsnHelp,
    };
  }

  /// Extra note shown in the link sheet, if any.
  String? note(BuildContext context) => switch (this) {
    GameProvider.steam => context.l10n.accountsSteamPublicNote,
    GameProvider.psn => context.l10n.accountsPsnExperimentalNote,
    _ => null,
  };
}

extension IntegrationErrorKindL10n on IntegrationErrorKind {
  String message(BuildContext context) {
    final l10n = context.l10n;
    return switch (this) {
      IntegrationErrorKind.unavailable => l10n.accountsErrorUnavailable,
      IntegrationErrorKind.accountNotFound => l10n.accountsErrorNotFound,
      IntegrationErrorKind.privateProfile => l10n.accountsErrorPrivate,
      IntegrationErrorKind.syncTooSoon => l10n.accountsErrorSyncTooSoon,
      IntegrationErrorKind.invalidIdentifier => l10n.accountsErrorInvalid,
      IntegrationErrorKind.gameNotFound => l10n.accountsErrorGameNotFound,
      IntegrationErrorKind.upstream => l10n.accountsErrorUpstream,
      IntegrationErrorKind.network => l10n.errorNetwork,
      IntegrationErrorKind.unknown => l10n.errorUnknown,
    };
  }
}

/// "just now", "5 min ago", "3 h ago", or a short date after a day.
String formatRelativeTime(
  BuildContext context,
  DateTime time, {
  DateTime? now,
}) {
  final l10n = context.l10n;
  final diff = (now ?? DateTime.now()).difference(time);
  if (diff.inMinutes < 1) return l10n.timeJustNow;
  if (diff.inHours < 1) return l10n.timeMinutesAgo(diff.inMinutes);
  if (diff.inDays < 1) return l10n.timeHoursAgo(diff.inHours);
  return formatShortDate(context, time);
}

/// Locale-aware short date, for example "Oct 8, 2026".
String formatShortDate(BuildContext context, DateTime time) {
  final locale = Localizations.localeOf(context).toLanguageTag();
  return DateFormat.yMMMd(locale).format(time.toLocal());
}

/// Rarity percent with one decimal under 10 and none above.
String formatRarity(double pct) =>
    pct < 10 ? pct.toStringAsFixed(1) : pct.round().toString();
