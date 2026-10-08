import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:picklog/core/data/services/storage/local_storage_service.dart';
import 'package:picklog/core/utils/app_router.dart';
import 'package:picklog/core/utils/l10n_extensions.dart';
import 'package:picklog/core/utils/service_locator.dart';
import 'package:picklog/core/theme/pf_tokens.dart';
import 'package:picklog/core/theme/picklog_colors.dart';
import 'package:picklog/core/widgets/brand_mark.dart';
import 'package:picklog/core/widgets/section_header.dart';
import 'package:picklog/features/auth/bloc/auth_bloc.dart';
import 'package:picklog/features/auth/bloc/auth_event.dart';
import 'package:picklog/features/auth/bloc/auth_state.dart';
import 'package:picklog/features/onboarding/onboarding_service.dart';

/// Splash screen that checks authentication status before navigating to the app.
///
/// Behavior:
/// - Shows the animated Picklog mark for a minimum of 800ms
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
      child: const Scaffold(
        body: SafeArea(child: Center(child: _SplashMark())),
      ),
    );
  }
}

/// Mark reveal: the mark settles in from a slight scale, then the word and
/// tagline fade up. Static under reduced motion.
class _SplashMark extends StatefulWidget {
  const _SplashMark();

  @override
  State<_SplashMark> createState() => _SplashMarkState();
}

class _SplashMarkState extends State<_SplashMark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: PfMotion.reveal,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (PfMotion.reduced(context)) {
      _controller.value = 1;
    } else if (_controller.isDismissed) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.pfColors;
    final mark = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.7, curve: PfMotion.forge),
    );
    final text = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.35, 1, curve: PfMotion.forge),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FadeTransition(
          opacity: mark,
          child: ScaleTransition(
            scale: Tween(begin: 0.9, end: 1.0).animate(mark),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                boxShadow: colors.glowSoft,
              ),
              child: BrandMark(size: 112, semanticLabel: context.l10n.appTitle),
            ),
          ),
        ),
        const SizedBox(height: PfSpace.xl),
        FadeTransition(
          opacity: text,
          child: SlideTransition(
            position: Tween(
              begin: const Offset(0, 0.3),
              end: Offset.zero,
            ).animate(text),
            child: Column(
              children: [
                Text(
                  context.l10n.appTitle,
                  style: theme.textTheme.displaySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: PfSpace.sm),
                Eyebrow(context.l10n.splashTagline, muted: true),
              ],
            ),
          ),
        ),
        const SizedBox(height: PfSpace.xxxl),
        const SizedBox(
          width: 96,
          child: ClipRRect(
            borderRadius: PfRadius.pillAll,
            child: LinearProgressIndicator(minHeight: 2),
          ),
        ),
      ],
    );
  }
}
