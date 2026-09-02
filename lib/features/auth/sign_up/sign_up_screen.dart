import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:picklog/core/utils/app_router.dart';
import 'package:picklog/core/utils/l10n_extensions.dart';
import 'package:picklog/core/utils/messages_extensions.dart';
import 'package:picklog/core/widgets/brand_logo.dart';
import 'package:picklog/features/auth/bloc/auth_bloc.dart';
import 'package:picklog/features/auth/bloc/auth_event.dart';
import 'package:picklog/features/auth/sign_up/bloc/sign_up_bloc.dart';
import 'package:picklog/features/auth/sign_up/bloc/sign_up_event.dart';
import 'package:picklog/features/auth/sign_up/bloc/sign_up_state.dart';
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
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.l10n.signUpAppBarTitle),
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
                      context.l10n.signUpBodyTitle,
                      style: Theme.of(context).textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.l10n.signUpSubtitle,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),

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
                    const SizedBox(height: 16),

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
                    const SizedBox(height: 16),

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
                    const SizedBox(height: 16),

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
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword;
                            });
                          },
                        ),
                      ),
                      validator: Validatorless.multiple([
                        Validatorless.required(
                          context.l10n.confirmPasswordRequired,
                        ),
                        Validatorless.compare(
                          _passwordController,
                          context.l10n.passwordMismatch,
                        ),
                      ]),
                    ),
                    const SizedBox(height: 16),

                    // Required Privacy Policy / Terms acceptance gate
                    LegalAcceptanceCheckbox(
                      value: _acceptedTerms,
                      onChanged: (value) =>
                          setState(() => _acceptedTerms = value),
                    ),
                    const SizedBox(height: 16),

                    // Sign Up Button — disabled until the user accepts the
                    // Privacy Policy and Terms.
                    BlocBuilder<SignUpBloc, SignUpState>(
                      builder: (context, state) {
                        final isLoading = state is SignUpLoading;
                        final canSubmit = _acceptedTerms && !isLoading;

                        return FilledButton(
                          onPressed: canSubmit ? _handleSignUp : null,
                          child: isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(context.l10n.signUpButton),
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Sign In Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(context.l10n.alreadyHaveAccount),
                        TextButton(
                          onPressed: () => context.go(AppRouter.signInPath),
                          child: Text(
                            context.l10n.signInLink,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
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
