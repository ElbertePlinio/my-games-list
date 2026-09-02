import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:picklog/core/utils/app_router.dart';
import 'package:picklog/core/utils/l10n_extensions.dart';
import 'package:picklog/core/utils/messages_extensions.dart';
import 'package:picklog/features/auth/bloc/auth_bloc.dart';
import 'package:picklog/features/auth/bloc/auth_event.dart';
import 'package:picklog/features/auth/bloc/auth_state.dart';
import 'package:picklog/features/consent/widgets/consent_settings_section.dart';
import 'package:picklog/features/settings/bloc/account_management_bloc.dart';
import 'package:picklog/features/settings/bloc/account_management_event.dart';
import 'package:picklog/features/settings/bloc/account_management_state.dart';
import 'package:picklog/features/settings/bloc/settings_bloc.dart';
import 'package:picklog/features/settings/bloc/settings_event.dart';
import 'package:picklog/features/settings/bloc/settings_state.dart';
import 'package:picklog/features/settings/widgets/delete_account_dialog.dart';

// Language autonyms — shown in their own language, intentionally not localized.
const List<({String code, String name})> _languageOptions = [
  (code: 'en', name: 'English'),
  (code: 'pt', name: 'Português'),
];

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // AuthBloc and SettingsBloc are already provided at the app level;
    // AccountManagementBloc is provided by the settings route.
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.settingsTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Info Section
              const _UserInfoSection(),
              const SizedBox(height: 24),

              // Theme Settings Section
              Text(
                context.l10n.appearanceTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              BlocBuilder<SettingsBloc, SettingsState>(
                builder: (context, state) {
                  return Card(
                    child: SwitchListTile(
                      title: Text(context.l10n.darkModeTitle),
                      subtitle: Text(context.l10n.darkModeSubtitle),
                      value: state.isDarkMode,
                      onChanged: (value) => context.read<SettingsBloc>().add(
                        SettingsDarkModeSet(value),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Language Settings Section
              const _LanguageSection(),
              const SizedBox(height: 24),

              // Privacy & data Section (LGPD: export + delete), with the
              // per-category consent toggles grouped directly under it so the two
              // read as one privacy area rather than two competing sections.
              const _PrivacyDataSection(),
              const SizedBox(height: 8),
              const ConsentSettingsSection(),
              const SizedBox(height: 24),

              // Legal Section — Privacy Policy & Terms documents
              const _LegalSection(),
              const SizedBox(height: 24),

              // Logout Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Logout teardown (token + per-user in-memory state) is
                    // handled centrally by AuthBloc via SessionResetService.
                    context.read<AuthBloc>().add(const AuthLogoutRequested());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(context.l10n.logoutButton),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrivacyDataSection extends StatelessWidget {
  const _PrivacyDataSection();

  @override
  Widget build(BuildContext context) {
    return BlocListener<AccountManagementBloc, AccountManagementState>(
      listenWhen: (previous, current) =>
          previous.exportStatus != current.exportStatus ||
          previous.deleteStatus != current.deleteStatus,
      listener: _onStateChanged,
      child: BlocBuilder<AccountManagementBloc, AccountManagementState>(
        builder: (context, state) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.privacyDataTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: [
                    Builder(
                      builder: (tileContext) => ListTile(
                        leading: const Icon(Icons.download_outlined),
                        title: Text(context.l10n.exportDataTitle),
                        subtitle: Text(context.l10n.exportDataSubtitle),
                        trailing:
                            state.exportStatus == AccountActionStatus.loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.chevron_right),
                        onTap: state.isBusy
                            ? null
                            : () => context.read<AccountManagementBloc>().add(
                                AccountManagementExportRequested(
                                  sharePositionOrigin: _shareOrigin(
                                    tileContext,
                                  ),
                                ),
                              ),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(
                        Icons.delete_forever_outlined,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      title: Text(
                        context.l10n.deleteAccountTitle,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                      subtitle: Text(context.l10n.deleteAccountSubtitle),
                      trailing:
                          state.deleteStatus == AccountActionStatus.loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : null,
                      onTap: state.isBusy
                          ? null
                          : () => _confirmDelete(context),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// The screen-space rect of the tapped tile, used to anchor the iPad share
  /// sheet. Returns null if the render box isn't available yet (share_plus
  /// tolerates a null origin on non-iPad platforms).
  Rect? _shareOrigin(BuildContext context) {
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  void _onStateChanged(BuildContext context, AccountManagementState state) {
    if (state.exportStatus == AccountActionStatus.success) {
      context.showSuccessMessage(context.l10n.exportDataSuccess);
    } else if (state.exportStatus == AccountActionStatus.failure) {
      context.showErrorMessage(context.l10n.exportDataError);
    }

    if (state.deleteStatus == AccountActionStatus.success) {
      // Tear down the session the same way logout does, then the router
      // redirects to sign-in once AuthUnauthenticated is emitted.
      context.read<AuthBloc>().add(const AuthLogoutRequested());
    } else if (state.deleteStatus == AccountActionStatus.failure) {
      context.showErrorMessage(context.l10n.deleteAccountError);
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final bloc = context.read<AccountManagementBloc>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => const DeleteAccountDialog(),
    );

    if (confirmed ?? false) {
      bloc.add(const AccountManagementDeleteRequested());
    }
  }
}

class _LegalSection extends StatelessWidget {
  const _LegalSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.legalTitle,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: Text(context.l10n.privacyPolicyTitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.pushNamed(AppRouter.privacyPolicyName),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.description_outlined),
                title: Text(context.l10n.termsTitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.pushNamed(AppRouter.termsName),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Full-width profile header: avatar (name initial) + name + email.
class _UserInfoSection extends StatelessWidget {
  const _UserInfoSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.userInformationTitle,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            final user = state is AuthAuthenticated ? state.user : null;
            final name = user?.name ?? context.l10n.unknown;
            final email = user?.email ?? context.l10n.unknown;
            final trimmed = name.trim();
            final initial = trimmed.isEmpty
                ? '?'
                : trimmed.substring(0, 1).toUpperCase();
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Text(
                        initial,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            email,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Language preference: a clean tappable row (no dropdown underline) that opens
/// a bottom-sheet picker. System follows the device language.
class _LanguageSection extends StatelessWidget {
  const _LanguageSection();

  String _displayName(BuildContext context, String? code) {
    for (final option in _languageOptions) {
      if (option.code == code) return option.name;
    }
    return context.l10n.languageSystem;
  }

  Future<void> _openPicker(BuildContext context, String? current) {
    final bloc = context.read<SettingsBloc>();
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    context.l10n.languageTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              _LanguageOptionTile(
                label: context.l10n.languageSystem,
                selected: current == null,
                onTap: () {
                  bloc.add(const SettingsLocaleSet(null));
                  Navigator.of(sheetContext).pop();
                },
              ),
              for (final option in _languageOptions)
                _LanguageOptionTile(
                  label: option.name,
                  selected: current == option.code,
                  onTap: () {
                    bloc.add(SettingsLocaleSet(option.code));
                    Navigator.of(sheetContext).pop();
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.languageTitle,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        BlocBuilder<SettingsBloc, SettingsState>(
          builder: (context, state) {
            return Card(
              child: ListTile(
                leading: const Icon(Icons.language),
                title: Text(context.l10n.languageTitle),
                subtitle: Text(_displayName(context, state.localeCode)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _openPicker(context, state.localeCode),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _LanguageOptionTile extends StatelessWidget {
  const _LanguageOptionTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      title: Text(
        label,
        style: selected
            ? TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              )
            : null,
      ),
      trailing: selected
          ? Icon(Icons.check, color: theme.colorScheme.primary)
          : null,
      onTap: onTap,
    );
  }
}
