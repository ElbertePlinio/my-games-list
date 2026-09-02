import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:picklog/core/services/connectivity_cubit.dart';
import 'package:picklog/core/utils/l10n_extensions.dart';

/// Wraps [child] and shows a thin banner at the top while the device is offline.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConnectivityCubit, bool>(
      builder: (context, online) {
        final colors = Theme.of(context).colorScheme;
        return Column(
          children: [
            if (!online)
              Material(
                color: colors.errorContainer,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 16,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.wifi_off,
                          size: 16,
                          color: colors.onErrorContainer,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          context.l10n.offlineBannerMessage,
                          style: TextStyle(color: colors.onErrorContainer),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            // Always keep the router child in the same MediaQuery slot so it
            // isn't torn down/reinflated when the banner toggles; only the top
            // inset (consumed by the banner) is conditionally stripped to avoid
            // a double gap.
            Expanded(
              child: MediaQuery.removePadding(
                context: context,
                removeTop: !online,
                child: child,
              ),
            ),
          ],
        );
      },
    );
  }
}
