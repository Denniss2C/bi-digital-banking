import 'package:banking_app/l10n/gen/app_localizations.dart';
import 'package:flutter/widgets.dart';

export 'package:banking_app/l10n/gen/app_localizations.dart';

/// Shortcut: `context.l10n.tabHome`.
extension AppLocalizationsContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// Spanish is the product language: it is used when none of the device
/// languages is supported. Flutter's default would pick the first supported
/// locale, which is English because the generated list is alphabetical.
Locale resolveAppLocale(
  List<Locale>? deviceLocales,
  Iterable<Locale> supportedLocales,
) {
  for (final locale in deviceLocales ?? const <Locale>[]) {
    for (final supported in supportedLocales) {
      if (supported.languageCode == locale.languageCode) return supported;
    }
  }
  return const Locale('es');
}
