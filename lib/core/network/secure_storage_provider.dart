import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../storage/secure_storage_service.dart';

part 'secure_storage_provider.g.dart';

@Riverpod(keepAlive: true)
FlutterSecureStorage flutterSecureStorage(ProviderRef<FlutterSecureStorage> ref) =>
    const FlutterSecureStorage();

@Riverpod(keepAlive: true)
SecureStorageService secureStorageService(ProviderRef<SecureStorageService> ref) {
  return SecureStorageService(ref.watch(flutterSecureStorageProvider));
}
