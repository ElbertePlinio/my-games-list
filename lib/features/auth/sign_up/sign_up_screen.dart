import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:picklog/core/theme/pf_tokens.dart';
import 'package:picklog/core/theme/picklog_colors.dart';
import 'package:picklog/core/utils/app_router.dart';
import 'package:picklog/core/utils/l10n_extensions.dart';
import 'package:picklog/core/utils/messages_extensions.dart';
import 'package:picklog/core/widgets/pf_button.dart';
import 'package:picklog/features/auth/bloc/auth_bloc.dart';
import 'package:picklog/features/auth/bloc/auth_event.dart';
import 'package:picklog/features/auth/sign_up/bloc/sign_up_bloc.dart';
import 'package:picklog/features/auth/sign_up/bloc/sign_up_event.dart';
import 'package:picklog/features/auth/sign_up/bloc/sign_up_state.dart';
import 'package:picklog/features/auth/widgets/auth_layout.dart';
import 'package:picklog/features/legal/presentation/legal_acceptance_checkbox.dart';
import 'package:validatorless/validatorless.dart';

/// SignUp screen for new user registration.
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptedTerms = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleSignUp() {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (isValid) {
      context.read<SignUpBloc>().add(
        SignUpSubmitted(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          username: _usernameController.text.trim(),
          acceptedTerms: _acceptedTerms,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SignUpBloc, SignUpState>(
      listener: (context, state) {
        if (state is SignUpSuccess) {
          // Update global auth state with authenticated user
          context.read<AuthBloc>().add(
            AuthUserAuthenticated(state.authResponse.user),
          );
          // Navigate to home on success
          context.goNamed(AppRouter.homeName);
        } else if (state is SignUpError) {
          // Show error message
          context.showErrorMessage(state.message);
        } else if (state is SignUpTermsNotAccepted) {
          // Defensive: the button is disabled until acceptance, but surface a
          // localized prompt if a submission still arrives unaccepted.
          context.showErrorMessage(context.l10n.signUpAcceptRequired);
        }
      },
      child: Form(
        key: _formKey,
        child: AuthLayout(
          eyebrow: context.l10n.signUpEyebrow,
          title: context.l10n.signUpBodyTitle,
          subtitle: context.l10n.signUpSubtitle,
          children: [
            // Username Field
            TextFormField(
              controller: _usernameController,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: context.l10n.usernameLabel,
                hintText: context.l10n.usernameHint,
                prefixIcon: const Icon(Icons.person_outline),
              ),
              validator: Validatorless.multiple([
                Validatorless.required(context.l10n.usernameRequired),
                Validatorless.min(3, context.l10n.usernameMinLength),
                Validatorless.max(20, context.l10n.usernameMaxLength),
              ]),
            ),
            const SizedBox(height: PfSpace.lg),

            // Email Field
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
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

            // Password Field
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: context.l10n.passwordLabel,
                hintText: context.l10n.passwordCreateHint,
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
                Validatorless.required(context.l10n.passwordRequired),
                Validatorless.min(6, context.l10n.passwordMinLength),
              ]),
            ),
            const SizedBox(height: PfSpace.lg),

            // Confirm Password Field
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _handleSignUp(),
              decoration: InputDecoration(
                labelText: context.l10n.confirmPasswordLabel,
                hintText: context.l10n.confirmPasswordHint,
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                ),
              ),
              validator: Validatorless.multiple([
                Validatorless.required(context.l10n.confirmPasswordRequired),
                Validatorless.compare(
                  _passwordController,
                  context.l10n.passwordMismatch,
                ),
              ]),
            ),
            const SizedBox(height: PfSpace.lg),

            // Required Privacy Policy / Terms acceptance gate
            LegalAcceptanceCheckbox(
              value: _acceptedTerms,
              onChanged: (value) => setState(() => _acceptedTerms = value),
            ),
            const SizedBox(height: PfSpace.lg),

            // Sign Up Button — disabled until the user accepts the
            // Privacy Policy and Terms.
            BlocBuilder<SignUpBloc, SignUpState>(
              builder: (context, state) {
                final isLoading = state is SignUpLoading;
                return PfButton(
                  label: context.l10n.signUpButton,
                  isBusy: isLoading,
                  onPressed: _acceptedTerms ? _handleSignUp : null,
                  size: PfButtonSize.lg,
                  expand: true,
                );
              },
            ),
            const SizedBox(height: PfSpace.lg),

            // Sign In Link
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  context.l10n.alreadyHaveAccount,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: context.pfColors.textMed,
                  ),
                ),
                TextButton(
                  onPressed: () => context.go(AppRouter.signInPath),
                  child: Text(context.l10n.signInLink),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
