import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:picklog/features/auth/auth_repository.dart';
import 'package:picklog/features/auth/auth_response.dart';
import 'package:picklog/features/auth/sign_up/bloc/sign_up_bloc.dart';
import 'package:picklog/features/auth/sign_up/bloc/sign_up_event.dart';
import 'package:picklog/features/auth/sign_up/bloc/sign_up_state.dart';
import 'package:picklog/features/auth/sign_up/sign_up_request.dart';
import 'package:picklog/features/auth/user_model.dart';
import 'package:picklog/features/legal/legal_constants.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late SignUpBloc bloc;
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    bloc = SignUpBloc(mockAuthRepository);
  });

  setUpAll(() {
    registerFallbackValue(
      const SignUpRequest(
        email: 'test@example.com',
        password: 'password123',
        username: 'testuser',
        consentVersion: '2026-06-22',
      ),
    );
  });

  tearDown(() {
    bloc.close();
  });

  group('SignUpBloc Tests', () {
    const testEmail = 'newuser@example.com';
    const testPassword = 'password123';
    const testUsername = 'newuser';

    const mockAuthResponse = AuthResponse(
      token: 'new-token-456',
      user: User(
        id: 'user-2',
        email: testEmail,
        name: testUsername,
        username: testUsername,
      ),
    );

    test('initial state is SignUpInitial', () {
      expect(bloc.state, equals(const SignUpInitial()));
    });

    blocTest<SignUpBloc, SignUpState>(
      'emits [SignUpLoading, SignUpSuccess] when signUp succeeds',
      build: () {
        when(
          () => mockAuthRepository.signUp(any()),
        ).thenAnswer((_) async => mockAuthResponse);
        return bloc;
      },
      act: (bloc) => bloc.add(
        const SignUpSubmitted(
          email: testEmail,
          password: testPassword,
          username: testUsername,
          acceptedTerms: true,
        ),
      ),
      expect: () => [
        const SignUpLoading(),
        const SignUpSuccess(mockAuthResponse),
      ],
      verify: (_) {
        verify(() => mockAuthRepository.signUp(any())).called(1);
      },
    );

    blocTest<SignUpBloc, SignUpState>(
      'sends consent_version in the SignUpRequest when terms are accepted',
      build: () {
        when(
          () => mockAuthRepository.signUp(any()),
        ).thenAnswer((_) async => mockAuthResponse);
        return bloc;
      },
      act: (bloc) => bloc.add(
        const SignUpSubmitted(
          email: testEmail,
          password: testPassword,
          username: testUsername,
          acceptedTerms: true,
        ),
      ),
      verify: (_) {
        final captured =
            verify(
                  () => mockAuthRepository.signUp(captureAny()),
                ).captured.single
                as SignUpRequest;
        expect(captured.consentVersion, kConsentVersion);
        expect(captured.toJson()['consent_version'], kConsentVersion);
      },
    );

    blocTest<SignUpBloc, SignUpState>(
      'emits [SignUpTermsNotAccepted] and never calls the repo when terms are '
      'not accepted',
      build: () => bloc,
      act: (bloc) => bloc.add(
        const SignUpSubmitted(
          email: testEmail,
          password: testPassword,
          username: testUsername,
          acceptedTerms: false,
        ),
      ),
      expect: () => [const SignUpTermsNotAccepted()],
      verify: (_) {
        verifyNever(() => mockAuthRepository.signUp(any()));
      },
    );

    blocTest<SignUpBloc, SignUpState>(
      'emits [SignUpLoading, SignUpError] when signUp fails',
      build: () {
        when(
          () => mockAuthRepository.signUp(any()),
        ).thenThrow(Exception('Email already exists'));
        return bloc;
      },
      act: (bloc) => bloc.add(
        const SignUpSubmitted(
          email: testEmail,
          password: testPassword,
          username: testUsername,
          acceptedTerms: true,
        ),
      ),
      expect: () => [
        const SignUpLoading(),
        const SignUpError('Email already exists'),
      ],
      verify: (_) {
        verify(() => mockAuthRepository.signUp(any())).called(1);
      },
    );

    blocTest<SignUpBloc, SignUpState>(
      'emits [SignUpLoading, SignUpError] when validation fails',
      build: () {
        when(
          () => mockAuthRepository.signUp(any()),
        ).thenThrow(Exception('Bad request. Please check your input.'));
        return bloc;
      },
      act: (bloc) => bloc.add(
        const SignUpSubmitted(
          email: testEmail,
          password: testPassword,
          username: testUsername,
          acceptedTerms: true,
        ),
      ),
      expect: () => [
        const SignUpLoading(),
        const SignUpError('Bad request. Please check your input.'),
      ],
    );
  });
}
