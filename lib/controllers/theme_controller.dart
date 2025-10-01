import 'package:flutter/material.dart';

class ThemeController {
  ThemeController._();

  static final ThemeController instance = ThemeController._();

  final ValueNotifier<ThemeMode> themeModeNotifier =
      ValueNotifier<ThemeMode>(ThemeMode.light);

  ThemeMode get themeMode => themeModeNotifier.value;

  void toggleDarkMode(bool enabled) {
    themeModeNotifier.value = enabled ? ThemeMode.dark : ThemeMode.light;
  }
}


