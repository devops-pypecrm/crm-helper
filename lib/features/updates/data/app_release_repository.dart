import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_provider.dart';
import '../domain/app_release.dart';

part 'app_release_repository.g.dart';

@Riverpod(keepAlive: true)
AppReleaseRepository appReleaseRepository(ProviderRef<AppReleaseRepository> ref) =>
    AppReleaseRepository(ref.watch(dioProvider));

/// Talks to `/api/app-releases/*` for `platform=helper` — mirrors
/// Dad-mobile/lib/features/app_updates/data/app_release_repository.dart
/// exactly (see pypecrm/APP_UPDATE_SYSTEM.md for the shared mechanism).
class AppReleaseRepository {
  AppReleaseRepository(this._dio);

  final Dio _dio;

  /// Returns `null` (not a throw) on a 404 — no release published yet for
  /// this platform is an expected state, not a failure.
  Future<AppRelease?> getLatestRelease() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/app-releases/latest',
        queryParameters: {'platform': 'helper'},
      );
      return AppRelease.fromJson(response.data!);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> downloadApk({
    required String savePath,
    required void Function(int received, int total) onProgress,
  }) async {
    try {
      await _dio.download(
        '/app-releases/download/helper',
        savePath,
        onReceiveProgress: onProgress,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
