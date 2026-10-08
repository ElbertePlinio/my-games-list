import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:picklog/core/services/connectivity_cubit.dart';
import 'package:picklog/core/theme/pf_tokens.dart';
import 'package:picklog/core/theme/picklog_colors.dart';
import 'package:picklog/core/utils/l10n_extensions.dart';

/// Friendly empty placeholder: a soft icon, a title, an optional message and
/// an optional action.
class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.icon,
    required this.title,
    this.message,
    this.action,
    this.compact = false,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  /// Inline variant for use inside a section instead of a full screen.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return _StateLayout(
      icon: icon,
      tone: PfTone.neutral,
      title: title,
      message: message,
      action: action,
      compact: compact,
    );
  }
}

/// Error view with a localized message and a retry button.
///
/// When the device is offline (and a [ConnectivityCubit] is provided) it
/// explains the connectivity problem instead, while still offering retry.
class ErrorState extends StatelessWidget {
  const ErrorState({
    required this.message,
    required this.onRetry,
    this.title,
    this.compact = false,
    super.key,
  });

  /// Localized message. Never pass raw exception text.
  final String message;
  final VoidCallback? onRetry;
  final String? title;

  /// Inline card variant for one failed section of a larger screen.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final online = _isOnline(context);

    final retry = onRetry == null
        ? null
        : compact
        ? OutlinedButton.icon(
            onPressed: onRetry,
            style: OutlinedButton.styleFrom(minimumSize: const Size(64, 36)),
            icon: const Icon(Icons.refresh, size: 18),
            label: Text(l10n.browseRetry),
          )
        : FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 18),
            label: Text(l10n.browseRetry),
          );

    return _StateLayout(
      icon: online ? Icons.error_outline : Icons.wifi_off,
      tone: PfTone.error,
      title: online ? (title ?? l10n.errorLoadingData) : l10n.offlineTitle,
      message: online ? message : l10n.offlineErrorMessage,
      action: retry,
      compact: compact,
      liveRegion: true,
    );
  }

  static bool _isOnline(BuildContext context) {
    try {
      return context.watch<ConnectivityCubit>().state;
    } on ProviderNotFoundException {
      return true;
    }
  }
}

class _StateLayout extends StatelessWidget {
  const _StateLayout({
    required this.icon,
    required this.tone,
    required this.title,
    required this.compact,
    this.message,
    this.action,
    this.liveRegion = false,
  });

  final IconData icon;
  final PfTone tone;
  final String title;
  final String? message;
  final Widget? action;
  final bool compact;
  final bool liveRegion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.pfColors;
    final iconColor = tone == PfTone.neutral
        ? colors.textLow
        : colors.toneForeground(tone);

    if (compact) {
      return Semantics(
        liveRegion: liveRegion,
        container: true,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: PfSpace.lg),
          padding: const EdgeInsets.all(PfSpace.lg),
          decoration: BoxDecoration(
            color: colors.surface1,
            borderRadius: PfRadius.cardAll,
            border: Border.all(color: colors.hairline),
          ),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 22),
              const SizedBox(width: PfSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, style: theme.textTheme.titleSmall),
                    if (message != null) ...[
                      const SizedBox(height: 2),
                      Text(message!, style: theme.textTheme.bodySmall),
                    ],
                  ],
                ),
              ),
              if (action != null) ...[
                const SizedBox(width: PfSpace.md),
                action!,
              ],
            ],
          ),
        ),
      );
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(PfSpace.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Semantics(
            liveRegion: liveRegion,
            container: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: tone == PfTone.neutral
                        ? colors.surface2
                        : colors.toneBackground(tone),
                    borderRadius: PfRadius.xlAll,
                    border: Border.all(color: colors.hairline),
                  ),
                  child: Icon(icon, size: 32, color: iconColor),
                ),
                const SizedBox(height: PfSpace.lg),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall,
                ),
                if (message != null) ...[
                  const SizedBox(height: PfSpace.sm),
                  Text(
                    message!,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium!.copyWith(
                      color: colors.textMed,
                    ),
                  ),
                ],
                if (action != null) ...[
                  const SizedBox(height: PfSpace.xl),
                  action!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
