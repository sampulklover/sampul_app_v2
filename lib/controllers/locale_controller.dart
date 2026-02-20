import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleController {
  LocaleController._();

  static final LocaleController instance = LocaleController._();

  final ValueNotifier<Locale> localeNotifier = ValueNotifier<Locale>(const Locale('en'));

  Locale get locale => localeNotifier.value;

  /// Initialize locale from SharedPreferences
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('language_code') ?? 'en';
    localeNotifier.value = Locale(languageCode);
  }

  /// Set the locale and persist it
  Future<void> setLocale(Locale locale) async {
    localeNotifier.value = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', locale.languageCode);
  }

  /// Get available locales
  List<Locale> get supportedLocales => const [
        Locale('en'), // English
        Locale('ms'), // Malay
      ];
}
