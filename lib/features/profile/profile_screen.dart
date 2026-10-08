import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:picklog/core/theme/pf_tokens.dart';
import 'package:picklog/core/theme/picklog_colors.dart';
import 'package:picklog/core/utils/app_router.dart';
import 'package:picklog/core/utils/l10n_extensions.dart';
import 'package:picklog/core/widgets/app_scaffold.dart';
import 'package:picklog/core/widgets/section_header.dart';
import 'package:picklog/core/widgets/state_views.dart';
import 'package:picklog/features/auth/bloc/auth_bloc.dart';
import 'package:picklog/features/auth/bloc/auth_state.dart';

/// Profile screen: avatar, name and account details.
///
/// The gear in the app bar opens Settings. Content is width-capped on wide
/// screens. Stats and achievements will slot in under the details card.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.profileTitle),
        actions: [
          IconButton(
            key: const Key('profile_settings_button'),
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(AppRouter.settingsPath),
            tooltip: context.l10n.settingsTitle,
          ),
          const SizedBox(width: PfSpace.xs),
        ],
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is! AuthAuthenticated) {
            // Fallback for non-authenticated state (shouldn't normally happen)
            return EmptyState(
              icon: Icons.person_off_outlined,
              title: context.l10n.noUserInfo,
            );
          }
          final user = state.user;
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              PfSpace.lg,
              PfSpace.xs,
              PfSpace.lg,
              PfSpace.xxl,
            ),
            child: MaxWidthBox(
              maxWidth: PfBreakpoints.narrow,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Eyebrow(context.l10n.profileEyebrow),
                  const SizedBox(height: PfSpace.xl),
                  _ProfileHeader(name: user.name, email: user.email),
                  const SizedBox(height: PfSpace.xl),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(PfSpace.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _InfoRow(
                            icon: Icons.alternate_email,
                            label: context.l10n.usernameLabel,
                            value: user.name,
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: PfSpace.md),
                            child: Divider(),
                          ),
                          _InfoRow(
                            icon: Icons.mail_outline,
                            label: context.l10n.emailLabel,
                            value: user.email,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.name, required this.email});

  final String name;
  final String email;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.pfColors;
    final trimmed = name.trim();
    final initial = trimmed.isEmpty ? '?' : trimmed[0].toUpperCase();

    return Row(
      children: [
        Container(
          width: 80,
          height: 80,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colors.ember.withValues(alpha: colors.isDark ? 0.16 : 0.14),
            border: Border.all(color: colors.ember.withValues(alpha: 0.35)),
            boxShadow: colors.glowSoft,
          ),
          child: ExcludeSemantics(
            child: Text(
              initial,
              style: theme.textTheme.displaySmall!.copyWith(
                color: colors.emberFg,
              ),
            ),
          ),
        ),
        const SizedBox(width: PfSpace.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: theme.textTheme.headlineLarge,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: PfSpace.xs),
              Text(
                email,
                style: theme.textTheme.bodyMedium!.copyWith(
                  color: colors.textMed,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.pfColors;
    return Row(
      children: [
        Icon(icon, size: 20, color: colors.textMed),
        const SizedBox(width: PfSpace.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Eyebrow(label, muted: true),
              const SizedBox(height: 2),
              Text(value, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ),
      ],
    );
  }
}
