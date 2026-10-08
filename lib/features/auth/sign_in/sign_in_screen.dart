import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:picklog/core/theme/pf_tokens.dart';
import 'package:picklog/core/theme/picklog_colors.dart';
import 'package:picklog/core/utils/app_router.dart';
import 'package:picklog/core/utils/l10n_extensions.dart';
import 'package:picklog/core/utils/messages_extensions.dart';
import 'package:picklog/core/widgets/google_sign_in_button.dart';
import 'package:picklog/core/widgets/pf_button.dart';
import 'package:picklog/core/widgets/status_pill.dart';
import 'package:picklog/features/auth/bloc/auth_bloc.dart';
import 'package:picklog/features/auth/bloc/auth_event.dart';
import 'package:picklog/features/auth/sign_in/bloc/sign_in_bloc.dart';
import 'package:picklog/features/auth/sign_in/bloc/sign_in_event.dart';
import 'package:picklog/features/auth/sign_in/bloc/sign_in_state.dart';
import 'package:picklog/features/auth/widgets/auth_layout.dart';
import 'package:validatorless/validatorless.dart';

/// SignIn screen with email/password authentication.
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _showEmailForm = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleSignIn() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<SignInBloc>().add(
        SignInSubmitted(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.pfColors;

    return BlocListener<SignInBloc, SignInState>(
      listener: (context, state) {
        if (state is SignInSuccess) {
          // Update global auth state with authenticated user
          context.read<AuthBloc>().add(
            AuthUserAuthenticated(state.authResponse.user),
          );
          // Navigate to home on success
          context.goNamed(AppRouter.homeName);
        } else if (state is SignInError) {
          // Show error message
          context.showErrorMessage(state.message);
        }
      },
      child: Form(
        key: _formKey,
        child: AuthLayout(
          eyebrow: context.l10n.signInEyebrow,
          title: context.l10n.signInHeadline,
          subtitle: context.l10n.signInSubtitle,
          children: [
            // Primary path: Google sign-in comes first and is badged so
            // it reads as the preferred, recommended option.
            const _RecommendedBadge(),
            const SizedBox(height: PfSpace.md),
            BlocBuilder<SignInBloc, SignInState>(
              builder: (context, state) {
                final isLoading = state is SignInLoading;
                return GoogleSignInButton(
                  label: context.l10n.signInWithGoogle,
                  onPressed: isLoading
                      ? null
                      : () => context.read<SignInBloc>().add(
                          const GoogleSignInRequested(),
                        ),
                );
              },
            ),
            const SizedBox(height: PfSpace.md),

            // Secondary path, collapsed by default so "Continue with
            // Google" stays the single dominant call to action. Tapping
            // reveals the email/password fields + Sign In button.
            Center(
              child: TextButton.icon(
                onPressed: () =>
                    setState(() => _showEmailForm = !_showEmailForm),
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.onSurfaceVariant,
                ),
                icon: Icon(
                  _showEmailForm ? Icons.expand_less : Icons.expand_more,
                  size: 18,
                ),
                label: Text(context.l10n.signInWithEmail),
              ),
            ),
            AnimatedSize(
              duration: PfMotion.of(context, PfMotion.standard),
              curve: PfMotion.forge,
              alignment: Alignment.topCenter,
              child: !_showEmailForm
                  ? const SizedBox(width: double.infinity)
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: PfSpace.sm),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.email],
                          decoration: InputDecoration(
                            labelText: context.l10n.emailLabel,
                            hintText: context.l10n.emailHint,
                            prefixIcon: const Icon(Icons.email_outlined),
                          ),
                          validator: Validatorless.multiple([
                            Validatorless.required(context.l10n.emailRequired),
                            Validatorless.email(context.l10n.emailInvalid),
                          ]),
                        ),
                        const SizedBox(height: PfSpace.lg),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.password],
                          onFieldSubmitted: (_) => _handleSignIn(),
                          decoration: InputDecoration(
                            labelText: context.l10n.passwordLabel,
                            hintText: context.l10n.passwordHint,
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                          validator: Validatorless.multiple([
                            Validatorless.required(
                              context.l10n.passwordRequired,
                            ),
                            Validatorless.min(
                              6,
                              context.l10n.passwordMinLength,
                            ),
                          ]),
                        ),
                        const SizedBox(height: PfSpace.xl),

                        // Email sign in is the secondary CTA (Google is
                        // primary), so it uses the outlined pill.
                        BlocBuilder<SignInBloc, SignInState>(
                          builder: (context, state) {
                            return PfButton(
                              label: context.l10n.signInButton,
                              variant: PfButtonVariant.secondary,
                              isBusy: state is SignInLoading,
                              onPressed: _handleSignIn,
                              expand: true,
                            );
                          },
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: PfSpace.lg),

            // Sign Up Link
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  context.l10n.noAccount,
                  style: theme.textTheme.bodyMedium!.copyWith(
                    color: colors.textMed,
                  ),
                ),
                TextButton(
                  onPressed: () => context.go(AppRouter.signUpPath),
                  child: Text(context.l10n.signUpLink),
                ),
              ],
            ),
            const SizedBox(height: PfSpace.lg),
            Divider(color: colors.hairline),
            const SizedBox(height: PfSpace.md),

            // Legal notice: continuing (incl. Google) implies acceptance
            // of the Privacy Policy and Terms, both reachable below.
            Text(
              context.l10n.signInLegalNotice,
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                TextButton(
                  onPressed: () =>
                      context.pushNamed(AppRouter.privacyPolicyName),
                  style: TextButton.styleFrom(foregroundColor: colors.textMed),
                  child: Text(context.l10n.privacyPolicyTitle),
                ),
                Text(
                  context.l10n.signUpAcceptConjunction,
                  style: theme.textTheme.bodySmall,
                ),
                TextButton(
                  onPressed: () => context.pushNamed(AppRouter.termsName),
                  style: TextButton.styleFrom(foregroundColor: colors.textMed),
                  child: Text(context.l10n.termsTitle),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Small pill that marks Google as the recommended sign-in option.
class _RecommendedBadge extends StatelessWidget {
  const _RecommendedBadge();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: StatusPill(
        label: context.l10n.recommended,
        tone: PfTone.neutral,
        icon: Icons.verified_outlined,
      ),
    );
  }
}
