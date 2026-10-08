import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:picklog/core/utils/l10n_extensions.dart';
import 'package:picklog/core/utils/messages_extensions.dart';
import 'package:picklog/features/library/bloc/library_bloc.dart';
import 'package:picklog/features/library/bloc/library_state.dart';

/// Shows a localized snackbar when a background library action fails
/// (favorite toggle, delete, refresh).
///
/// Only the visible screen reacts (current route, tickers on), so two screens
/// that share the library bloc never show the same message twice. Add and update failures are reported
/// by the add-to-library sheet itself.
class LibraryFailureListener extends StatelessWidget {
  const LibraryFailureListener({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocListener<LibraryBloc, LibraryState>(
      listenWhen: (previous, current) =>
          current.failure != null && previous.failure != current.failure,
      listener: (context, state) {
        // Covered routes and hidden shell tabs run with tickers off.
        if (!TickerMode.of(context)) return;
        final route = ModalRoute.of(context);
        if (route != null && !route.isCurrent) return;
        final l10n = context.l10n;
        final message = switch (state.failure!.action) {
          LibraryAction.toggleFavorite => l10n.libraryFavoriteFailed,
          LibraryAction.delete => l10n.libraryDeleteFailed,
          LibraryAction.refresh => l10n.libraryRefreshFailed,
          _ => null,
        };
        if (message != null) context.showErrorMessage(message);
      },
      child: child,
    );
  }
}
