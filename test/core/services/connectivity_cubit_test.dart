import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:picklog/core/services/connectivity_cubit.dart';

class _MockConnectivity extends Mock implements Connectivity {}

void main() {
  group('ConnectivityCubit', () {
    late _MockConnectivity connectivity;
    late StreamController<List<ConnectivityResult>> controller;

    setUp(() {
      connectivity = _MockConnectivity();
      controller = StreamController<List<ConnectivityResult>>.broadcast();
      when(
        () => connectivity.onConnectivityChanged,
      ).thenAnswer((_) => controller.stream);
    });

    tearDown(() => controller.close());

    test('starts online and reflects the initial check', () async {
      when(
        () => connectivity.checkConnectivity(),
      ).thenAnswer((_) async => [ConnectivityResult.wifi]);

      final cubit = ConnectivityCubit(connectivity);
      expect(cubit.state, isTrue);
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state, isTrue);
      await cubit.close();
    });

    test('emits false with no connectivity, then true again', () async {
      when(
        () => connectivity.checkConnectivity(),
      ).thenAnswer((_) async => [ConnectivityResult.wifi]);

      final cubit = ConnectivityCubit(connectivity);
      await Future<void>.delayed(Duration.zero);

      controller.add([ConnectivityResult.none]);
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state, isFalse);

      controller.add([ConnectivityResult.mobile]);
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state, isTrue);

      await cubit.close();
    });
  });
}
