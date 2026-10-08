import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:picklog/core/theme/app_theme.dart';
import 'package:picklog/core/utils/app_router.dart';
import 'package:picklog/l10n/app_localizations.dart';

/// Route names that tests can navigate to. Each renders `route:<name>`.
const List<(String, String)> _stubRoutes = [
  ('/ai/play-next', AppRouter.aiPlayNextName),
  ('/ai/discover', AppRouter.aiDiscoverName),
  ('/explore', AppRouter.exploreName),
  ('/search', AppRouter.searchName),
  ('/games/:id', AppRouter.gameDetailsName),
  ('/settings/accounts', AppRouter.connectedAccountsName),
  ('/achievements', AppRouter.achievementsName),
  ('/achievements/:provider/:externalGameId', AppRouter.achievementGameName),
  ('/privacy-policy', AppRouter.privacyPolicyName),
];

/// A themed, localized app whose home is [home] and whose named routes are
/// stubs, so taps that navigate can be asserted without the real screens.
Widget stubRouterApp(
  Widget home, {
  Brightness brightness = Brightness.dark,
  Locale locale = const Locale('en'),
}) {
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => home),
      for (final (path, name) in _stubRoutes)
        GoRoute(
          path: path,
          name: name,
          builder: (_, state) => Scaffold(
            body: Text('route:$name ${state.pathParameters.values.join('/')}'),
          ),
        ),
    ],
  );
  return MaterialApp.router(
    debugShowCheckedModeBanner: false,
    theme: brightness == Brightness.dark ? AppTheme.dark() : AppTheme.light(),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: locale,
    routerConfig: router,
  );
}
