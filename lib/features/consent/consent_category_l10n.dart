import 'package:flutter/widgets.dart';
import 'package:picklog/core/services/consent/consent_category.dart';
import 'package:picklog/core/utils/l10n_extensions.dart';

/// Localized labels for each [ConsentCategory], shared by the first-run
/// customize sheet and the settings toggles so the copy stays in one place.
extension ConsentCategoryL10n on ConsentCategory {
  String localizedTitle(BuildContext context) => switch (this) {
    ConsentCategory.analytics => context.l10n.consentAnalyticsTitle,
    ConsentCategory.crash => context.l10n.consentCrashTitle,
    ConsentCategory.push => context.l10n.consentPushTitle,
  };

  String localizedSubtitle(BuildContext context) => switch (this) {
    ConsentCategory.analytics => context.l10n.consentAnalyticsSubtitle,
    ConsentCategory.crash => context.l10n.consentCrashSubtitle,
    ConsentCategory.push => context.l10n.consentPushSubtitle,
  };
}
