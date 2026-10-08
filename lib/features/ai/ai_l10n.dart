import 'package:flutter/widgets.dart';
import 'package:picklog/core/utils/l10n_extensions.dart';
import 'package:picklog/features/ai/ai_models.dart';
import 'package:picklog/features/ai/ai_repository.dart';
import 'package:picklog/l10n/app_localizations.dart';

extension AiMoodL10n on AiMood {
  String label(BuildContext context) {
    final l10n = context.l10n;
    return switch (this) {
      AiMood.chill => l10n.aiMoodChill,
      AiMood.intense => l10n.aiMoodIntense,
      AiMood.story => l10n.aiMoodStory,
      AiMood.social => l10n.aiMoodSocial,
      AiMood.quick => l10n.aiMoodQuick,
      AiMood.challenge => l10n.aiMoodChallenge,
    };
  }
}

extension AiErrorKindL10n on AiErrorKind {
  String message(BuildContext context) {
    final l10n = context.l10n;
    return switch (this) {
      AiErrorKind.unavailable => l10n.aiErrorUnavailable,
      AiErrorKind.consentRequired => l10n.aiErrorConsentRequired,
      AiErrorKind.quotaExceeded => l10n.aiErrorQuotaExceeded,
      AiErrorKind.upstream => l10n.aiErrorUpstream,
      AiErrorKind.network => l10n.errorNetwork,
      AiErrorKind.unknown => l10n.errorUnknown,
    };
  }
}

/// Formats [minutes] as "45 min", "2 h" or "1 h 30 min".
String formatAiDuration(AppLocalizations l10n, int minutes) {
  if (minutes < 60) return l10n.aiDurationMinutes(minutes);
  final hours = minutes ~/ 60;
  final rest = minutes % 60;
  return rest == 0
      ? l10n.aiDurationHours(hours)
      : l10n.aiDurationHoursMinutes(hours, rest);
}
