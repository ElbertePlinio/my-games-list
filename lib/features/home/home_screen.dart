import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:picklog/core/theme/pf_tokens.dart';
import 'package:picklog/core/theme/picklog_colors.dart';
import 'package:picklog/core/utils/app_router.dart';
import 'package:picklog/core/utils/l10n_extensions.dart';
import 'package:picklog/core/widgets/app_scaffold.dart';
import 'package:picklog/core/widgets/brand_mark.dart';
import 'package:picklog/core/widgets/section_header.dart';
import 'package:picklog/features/ai/widgets/home_ai_entry.dart';
import 'package:picklog/features/auth/bloc/auth_bloc.dart';
import 'package:picklog/features/auth/bloc/auth_state.dart';
import 'package:picklog/features/games/bloc/anticipated_games_bloc.dart';
import 'package:picklog/features/games/bloc/anticipated_games_event.dart';
import 'package:picklog/features/games/bloc/collections_bloc.dart';
import 'package:picklog/features/games/bloc/collections_event.dart';
import 'package:picklog/features/games/bloc/discovery_games_bloc.dart';
import 'package:picklog/features/games/bloc/discovery_games_event.dart';
import 'package:picklog/features/games/bloc/discovery_games_state.dart';
import 'package:picklog/features/games/bloc/featured_banners_bloc.dart';
import 'package:picklog/features/games/bloc/featured_banners_event.dart';
import 'package:picklog/features/games/bloc/recommendations_bloc.dart';
import 'package:picklog/features/games/bloc/recommendations_event.dart';
import 'package:picklog/features/games/discovery_game_model.dart';
import 'package:picklog/features/games/widgets/anticipated_games_carousel.dart';
import 'package:picklog/features/games/widgets/collections_widget.dart';
import 'package:picklog/features/games/widgets/discovery_games_widget.dart';
import 'package:picklog/features/games/widgets/featured_banners_carousel.dart';
import 'package:picklog/features/games/widgets/recommendations_widget.dart';
import 'package:picklog/l10n/app_localizations.dart';

/// Home feed: greeting, featured picks, anticipated releases,
/// recommendations, discovery rails and curated collections.
///
/// Every row owns its loading, error (inline retry) and content states. Pull
/// to refresh reloads all of them.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  /// Hero prefixes unique per home section.
  static const String _homePrefix = 'home-';

  Future<void> _refresh(BuildContext context) async {
    final banners = context.read<FeaturedBannersBloc>()
      ..add(const FeaturedBannersRefreshRequested());
    final anticipated = context.read<AnticipatedGamesBloc>()
      ..add(const AnticipatedGamesRefreshRequested());
    final recommendations = context.read<RecommendationsBloc>()
      ..add(const RecommendationsLoadRequested());
    final collections = context.read<CollectionsBloc>()
      ..add(const CollectionsLoadRequested());
    final discovery = context.read<DiscoveryGamesBloc>();
    for (final type in DiscoveryType.values) {
      if (discovery.state.getStateForType(type).status !=
          DiscoveryGamesStatus.initial) {
        discovery.add(DiscoveryGamesLoadRequested(type));
      }
    }

    // Keep the indicator up until every section settles (bounded).
    await Future.wait([
      banners.stream.firstWhere((s) => !s.isLoading),
      anticipated.stream.firstWhere((s) => !s.isLoading),
      recommendations.stream.firstWhere((s) => !s.isLoading),
      collections.stream.firstWhere((s) => !s.isLoading),
    ]).timeout(const Duration(seconds: 12), onTimeout: () => const []);
  }

  @override
  Widget build(BuildContext context) {
    final showWordmark =
        MediaQuery.sizeOf(context).width < PfBreakpoints.expanded;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => _refresh(context),
        edgeOffset: kToolbarHeight + MediaQuery.paddingOf(context).top,
        child: MaxWidthBox(
          maxWidth: 1440,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverAppBar(
                floating: true,
                snap: true,
                titleSpacing: PfSpace.lg,
                title: showWordmark ? const Wordmark(markSize: 28) : null,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () => context.pushNamed(AppRouter.searchName),
                    tooltip: context.l10n.searchGamesTooltip,
                  ),
                  const SizedBox(width: PfSpace.xs),
                ],
              ),
              const SliverToBoxAdapter(child: _Greeting()),
              const SliverToBoxAdapter(child: HomeAiEntry()),
              const SliverToBoxAdapter(child: FeaturedBannersCarousel()),
              const SliverToBoxAdapter(
                child: AnticipatedGamesCarousel(
                  heroTagPrefix: '${_homePrefix}anticipated-',
                ),
              ),
              const SliverToBoxAdapter(
                child: RecommendationsWidget(
                  heroTagPrefix: '${_homePrefix}rec-',
                ),
              ),
              const SliverToBoxAdapter(
                child: DiscoveryGamesWidget(
                  discoveryType: DiscoveryType.trending,
                  heroTagPrefix: '${_homePrefix}trending-',
                ),
              ),
              const SliverToBoxAdapter(
                child: CollectionsWidget(heroTagPrefix: _homePrefix),
              ),
              const SliverToBoxAdapter(
                child: LazyDiscoveryGamesWidget(
                  discoveryType: DiscoveryType.indie,
                  heroTagPrefix: '${_homePrefix}indie-',
                ),
              ),
              const SliverToBoxAdapter(
                child: LazyDiscoveryGamesWidget(
                  discoveryType: DiscoveryType.newReleases,
                  heroTagPrefix: '${_homePrefix}new-',
                ),
              ),
              const SliverToBoxAdapter(
                child: LazyDiscoveryGamesWidget(
                  discoveryType: DiscoveryType.comingSoon,
                  heroTagPrefix: '${_homePrefix}soon-',
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height:
                      PfSpace.xxl + MediaQuery.viewPaddingOf(context).bottom,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Greeting for the local [hour]: night 0-4, morning 5-11, afternoon 12-17
/// and evening 18-23. Uses only the first word of [name].
String homeGreeting(AppLocalizations l10n, String? name, int hour) {
  if (name == null || name.trim().isEmpty) return l10n.homeGreetingAnonymous;
  final first = name.trim().split(RegExp(r'\s+')).first;
  if (hour < 5) return l10n.homeGreetingNight(first);
  if (hour < 12) return l10n.homeGreetingMorning(first);
  if (hour < 18) return l10n.homeGreetingAfternoon(first);
  return l10n.homeGreetingEvening(first);
}

/// Personal greeting with an ember eyebrow.
class _Greeting extends StatelessWidget {
  const _Greeting();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    String? name;
    try {
      final authState = context.watch<AuthBloc>().state;
      name = authState is AuthAuthenticated ? authState.user.name : null;
    } on ProviderNotFoundException {
      name = null;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        PfSpace.lg,
        PfSpace.sm,
        PfSpace.lg,
        PfSpace.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Eyebrow(context.l10n.homeEyebrow),
          const SizedBox(height: PfSpace.sm),
          Semantics(
            header: true,
            child: Text(
              homeGreeting(context.l10n, name, DateTime.now().hour),
              style: theme.textTheme.displaySmall,
            ),
          ),
          const SizedBox(height: PfSpace.xs),
          Text(
            context.l10n.homeSubtitle,
            style: theme.textTheme.bodyLarge!.copyWith(
              color: context.pfColors.textMed,
            ),
          ),
        ],
      ),
    );
  }
}
