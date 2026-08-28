enum Flavor { dev, prod }

/// App-wide configuration, resolved once at startup (see `main.dart`).
/// Mirrors Dad-mobile/lib/core/config/app_config.dart's flavor pattern —
/// this app has only one entrypoint (not separate main_dev.dart/main_prod.dart
/// files), so the flavor is picked automatically from the build mode instead
/// (see `main.dart`), which is enough for a 3-screen utility app.
class AppConfig {
  AppConfig._({required this.flavor, required this.apiBaseUrl});

  final Flavor flavor;
  final String apiBaseUrl;

  static AppConfig? _instance;

  static AppConfig get instance {
    assert(_instance != null, 'AppConfig.init() must be called before use');
    return _instance!;
  }

  static void init(Flavor flavor) {
    _instance = AppConfig._(flavor: flavor, apiBaseUrl: _resolveBaseUrl(flavor));
  }

  static String _resolveBaseUrl(Flavor flavor) {
    switch (flavor) {
      case Flavor.prod:
        // Matches Dad-backend production origin (envs/backend/.env.production),
        // same value Dad-mobile's AppConfig uses.
        return 'https://pypecrm.com/api';
      case Flavor.dev:
        // Matches Dad-backend dev server (PORT=5001 in Dad-backend/.env.example).
        // Android (emulator or physical device over USB) reaches the host via
        // `adb reverse tcp:5001 tcp:5001`, which tunnels the device's own
        // localhost:5001 to the host machine. Run that before `flutter run`.
        return 'http://localhost:5001/api';
    }
  }

  bool get isProd => flavor == Flavor.prod;
}
