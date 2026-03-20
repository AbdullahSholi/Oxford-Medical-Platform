import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/api_endpoints.dart';
import '../constants/app_constants.dart';

class AuthInterceptor extends Interceptor {
  final FlutterSecureStorage _storage;
  final Dio _dio;

  // In-memory token cache to avoid FlutterSecureStorage hangs on web
  String? _cachedAccessToken;
  String? _cachedRefreshToken;

  AuthInterceptor({
    required FlutterSecureStorage storage,
    required Dio dio,
  })  : _storage = storage,
        _dio = dio;

  /// Call after login/token refresh to update in-memory cache
  void updateTokens({String? accessToken, String? refreshToken}) {
    _cachedAccessToken = accessToken;
    _cachedRefreshToken = refreshToken;
  }

  void clearTokens() {
    _cachedAccessToken = null;
    _cachedRefreshToken = null;
  }

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Use cached token first, fallback to storage
    String? token = _cachedAccessToken;
    if (token == null) {
      try {
        token = await _storage.read(key: AppConstants.accessTokenKey)
            .timeout(const Duration(seconds: 2), onTimeout: () => null);
        _cachedAccessToken = token;
      } catch (_) {
        // Storage read failed, proceed without token
      }
    }
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      final refreshed = await _tryRefreshToken();
      if (refreshed) {
        err.requestOptions.headers['Authorization'] = 'Bearer $_cachedAccessToken';
        try {
          final response = await _dio.fetch(err.requestOptions);
          return handler.resolve(response);
        } on DioException catch (e) {
          return handler.next(e);
        }
      }
    }
    handler.next(err);
  }

  Future<bool> _tryRefreshToken() async {
    try {
      String? refreshToken = _cachedRefreshToken;
      refreshToken ??= await _storage.read(key: AppConstants.refreshTokenKey)
          .timeout(const Duration(seconds: 2), onTimeout: () => null);
      if (refreshToken == null) return false;

      final response = await Dio().post(
        '${kDebugMode ? AppConstants.devBaseUrl : AppConstants.baseUrl}${ApiEndpoints.refreshToken}',
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200) {
        final data = response.data['data'];
        _cachedAccessToken = data['accessToken'];
        _cachedRefreshToken = data['refreshToken'];
        await _storage.write(
          key: AppConstants.accessTokenKey,
          value: _cachedAccessToken!,
        );
        await _storage.write(
          key: AppConstants.refreshTokenKey,
          value: _cachedRefreshToken!,
        );
        return true;
      }
    } catch (_) {}
    return false;
  }
}

class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('→ ${options.method} ${options.path}');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('← ${response.statusCode} ${response.requestOptions.path}');
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('✕ ${err.response?.statusCode} ${err.requestOptions.path}: ${err.message}');
    }
    handler.next(err);
  }
}

class RetryInterceptor extends Interceptor {
  final Dio _dio;
  final int retries;

  RetryInterceptor({required Dio dio, this.retries = 2}) : _dio = dio;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (_shouldRetry(err)) {
      for (var i = 0; i < retries; i++) {
        await Future.delayed(Duration(seconds: i + 1));
        try {
          final response = await _dio.fetch(err.requestOptions);
          return handler.resolve(response);
        } on DioException catch (e) {
          if (i == retries - 1) return handler.next(e);
        }
      }
    }
    handler.next(err);
  }

  bool _shouldRetry(DioException err) {
    return err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        (err.response?.statusCode != null && err.response!.statusCode! >= 500);
  }
}
