import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/network/secure_storage_provider.dart';

part 'dismissed_update_provider.g.dart';

/// Remembers which release's versionCode the user last tapped "Later" on,
/// so [PendingUpdatePromptController]/the popup doesn't nag on every single
/// app open — but a version *newer* than the dismissed one still prompts,
/// so dismissing once can't accidentally suppress every future update
/// forever. Not auth data, but reuses the same [FlutterSecureStorage]
/// instance already provided for that (see SecureStorageService's own doc
/// comment on why auth specifically needs secure storage) rather than
/// pulling in a whole separate preferences package for one integer.
const _dismissedVersionKey = 'dismissed_update_version_code';

@riverpod
class DismissedUpdateVersion extends _$DismissedUpdateVersion {
  @override
  Future<int?> build() async {
    final raw = await ref.watch(flutterSecureStorageProvider).read(key: _dismissedVersionKey);
    return raw == null ? null : int.tryParse(raw);
  }

  Future<void> dismiss(int versionCode) async {
    await ref.read(flutterSecureStorageProvider).write(
          key: _dismissedVersionKey,
          value: versionCode.toString(),
        );
    state = AsyncData(versionCode);
  }
}
