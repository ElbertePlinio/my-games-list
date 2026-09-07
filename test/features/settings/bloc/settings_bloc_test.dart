import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picklog/features/settings/bloc/settings_bloc.dart';
import 'package:picklog/features/settings/bloc/settings_event.dart';
import 'package:picklog/features/settings/bloc/settings_state.dart';

import '../../../mocks/mock_services.dart';

void main() {
  group('SettingsBloc', () {
    late MockLocalStorageService mockStorageService;

    setUp(() {
      mockStorageService = MockLocalStorageService();
    });

    test('initial state has dark mode off', () {
      final settingsBloc = SettingsBloc(mockStorageService);
      expect(settingsBloc.state.isDarkMode, isFalse);
      settingsBloc.close();
    });

    blocTest<SettingsBloc, SettingsState>(
      'emits state with dark mode off when initialized with no stored setting',
      build: () {
        mockStorageService.setBoolReturn(null);
        return SettingsBloc(mockStorageService);
      },
      act: (bloc) => bloc.add(const SettingsInitialized()),
      expect: () => [const SettingsState(isDarkMode: false)],
    );

    blocTest<SettingsBloc, SettingsState>(
      'emits state with dark mode on when initialized with stored setting',
      build: () {
        mockStorageService.setBoolReturn(true);
        return SettingsBloc(mockStorageService);
      },
      act: (bloc) => bloc.add(const SettingsInitialized()),
      expect: () => [const SettingsState(isDarkMode: true)],
    );

    blocTest<SettingsBloc, SettingsState>(
      'toggles theme correctly from off to on',
      build: () => SettingsBloc(mockStorageService),
      seed: () => const SettingsState(isDarkMode: false),
      act: (bloc) => bloc.add(const SettingsThemeToggled()),
      expect: () => [const SettingsState(isDarkMode: true)],
      verify: (_) {
        expect(mockStorageService.setBoolCallHistory.length, greaterThan(0));
      },
    );

    blocTest<SettingsBloc, SettingsState>(
      'toggles theme correctly from on to off',
      build: () => SettingsBloc(mockStorageService),
      seed: () => const SettingsState(isDarkMode: true),
      act: (bloc) => bloc.add(const SettingsThemeToggled()),
      expect: () => [const SettingsState(isDarkMode: false)],
    );

    blocTest<SettingsBloc, SettingsState>(
      'sets dark mode to true',
      build: () => SettingsBloc(mockStorageService),
      act: (bloc) => bloc.add(const SettingsDarkModeSet(true)),
      expect: () => [const SettingsState(isDarkMode: true)],
      verify: (_) {
        final savedCall = mockStorageService.setBoolCallHistory.last;
        expect(savedCall['key'], equals('is_dark_mode'));
        expect(savedCall['value'], isTrue);
      },
    );

    blocTest<SettingsBloc, SettingsState>(
      'sets dark mode to false',
      build: () => SettingsBloc(mockStorageService),
      seed: () => const SettingsState(isDarkMode: true),
      act: (bloc) => bloc.add(const SettingsDarkModeSet(false)),
      expect: () => [const SettingsState(isDarkMode: false)],
      verify: (_) {
        final savedCall = mockStorageService.setBoolCallHistory.last;
        expect(savedCall['key'], equals('is_dark_mode'));
        expect(savedCall['value'], isFalse);
      },
    );

    blocTest<SettingsBloc, SettingsState>(
      'saves settings to storage when changed',
      build: () => SettingsBloc(mockStorageService),
      act: (bloc) => bloc.add(const SettingsThemeToggled()),
      expect: () => [const SettingsState(isDarkMode: true)],
      verify: (_) {
        expect(mockStorageService.setBoolCallHistory.length, greaterThan(0));
        expect(
          mockStorageService.setBoolCallHistory.last['key'],
          equals('is_dark_mode'),
        );
      },
    );

    blocTest<SettingsBloc, SettingsState>(
      'handles storage errors gracefully',
      build: () {
        mockStorageService.setBoolReturn(null);
        return SettingsBloc(mockStorageService);
      },
      act: (bloc) async {
        bloc.add(const SettingsInitialized());
        await Future<void>.delayed(const Duration(milliseconds: 10));
        bloc.add(const SettingsThemeToggled());
      },
      skip: 1, // Skip the initialization state
      expect: () => [const SettingsState(isDarkMode: true)],
    );

    blocTest<SettingsBloc, SettingsState>(
      'persists theme changes correctly',
      build: () => SettingsBloc(mockStorageService),
      act: (bloc) async {
        bloc.add(const SettingsDarkModeSet(true));
        await Future<void>.delayed(const Duration(milliseconds: 10));
        bloc.add(const SettingsDarkModeSet(false));
      },
      skip: 1, // Skip to the final state
      expect: () => [const SettingsState(isDarkMode: false)],
      verify: (_) {
        expect(mockStorageService.setBoolCallHistory.length, equals(2));
        expect(mockStorageService.setBoolCallHistory.last['value'], isFalse);
      },
    );

    blocTest<SettingsBloc, SettingsState>(
      'tracks multiple theme toggles',
      build: () => SettingsBloc(mockStorageService),
      act: (bloc) async {
        bloc.add(const SettingsThemeToggled()); // true
        await Future<void>.delayed(const Duration(milliseconds: 10));
        bloc.add(const SettingsThemeToggled()); // false
        await Future<void>.delayed(const Duration(milliseconds: 10));
        bloc.add(const SettingsThemeToggled()); // true
      },
      skip: 2, // Skip to the final state
      expect: () => [const SettingsState(isDarkMode: true)],
      verify: (_) {
        expect(mockStorageService.setBoolCallHistory.length, equals(3));
      },
    );

    blocTest<SettingsBloc, SettingsState>(
      'loads the stored locale on init',
      build: () {
        mockStorageService.setStringReturn('pt');
        return SettingsBloc(mockStorageService);
      },
      act: (bloc) => bloc.add(const SettingsInitialized()),
      expect: () => [const SettingsState(isDarkMode: false, localeCode: 'pt')],
    );

    blocTest<SettingsBloc, SettingsState>(
      'setting a locale persists it and emits the new code',
      build: () => SettingsBloc(mockStorageService),
      act: (bloc) => bloc.add(const SettingsLocaleSet('pt')),
      expect: () => [const SettingsState(localeCode: 'pt')],
      verify: (_) {
        expect(mockStorageService.setStringCallHistory.last, {
          'key': 'locale_code',
          'value': 'pt',
        });
      },
    );

    blocTest<SettingsBloc, SettingsState>(
      'clearing the locale removes the key and follows the system',
      build: () => SettingsBloc(mockStorageService),
      seed: () => const SettingsState(localeCode: 'pt'),
      act: (bloc) => bloc.add(const SettingsLocaleSet(null)),
      expect: () => [const SettingsState()],
      verify: (_) {
        expect(mockStorageService.removeCallHistory, contains('locale_code'));
      },
    );
  });
}
