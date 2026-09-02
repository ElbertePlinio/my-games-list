import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:picklog/core/data/services/http/i_http_client.dart';
import 'package:picklog/core/data/services/storage/local_storage_service.dart';
import 'package:picklog/core/data/services/storage/token_storage.dart';
import 'package:picklog/core/utils/l10n_extensions.dart';
import 'package:picklog/core/utils/service_locator.dart';
import 'package:picklog/core/widgets/bottom_nav_bar.dart';
import 'package:picklog/features/auth/auth_repository.dart';
import 'package:picklog/features/auth/bloc/auth_bloc.dart';
import 'package:picklog/features/auth/bloc/auth_state.dart';
import 'package:picklog/features/auth/sign_in/bloc/sign_in_bloc.dart';
import 'package:picklog/features/auth/sign_in/sign_in_screen.dart';
import 'package:picklog/features/auth/sign_up/bloc/sign_up_bloc.dart';
import 'package:picklog/features/auth/sign_up/sign_up_screen.dart';
import 'package:picklog/features/browse/bloc/browse_genre_games_bloc.dart';
import 'package:picklog/features/browse/bloc/browse_genre_games_event.dart';
import 'package:picklog/features/browse/bloc/browse_genres_bloc.dart';
import 'package:picklog/features/browse/bloc/browse_genres_event.dart';
import 'package:picklog/features/browse/browse_genre_games_screen.dart';
import 'package:picklog/features/browse/browse_screen.dart';
import 'package:picklog/features/games/bloc/anticipated_games_bloc.dart';
import 'package:picklog/features/games/bloc/anticipated_games_event.dart';
import 'package:picklog/features/games/bloc/discovery_games_bloc.dart';
import 'package:picklog/features/games/bloc/discovery_games_event.dart';
import 'package:picklog/features/games/bloc/featured_banners_bloc.dart';
import 'package:picklog/features/games/bloc/featured_banners_event.dart';
import 'package:picklog/features/games/bloc/collections_bloc.dart';
import 'package:picklog/features/games/bloc/collections_event.dart';
import 'package:picklog/features/games/bloc/recommendations_bloc.dart';
import 'package:picklog/features/games/bloc/recommendations_event.dart';
import 'package:picklog/features/games/bloc/game_details_bloc.dart';
import 'package:picklog/features/games/bloc/game_details_event.dart';
import 'package:picklog/features/games/bloc/game_search_bloc.dart';
import 'package:picklog/features/games/discovery_game_model.dart';
import 'package:picklog/features/games/discovery_games_screen.dart';
import 'package:picklog/features/games/game_details_screen.dart';
import 'package:picklog/features/games/game_search_screen.dart';
import 'package:picklog/features/games/games_repository.dart';
import 'package:picklog/features/games/games_screen.dart';
import 'package:picklog/features/games/i_games_repository.dart';
import 'package:picklog/features/games/widgets/video_player_screen.dart';
import 'package:picklog/features/home/home_screen.dart';
import 'package:picklog/features/legal/legal_document.dart';
import 'package:picklog/features/legal/presentation/legal_document_screen.dart';
import 'package:picklog/features/library/bloc/library_bloc.dart';
import 'package:picklog/features/library/bloc/library_event.dart';
import 'package:picklog/features/library/library_repository.dart';
import 'package:picklog/features/onboarding/onboarding_screen.dart';
import 'package:picklog/features/onboarding/onboarding_service.dart';
import 'package:picklog/features/profile/profile_screen.dart';
import 'package:picklog/features/settings/bloc/account_management_bloc.dart';
import 'package:picklog/features/settings/settings_screen.dart';
import 'package:picklog/features/splash/splash_screen.dart';

/// Application router configuration using GoRouter with modular dependency injection.
///
/// Architecture Pattern:
/// - AuthRepository: Lazily registered on first auth route access, stays in memory as singleton
/// - BLoCs: Created per route via BlocProvider, automatically disposed when route is popped
/// - Bottom Navigation: Uses StatefulShellRoute for persistent navigation with state preservation
///
/// This approach provides:
/// - Performance: Auth module not loaded until needed
/// - Memory efficiency: BLoCs are disposed automatically by Flutter
/// - Maintainability: Clear separation of concerns
/// - State preservation: Each bottom nav tab maintains its state when switching
class AppRouter {
  static const String splashPath = '/splash';
  static const String onboardingPath = '/onboarding';
  static const String signInPath = '/signin';
  static const String signUpPath = '/signup';
  static const String homePath = '/home';
  static const String browsePath = '/browse';
  static const String gamesPath = '/games';
  static const String profilePath = '/profile';
  static const String settingsPath = '/settings';
  static const String searchPath = '/search';
  static const String gameDetailsPath = '/games/:id';
  static const String videoPlayerPath = '/video/:videoId';
  static const String discoveryPath = '/discovery/:type';
  static const String genreGamesPath = '/browse/genres/:genreId';
  static const String privacyPolicyPath = '/privacy-policy';
  static const String termsPath = '/terms';

  /// Route names for named navigation
  static const String splashName = 'splash';
  static const String onboardingName = 'onboarding';
  static const String signInName = 'signin';
  static const String signUpName = 'signup';
  static const String homeName = 'home';
  static const String browseName = 'browse';
  static const String gamesName = 'games';
  static const String profileName = 'profile';
  static const String settingsName = 'settings';
  static const String searchName = 'search';
  static const String gameDetailsName = 'gameDetails';
  static const String videoPlayerName = 'videoPlayer';
  static const String discoveryName = 'discovery';
  static const String genreGamesName = 'genreGames';
  static const String privacyPolicyName = 'privacyPolicy';
  static const String termsName = 'terms';

  /// Creates the GoRouter configuration for the app.
  /// Auth-specific dependencies are registered lazily when routes are accessed.
  static GoRouter createRouter() {
    return GoRouter(
      initialLocation: splashPath,
      refreshListenable: GoRouterRefreshStream(sl<AuthBloc>().stream),
      redirect: (context, state) {
        final authState = sl<AuthBloc>().state;
        final isAuthenticated = authState is AuthAuthenticated;
        final currentPath = state.matchedLocation;

        // Splash performs the initial auth + onboarding routing, and the
        // onboarding flow is shown once regardless of auth state. Let both
        // through untouched so the auth redirect below never bounces them.
        if (currentPath == splashPath || currentPath == onboardingPath) {
          return null;
        }

        final isGoingToAuth =
            currentPath == signInPath || currentPath == signUpPath;

        // Legal documents must be reachable before an account exists (linked
        // from the sign-up consent gate), so never bounce them through the
        // auth guard regardless of auth state.
        final isLegalDocument =
            currentPath == privacyPolicyPath || currentPath == termsPath;
        if (isLegalDocument) {
          return null;
        }

        // If authenticated and going to auth pages, redirect to home
        if (isAuthenticated && isGoingToAuth) {
          return homePath;
        }

        // If not authenticated and trying to access protected routes, redirect to signin
        if (!isAuthenticated && !isGoingToAuth) {
          return signInPath;
        }

        // No redirect needed
        return null;
      },
      routes: [
        // Splash Route - Initial loading screen
        GoRoute(
          path: splashPath,
          name: splashName,
          builder: (context, state) => const SplashScreen(),
        ),

        // Onboarding Route - First-run welcome flow (shown once per install)
        GoRoute(
          path: onboardingPath,
          name: onboardingName,
          builder: (context, state) {
            _ensureOnboardingServiceRegistered();

            return OnboardingScreen(
              onboardingService: sl<OnboardingService>(),
              // Destination depends on auth state, which only the router knows.
              onCompleted: () => context.go(_postOnboardingDestination()),
            );
          },
        ),

        // SignIn Route with modular dependency injection
        GoRoute(
          path: signInPath,
          name: signInName,
          builder: (context, state) {
            // Register auth repository lazily (only once, stays in memory)
            _ensureAuthRepositoryRegistered();

            // Provide SignInBloc to the screen (auto-disposed by BlocProvider)
            return BlocProvider(
              create: (_) => SignInBloc(sl<AuthRepository>()),
              child: const SignInScreen(),
            );
          },
        ),

        // SignUp Route with modular dependency injection
        GoRoute(
          path: signUpPath,
          name: signUpName,
          builder: (context, state) {
            // Register auth repository lazily (only once, stays in memory)
            _ensureAuthRepositoryRegistered();

            // Provide SignUpBloc to the screen (auto-disposed by BlocProvider)
            return BlocProvider(
              create: (_) => SignUpBloc(sl<AuthRepository>()),
              child: const SignUpScreen(),
            );
          },
        ),

        // Shell Route for bottom navigation with state preservation
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return BottomNavBar(navigationShell: navigationShell);
          },
          branches: [
            // Home Branch
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: homePath,
                  name: homeName,
                  builder: (context, state) {
                    // Register games repository lazily (only once, stays in memory)
                    _ensureGamesRepositoryRegistered();

                    // Provide the home dashboard blocs (auto-disposed by
                    // BlocProvider).
                    return MultiBlocProvider(
                      providers: [
                        BlocProvider(
                          create: (_) => AnticipatedGamesBloc(
                            gamesRepository: sl<IGamesRepository>(),
                          )..add(const AnticipatedGamesLoadRequested()),
                        ),
                        BlocProvider(
                          create: (_) =>
                              DiscoveryGamesBloc(
                                gamesRepository: sl<IGamesRepository>(),
                              )..add(
                                const DiscoveryGamesLoadRequested(
                                  DiscoveryType.trending,
                                ),
                              ),
                        ),
                        BlocProvider(
                          create: (_) => FeaturedBannersBloc(
                            gamesRepository: sl<IGamesRepository>(),
                          )..add(const FeaturedBannersLoadRequested()),
                        ),
                        BlocProvider(
                          create: (_) => RecommendationsBloc(
                            gamesRepository: sl<IGamesRepository>(),
                          )..add(const RecommendationsLoadRequested()),
                        ),
                        BlocProvider(
                          create: (_) => CollectionsBloc(
                            gamesRepository: sl<IGamesRepository>(),
                          )..add(const CollectionsLoadRequested()),
                        ),
                      ],
                      child: const HomeScreen(),
                    );
                  },
                ),
              ],
            ),

            // Browse Branch (public discovery hub)
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: browsePath,
                  name: browseName,
                  builder: (context, state) {
                    _ensureGamesRepositoryRegistered();

                    // The Browse tab owns its own discovery/collections blocs,
                    // separate from the Home tab's instances, so both can stay
                    // alive in the indexed stack without sharing state.
                    return MultiBlocProvider(
                      providers: [
                        BlocProvider(
                          create: (_) => BrowseGenresBloc(
                            gamesRepository: sl<IGamesRepository>(),
                          )..add(const BrowseGenresLoadRequested()),
                        ),
                        BlocProvider(
                          create: (_) => DiscoveryGamesBloc(
                            gamesRepository: sl<IGamesRepository>(),
                          ),
                        ),
                        BlocProvider(
                          create: (_) => CollectionsBloc(
                            gamesRepository: sl<IGamesRepository>(),
                          )..add(const CollectionsLoadRequested()),
                        ),
                      ],
                      child: const BrowseScreen(),
                    );
                  },
                ),
              ],
            ),

            // Games Branch (User Library)
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: gamesPath,
                  name: gamesName,
                  builder: (context, state) {
                    // Register library repository lazily
                    _ensureLibraryRepositoryAndBlocRegistered();

                    // Get the current user ID from AuthBloc
                    final authState = sl<AuthBloc>().state;
                    final userId = authState is AuthAuthenticated
                        ? authState.user.id
                        : '';

                    // Provide LibraryBloc (auto-disposed by BlocProvider)
                    return BlocProvider.value(
                      value: sl<LibraryBloc>()
                        ..add(LibraryLoadRequested(userId: userId)),
                      child: const GamesScreen(),
                    );
                  },
                ),
              ],
            ),

            // Profile Branch
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: profilePath,
                  name: profileName,
                  builder: (context, state) => const ProfileScreen(),
                ),
              ],
            ),
          ],
        ),

        // Settings Route (outside bottom navigation)
        GoRoute(
          path: settingsPath,
          name: settingsName,
          builder: (context, state) {
            _ensureAuthRepositoryRegistered();
            return BlocProvider(
              create: (_) =>
                  AccountManagementBloc(authRepository: sl<AuthRepository>()),
              child: const SettingsScreen(),
            );
          },
        ),

        // Search Route (outside bottom navigation)
        GoRoute(
          path: searchPath,
          name: searchName,
          builder: (context, state) {
            // Register games repository lazily (only once, stays in memory)
            _ensureGamesRepositoryRegistered();

            // Provide GameSearchBloc to the screen (auto-disposed by BlocProvider)
            return BlocProvider(
              create: (_) =>
                  GameSearchBloc(gamesRepository: sl<IGamesRepository>()),
              child: const GameSearchScreen(),
            );
          },
        ),

        // Privacy Policy Route (outside bottom navigation; reachable while
        // unauthenticated so the sign-up consent gate can link to it)
        GoRoute(
          path: privacyPolicyPath,
          name: privacyPolicyName,
          builder: (context, state) =>
              const LegalDocumentScreen(document: LegalDocument.privacyPolicy),
        ),

        // Terms of Service Route (outside bottom navigation; reachable while
        // unauthenticated so the sign-up consent gate can link to it)
        GoRoute(
          path: termsPath,
          name: termsName,
          builder: (context, state) =>
              const LegalDocumentScreen(document: LegalDocument.terms),
        ),

        // Game Details Route (outside bottom navigation)
        GoRoute(
          path: gameDetailsPath,
          name: gameDetailsName,
          builder: (context, state) {
            final gameIdStr = state.pathParameters['id']!;
            final gameId = int.parse(gameIdStr);
            // Hero tag prefix passed from the source tile (e.g. recommendations
            // row) so the cover transition matches the source card.
            final heroTagPrefix = state.extra is String
                ? state.extra! as String
                : '';

            // Register games repository lazily (only once, stays in memory)
            _ensureGamesRepositoryRegistered();
            _ensureLibraryRepositoryAndBlocRegistered();

            // Provide GameDetailsBloc to the screen (auto-disposed by BlocProvider)
            return MultiBlocProvider(
              providers: [
                BlocProvider(
                  create: (_) =>
                      GameDetailsBloc(gamesRepository: sl<IGamesRepository>())
                        ..add(GameDetailsLoadRequested(gameId)),
                ),
                BlocProvider.value(
                  value: sl<LibraryBloc>()
                    ..add(
                      LibraryLoadRequested(
                        userId:
                            (sl<AuthBloc>().state as AuthAuthenticated).user.id,
                      ),
                    ),
                ),
              ],
              child: GameDetailsScreen(
                gameId: gameId,
                heroTagPrefix: heroTagPrefix,
              ),
            );
          },
        ),

        // Video Player Route (outside bottom navigation)
        GoRoute(
          path: videoPlayerPath,
          name: videoPlayerName,
          builder: (context, state) {
            final videoId = state.pathParameters['videoId']!;
            final title = state.uri.queryParameters['title'];

            return VideoPlayerScreen(videoId: videoId, title: title);
          },
        ),

        // Discovery Games Route (outside bottom navigation)
        GoRoute(
          path: discoveryPath,
          name: discoveryName,
          builder: (context, state) {
            final typeParam = state.pathParameters['type']!;
            final discoveryType = DiscoveryType.fromQueryParam(typeParam);

            // Register games repository lazily (only once, stays in memory)
            _ensureGamesRepositoryRegistered();

            // Provide DiscoveryGamesBloc to the screen (auto-disposed by BlocProvider)
            return BlocProvider(
              create: (_) =>
                  DiscoveryGamesBloc(gamesRepository: sl<IGamesRepository>())
                    ..add(DiscoveryGamesLoadRequested(discoveryType)),
              child: DiscoveryGamesScreen(discoveryType: discoveryType),
            );
          },
        ),

        // Genre Games Route (outside bottom navigation)
        GoRoute(
          path: genreGamesPath,
          name: genreGamesName,
          builder: (context, state) {
            final genreId = int.tryParse(state.pathParameters['genreId'] ?? '');
            final genreName = state.uri.queryParameters['name'] ?? '';

            // Guard against a malformed/bookmarked URL (e.g. /browse/genres/abc):
            // an exception in a builder is not caught by errorBuilder.
            if (genreId == null) {
              return Scaffold(
                appBar: AppBar(),
                body: Center(child: Text(context.l10n.browseGenreGamesError)),
              );
            }

            _ensureGamesRepositoryRegistered();

            return BlocProvider(
              create: (_) =>
                  BrowseGenreGamesBloc(gamesRepository: sl<IGamesRepository>())
                    ..add(BrowseGenreGamesLoadRequested(genreId)),
              child: BrowseGenreGamesScreen(
                genreId: genreId,
                genreName: genreName,
              ),
            );
          },
        ),
      ],
      errorBuilder: (context, state) => _ErrorScreen(error: state.error),
      debugLogDiagnostics: kDebugMode,
    );
  }

  /// Resolves where to send the user after onboarding finishes.
  /// Mirrors the splash decision: authenticated users go home, everyone else
  /// goes to sign in.
  static String _postOnboardingDestination() {
    final isAuthenticated = sl<AuthBloc>().state is AuthAuthenticated;
    return isAuthenticated ? homePath : signInPath;
  }

  /// Ensures OnboardingService is registered in the service locator.
  /// Called lazily when the onboarding route is accessed; reads/writes the
  /// one-time completion flag through the shared local storage service.
  static void _ensureOnboardingServiceRegistered() {
    if (!sl.isRegistered<OnboardingService>()) {
      sl.registerLazySingleton<OnboardingService>(
        () => OnboardingService(sl<LocalStorageService>()),
      );
    }
  }

  /// Ensures AuthRepository is registered in the service locator.
  /// This is called lazily when auth routes are accessed.
  /// The repository stays registered as a singleton for token management and logout.
  static void _ensureAuthRepositoryRegistered() {
    if (!sl.isRegistered<AuthRepository>()) {
      sl.registerLazySingleton<AuthRepository>(
        () => AuthRepository(
          httpClient: sl<IHttpClient>(),
          tokenStorage: sl<TokenStorage>(),
        ),
      );
    }
  }

  /// Ensures GamesRepository is registered in the service locator.
  /// This is called lazily when home route is accessed.
  /// The repository stays registered as a singleton for API calls.
  static void _ensureGamesRepositoryRegistered() {
    if (!sl.isRegistered<IGamesRepository>()) {
      sl.registerLazySingleton<IGamesRepository>(
        () => GamesRepository(httpClient: sl<IHttpClient>()),
      );
    }
  }

  /// Ensures LibraryRepository and LibraryBloc are registered in the service locator.
  /// This is called lazily when games (library) route is accessed.
  /// The repository stays registered as a singleton for API calls.
  static void _ensureLibraryRepositoryAndBlocRegistered() {
    if (!sl.isRegistered<LibraryRepository>()) {
      sl.registerLazySingleton<LibraryRepository>(
        () => LibraryRepository(httpClient: sl<IHttpClient>()),
      );
    }

    if (!sl.isRegistered<LibraryBloc>()) {
      sl.registerLazySingleton<LibraryBloc>(
        () => LibraryBloc(libraryRepository: sl<LibraryRepository>()),
      );
    }
  }
}

/// Helper class to convert Stream to ChangeNotifier for GoRouter
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) {
      notifyListeners();
    });
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

/// Error screen widget for handling route errors
class _ErrorScreen extends StatelessWidget {
  const _ErrorScreen({this.error});
  final Exception? error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.errorTitle),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                context.l10n.errorMessage,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              if (error != null)
                Text(
                  error.toString(),
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => context.go(AppRouter.homePath),
                child: Text(context.l10n.goHome),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
