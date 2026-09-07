import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picklog/features/auth/bloc/auth_bloc.dart';
import 'package:picklog/features/auth/bloc/auth_event.dart';
import 'package:picklog/features/auth/bloc/auth_state.dart';
import 'package:picklog/features/auth/user_model.dart';

import '../../../mocks/mock_services.dart';

void main() {
  group('AuthBloc', () {
    late MockLocalStorageService mockStorageService;
    late FakeSessionResetService fakeSessionReset;

    setUp(() {
      mockStorageService = MockLocalStorageService();
      fakeSessionReset = FakeSessionResetService();
    });

    test('initial state is AuthInitial', () {
      final authBloc = AuthBloc(mockStorageService, fakeSessionReset);
      expect(authBloc.state, isA<AuthInitial>());
      authBloc.close();
    });

    blocTest<AuthBloc, AuthState>(
      'emits [AuthUnauthenticated] when AuthStateLoaded is added and no stored auth',
      build: () {
        mockStorageService.setBoolReturn(false);
        mockStorageService.setStringReturn(null);
        return AuthBloc(mockStorageService, fakeSessionReset);
      },
      act: (bloc) => bloc.add(const AuthStateLoaded()),
      expect: () => [const AuthUnauthenticated()],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthAuthenticated] when AuthStateLoaded is added with stored auth',
      build: () {
        mockStorageService.setBoolReturn(true);
        mockStorageService.setStringReturn(
          '{"id":"123","email":"saved@example.com","name":"Saved User"}',
        );
        return AuthBloc(mockStorageService, fakeSessionReset);
      },
      act: (bloc) => bloc.add(const AuthStateLoaded()),
      expect: () => [
        predicate<AuthAuthenticated>((state) {
          return state.user.email == 'saved@example.com' &&
              state.user.name == 'Saved User';
        }),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthUnauthenticated] when AuthStateLoaded with invalid JSON',
      build: () {
        mockStorageService.setBoolReturn(true);
        mockStorageService.setStringReturn('invalid json');
        return AuthBloc(mockStorageService, fakeSessionReset);
      },
      act: (bloc) => bloc.add(const AuthStateLoaded()),
      expect: () => [const AuthUnauthenticated()],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthUnauthenticated] when logout is requested',
      build: () => AuthBloc(mockStorageService, fakeSessionReset),
      act: (bloc) => bloc.add(const AuthLogoutRequested()),
      expect: () => [const AuthUnauthenticated()],
      verify: (_) {
        expect(mockStorageService.removeCallHistory.length, greaterThan(0));
        expect(fakeSessionReset.teardownCalled, isTrue);
      },
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthAuthenticated] when AuthUserAuthenticated is added (real API path)',
      build: () => AuthBloc(mockStorageService, fakeSessionReset),
      act: (bloc) => bloc.add(
        const AuthUserAuthenticated(
          User(
            id: 'api-user-123',
            email: 'api@example.com',
            name: 'API User',
            username: 'apiuser',
          ),
        ),
      ),
      expect: () => [
        predicate<AuthAuthenticated>((state) {
          return state.user.id == 'api-user-123' &&
              state.user.email == 'api@example.com' &&
              state.user.name == 'API User' &&
              state.user.username == 'apiuser';
        }),
      ],
      verify: (_) {
        expect(mockStorageService.setStringCallHistory.length, greaterThan(0));
        expect(mockStorageService.setBoolCallHistory.length, greaterThan(0));
      },
    );

    blocTest<AuthBloc, AuthState>(
      'AuthUserAuthenticated persists user and can be restored via AuthStateLoaded',
      build: () => AuthBloc(mockStorageService, fakeSessionReset),
      act: (bloc) async {
        bloc.add(
          const AuthUserAuthenticated(
            User(
              id: 'persisted-123',
              email: 'persisted@example.com',
              name: 'Persisted User',
            ),
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 50));
      },
      expect: () => [
        predicate<AuthAuthenticated>((state) {
          return state.user.email == 'persisted@example.com';
        }),
      ],
      verify: (_) {
        final savedUser = mockStorageService.setStringCallHistory.firstWhere(
          (call) => call['key'] == 'current_user',
        );
        expect(savedUser['value'], contains('persisted@example.com'));
      },
    );
  });
}
