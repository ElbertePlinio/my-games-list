import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:picklog/core/utils/app_router.dart';
import 'package:picklog/core/utils/l10n_extensions.dart';
import 'package:picklog/core/utils/messages_extensions.dart';
import 'package:picklog/core/widgets/brand_logo.dart';
import 'package:picklog/core/widgets/google_sign_in_button.dart';
import 'package:picklog/features/auth/bloc/auth_bloc.dart';
import 'package:picklog/features/auth/bloc/auth_event.dart';
import 'package:picklog/features/auth/sign_in/bloc/sign_in_bloc.dart';
import 'package:picklog/features/auth/sign_in/bloc/sign_in_event.dart';
import 'package:picklog/features/auth/sign_in/bloc/sign_in_state.dart';
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
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.l10n.signInTitle),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // App Title/Logo
                    const Center(child: BrandLogo(size: 88)),
                    const SizedBox(height: 20),
                    Text(
                      context.l10n.appTitle,
                      style: theme.textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.l10n.signInSubtitle,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    // Primary path: Google sign-in comes first and is badged so
                    // it reads as the preferred, recommended option.
                    const _RecommendedBadge(),
                    const SizedBox(height: 12),
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
                    const SizedBox(height: 8),

                    // Secondary path, collapsed by default so "Continue with
                    // Google" stays the single dominant call to action. Tapping
                    // reveals the email/password fields + Sign In button.
                    Center(
                      child: TextButton.icon(
                        onPressed: () =>
                            setState(() => _showEmailForm = !_showEmailForm),
                        style: TextButton.styleFrom(
                          foregroundColor: theme.colorScheme.onSurfaceVariant,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                        icon: Icon(
                          _showEmailForm
                              ? Icons.expand_less
                              : Icons.expand_more,
                          size: 18,
                        ),
                        label: Text(context.l10n.signInWithEmail),
                      ),
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeInOut,
                      alignment: Alignment.topCenter,
                      child: !_showEmailForm
                          ? const SizedBox(width: double.infinity)
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const SizedBox(height: 8),

                                // Email Field
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  decoration: InputDecoration(
                                    labelText: context.l10n.emailLabel,
                                    hintText: context.l10n.emailHint,
                                    prefixIcon: const Icon(
                                      Icons.email_outlined,
                                    ),
                                  ),
                                  validator: Validatorless.multiple([
                                    Validatorless.required(
                                      context.l10n.emailRequired,
                                    ),
                                    Validatorless.email(
                                      context.l10n.emailInvalid,
                                    ),
                                  ]),
                                ),
                                const SizedBox(height: 16),

                                // Password Field
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  textInputAction: TextInputAction.done,
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
                                const SizedBox(height: 24),

                                // Email Sign In Button (secondary CTA — Google is primary,
                                // so this uses the muted tonal style).
                                BlocBuilder<SignInBloc, SignInState>(
                                  builder: (context, state) {
                                    final isLoading = state is SignInLoading;

                                    return FilledButton.tonal(
                                      onPressed: isLoading
                                          ? null
                                          : _handleSignIn,
                                      child: isLoading
                                          ? const SizedBox(
                                              height: 20,
                                              width: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : Text(context.l10n.signInButton),
                                    );
                                  },
                                ),
                              ],
                            ),
                    ),
                    const SizedBox(height: 16),

                    // Sign Up Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(context.l10n.noAccount),
                        TextButton(
                          onPressed: () => context.go(AppRouter.signUpPath),
                          child: Text(
                            context.l10n.signUpLink,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Legal notice: continuing (incl. Google) implies acceptance
                    // of the Privacy Policy and Terms, both reachable below.
                    Text(
                      context.l10n.signInLegalNotice,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () =>
                              context.pushNamed(AppRouter.privacyPolicyName),
                          child: Text(context.l10n.privacyPolicyTitle),
                        ),
                        Text(context.l10n.signUpAcceptConjunction),
                        TextButton(
                          onPressed: () =>
                              context.pushNamed(AppRouter.termsName),
                          child: Text(context.l10n.termsTitle),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
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
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            // Quiet neutral surface so the pill reads as an endorsement label,
            // not a second call-to-action competing with the Google button.
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.verified, size: 15, color: theme.colorScheme.primary),
              const SizedBox(width: 6),
              Text(
                context.l10n.recommended,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
