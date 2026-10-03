import 'package:banking_app/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const supported = AppLocalizations.supportedLocales;

  group('resolveAppLocale', () {
    test('matches the device language ignoring the country', () {
      expect(
        resolveAppLocale(const [Locale('es', 'EC')], supported),
        const Locale('es'),
      );
      expect(
        resolveAppLocale(const [Locale('en', 'US')], supported),
        const Locale('en'),
      );
    });

    test('uses the first supported language in the device order', () {
      expect(
        resolveAppLocale(const [Locale('fr'), Locale('en')], supported),
        const Locale('en'),
      );
    });

    test('falls back to Spanish, not to the first (alphabetical) locale', () {
      expect(supported.first, const Locale('en'));
      expect(
        resolveAppLocale(const [Locale('fr')], supported),
        const Locale('es'),
      );
      expect(resolveAppLocale(null, supported), const Locale('es'));
    });
  });
}
