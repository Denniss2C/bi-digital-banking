/// Environment the app was built for. Each value maps to a native flavor
/// (Android product flavor / iOS scheme) and to its own Firebase app.
enum Flavor { dev, prod }

/// Immutable build-time configuration, chosen by the entry point
/// (`main_dev.dart` or `main_prod.dart`).
class AppConfig {
  const AppConfig._({required this.flavor, required this.appName});

  static const dev = AppConfig._(flavor: Flavor.dev, appName: 'BI Dev');
  static const prod = AppConfig._(flavor: Flavor.prod, appName: 'BI Banca');

  final Flavor flavor;

  /// Same name the launcher shows: Android `appName` manifest placeholder and
  /// iOS `APP_DISPLAY_NAME`.
  final String appName;

  /// Debug tooling (debug panel, ChaosInterceptor) only exists in dev.
  bool get enableDebugTools => flavor == Flavor.dev;
}
