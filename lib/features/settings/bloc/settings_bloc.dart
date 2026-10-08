import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:picklog/core/data/services/storage/local_storage_service.dart';
import 'package:picklog/features/settings/bloc/settings_event.dart';
import 'package:picklog/features/settings/bloc/settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  SettingsBloc(this._storageService) : super(const SettingsState()) {
    on<SettingsInitialized>(_onSettingsInitialized);
    on<SettingsThemeModeSet>(_onThemeModeSet);
    on<SettingsLocaleSet>(_onSettingsLocaleSet);
  }
  final LocalStorageService _storageService;

  /// Current key: 'system' | 'light' | 'dark'.
  static const String themeModeKey = 'theme_mode';

  /// Legacy bool key from the old dark-mode switch. Migrated once on load.
  static const String legacyDarkModeKey = 'is_dark_mode';
  static const String _localeCodeKey = 'locale_code';

  Future<void> _onSettingsInitialized(
    SettingsInitialized event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      final themeMode = await _loadThemeMode();
      final localeCode = await _storageService.getString(_localeCodeKey);
      emit(state.copyWith(themeMode: themeMode, localeCode: localeCode));
    } catch (e) {
      emit(state.copyWith(themeMode: ThemeMode.system, localeCode: null));
    }
  }

  /// Reads the stored mode. When only the legacy bool exists, maps it to an
  /// explicit light or dark choice, saves the new key and drops the old one.
  Future<ThemeMode> _loadThemeMode() async {
    final stored = await _storageService.getString(themeModeKey);
    final parsed = _parse(stored);
    if (parsed != null) return parsed;

    final legacy = await _storageService.getBool(legacyDarkModeKey);
    if (legacy == null) return ThemeMode.system;

    final migrated = legacy ? ThemeMode.dark : ThemeMode.light;
    await _storageService.setString(themeModeKey, migrated.name);
    await _storageService.remove(legacyDarkModeKey);
    return migrated;
  }

  static ThemeMode? _parse(String? value) {
    for (final mode in ThemeMode.values) {
      if (mode.name == value) return mode;
    }
    return null;
  }

  Future<void> _onThemeModeSet(
    SettingsThemeModeSet event,
    Emitter<SettingsState> emit,
  ) async {
    await _storageService.setString(themeModeKey, event.themeMode.name);
    emit(state.copyWith(themeMode: event.themeMode));
  }

  Future<void> _onSettingsLocaleSet(
    SettingsLocaleSet event,
    Emitter<SettingsState> emit,
  ) async {
    if (event.localeCode == null) {
      await _storageService.remove(_localeCodeKey);
    } else {
      await _storageService.setString(_localeCodeKey, event.localeCode!);
    }
    emit(state.copyWith(localeCode: event.localeCode));
  }
}
