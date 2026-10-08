import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_test/flutter_test.dart';
import 'package:picklog/features/settings/bloc/settings_bloc.dart';
import 'package:picklog/features/settings/bloc/settings_event.dart';
import 'package:picklog/features/settings/bloc/settings_state.dart';

import '../../../mocks/mock_services.dart';

void main() {
  group('SettingsBloc', () {
    late MockLocalStorageService storage;

    setUp(() {
      storage = MockLocalStorageService();
    });

    test('initial state follows the system theme', () {
      final bloc = SettingsBloc(storage);
      expect(bloc.state.themeMode, ThemeMode.system);
      bloc.close();
    });

    blocTest<SettingsBloc, SettingsState>(
      'defaults to System when nothing is stored',
      build: () => SettingsBloc(storage),
      act: (bloc) => bloc.add(const SettingsInitialized()),
      expect: () => [const SettingsState()],
      verify: (_) {
        // No migration writes happen for a fresh install.
        expect(storage.setStringCallHistory, isEmpty);
      },
    );

    for (final mode in ThemeMode.values) {
      blocTest<SettingsBloc, SettingsState>(
        'loads a stored ${mode.name} theme mode',
        build: () {
          storage.setString(SettingsBloc.themeModeKey, mode.name);
          storage.setStringCallHistory.clear();
          return SettingsBloc(storage);
        },
        act: (bloc) => bloc.add(const SettingsInitialized()),
        expect: () => [SettingsState(themeMode: mode)],
      );
    }

    group('migration from the legacy dark-mode bool', () {
      blocTest<SettingsBloc, SettingsState>(
        'maps a stored true to Dark, saves the new key and drops the old one',
        build: () {
          storage.setBool(SettingsBloc.legacyDarkModeKey, true);
          return SettingsBloc(storage);
        },
        act: (bloc) => bloc.add(const SettingsInitialized()),
        expect: () => [const SettingsState(themeMode: ThemeMode.dark)],
        verify: (_) {
          expect(storage.setStringCallHistory.last, {
            'key': SettingsBloc.themeModeKey,
            'value': 'dark',
          });
          expect(
            storage.removeCallHistory,
            contains(SettingsBloc.legacyDarkModeKey),
          );
        },
      );

      blocTest<SettingsBloc, SettingsState>(
        'maps a stored false to Light (an explicit earlier choice)',
        build: () {
          storage.setBool(SettingsBloc.legacyDarkModeKey, false);
          return SettingsBloc(storage);
        },
        act: (bloc) => bloc.add(const SettingsInitialized()),
        expect: () => [const SettingsState(themeMode: ThemeMode.light)],
        verify: (_) {
          expect(storage.setStringCallHistory.last['value'], 'light');
        },
      );

      blocTest<SettingsBloc, SettingsState>(
        'prefers the new key when both exist',
        build: () {
          storage
            ..setBool(SettingsBloc.legacyDarkModeKey, true)
            ..setString(SettingsBloc.themeModeKey, 'light');
          storage.setStringCallHistory.clear();
          return SettingsBloc(storage);
        },
        act: (bloc) => bloc.add(const SettingsInitialized()),
        expect: () => [const SettingsState(themeMode: ThemeMode.light)],
        verify: (_) {
          expect(storage.setStringCallHistory, isEmpty);
          expect(storage.removeCallHistory, isEmpty);
        },
      );

      blocTest<SettingsBloc, SettingsState>(
        'ignores an unknown stored value and falls back to the legacy bool',
        build: () {
          storage
            ..setString(SettingsBloc.themeModeKey, 'sepia')
            ..setBool(SettingsBloc.legacyDarkModeKey, true);
          return SettingsBloc(storage);
        },
        act: (bloc) => bloc.add(const SettingsInitialized()),
        expect: () => [const SettingsState(themeMode: ThemeMode.dark)],
      );
    });

    blocTest<SettingsBloc, SettingsState>(
      'setting a theme mode persists it as a string',
      build: () => SettingsBloc(storage),
      act: (bloc) => bloc.add(const SettingsThemeModeSet(ThemeMode.dark)),
      expect: () => [const SettingsState(themeMode: ThemeMode.dark)],
      verify: (_) {
        expect(storage.setStringCallHistory.last, {
          'key': SettingsBloc.themeModeKey,
          'value': 'dark',
        });
      },
    );

    blocTest<SettingsBloc, SettingsState>(
      'switching back to System persists system',
      build: () => SettingsBloc(storage),
      seed: () => const SettingsState(themeMode: ThemeMode.dark),
      act: (bloc) => bloc.add(const SettingsThemeModeSet(ThemeMode.system)),
      expect: () => [const SettingsState()],
      verify: (_) {
        expect(storage.setStringCallHistory.last['value'], 'system');
      },
    );

    blocTest<SettingsBloc, SettingsState>(
      'loads the stored locale on init',
      build: () {
        storage.setString('locale_code', 'pt');
        return SettingsBloc(storage);
      },
      act: (bloc) => bloc.add(const SettingsInitialized()),
      expect: () => [const SettingsState(localeCode: 'pt')],
    );

    blocTest<SettingsBloc, SettingsState>(
      'setting a locale persists it and emits the new code',
      build: () => SettingsBloc(storage),
      act: (bloc) => bloc.add(const SettingsLocaleSet('pt')),
      expect: () => [const SettingsState(localeCode: 'pt')],
      verify: (_) {
        expect(storage.setStringCallHistory.last, {
          'key': 'locale_code',
          'value': 'pt',
        });
      },
    );

    blocTest<SettingsBloc, SettingsState>(
      'clearing the locale removes the key and follows the system',
      build: () => SettingsBloc(storage),
      seed: () => const SettingsState(localeCode: 'pt'),
      act: (bloc) => bloc.add(const SettingsLocaleSet(null)),
      expect: () => [const SettingsState()],
      verify: (_) {
        expect(storage.removeCallHistory, contains('locale_code'));
      },
    );
  });
}
