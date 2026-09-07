import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:picklog/features/games/discovery_game_model.dart';
import 'package:picklog/features/games/bloc/discovery_games_bloc.dart';
import 'package:picklog/features/games/bloc/discovery_games_event.dart';
import 'package:picklog/features/games/bloc/discovery_games_state.dart';
import 'package:picklog/features/games/i_games_repository.dart';

class MockGamesRepository extends Mock implements IGamesRepository {}

/// Builds a [DiscoveryGamesState] for a single discovery type using the
/// per-type API, mirroring how the bloc seeds and emits state.
DiscoveryGamesState stateForType(
  DiscoveryType type, {
  DiscoveryGamesStatus status = DiscoveryGamesStatus.initial,
  List<DiscoveryGame> games = const [],
  String? errorMessage,
  bool hasMore = true,
  int currentOffset = 0,
  bool offsetLimitReached = false,
}) {
  return DiscoveryGamesState(
    stateByType: {
      type: DiscoveryTypeState(
        status: status,
        games: games,
        errorMessage: errorMessage,
        hasMore: hasMore,
        currentOffset: currentOffset,
        offsetLimitReached: offsetLimitReached,
      ),
    },
    activeDiscoveryType: type,
  );
}

void main() {
  late MockGamesRepository mockRepository;

  setUp(() {
    mockRepository = MockGamesRepository();
  });

  setUpAll(() {
    registerFallbackValue(DiscoveryType.trending);
  });

  group('DiscoveryGamesBloc', () {
    final mockGames = [
      const DiscoveryGame(
        id: 1942,
        name: 'The Witcher 3: Wild Hunt',
        coverUrl:
            'https://images.igdb.com/igdb/image/upload/t_cover_big/coaarl.jpg',
        totalRating: 92.82,
      ),
      const DiscoveryGame(
        id: 12345,
        name: 'Another Game',
        coverUrl:
            'https://images.igdb.com/igdb/image/upload/t_cover_big/co1234.jpg',
        totalRating: 85.0,
      ),
    ];

    final mockResponse = DiscoveryGamesResponse(
      games: mockGames,
      type: 'trending',
      totalCount: 2,
      hasMore: true,
      offset: 0,
      limit: 50,
    );

    final mockResponseNoMore = DiscoveryGamesResponse(
      games: mockGames,
      type: 'trending',
      totalCount: 2,
      hasMore: false,
      offset: 50,
      limit: 50,
    );

    group('DiscoveryGamesLoadRequested', () {
      blocTest<DiscoveryGamesBloc, DiscoveryGamesState>(
        'emits [loading, success] when load is requested successfully',
        build: () {
          when(
            () => mockRepository.getDiscoveryGames(
              any(),
              limit: any(named: 'limit'),
              offset: any(named: 'offset'),
            ),
          ).thenAnswer((_) async => mockResponse);
          return DiscoveryGamesBloc(gamesRepository: mockRepository);
        },
        act: (bloc) =>
            bloc.add(const DiscoveryGamesLoadRequested(DiscoveryType.trending)),
        expect: () => [
          stateForType(
            DiscoveryType.trending,
            status: DiscoveryGamesStatus.loading,
          ),
          predicate<DiscoveryGamesState>((state) {
            final typeState = state.getStateForType(DiscoveryType.trending);
            return typeState.status == DiscoveryGamesStatus.success &&
                typeState.games.length == 2 &&
                typeState.games[0].name == 'The Witcher 3: Wild Hunt';
          }),
        ],
        verify: (_) {
          verify(
            () => mockRepository.getDiscoveryGames(
              DiscoveryType.trending,
              limit: 50,
              offset: 0,
            ),
          ).called(1);
        },
      );

      blocTest<DiscoveryGamesBloc, DiscoveryGamesState>(
        'emits [loading, failure] when load fails',
        build: () {
          when(
            () => mockRepository.getDiscoveryGames(
              any(),
              limit: any(named: 'limit'),
              offset: any(named: 'offset'),
            ),
          ).thenThrow(Exception('Network error'));
          return DiscoveryGamesBloc(gamesRepository: mockRepository);
        },
        act: (bloc) =>
            bloc.add(const DiscoveryGamesLoadRequested(DiscoveryType.trending)),
        expect: () => [
          stateForType(
            DiscoveryType.trending,
            status: DiscoveryGamesStatus.loading,
          ),
          predicate<DiscoveryGamesState>((state) {
            final typeState = state.getStateForType(DiscoveryType.trending);
            return typeState.status == DiscoveryGamesStatus.failure &&
                typeState.errorMessage != null;
          }),
        ],
      );

      blocTest<DiscoveryGamesBloc, DiscoveryGamesState>(
        'sets correct discovery type for indie',
        build: () {
          when(
            () => mockRepository.getDiscoveryGames(
              any(),
              limit: any(named: 'limit'),
              offset: any(named: 'offset'),
            ),
          ).thenAnswer((_) async => mockResponse);
          return DiscoveryGamesBloc(gamesRepository: mockRepository);
        },
        act: (bloc) =>
            bloc.add(const DiscoveryGamesLoadRequested(DiscoveryType.indie)),
        expect: () => [
          stateForType(
            DiscoveryType.indie,
            status: DiscoveryGamesStatus.loading,
          ),
          predicate<DiscoveryGamesState>((state) {
            final typeState = state.getStateForType(DiscoveryType.indie);
            return typeState.status == DiscoveryGamesStatus.success &&
                state.activeDiscoveryType == DiscoveryType.indie;
          }),
        ],
      );
    });

    group('DiscoveryGamesLoadMore', () {
      blocTest<DiscoveryGamesBloc, DiscoveryGamesState>(
        'emits [loadingMore, success] when load more is successful',
        build: () {
          when(
            () => mockRepository.getDiscoveryGames(
              any(),
              limit: any(named: 'limit'),
              offset: any(named: 'offset'),
            ),
          ).thenAnswer((_) async => mockResponseNoMore);
          return DiscoveryGamesBloc(gamesRepository: mockRepository);
        },
        seed: () => stateForType(
          DiscoveryType.trending,
          status: DiscoveryGamesStatus.success,
          games: mockGames,
          hasMore: true,
          currentOffset: 50,
        ),
        act: (bloc) => bloc.add(const DiscoveryGamesLoadMore()),
        expect: () => [
          predicate<DiscoveryGamesState>(
            (state) =>
                state.getStateForType(DiscoveryType.trending).status ==
                DiscoveryGamesStatus.loadingMore,
          ),
          predicate<DiscoveryGamesState>((state) {
            final typeState = state.getStateForType(DiscoveryType.trending);
            return typeState.status == DiscoveryGamesStatus.success &&
                typeState.games.length == 4 &&
                typeState.currentOffset == 100;
          }),
        ],
        verify: (_) {
          verify(
            () => mockRepository.getDiscoveryGames(
              DiscoveryType.trending,
              limit: 50,
              offset: 50,
            ),
          ).called(1);
        },
      );

      blocTest<DiscoveryGamesBloc, DiscoveryGamesState>(
        'does nothing when already loading more',
        build: () => DiscoveryGamesBloc(gamesRepository: mockRepository),
        seed: () => stateForType(
          DiscoveryType.trending,
          status: DiscoveryGamesStatus.loadingMore,
          hasMore: true,
        ),
        act: (bloc) => bloc.add(const DiscoveryGamesLoadMore()),
        expect: () => [],
        verify: (_) {
          verifyNever(
            () => mockRepository.getDiscoveryGames(
              any(),
              limit: any(named: 'limit'),
              offset: any(named: 'offset'),
            ),
          );
        },
      );

      blocTest<DiscoveryGamesBloc, DiscoveryGamesState>(
        'does nothing when hasMore is false',
        build: () => DiscoveryGamesBloc(gamesRepository: mockRepository),
        seed: () => stateForType(
          DiscoveryType.trending,
          status: DiscoveryGamesStatus.success,
          hasMore: false,
        ),
        act: (bloc) => bloc.add(const DiscoveryGamesLoadMore()),
        expect: () => [],
      );

      blocTest<DiscoveryGamesBloc, DiscoveryGamesState>(
        'sets offsetLimitReached when offset exceeds max',
        build: () => DiscoveryGamesBloc(gamesRepository: mockRepository),
        seed: () => stateForType(
          DiscoveryType.trending,
          status: DiscoveryGamesStatus.success,
          hasMore: true,
          currentOffset: 10000,
        ),
        act: (bloc) => bloc.add(const DiscoveryGamesLoadMore()),
        expect: () => [
          predicate<DiscoveryGamesState>((state) {
            final typeState = state.getStateForType(DiscoveryType.trending);
            return typeState.offsetLimitReached && !typeState.hasMore;
          }),
        ],
      );
    });

    group('DiscoveryGamesViewModeToggled', () {
      blocTest<DiscoveryGamesBloc, DiscoveryGamesState>(
        'toggles from grid to list view',
        build: () => DiscoveryGamesBloc(gamesRepository: mockRepository),
        seed: () => const DiscoveryGamesState(viewMode: DiscoveryViewMode.grid),
        act: (bloc) => bloc.add(const DiscoveryGamesViewModeToggled()),
        expect: () => [
          predicate<DiscoveryGamesState>(
            (state) => state.viewMode == DiscoveryViewMode.list,
          ),
        ],
      );

      blocTest<DiscoveryGamesBloc, DiscoveryGamesState>(
        'toggles from list to grid view',
        build: () => DiscoveryGamesBloc(gamesRepository: mockRepository),
        seed: () => const DiscoveryGamesState(viewMode: DiscoveryViewMode.list),
        act: (bloc) => bloc.add(const DiscoveryGamesViewModeToggled()),
        expect: () => [
          predicate<DiscoveryGamesState>(
            (state) => state.viewMode == DiscoveryViewMode.grid,
          ),
        ],
      );
    });

    group('DiscoveryGamesRefreshRequested', () {
      blocTest<DiscoveryGamesBloc, DiscoveryGamesState>(
        'emits [loading, success] when refresh is successful',
        build: () {
          when(
            () => mockRepository.getDiscoveryGames(
              any(),
              limit: any(named: 'limit'),
              offset: any(named: 'offset'),
            ),
          ).thenAnswer((_) async => mockResponse);
          return DiscoveryGamesBloc(gamesRepository: mockRepository);
        },
        seed: () => stateForType(
          DiscoveryType.trending,
          status: DiscoveryGamesStatus.success,
          games: mockGames,
          currentOffset: 100,
        ),
        act: (bloc) => bloc.add(const DiscoveryGamesRefreshRequested()),
        expect: () => [
          predicate<DiscoveryGamesState>((state) {
            final typeState = state.getStateForType(DiscoveryType.trending);
            return typeState.status == DiscoveryGamesStatus.loading &&
                typeState.currentOffset == 0;
          }),
          predicate<DiscoveryGamesState>((state) {
            final typeState = state.getStateForType(DiscoveryType.trending);
            return typeState.status == DiscoveryGamesStatus.success &&
                typeState.games.length == 2 &&
                typeState.currentOffset == 50;
          }),
        ],
        verify: (_) {
          verify(
            () => mockRepository.getDiscoveryGames(
              DiscoveryType.trending,
              limit: 50,
              offset: 0,
            ),
          ).called(1);
        },
      );
    });
  });

  group('DiscoveryGame', () {
    test('fromJson parses correctly', () {
      final json = {
        'id': 1942,
        'name': 'The Witcher 3',
        'cover_url': 'https://example.com/cover.jpg',
        'total_rating': 92.5,
      };

      final game = DiscoveryGame.fromJson(json);

      expect(game.id, 1942);
      expect(game.name, 'The Witcher 3');
      expect(game.coverUrl, 'https://example.com/cover.jpg');
      expect(game.totalRating, 92.5);
    });

    test('fromJson handles null values', () {
      final json = {'id': 1, 'name': 'Test Game'};

      final game = DiscoveryGame.fromJson(json);

      expect(game.id, 1);
      expect(game.name, 'Test Game');
      expect(game.coverUrl, isNull);
      expect(game.totalRating, isNull);
    });

    test('ratingPercentage returns formatted string', () {
      const game = DiscoveryGame(id: 1, name: 'Test', totalRating: 92.5);

      expect(game.ratingPercentage, '93%');
    });

    test('ratingPercentage returns empty string when no rating', () {
      const game = DiscoveryGame(id: 1, name: 'Test');

      expect(game.ratingPercentage, '');
    });

    test('hasRating returns true when rating exists', () {
      const game = DiscoveryGame(id: 1, name: 'Test', totalRating: 85.0);

      expect(game.hasRating, isTrue);
    });

    test('hasRating returns false when rating is null', () {
      const game = DiscoveryGame(id: 1, name: 'Test');

      expect(game.hasRating, isFalse);
    });

    test('hasRating returns false when rating is 0', () {
      const game = DiscoveryGame(id: 1, name: 'Test', totalRating: 0);

      expect(game.hasRating, isFalse);
    });
  });

  group('DiscoveryType', () {
    test('fromQueryParam returns correct type for trending', () {
      expect(DiscoveryType.fromQueryParam('trending'), DiscoveryType.trending);
    });

    test('fromQueryParam returns correct type for indie', () {
      expect(DiscoveryType.fromQueryParam('indie'), DiscoveryType.indie);
    });

    test('fromQueryParam returns correct type for upcoming', () {
      expect(DiscoveryType.fromQueryParam('upcoming'), DiscoveryType.upcoming);
    });

    test('fromQueryParam returns trending for invalid param', () {
      expect(DiscoveryType.fromQueryParam('invalid'), DiscoveryType.trending);
    });

    test('queryParam returns correct string', () {
      expect(DiscoveryType.trending.queryParam, 'trending');
      expect(DiscoveryType.indie.queryParam, 'indie');
      expect(DiscoveryType.upcoming.queryParam, 'upcoming');
    });

    test('displayName returns user-friendly string', () {
      expect(DiscoveryType.trending.displayName, 'Trending Now');
      expect(DiscoveryType.indie.displayName, 'Indie Games');
      expect(DiscoveryType.upcoming.displayName, 'Upcoming Games');
    });
  });

  group('DiscoveryGamesResponse', () {
    test('fromJson parses correctly', () {
      final json = {
        'games': [
          {'id': 1, 'name': 'Game 1'},
          {'id': 2, 'name': 'Game 2'},
        ],
        'type': 'trending',
        'total_count': 2,
        'has_more': true,
        'offset': 0,
        'limit': 20,
      };

      final response = DiscoveryGamesResponse.fromJson(json);

      expect(response.games.length, 2);
      expect(response.type, 'trending');
      expect(response.totalCount, 2);
      expect(response.hasMore, isTrue);
      expect(response.offset, 0);
      expect(response.limit, 20);
    });
  });
}
