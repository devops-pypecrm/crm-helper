import 'package:dio/dio.dart';

/// Normalized error surfaced by Repositories so Presentation code never has
/// to know about Dio/DioException directly. Copied pattern-for-pattern from
/// Dad-mobile/lib/core/network/api_exception.dart.
class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  factory ApiException.fromDioException(DioException e) {
    final data = e.response?.data;
    final serverMessage = data is Map<String, dynamic> ? data['message'] as String? : null;
    return ApiException(
      serverMessage ?? _fallbackMessage(e),
      statusCode: e.response?.statusCode,
    );
  }

  static String _fallbackMessage(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'The request timed out. Check your connection and try again.';
      case DioExceptionType.connectionError:
        return 'Could not reach the server. Check your internet connection.';
      case DioExceptionType.badCertificate:
        return 'Could not establish a secure connection. Check your device\'s '
            'date & time are set correctly and try again.';
      case DioExceptionType.cancel:
        return 'Request cancelled.';
      case DioExceptionType.badResponse:
        return 'Something went wrong. Please try again.';
      case DioExceptionType.unknown:
        // Dio's catch-all for low-level failures below its own HTTP layer —
        // most commonly a TLS handshake failure (SocketException/
        // HandshakeException/TlsException), which on a real device is
        // almost always a wrong system clock rather than an app bug. That
        // distinction was previously lost behind a plain "something went
        // wrong", making a device-specific TLS failure indistinguishable
        // from a server error.
        final inner = e.error;
        final innerText = inner?.toString() ?? '';
        final looksLikeTls = innerText.contains('HandshakeException') ||
            innerText.contains('TlsException') ||
            innerText.contains('CERTIFICATE_VERIFY_FAILED');
        if (looksLikeTls) {
          return 'Could not establish a secure connection. This usually means '
              "your device's date & time is incorrect — check it's set to "
              'automatic and try again.';
        }
        return 'Something went wrong. Please try again.';
      case DioExceptionType.transformTimeout:
        return 'Something went wrong. Please try again.';
    }
  }

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}
