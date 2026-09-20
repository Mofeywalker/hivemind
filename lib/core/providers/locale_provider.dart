import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppLanguage {
  system,
  english,
  german,
}

class LocaleNotifier extends StateNotifier<Locale?> {
  LocaleNotifier() : super(null);

  AppLanguage get currentLanguage {
    if (state == null) return AppLanguage.system;
    if (state?.languageCode == 'de') return AppLanguage.german;
    return AppLanguage.english;
  }

  void setLanguage(AppLanguage language) {
    switch (language) {
      case AppLanguage.system:
        state = null;
        break;
      case AppLanguage.english:
        state = const Locale('en');
        break;
      case AppLanguage.german:
        state = const Locale('de');
        break;
    }
  }

  void setLocale(Locale? locale) {
    state = locale;
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale?>((ref) {
  return LocaleNotifier();
});
