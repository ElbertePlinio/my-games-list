import 'dart:async';
import 'dart:ui';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router/go_router.dart';
import 'package:picklog/core/services/connectivity_cubit.dart';
import 'package:picklog/core/services/consent/consent_service.dart';
import 'package:picklog/core/services/consent/push_registration_coordinator.dart';
import 'package:picklog/core/services/notification_service.dart';
import 'package:picklog/core/theme/app_theme.dart';
import 'package:picklog/core/utils/app_router.dart';
import 'package:picklog/core/utils/env.dart';
import 'package:picklog/core/utils/l10n_extensions.dart';
import 'package:picklog/core/utils/service_locator.dart';
import 'package:picklog/core/widgets/app_error_boundary.dart';
import 'package:picklog/core/widgets/offline_banner.dart';
import 'package:picklog/features/consent/bloc/consent_cubit.dart';
import 'package:picklog/features/consent/widgets/consent_banner.dart';
import 'package:picklog/features/auth/bloc/auth_bloc.dart';
import 'package:picklog/features/auth/bloc/auth_event.dart';
import 'package:picklog/features/settings/bloc/settings_bloc.dart';
import 'package:picklog/features/settings/bloc/settings_event.dart';
import 'package:picklog/features/settings/bloc/settings_state.dart';
import 'package:picklog/firebase_options_production.dart';
import 'package:picklog/firebase_options_staging.dart';
import 'package:picklog/l10n/app_localizations.dart';

/// Firebase options for the active build flavor.
FirebaseOptions get _firebaseOptions => Env.isProduction
    ? ProductionFirebaseOptions.currentPlatform
    : StagingFirebaseOptions.currentPlatform;

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: _firebaseOptions);
}

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Clean path-based URLs on web (/home instead of /#/home) for deep links + SEO.
  if (kIsWeb) usePathUrlStrategy();

  // Firebase MUST finish initializing before the service locator runs:
  // setupServiceLocator() loads persisted consent, which applies each
  // collector's state through the gateway and touches
  // FirebaseCrashlytics.instance. Touching it before the default Firebase app
  // exists aborts launch, so these cannot run concurrently. Consent application
  // leaves every collector disabled until the user grants it.
  await Firebase.initializeApp(options: _firebaseOptions);
  await setupServiceLocator();

  // Error hooks are always installed but route through ConsentService, so they
  // no-op until crash-reporting consent is granted (LGPD). The check is read at
  // report time, so revoking consent stops reporting immediately.
  final consent = sl<ConsentService>();
  FlutterError.onError = (details) {
    unawaited(consent.reportFlutterError(details));
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    unawaited(consent.reportError(error, stack, fatal: true));
    return true;
  };

  // Friendly fallback for widget build errors in production; the error is still
  // reported above when consent allows. Debug keeps Flutter's red error screen.
  if (!kDebugMode) {
    ErrorWidget.builder = (_) => const AppErrorBoundary();
  }

  // Register FCM background message handler (mobile only; not supported on web).
  if (!kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  // Run the app
  runApp(const PicklogApp());
}

class PicklogApp extends StatefulWidget {
  const PicklogApp({super.key});

  @override
  State<PicklogApp> createState() => _PicklogAppState();
}

class _PicklogAppState extends State<PicklogApp> {
  late final AuthBloc authBloc;
  late final SettingsBloc settingsBloc;
  late final ConsentCubit consentCubit;
  late final GoRouter router;
  late final PushRegistrationCoordinator _pushCoordinator;
  StreamSubscription<String>? _notificationNavSubscription;

  @override
  void initState() {
    super.initState();
    // Initialize global BLoCs
    authBloc = sl<AuthBloc>()..add(const AuthStateLoaded());
    settingsBloc = sl<SettingsBloc>()..add(const SettingsInitialized());
    consentCubit = sl<ConsentCubit>();
    // Create router once to avoid recreation on theme changes
    router = AppRouter.createRouter();

    _initNotifications();
  }

  void _initNotifications() {
    final notificationService = sl<NotificationService>();

    // Forward notification tap routes to the GoRouter.
    _notificationNavSubscription = notificationService.navigationStream.listen(
      (route) => router.go(route),
    );

    // FCM is no longer started at cold start. The coordinator registers the
    // token only once push consent is granted AND the user is authenticated
    // (LGPD), which also fixes the unauthenticated PATCH /users/me/fcm-token
    // 401 that fired on every launch.
    _pushCoordinator = sl<PushRegistrationCoordinator>()..start();
  }

  @override
  void dispose() {
    _notificationNavSubscription?.cancel();
    _pushCoordinator.dispose();
    sl<NotificationService>().dispose();
    // Note: These are singletons, but we close them here when the app terminates
    authBloc.close();
    settingsBloc.close();
    consentCubit.close();
    super.dispose();
  }

  // Built once (ColorScheme.fromSeed is not free) and reused, so a settings
  // change doesn't rebuild the theme palette on every render.
  static final ThemeData _lightTheme = AppTheme.light();
  static final ThemeData _darkTheme = AppTheme.dark();

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: authBloc),
        BlocProvider.value(value: settingsBloc),
        BlocProvider.value(value: consentCubit),
        BlocProvider(create: (_) => ConnectivityCubit(Connectivity())),
      ],
      child: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) {
          return MaterialApp.router(
            onGenerateTitle: (context) => context.l10n.appTitle,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            // null = follow the device locale; a code = the user's choice.
            locale: state.localeCode == null ? null : Locale(state.localeCode!),
            localeResolutionCallback: (deviceLocale, supportedLocales) {
              // Use the chosen/device language when supported; otherwise
              // default to pt for the Brazilian launch.
              for (final supported in supportedLocales) {
                if (supported.languageCode == deviceLocale?.languageCode) {
                  return supported;
                }
              }
              return const Locale('pt');
            },
            routerConfig: router,
            theme: _lightTheme,
            darkTheme: _darkTheme,
            themeMode: state.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            builder: (context, child) => ConsentBanner(
              child: OfflineBanner(child: child ?? const SizedBox.shrink()),
            ),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
