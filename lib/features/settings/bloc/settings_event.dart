import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart' show ThemeMode;

abstract class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object?> get props => [];
}

class SettingsInitialized extends SettingsEvent {
  const SettingsInitialized();
}

/// Sets the theme to follow the system, or forces light or dark.
class SettingsThemeModeSet extends SettingsEvent {
  const SettingsThemeModeSet(this.themeMode);
  final ThemeMode themeMode;

  @override
  List<Object?> get props => [themeMode];
}

class SettingsLocaleSet extends SettingsEvent {
  const SettingsLocaleSet(this.localeCode);

  /// 'en', 'pt', or null to follow the device locale.
  final String? localeCode;

  @override
  List<Object?> get props => [localeCode];
}
