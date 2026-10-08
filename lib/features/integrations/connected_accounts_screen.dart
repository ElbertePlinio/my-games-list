import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:picklog/core/theme/pf_tokens.dart';
import 'package:picklog/core/theme/picklog_colors.dart';
import 'package:picklog/core/utils/app_router.dart';
import 'package:picklog/core/utils/l10n_extensions.dart';
import 'package:picklog/core/utils/messages_extensions.dart';
import 'package:picklog/core/widgets/animated_state_switcher.dart';
import 'package:picklog/core/widgets/app_scaffold.dart';
import 'package:picklog/core/widgets/pf_button.dart';
import 'package:picklog/core/widgets/pf_dialog.dart';
import 'package:picklog/core/widgets/pf_network_image.dart';
import 'package:picklog/core/widgets/section_header.dart';
import 'package:picklog/core/widgets/skeleton_box.dart';
import 'package:picklog/core/widgets/staggered_reveal.dart';
import 'package:picklog/core/widgets/state_views.dart';
import 'package:picklog/core/widgets/status_pill.dart';
import 'package:picklog/features/integrations/bloc/connected_accounts_cubit.dart';
import 'package:picklog/features/integrations/integrations_l10n.dart';
import 'package:picklog/features/integrations/integrations_models.dart';
import 'package:picklog/features/integrations/integrations_repository.dart';
import 'package:picklog/features/integrations/widgets/link_account_sheet.dart';

/// Link Steam, Xbox, RetroAchievements and PlayStation with a public
/// identifier, sync them, and unlink them.
class ConnectedAccountsScreen extends StatelessWidget {
  const ConnectedAccountsScreen({super.key});

  void _onNotice(BuildContext context, ConnectedAccountsState state) {
    final notice = state.notice;
    if (notice == null) return;
    final l10n = context.l10n;
    final name = notice.provider.displayName;
    switch (notice.type) {
      case AccountNoticeType.linked:
        context.showSuccessMessage(l10n.accountsLinkedMessage(name));
      case AccountNoticeType.unlinked:
        context.showMessage(l10n.accountsUnlinkedMessage(name));
      case AccountNoticeType.syncStarted:
        context.showMessage(l10n.accountsSyncStarted(name));
      case AccountNoticeType.syncFinished:
        context.showSuccessMessage(l10n.accountsSyncFinished(name));
      case AccountNoticeType.syncFailed:
      case AccountNoticeType.unlinkFailed:
        context.showErrorMessage(
          (notice.errorKind ?? IntegrationErrorKind.unknown).message(context),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.accountsTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.emoji_events_outlined),
            tooltip: l10n.achievementsTitle,
            onPressed: () => context.pushNamed(AppRouter.achievementsName),
          ),
          const SizedBox(width: PfSpace.xs),
        ],
      ),
      body: SafeArea(
        top: false,
        child: BlocListener<ConnectedAccountsCubit, ConnectedAccountsState>(
          listenWhen: (p, c) => p.notice != c.notice,
          listener: _onNotice,
          child: BlocBuilder<ConnectedAccountsCubit, ConnectedAccountsState>(
            builder: (context, state) {
              final cubit = context.read<ConnectedAccountsCubit>();
              final Widget body;
              switch (state.status) {
                case ConnectedAccountsStatus.initial:
                case ConnectedAccountsStatus.loading:
                  body = const _AccountsSkeleton();
                case ConnectedAccountsStatus.failure:
                  body = ErrorState(
                    message: (state.errorKind ?? IntegrationErrorKind.unknown)
                        .message(context),
                    onRetry: cubit.load,
                  );
                case ConnectedAccountsStatus.ready:
                  body = RefreshIndicator(
                    onRefresh: cubit.load,
                    child: _AccountsList(state: state),
                  );
              }
              return AnimatedStateSwitcher(
                stateKey: state.status == ConnectedAccountsStatus.ready
                    ? 'ready'
                    : state.status,
                child: body,
              );
            },
          ),
        ),
      ),
    );
  }
}

class _AccountsList extends StatelessWidget {
  const _AccountsList({required this.state});

  final ConnectedAccountsState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        PfSpace.lg,
        PfSpace.xs,
        PfSpace.lg,
        PfSpace.xxl,
      ),
      children: [
        MaxWidthBox(
          maxWidth: PfBreakpoints.narrow,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Eyebrow(l10n.accountsEyebrow),
              const SizedBox(height: PfSpace.sm),
              Text(
                l10n.accountsIntro,
                style: theme.textTheme.bodyMedium!.copyWith(
                  color: context.pfColors.textMed,
                ),
              ),
              const SizedBox(height: PfSpace.xl),
              for (var i = 0; i < state.providers.length; i++) ...[
                if (i > 0) const SizedBox(height: PfSpace.md),
                StaggeredReveal(
                  index: i,
                  child: ProviderAccountCard(
                    entry: state.providers[i],
                    busy: state.busyProviders.contains(
                      state.providers[i].provider,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Skeleton matching the provider cards.
class _AccountsSkeleton extends StatelessWidget {
  const _AccountsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: context.l10n.loadingLabel,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          PfSpace.lg,
          PfSpace.xs,
          PfSpace.lg,
          PfSpace.xxl,
        ),
        children: [
          MaxWidthBox(
            maxWidth: PfBreakpoints.narrow,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SkeletonBox(width: 120, height: 12),
                const SizedBox(height: PfSpace.md),
                const SkeletonBox(height: 36),
                const SizedBox(height: PfSpace.xl),
                for (var i = 0; i < GameProvider.values.length; i++) ...[
                  if (i > 0) const SizedBox(height: PfSpace.md),
                  const SkeletonBox(height: 112, borderRadius: PfRadius.card),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One provider: unavailable, ready to link, syncing, or linked.
class ProviderAccountCard extends StatefulWidget {
  const ProviderAccountCard({
    required this.entry,
    this.busy = false,
    super.key,
  });

  final LinkedProvider entry;
  final bool busy;

  @override
  State<ProviderAccountCard> createState() => _ProviderAccountCardState();
}

class _ProviderAccountCardState extends State<ProviderAccountCard> {
  bool _importLibrary = false;

  Future<void> _confirmUnlink() async {
    final l10n = context.l10n;
    final cubit = context.read<ConnectedAccountsCubit>();
    final provider = widget.entry.provider;
    final colors = context.pfColors;
    final confirmed = await showPfDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.accountsUnlinkTitle(provider.displayName)),
        content: Text(l10n.accountsUnlinkMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: colors.errorFg),
            child: Text(l10n.accountsUnlink),
          ),
        ],
      ),
    );
    if (confirmed ?? false) await cubit.unlink(provider);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final entry = widget.entry;
    final provider = entry.provider;
    final account = entry.account;

    final pills = <Widget>[
      if (entry.experimental)
        StatusPill(
          label: l10n.accountsExperimental,
          tone: PfTone.warning,
          icon: Icons.science_outlined,
          dense: true,
        ),
      if (!entry.available)
        StatusPill(
          label: l10n.accountsUnavailable,
          tone: PfTone.neutral,
          dense: true,
        ),
    ];

    final Widget body;
    if (account != null) {
      body = _LinkedBody(
        account: account,
        busy: widget.busy,
        available: entry.available,
        importLibrary: _importLibrary,
        onImportChanged: (v) => setState(() => _importLibrary = v),
        onSync: () => context.read<ConnectedAccountsCubit>().sync(
          provider,
          importLibrary: _importLibrary,
        ),
        onUnlink: _confirmUnlink,
      );
    } else if (!entry.available) {
      body = Text(
        l10n.accountsUnavailableMessage,
        style: theme.textTheme.bodySmall,
      );
    } else {
      body = Row(
        children: [
          Expanded(
            child: Text(
              l10n.accountsNotLinked,
              style: theme.textTheme.bodySmall,
            ),
          ),
          PfButton(
            label: l10n.accountsLink,
            icon: Icons.link,
            size: PfButtonSize.sm,
            variant: PfButtonVariant.secondary,
            onPressed: () => showLinkAccountSheet(context, provider),
          ),
        ],
      );
    }

    return Semantics(
      container: true,
      child: Opacity(
        opacity: entry.available || account != null ? 1 : 0.72,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(PfSpace.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ProviderHeader(provider: provider, pills: pills),
                const SizedBox(height: PfSpace.md),
                body,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LinkedBody extends StatelessWidget {
  const _LinkedBody({
    required this.account,
    required this.busy,
    required this.available,
    required this.importLibrary,
    required this.onImportChanged,
    required this.onSync,
    required this.onUnlink,
  });

  final LinkedAccount account;
  final bool busy;
  final bool available;
  final bool importLibrary;
  final ValueChanged<bool> onImportChanged;
  final VoidCallback onSync;
  final VoidCallback onUnlink;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.pfColors;
    final syncing = account.syncStatus == SyncStatus.syncing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _AccountIdentity(account: account),
        if (syncing && !PfMotion.reduced(context)) ...[
          const SizedBox(height: PfSpace.md),
          ClipRRect(
            borderRadius: PfRadius.pillAll,
            child: LinearProgressIndicator(
              minHeight: 3,
              color: colors.info,
              backgroundColor: colors.surface3,
            ),
          ),
        ],
        const SizedBox(height: PfSpace.sm),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: Text(l10n.accountsImportToggle),
          subtitle: Text(l10n.accountsImportHelp),
          value: importLibrary,
          onChanged: syncing || busy || !available ? null : onImportChanged,
        ),
        const SizedBox(height: PfSpace.sm),
        Wrap(
          spacing: PfSpace.sm,
          runSpacing: PfSpace.sm,
          alignment: WrapAlignment.spaceBetween,
          children: [
            PfButton(
              label: l10n.accountsSyncNow,
              icon: Icons.sync,
              size: PfButtonSize.sm,
              variant: PfButtonVariant.secondary,
              isBusy: busy,
              onPressed: syncing || !available ? null : onSync,
            ),
            TextButton.icon(
              onPressed: busy ? null : onUnlink,
              style: TextButton.styleFrom(
                foregroundColor: colors.errorFg,
                minimumSize: const Size(48, 36),
              ),
              icon: const Icon(Icons.link_off, size: 18),
              label: Text(l10n.accountsUnlink),
            ),
          ],
        ),
      ],
    );
  }
}

class _ProviderHeader extends StatelessWidget {
  const _ProviderHeader({required this.provider, required this.pills});

  final GameProvider provider;
  final List<Widget> pills;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.pfColors;
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: colors.surface2,
            borderRadius: PfRadius.mdAll,
            border: Border.all(color: colors.hairline),
          ),
          child: Icon(provider.icon, color: colors.textHi, size: 22),
        ),
        const SizedBox(width: PfSpace.md),
        // The pills sit at the right edge when they fit beside
        // the title, and wrap under it on narrow cards.
        Expanded(
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: PfSpace.sm,
            runSpacing: PfSpace.xs,
            children: [
              Text(
                provider.displayName,
                style: theme.textTheme.titleLarge,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (pills.isNotEmpty)
                Wrap(
                  spacing: PfSpace.xs,
                  runSpacing: PfSpace.xs,
                  children: pills,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AccountIdentity extends StatelessWidget {
  const _AccountIdentity({required this.account});

  final LinkedAccount account;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final lastSynced = account.lastSyncedAt;

    final (
      String statusLabel,
      PfTone tone,
      IconData? icon,
    ) = switch (account.syncStatus) {
      SyncStatus.syncing => (l10n.accountsSyncing, PfTone.info, Icons.sync),
      SyncStatus.ok => (l10n.accountsSyncOk, PfTone.connected, Icons.check),
      SyncStatus.error => (
        l10n.accountsSyncError,
        PfTone.error,
        Icons.error_outline,
      ),
      SyncStatus.idle => (l10n.accountsNeverSynced, PfTone.neutral, null),
    };

    return Row(
      children: [
        _Avatar(url: account.avatarUrl, name: account.displayName),
        const SizedBox(width: PfSpace.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                account.displayName,
                style: theme.textTheme.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: PfSpace.xs),
              Wrap(
                spacing: PfSpace.sm,
                runSpacing: PfSpace.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  StatusPill(
                    label: statusLabel,
                    tone: tone,
                    icon: icon,
                    dense: true,
                  ),
                  if (lastSynced != null)
                    Text(
                      l10n.accountsLastSynced(
                        formatRelativeTime(context, lastSynced),
                      ),
                      style: theme.textTheme.bodySmall,
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.url, required this.name});

  final String? url;
  final String name;

  @override
  Widget build(BuildContext context) {
    final colors = context.pfColors;
    final initial = name.trim().isEmpty
        ? '?'
        : name.trim().substring(0, 1).toUpperCase();
    final fallback = Center(
      child: Text(
        initial,
        style: Theme.of(
          context,
        ).textTheme.titleMedium!.copyWith(color: colors.textMed),
      ),
    );
    return ExcludeSemantics(
      child: Container(
        width: 40,
        height: 40,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colors.surface2,
          border: Border.all(color: colors.hairline),
        ),
        child: url == null
            ? fallback
            : PfNetworkImage(url: url!, placeholder: fallback, error: fallback),
      ),
    );
  }
}

/// Settings group that links to Connected accounts.
class ConnectedAccountsSettingsSection extends StatelessWidget {
  const ConnectedAccountsSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: PfSpace.xs, bottom: PfSpace.sm),
          child: Semantics(
            header: true,
            child: Eyebrow(l10n.accountsTitle, muted: true),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.link),
            title: Text(l10n.accountsTitle),
            subtitle: Text(l10n.accountsSettingsSubtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.pushNamed(AppRouter.connectedAccountsName),
          ),
        ),
      ],
    );
  }
}
