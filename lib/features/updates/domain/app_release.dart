import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_release.freezed.dart';
part 'app_release.g.dart';

/// `GET /api/app-releases/latest?platform=helper` response shape — same
/// contract Dad-mobile's own update checker uses. See
/// pypecrm/APP_UPDATE_SYSTEM.md for the full mechanism this is part of.
@freezed
class AppRelease with _$AppRelease {
  const factory AppRelease({
    required String versionName,
    required int versionCode,
    required String releaseNotes,
    required String apkFileName,
    required String releasedAt,
  }) = _AppRelease;

  factory AppRelease.fromJson(Map<String, dynamic> json) => _$AppReleaseFromJson(json);
}
