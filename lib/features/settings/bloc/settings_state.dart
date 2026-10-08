import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart' show ThemeMode;

class SettingsState extends Equatable {
  const SettingsState({this.themeMode = ThemeMode.system, this.localeCode});

  /// System, light or dark. Defaults to following the device.
  final ThemeMode themeMode;

  /// The chosen language code ('en', 'pt'), or null to follow the device.
  final String? localeCode;

  // Sentinel so copyWith can distinguish "leave unchanged" from "set to null"
  // (null is a valid localeCode meaning "follow the device locale").
  static const Object _unchanged = Object();

  SettingsState copyWith({
    ThemeMode? themeMode,
    Object? localeCode = _unchanged,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      localeCode: identical(localeCode, _unchanged)
          ? this.localeCode
          : localeCode as String?,
    );
  }

  @override
  List<Object?> get props => [themeMode, localeCode];
}
