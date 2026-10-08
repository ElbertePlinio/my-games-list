import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:picklog/core/utils/l10n_extensions.dart';
import 'package:picklog/core/widgets/animated_state_switcher.dart';
import 'package:picklog/core/widgets/pf_button.dart';
import 'package:picklog/core/widgets/state_views.dart';
import 'package:picklog/features/ai/bloc/ai_status_cubit.dart';
import 'package:picklog/features/ai/widgets/ai_consent_dialog.dart';

/// Shows [child] only when AI is enabled and the user has opted in.
///
/// The first time a user opens an AI screen without consent, the opt-in
/// dialog opens by itself. If they decline, a calm placeholder offers to
/// review it again. Nothing reaches the AI service before consent.
class AiFeatureGate extends StatefulWidget {
  const AiFeatureGate({required this.child, super.key});

  final Widget child;

  @override
  State<AiFeatureGate> createState() => _AiFeatureGateState();
}

class _AiFeatureGateState extends State<AiFeatureGate> {
  bool _prompted = false;

  bool _needsConsent(AiStatusState s) =>
      s.load == AiStatusLoad.ready && s.isEnabled && !s.isConsented;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _maybePrompt(context.read<AiStatusCubit>().state);
    });
  }

  void _maybePrompt(AiStatusState state) {
    if (_prompted || !_needsConsent(state)) return;
    _prompted = true;
    ensureAiConsent(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocConsumer<AiStatusCubit, AiStatusState>(
      listenWhen: (p, c) => p.load != c.load || p.status != c.status,
      listener: (context, state) => _maybePrompt(state),
      builder: (context, state) {
        final Widget body;
        final Object key;
        switch (state.load) {
          case AiStatusLoad.initial:
          case AiStatusLoad.loading:
            key = 'loading';
            body = Semantics(
              label: l10n.loadingLabel,
              child: const Center(child: CircularProgressIndicator()),
            );
          case AiStatusLoad.failure:
            key = 'failure';
            body = ErrorState(
              message: l10n.errorUnknown,
              onRetry: () => context.read<AiStatusCubit>().load(),
            );
          case AiStatusLoad.ready:
            if (!state.isEnabled) {
              key = 'disabled';
              body = EmptyState(
                icon: Icons.cloud_off_outlined,
                title: l10n.aiUnavailableTitle,
                message: l10n.aiErrorUnavailable,
              );
            } else if (!state.isConsented) {
              key = 'consent';
              body = EmptyState(
                icon: Icons.auto_awesome_outlined,
                title: l10n.aiConsentNeededTitle,
                message: l10n.aiConsentNeededMessage,
                action: PfButton(
                  label: l10n.aiReviewConsent,
                  isBusy: state.isSavingConsent,
                  onPressed: () => ensureAiConsent(context),
                ),
              );
            } else {
              key = 'ready';
              body = widget.child;
            }
        }
        return AnimatedStateSwitcher(stateKey: key, child: body);
      },
    );
  }
}
