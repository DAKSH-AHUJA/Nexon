import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexon_erp/core/theme/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const prefKey = 'nexon_theme_mode';

  Future<ThemeModeNotifier> notifierWithPrefs(
    Map<String, Object> initialValues,
  ) async {
    SharedPreferences.setMockInitialValues(initialValues);
    final notifier = ThemeModeNotifier();
    addTearDown(notifier.dispose);
    // Let the constructor's preference load complete.
    await Future<void>.delayed(Duration.zero);
    return notifier;
  }

  group('initial state', () {
    test('defaults to light when nothing is stored', () async {
      final notifier = await notifierWithPrefs({});

      expect(notifier.state, ThemeMode.light);
    });

    test('restores a stored dark preference', () async {
      final notifier = await notifierWithPrefs({prefKey: 'dark'});

      expect(notifier.state, ThemeMode.dark);
    });

    test('restores a stored light preference', () async {
      final notifier = await notifierWithPrefs({prefKey: 'light'});

      expect(notifier.state, ThemeMode.light);
    });

    test('ignores an unrecognized stored value', () async {
      final notifier = await notifierWithPrefs({prefKey: 'sepia'});

      expect(notifier.state, ThemeMode.light);
    });
  });

  group('toggle', () {
    test('switches between light and dark and persists the choice', () async {
      final notifier = await notifierWithPrefs({});

      await notifier.toggle();
      expect(notifier.state, ThemeMode.dark);
      expect(
        (await SharedPreferences.getInstance()).getString(prefKey),
        'dark',
      );

      await notifier.toggle();
      expect(notifier.state, ThemeMode.light);
      expect(
        (await SharedPreferences.getInstance()).getString(prefKey),
        'light',
      );
    });
  });

  group('setTheme', () {
    test('stores dark and light explicitly', () async {
      final notifier = await notifierWithPrefs({});

      await notifier.setTheme(ThemeMode.dark);
      expect(notifier.state, ThemeMode.dark);
      expect(
        (await SharedPreferences.getInstance()).getString(prefKey),
        'dark',
      );

      await notifier.setTheme(ThemeMode.light);
      expect(notifier.state, ThemeMode.light);
      expect(
        (await SharedPreferences.getInstance()).getString(prefKey),
        'light',
      );
    });

    test('persists system mode as light', () async {
      final notifier = await notifierWithPrefs({});

      await notifier.setTheme(ThemeMode.system);

      expect(notifier.state, ThemeMode.system);
      expect(
        (await SharedPreferences.getInstance()).getString(prefKey),
        'light',
      );
    });
  });

  group('themeModeProvider', () {
    test('exposes the notifier state', () async {
      SharedPreferences.setMockInitialValues({prefKey: 'dark'});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(themeModeProvider), ThemeMode.light);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(themeModeProvider), ThemeMode.dark);
    });
  });
}
