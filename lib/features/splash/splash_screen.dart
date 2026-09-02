import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:picklog/core/data/services/storage/local_storage_service.dart';
import 'package:picklog/core/utils/app_router.dart';
import 'package:picklog/core/utils/l10n_extensions.dart';
import 'package:picklog/core/utils/service_locator.dart';
import 'package:picklog/core/widgets/brand_logo.dart';
import 'package:picklog/features/auth/bloc/auth_bloc.dart';
import 'package:picklog/features/auth/bloc/auth_event.dart';
import 'package:picklog/features/auth/bloc/auth_state.dart';
import 'package:picklog/features/onboarding/onboarding_service.dart';

/// Splash screen that checks authentication status before navigating to the app.
///
/// Behavior:
/// - Shows app branding (name + icon) for minimum 800ms
/// - Waits for AuthBloc to load authentication state
/// - On first launch (onboarding not completed) → navigates to /onboarding,
///   which then forwards to the auth-resolved destination below
/// - If authenticated → navigates to /home
/// - If not authenticated or error → navigates to /signin
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const Duration _minDisplayDuration = Duration(milliseconds: 800);

  DateTime? _splashStartTime;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _splashStartTime = DateTime.now();
    _startAuthCheck();
  }

  void _startAuthCheck() {
    // Trigger auth state load from storage
    context.read<AuthBloc>().add(const AuthStateLoaded());
  }

  Future<void> _handleNavigation(String path) async {
    if (_hasNavigated) return;

    // First launch shows onboarding once before the normal destination.
    // Resolve the flag before honoring the minimum splash duration so both the
    // storage read and the branding delay overlap.
    final showOnboarding = !await _onboardingService.isCompleted();

    // Ensure minimum display duration
    final elapsed = DateTime.now().difference(_splashStartTime!);
    if (elapsed < _minDisplayDuration) {
      await Future.delayed(_minDisplayDuration - elapsed);
    }

    if (!mounted) return;

    _hasNavigated = true;
    context.go(showOnboarding ? AppRouter.onboardingPath : path);
  }

  /// Lazily resolved so the splash works whether or not the onboarding route
  /// has been visited yet; registration is idempotent.
  OnboardingService get _onboardingService {
    if (!sl.isRegistered<OnboardingService>()) {
      sl.registerLazySingleton<OnboardingService>(
        () => OnboardingService(sl<LocalStorageService>()),
      );
    }
    return sl<OnboardingService>();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          _handleNavigation(AppRouter.homePath);
        } else if (state is AuthUnauthenticated) {
          _handleNavigation(AppRouter.signInPath);
        } else if (state is AuthError) {
          // Treat auth errors as unauthenticated
          _handleNavigation(AppRouter.signInPath);
        }
      },
      child: Scaffold(
        body: SafeArea(child: Center(child: _buildSplashView())),
      ),
    );
  }

  Widget _buildSplashView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // App Icon
        const BrandLogo(size: 120),
        const SizedBox(height: 24),

        // App Name
        Text(
          context.l10n.appTitle,
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 48),

        // Loading indicator
        CircularProgressIndicator(color: Theme.of(context).colorScheme.primary),
      ],
    );
  }
}
