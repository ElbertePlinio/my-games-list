import 'package:flutter_test/flutter_test.dart';
import 'package:picklog/core/data/services/storage/local_storage_service.dart';
import 'package:picklog/features/onboarding/onboarding_service.dart';

import '../../mocks/mock_services.dart';

/// Storage stub whose reads throw, to exercise the defensive default.
class _ThrowingStorageService implements LocalStorageService {
  @override
  Future<bool?> getBool(String key) async => throw Exception('boom');

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('not needed for this test');
}

void main() {
  group('OnboardingService', () {
    test('isCompleted defaults to false on a fresh install', () async {
      final service = OnboardingService(MockLocalStorageService());

      expect(await service.isCompleted(), isFalse);
    });

    test(
      'markCompleted persists the flag so isCompleted returns true',
      () async {
        final storage = MockLocalStorageService();
        final service = OnboardingService(storage);

        await service.markCompleted();

        expect(await service.isCompleted(), isTrue);
        expect(storage.setBoolCallHistory, hasLength(1));
        expect(
          storage.setBoolCallHistory.single['key'],
          'onboarding_completed',
        );
        expect(storage.setBoolCallHistory.single['value'], isTrue);
      },
    );

    test('isCompleted returns false when storage read fails', () async {
      final service = OnboardingService(_ThrowingStorageService());

      expect(await service.isCompleted(), isFalse);
    });
  });
}
