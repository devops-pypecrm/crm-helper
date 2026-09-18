import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../storage/secure_storage_service.dart';

part 'secure_storage_provider.g.dart';

// `resetOnError: true` on Android: if the Keystore-backed key is
// unreadable (common after an OS update, a MIUI/ColorOS "app lock"
// change, or a backup restore that doesn't carry the Keystore over),
// the plugin wipes and recreates its prefs file instead of throwing a
// `PlatformException` on every read/write forever — this was the
// device-specific "something went wrong" on login for users whose
// token write failed post-auth.
const _androidOptions = AndroidOptions(resetOnError: true);

@Riverpod(keepAlive: true)
FlutterSecureStorage flutterSecureStorage(ProviderRef<FlutterSecureStorage> ref) =>
    const FlutterSecureStorage(aOptions: _androidOptions);

@Riverpod(keepAlive: true)
SecureStorageService secureStorageService(ProviderRef<SecureStorageService> ref) {
  return SecureStorageService(ref.watch(flutterSecureStorageProvider));
}
