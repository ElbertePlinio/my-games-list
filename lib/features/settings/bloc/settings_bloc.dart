import 'package:bloc/bloc.dart';
import 'package:picklog/core/data/services/storage/local_storage_service.dart';
import 'package:picklog/features/settings/bloc/settings_event.dart';
import 'package:picklog/features/settings/bloc/settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  SettingsBloc(this._storageService) : super(const SettingsState()) {
    on<SettingsInitialized>(_onSettingsInitialized);
    on<SettingsThemeToggled>(_onSettingsThemeToggled);
    on<SettingsDarkModeSet>(_onSettingsDarkModeSet);
    on<SettingsLocaleSet>(_onSettingsLocaleSet);
  }
  final LocalStorageService _storageService;
  static const String _isDarkModeKey = 'is_dark_mode';
  static const String _localeCodeKey = 'locale_code';

  Future<void> _onSettingsInitialized(
    SettingsInitialized event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      final darkMode = await _storageService.getBool(_isDarkModeKey) ?? false;
      final localeCode = await _storageService.getString(_localeCodeKey);
      emit(state.copyWith(isDarkMode: darkMode, localeCode: localeCode));
    } catch (e) {
      emit(state.copyWith(isDarkMode: false, localeCode: null));
    }
  }

  Future<void> _onSettingsThemeToggled(
    SettingsThemeToggled event,
    Emitter<SettingsState> emit,
  ) async {
    final newValue = !state.isDarkMode;
    await _saveDarkMode(newValue);
    emit(state.copyWith(isDarkMode: newValue));
  }

  Future<void> _onSettingsDarkModeSet(
    SettingsDarkModeSet event,
    Emitter<SettingsState> emit,
  ) async {
    await _saveDarkMode(event.value);
    emit(state.copyWith(isDarkMode: event.value));
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

  Future<void> _saveDarkMode(bool isDarkMode) async {
    await _storageService.setBool(_isDarkModeKey, isDarkMode);
  }
}
