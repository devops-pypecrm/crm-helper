import 'dart:async';

import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app.dart';
import 'core/config/app_config.dart';

void main() {
  // google_fonts fetches its font files over the network at runtime by
  // default (no fonts are bundled as assets here) — on ANY failure (no
  // connectivity, DNS failure, timeout, a blocked request on a locked-down
  // network) its loader rethrows into an unhandled Future rejection, and
  // with no runZonedGuarded/FlutterError.onError anywhere, that took down
  // the whole isolate on every single cold start for a device with no/poor
  // internet — a tight crash loop, not a one-off, since AppTheme.light
  // (which triggers the font load) runs on every launch attempt. This is a
  // sideloaded field app that has to work offline, so runtime font
  // fetching is turned off outright rather than just caught — same visual
  // fallback (system default font) either way, but with zero network
  // dependency instead of a caught-but-still-ugly failure every launch.
  GoogleFonts.config.allowRuntimeFetching = false;

  // Safety net for whatever the next uncaught exception turns out to be —
  // this app has no crash reporting at all (no Crashlytics, nothing), so
  // an uncaught error anywhere was previously invisible: no trace, just a
  // generic OEM "app is experiencing crashes" watchdog notification with
  // nothing to go on. At minimum this gets a real stack trace into
  // logcat/adb instead of silence.
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('Uncaught FlutterError: ${details.exceptionAsString()}\n${details.stack}');
  };

  runZonedGuarded(
    () {
      // Single entrypoint (unlike Dad-mobile's main_dev.dart/main_prod.dart
      // pair) — release builds point at production, everything else (debug/
      // profile, i.e. `flutter run`) points at the local dev backend. Good
      // enough for a 3-screen utility app; see AppConfig's doc comment.
      AppConfig.init(kReleaseMode ? Flavor.prod : Flavor.dev);
      runApp(const ProviderScope(child: CallRecorderApp()));
    },
    (error, stack) {
      debugPrint('Uncaught zone error: $error\n$stack');
    },
  );
}
