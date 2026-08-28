import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/config/app_config.dart';

void main() {
  // Single entrypoint (unlike Dad-mobile's main_dev.dart/main_prod.dart
  // pair) — release builds point at production, everything else (debug/
  // profile, i.e. `flutter run`) points at the local dev backend. Good
  // enough for a 3-screen utility app; see AppConfig's doc comment.
  AppConfig.init(kReleaseMode ? Flavor.prod : Flavor.dev);
  runApp(const ProviderScope(child: CallRecorderApp()));
}
