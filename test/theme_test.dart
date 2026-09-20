import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hivemind/core/providers/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ThemeNotifier Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Defaults to ThemeMode.system', () {
      final notifier = ThemeNotifier();
      expect(notifier.state, ThemeMode.system);
    });

    test('Updates state when switching theme modes', () async {
      final notifier = ThemeNotifier();
      expect(notifier.state, ThemeMode.system);

      await notifier.setThemeMode(ThemeMode.dark);
      expect(notifier.state, ThemeMode.dark);

      await notifier.setThemeMode(ThemeMode.light);
      expect(notifier.state, ThemeMode.light);

      await notifier.setThemeMode(ThemeMode.system);
      expect(notifier.state, ThemeMode.system);
    });

    test('Persists theme mode to SharedPreferences', () async {
      final notifier = ThemeNotifier();

      await notifier.setThemeMode(ThemeMode.dark);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('app_theme_mode'), 'dark');

      await notifier.setThemeMode(ThemeMode.light);
      expect(prefs.getString('app_theme_mode'), 'light');

      await notifier.setThemeMode(ThemeMode.system);
      expect(prefs.getString('app_theme_mode'), isNull);
    });

    test('Loads previously saved theme mode on creation', () async {
      SharedPreferences.setMockInitialValues({'app_theme_mode': 'dark'});

      final notifier = ThemeNotifier();
      // Allow async _loadFromPrefs to complete
      await Future<void>.delayed(Duration.zero);

      expect(notifier.state, ThemeMode.dark);
    });
  });
}
