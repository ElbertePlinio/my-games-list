import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:picklog/core/data/services/http/i_http_client.dart';
import 'package:picklog/core/domain/models/api_response.dart';
import 'package:picklog/core/utils/service_locator.dart';
import 'package:picklog/features/ai/ai_models.dart';
import 'package:picklog/features/ai/ai_repository.dart';
import 'package:picklog/features/ai/bloc/play_next_cubit.dart';
import 'package:picklog/features/library/bloc/library_bloc.dart';
import 'package:picklog/features/library/bloc/library_event.dart';
import 'package:picklog/features/library/library_entry_model.dart';
import 'package:picklog/features/library/library_repository.dart';

import '../../../mocks/mock_blocs.dart';
import '../../library/library_fixtures.dart';

import '../ai_fixtures.dart';

class _MockHttpClient extends Mock implements IHttpClient {}

LibraryEntry _entry(
  String id,
  GameStatus status, {
  int? platformId,
  String? platform,
}) => LibraryEntry(
  id: id,
  userId: 'u1',
  game: CachedGame(
    id: 'g$id',
    igdbId: id.hashCode,
    name: 'Game $id',
    lastSyncedAt: DateTime.utc(2026),
  ),
  platform: platformId == null
      ? null
      : CachedPlatform(
          id: 'p$platformId',
          igdbPlatformId: platformId,
          name: platform!,
          abbreviation: platform,
        ),
  status: status,
  isFavorite: false,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

void main() {
  late MockAiRepository ai;
  late MockLibraryRepository library;

  setUpAll(() {
    registerFallbackValue(const PlayNextRequest());
    registerFallbackValue(const LibraryRefreshRequested(userId: 'u1'));
  });

  setUp(() {
    ai = MockAiRepository();
    library = MockLibraryRepository();
  });

  PlayNextCubit build() =>
      PlayNextCubit(aiRepository: ai, libraryRepository: library, userId: 'u1');

  group('PlayNextCubit', () {
    blocTest<PlayNextCubit, PlayNextState>(
      'loadLibrary collects platforms and counts the backlog',
      build: () {
        when(() => library.getLibrary('u1')).thenAnswer(
          (_) async => [
            _entry('1', GameStatus.planned, platformId: 6, platform: 'PC'),
            _entry('2', GameStatus.finished, platformId: 167, platform: 'PS5'),
            _entry('3', GameStatus.onHold, platformId: 6, platform: 'PC'),
          ],
        );
        return build();
      },
      act: (cubit) => cubit.loadLibrary(),
      expect: () => [
        const PlayNextState(
          platforms: [
            LibraryPlatformOption(id: 6, label: 'PC'),
            LibraryPlatformOption(id: 167, label: 'PS5'),
          ],
          backlogCount: 2,
        ),
      ],
    );

    blocTest<PlayNextCubit, PlayNextState>(
      'an empty backlog is detected before generating',
      build: () {
        when(
          () => library.getLibrary('u1'),
        ).thenAnswer((_) async => [_entry('1', GameStatus.finished)]);
        return build();
      },
      act: (cubit) => cubit.loadLibrary(),
      verify: (cubit) => expect(cubit.state.isBacklogEmpty, isTrue),
    );

    blocTest<PlayNextCubit, PlayNextState>(
      'generate sends the form and emits picks',
      build: () {
        when(() => ai.playNext(any())).thenAnswer((_) async => kPlayNextResult);
        return build();
      },
      act: (cubit) => cubit
        ..selectMood(AiMood.story)
        ..setMinutesStop(5)
        ..selectPlatform(6)
        ..setNote('cozy')
        ..generate(),
      skip: 4,
      expect: () => [
        isA<PlayNextState>().having(
          (s) => s.status,
          'status',
          PlayNextStatus.loading,
        ),
        isA<PlayNextState>()
            .having((s) => s.status, 'status', PlayNextStatus.success)
            .having((s) => s.picks, 'picks', kPlayNextResult.picks)
            .having((s) => s.remainingToday, 'remaining', 16),
      ],
      verify: (_) => verify(
        () => ai.playNext(
          const PlayNextRequest(
            minutesAvailable: 120,
            mood: AiMood.story,
            platformId: 6,
            note: 'cozy',
          ),
        ),
      ).called(1),
    );

    blocTest<PlayNextCubit, PlayNextState>(
      'selecting the same mood again clears it',
      build: build,
      act: (cubit) => cubit
        ..selectMood(AiMood.chill)
        ..selectMood(AiMood.chill),
      expect: () => [
        const PlayNextState(mood: AiMood.chill),
        const PlayNextState(),
      ],
    );

    blocTest<PlayNextCubit, PlayNextState>(
      'no picks from the API means an empty backlog',
      build: () {
        when(() => ai.playNext(any())).thenAnswer(
          (_) async => const PlayNextResult(picks: [], remainingToday: 20),
        );
        return build();
      },
      act: (cubit) => cubit.generate(),
      verify: (cubit) => expect(cubit.state.isBacklogEmpty, isTrue),
    );

    for (final kind in [
      AiErrorKind.consentRequired,
      AiErrorKind.quotaExceeded,
      AiErrorKind.upstream,
    ]) {
      blocTest<PlayNextCubit, PlayNextState>(
        'a $kind failure is stored',
        build: () {
          when(() => ai.playNext(any())).thenThrow(AiException(kind));
          return build();
        },
        act: (cubit) => cubit.generate(),
        expect: () => [
          const PlayNextState(status: PlayNextStatus.loading),
          PlayNextState(status: PlayNextStatus.failure, errorKind: kind),
        ],
      );
    }

    blocTest<PlayNextCubit, PlayNextState>(
      'startPlaying reads the entry and sets it to playing',
      build: () {
        final current = detailedEntry();
        when(
          () => library.getLibraryEntry('entry-1'),
        ).thenAnswer((_) async => current);
        when(
          () => library.updateLibraryEntry(current, status: GameStatus.playing),
        ).thenAnswer((_) async => _entry('entry-1', GameStatus.playing));
        return build();
      },
      seed: () => const PlayNextState(
        status: PlayNextStatus.success,
        picks: [kPickHades],
      ),
      act: (cubit) => cubit.startPlaying(kPickHades),
      expect: () => [
        const PlayNextState(
          status: PlayNextStatus.success,
          picks: [kPickHades],
          startingIds: {'entry-1'},
        ),
        const PlayNextState(
          status: PlayNextStatus.success,
          picks: [kPickHades],
          startedIds: {'entry-1'},
        ),
      ],
    );

    test('startPlaying refreshes the shared library on success', () async {
      final shared = MockLibraryBloc();
      when(() => shared.isClosed).thenReturn(false);
      sl.registerSingleton<LibraryBloc>(shared);
      addTearDown(() => sl.unregister<LibraryBloc>());
      final current = detailedEntry();
      when(
        () => library.getLibraryEntry('entry-1'),
      ).thenAnswer((_) async => current);
      when(
        () => library.updateLibraryEntry(current, status: GameStatus.playing),
      ).thenAnswer((_) async => _entry('entry-1', GameStatus.playing));
      final cubit = build();
      addTearDown(cubit.close);

      await cubit.startPlaying(kPickHades);

      verify(
        () => shared.add(const LibraryRefreshRequested(userId: 'u1')),
      ).called(1);
    });

    test('a save that ends after Back still refreshes the library', () async {
      final shared = MockLibraryBloc();
      when(() => shared.isClosed).thenReturn(false);
      sl.registerSingleton<LibraryBloc>(shared);
      addTearDown(() => sl.unregister<LibraryBloc>());
      final current = detailedEntry();
      final saving = Completer<LibraryEntry>();
      when(
        () => library.getLibraryEntry('entry-1'),
      ).thenAnswer((_) async => current);
      when(
        () => library.updateLibraryEntry(current, status: GameStatus.playing),
      ).thenAnswer((_) => saving.future);
      final cubit = build();

      final starting = cubit.startPlaying(kPickHades);
      await Future<void>.delayed(Duration.zero);
      await cubit.close();
      saving.complete(_entry('entry-1', GameStatus.playing));
      await starting;

      verify(
        () => shared.add(const LibraryRefreshRequested(userId: 'u1')),
      ).called(1);
    });

    test('a save that ends after a session switch refreshes nothing', () async {
      final first = MockLibraryBloc();
      when(() => first.isClosed).thenReturn(false);
      sl.registerSingleton<LibraryBloc>(first);
      final current = detailedEntry();
      final saving = Completer<LibraryEntry>();
      when(
        () => library.getLibraryEntry('entry-1'),
      ).thenAnswer((_) async => current);
      when(
        () => library.updateLibraryEntry(current, status: GameStatus.playing),
      ).thenAnswer((_) => saving.future);
      final cubit = build();

      final starting = cubit.startPlaying(kPickHades);
      await Future<void>.delayed(Duration.zero);
      // Session teardown closes the old library and registers a new one.
      when(() => first.isClosed).thenReturn(true);
      await cubit.close();
      await sl.unregister<LibraryBloc>();
      final second = MockLibraryBloc();
      when(() => second.isClosed).thenReturn(false);
      sl.registerSingleton<LibraryBloc>(second);
      addTearDown(() => sl.unregister<LibraryBloc>());
      saving.complete(_entry('entry-1', GameStatus.playing));
      await starting;

      verifyNever(() => first.add(any()));
      verifyNever(() => second.add(any()));
    });

    blocTest<PlayNextCubit, PlayNextState>(
      'a failed startPlaying bumps the failure counter',
      build: () {
        when(
          () => library.getLibraryEntry('entry-1'),
        ).thenThrow(Exception('offline'));
        return build();
      },
      seed: () => const PlayNextState(
        status: PlayNextStatus.success,
        picks: [kPickHades],
      ),
      act: (cubit) => cubit.startPlaying(kPickHades),
      skip: 1,
      expect: () => [
        const PlayNextState(
          status: PlayNextStatus.success,
          picks: [kPickHades],
          startFailureCount: 1,
        ),
      ],
    );

    test('startPlaying keeps score, dates, difficulty and notes', () async {
      // The QA repro: an entry with score 80 lost it after Start playing.
      final http = _MockHttpClient();
      when(() => http.get<Map<String, dynamic>>('/library/entry-1')).thenAnswer(
        (_) async => ApiResponse.success(
          entryJson(
            score: 80,
            startDate: '2026-01-05',
            endDate: '2026-02-10',
            difficulty: 'Steel Soul',
            notes: 'Pantheon left',
          ),
        ),
      );
      when(
        () => http.put<Map<String, dynamic>>(
          '/library/entry-1',
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => ApiResponse.success(entryJson(status: 'playing')),
      );
      final cubit = PlayNextCubit(
        aiRepository: ai,
        libraryRepository: LibraryRepository(httpClient: http),
        userId: 'u1',
      );
      addTearDown(cubit.close);

      await cubit.startPlaying(kPickHades);

      final body = verify(
        () => http.put<Map<String, dynamic>>(
          '/library/entry-1',
          data: captureAny(named: 'data'),
        ),
      ).captured.single;
      expect(body, {'status': 'playing', ...detailedEntryPayload});
      expect(cubit.state.startedIds, {'entry-1'});
    });

    blocTest<PlayNextCubit, PlayNextState>(
      'the note is capped at 200 characters',
      build: build,
      act: (cubit) => cubit.setNote('x' * 250),
      verify: (cubit) => expect(cubit.state.note.length, kPlayNextNoteMax),
    );
  });
}
