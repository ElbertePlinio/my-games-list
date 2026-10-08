import 'package:flutter/widgets.dart';
import 'package:picklog/core/domain/models/app_failure.dart';
import 'package:picklog/core/utils/l10n_extensions.dart';

/// Localized, user-facing message for an [AppErrorKind].
extension AppErrorKindL10n on AppErrorKind {
  String message(BuildContext context) {
    final l10n = context.l10n;
    return switch (this) {
      AppErrorKind.network => l10n.errorNetwork,
      AppErrorKind.notFound => l10n.errorNotFound,
      AppErrorKind.unauthorized => l10n.errorUnauthorized,
      AppErrorKind.server => l10n.errorServer,
      AppErrorKind.unknown => l10n.errorUnknown,
    };
  }
}
