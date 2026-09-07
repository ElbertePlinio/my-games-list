import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:picklog/core/data/services/http/i_http_client.dart';
import 'package:picklog/core/data/services/storage/token_storage.dart';
import 'package:picklog/core/domain/models/api_error.dart';
import 'package:picklog/core/domain/models/api_response.dart';
import 'package:picklog/features/auth/auth_repository.dart';
import 'package:picklog/features/auth/auth_response.dart';
import 'package:picklog/features/auth/sign_in/sign_in_request.dart';
import 'package:picklog/features/auth/sign_up/sign_up_request.dart';

class MockHttpClient extends Mock implements IHttpClient {}

class MockTokenStorage extends Mock implements TokenStorage {}

void main() {
  late AuthRepository repository;
  late MockHttpClient mockHttpClient;
  late MockTokenStorage mockTokenStorage;

  setUp(() {
    mockHttpClient = MockHttpClient();
    mockTokenStorage = MockTokenStorage();
    repository = AuthRepository(
      httpClient: mockHttpClient,
      tokenStorage: mockTokenStorage,
    );
  });

  group('AuthRepository SignIn Tests', () {
    const signInRequest = SignInRequest(
      email: 'test@example.com',
      password: 'password123',
    );

    final mockAuthData = {
      'token': 'test-token-123',
      'user': {
        'id': 'user-1',
        'email': 'test@example.com',
        'username': 'testuser',
      },
    };

    test('signIn succeeds with valid credentials', () async {
      // Arrange
      when(
        () => mockHttpClient.post<Map<String, dynamic>>(
          any(),
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async => ApiResponse.success(mockAuthData));

      when(() => mockTokenStorage.write(any())).thenAnswer((_) async {});

      // Act
      final result = await repository.signIn(signInRequest);

      // Assert
      expect(result, isA<AuthResponse>());
      expect(result.token, 'test-token-123');
      expect(result.user.email, 'test@example.com');
      expect(result.user.username, 'testuser');

      verify(
        () => mockHttpClient.post<Map<String, dynamic>>(
          '/auth/signin',
          data: signInRequest.toJson(),
        ),
      ).called(1);

      verify(() => mockTokenStorage.write('test-token-123')).called(1);
      verify(() => mockHttpClient.setAuthToken('test-token-123')).called(1);
    });
  });

  group('AuthRepository SignUp Tests', () {
    const signUpRequest = SignUpRequest(
      email: 'newuser@example.com',
      password: 'password123',
      username: 'newuser',
      consentVersion: '2026-06-22',
    );

    final mockAuthData = {
      'token': 'new-token-456',
      'user': {
        'id': 'user-2',
        'email': 'newuser@example.com',
        'username': 'newuser',
      },
    };

    test('signUp succeeds with valid data', () async {
      // Arrange
      when(
        () => mockHttpClient.post<Map<String, dynamic>>(
          any(),
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async => ApiResponse.success(mockAuthData));

      when(() => mockTokenStorage.write(any())).thenAnswer((_) async {});

      // Act
      final result = await repository.signUp(signUpRequest);

      // Assert
      expect(result, isA<AuthResponse>());
      expect(result.token, 'new-token-456');
      expect(result.user.email, 'newuser@example.com');
      expect(result.user.username, 'newuser');

      verify(
        () => mockHttpClient.post<Map<String, dynamic>>(
          '/auth/signup',
          data: signUpRequest.toJson(),
        ),
      ).called(1);

      verify(() => mockTokenStorage.write('new-token-456')).called(1);
      verify(() => mockHttpClient.setAuthToken('new-token-456')).called(1);
    });
  });

  group('AuthRepository Token Management Tests', () {
    test('saveToken stores token in secure storage', () async {
      // Arrange
      when(() => mockTokenStorage.write(any())).thenAnswer((_) async {});

      // Act
      await repository.saveToken('test-token');

      // Assert
      verify(() => mockTokenStorage.write('test-token')).called(1);
    });

    test('getToken retrieves token from secure storage', () async {
      // Arrange
      when(
        () => mockTokenStorage.read(),
      ).thenAnswer((_) async => 'stored-token');

      // Act
      final result = await repository.getToken();

      // Assert
      expect(result, 'stored-token');
      verify(() => mockTokenStorage.read()).called(1);
    });

    test('getToken returns null when no token is stored', () async {
      // Arrange
      when(() => mockTokenStorage.read()).thenAnswer((_) async => null);

      // Act
      final result = await repository.getToken();

      // Assert
      expect(result, isNull);
      verify(() => mockTokenStorage.read()).called(1);
    });

    test('clearToken removes token and clears auth header', () async {
      // Arrange
      when(() => mockTokenStorage.delete()).thenAnswer((_) async {});
      when(() => mockHttpClient.clearAuthToken()).thenReturn(null);

      // Act
      await repository.clearToken();

      // Assert
      verify(() => mockTokenStorage.delete()).called(1);
      verify(() => mockHttpClient.clearAuthToken()).called(1);
    });
  });

  group('AuthRepository Account Deletion Tests', () {
    test('deleteAccount calls DELETE /users/me', () async {
      // Arrange
      when(
        () => mockHttpClient.delete<void>(any()),
      ).thenAnswer((_) async => ApiResponse.success(null));

      // Act
      await repository.deleteAccount();

      // Assert
      verify(() => mockHttpClient.delete<void>('/users/me')).called(1);
    });

    test('deleteAccount throws when the request fails', () async {
      // Arrange
      when(() => mockHttpClient.delete<void>(any())).thenAnswer(
        (_) async => ApiResponse.failure(
          const ApiError(
            name: 'Server Error',
            message: 'boom',
            action: 'retry',
            statusCode: 500,
            errorCode: 'error.server',
          ),
        ),
      );

      // Act & Assert
      await expectLater(repository.deleteAccount(), throwsException);
    });
  });

  group('AuthRepository Data Export Tests', () {
    final exportPayload = {
      'user': {
        'id': 'user-1',
        'email': 'test@example.com',
        'username': 'testuser',
      },
      'library': <dynamic>[],
    };

    test(
      'exportData returns pretty-printed JSON from GET /users/me/export',
      () async {
        // Arrange
        when(
          () => mockHttpClient.get<Map<String, dynamic>>(any()),
        ).thenAnswer((_) async => ApiResponse.success(exportPayload));

        // Act
        final result = await repository.exportData();

        // Assert
        verify(
          () => mockHttpClient.get<Map<String, dynamic>>('/users/me/export'),
        ).called(1);
        expect(result, contains('"email": "test@example.com"'));
        expect(result, contains('\n')); // pretty-printed (indented)
      },
    );

    test('exportData throws when the request fails', () async {
      // Arrange
      when(() => mockHttpClient.get<Map<String, dynamic>>(any())).thenAnswer(
        (_) async => ApiResponse.failure(
          const ApiError(
            name: 'Server Error',
            message: 'boom',
            action: 'retry',
            statusCode: 500,
            errorCode: 'error.server',
          ),
        ),
      );

      // Act & Assert
      await expectLater(repository.exportData(), throwsException);
    });
  });
}
