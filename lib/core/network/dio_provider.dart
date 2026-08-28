import 'dart:convert';
import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/auth/providers/session_provider.dart';
import '../config/app_config.dart';
import '../storage/secure_storage_service.dart';
import 'secure_storage_provider.dart';

part 'dio_provider.g.dart';

/// The single Dio instance for the whole app. UI/providers must never call
/// Dio directly — go through a Repository. Mirrors
/// Dad-mobile/lib/core/network/dio_provider.dart.
@Riverpod(keepAlive: true)
Dio dio(ProviderRef<Dio> ref) {
  final storage = ref.watch(secureStorageServiceProvider);
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.instance.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      contentType: 'application/json',
    ),
  );

  dio.interceptors.add(_AuthInterceptor(storage, ref));
  if (kDebugMode) {
    dio.interceptors.add(_CompactLogInterceptor());
  }

  return dio;
}

/// Logs `METHOD path -> status (Nms, Nb)` on success and the error message
/// (never the full body) on failure — gated on kDebugMode so it never runs
/// in release builds.
class _CompactLogInterceptor extends Interceptor {
  final _startTimes = Expando<DateTime>();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _startTimes[options] = DateTime.now();
    developer.log(
      '${options.method} ${options.uri.path}${options.uri.query.isEmpty ? '' : '?${options.uri.query}'}',
      name: 'http',
    );
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final started = _startTimes[response.requestOptions];
    final ms = started == null ? '?' : DateTime.now().difference(started).inMilliseconds;
    final bytes = _byteLength(response.data);
    developer.log(
      '${response.requestOptions.method} ${response.requestOptions.uri.path} -> ${response.statusCode} (${ms}ms, ${bytes}b)',
      name: 'http',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    developer.log(
      '${err.requestOptions.method} ${err.requestOptions.uri.path} -> ERROR ${err.response?.statusCode ?? ''} ${err.message}',
      name: 'http',
      level: 900,
    );
    handler.next(err);
  }

  int _byteLength(dynamic data) {
    try {
      return utf8.encode(data is String ? data : jsonEncode(data)).length;
    } catch (_) {
      return -1;
    }
  }
}

/// Injects the stored JWT as `Authorization: Bearer <token>` on every
/// request, and reacts to a `401` by clearing the session — there's no
/// refresh-token flow on the backend, so a 401 always means "log out."
class _AuthInterceptor extends Interceptor {
  _AuthInterceptor(this._storage, this._ref);

  final SecureStorageService _storage;
  final ProviderRef<Dio> _ref;

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _storage.readToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final isLoginRequest = err.requestOptions.path.contains('/auth/login');
    if (err.response?.statusCode == 401 && !isLoginRequest) {
      await _ref.read(sessionControllerProvider.notifier).forceLogout();
    }
    handler.next(err);
  }
}
