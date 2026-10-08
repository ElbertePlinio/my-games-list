import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:picklog/core/theme/pf_tokens.dart';
import 'package:picklog/core/theme/picklog_colors.dart';
import 'package:picklog/core/utils/l10n_extensions.dart';
import 'package:picklog/core/widgets/pf_button.dart';
import 'package:picklog/features/integrations/bloc/connected_accounts_cubit.dart';
import 'package:picklog/features/integrations/integrations_l10n.dart';
import 'package:picklog/features/integrations/integrations_models.dart';

/// Opens the link sheet for [provider] on the route's
/// [ConnectedAccountsCubit]. Resolves to true when the account was linked.
Future<bool?> showLinkAccountSheet(
  BuildContext context,
  GameProvider provider,
) {
  final cubit = context.read<ConnectedAccountsCubit>()..resetLink();
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => BlocProvider.value(
      value: cubit,
      child: LinkAccountSheet(provider: provider),
    ),
  );
}

/// Asks for the provider's public identifier, with provider-specific help.
class LinkAccountSheet extends StatefulWidget {
  const LinkAccountSheet({required this.provider, super.key});

  final GameProvider provider;

  @override
  State<LinkAccountSheet> createState() => _LinkAccountSheetState();
}

class _LinkAccountSheetState extends State<LinkAccountSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() => context.read<ConnectedAccountsCubit>().link(
    widget.provider,
    _controller.text,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = context.pfColors;
    final provider = widget.provider;
    final note = provider.note(context);

    return BlocConsumer<ConnectedAccountsCubit, ConnectedAccountsState>(
      listenWhen: (p, c) => p.linkStatus != c.linkStatus,
      listener: (context, state) {
        if (state.linkStatus == LinkStatus.success) {
          Navigator.of(context).pop(true);
        }
      },
      builder: (context, state) {
        final busy = state.linkStatus == LinkStatus.submitting;
        final error = state.linkStatus == LinkStatus.failure
            ? state.linkErrorKind?.message(context)
            : null;
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              PfSpace.xl,
              0,
              PfSpace.xl,
              PfSpace.xl,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _SheetTitle(provider: provider),
                    const SizedBox(height: PfSpace.md),
                    Text(
                      provider.help(context),
                      style: theme.textTheme.bodyMedium!.copyWith(
                        color: colors.textMed,
                      ),
                    ),
                    const SizedBox(height: PfSpace.lg),
                    TextField(
                      controller: _controller,
                      autofocus: true,
                      autocorrect: false,
                      enabled: !busy,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submit(),
                      decoration: InputDecoration(
                        labelText: provider.fieldLabel(context),
                        errorText: error,
                        errorMaxLines: 3,
                      ),
                    ),
                    if (note != null) ...[
                      const SizedBox(height: PfSpace.md),
                      _ProviderNote(note: note),
                    ],
                    const SizedBox(height: PfSpace.xl),
                    PfButton(
                      label: l10n.accountsLinkSubmit,
                      icon: Icons.link,
                      expand: true,
                      isBusy: busy,
                      onPressed: _submit,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SheetTitle extends StatelessWidget {
  const _SheetTitle({required this.provider});

  final GameProvider provider;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(provider.icon, color: context.pfColors.textHi),
        const SizedBox(width: PfSpace.md),
        Expanded(
          child: Semantics(
            header: true,
            child: Text(
              context.l10n.accountsLinkTitle(provider.displayName),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
        ),
      ],
    );
  }
}

class _ProviderNote extends StatelessWidget {
  const _ProviderNote({required this.note});

  final String note;

  @override
  Widget build(BuildContext context) {
    final colors = context.pfColors;
    return Container(
      padding: const EdgeInsets.all(PfSpace.md),
      decoration: BoxDecoration(
        color: colors.toneBackground(PfTone.info),
        borderRadius: PfRadius.mdAll,
        border: Border.all(color: colors.info.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 18, color: colors.infoFg),
          const SizedBox(width: PfSpace.sm),
          Expanded(
            child: Text(
              note,
              style: Theme.of(
                context,
              ).textTheme.bodySmall!.copyWith(color: colors.textHi),
            ),
          ),
        ],
      ),
    );
  }
}
