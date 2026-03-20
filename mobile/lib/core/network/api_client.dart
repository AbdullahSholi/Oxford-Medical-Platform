import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';
import '../error/exceptions.dart';
import 'api_interceptors.dart';
import 'api_response.dart';

class ApiClient {
  late final Dio _dio;
  late final AuthInterceptor authInterceptor;

  ApiClient({required FlutterSecureStorage storage}) {
    _dio = Dio(BaseOptions(
      baseUrl: kDebugMode ? AppConstants.devBaseUrl : AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: AppConstants.connectTimeout),
      receiveTimeout: const Duration(seconds: AppConstants.receiveTimeout),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-App-Version': AppConstants.appVersion,
        'X-Platform': kIsWeb ? 'web' : (defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android'),
      },
    ));

    authInterceptor = AuthInterceptor(storage: storage, dio: _dio);
    _dio.interceptors.addAll([
      authInterceptor,
      LoggingInterceptor(),
      RetryInterceptor(dio: _dio, retries: 2),
    ]);
  }

  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParams,
    required T Function(dynamic) parser,
  }) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParams);
      return ApiResponse.success(parser(response.data['data']));
    } on DioException catch (e) {
      return ApiResponse.error(_mapDioError(e));
    }
  }

  Future<ApiResponse<T>> post<T>(
    String path, {
    dynamic data,
    required T Function(dynamic) parser,
  }) async {
    try {
      final response = await _dio.post(path, data: data);
      return ApiResponse.success(parser(response.data['data']));
    } on DioException catch (e) {
      return ApiResponse.error(_mapDioError(e));
    }
  }

  Future<ApiResponse<T>> patch<T>(
    String path, {
    dynamic data,
    required T Function(dynamic) parser,
  }) async {
    try {
      final response = await _dio.patch(path, data: data);
      return ApiResponse.success(parser(response.data['data']));
    } on DioException catch (e) {
      return ApiResponse.error(_mapDioError(e));
    }
  }

  Future<ApiResponse<T>> delete<T>(
    String path, {
    required T Function(dynamic) parser,
  }) async {
    try {
      final response = await _dio.delete(path);
      final data = response.data is Map ? response.data['data'] : response.data;
      return ApiResponse.success(parser(data));
    } on DioException catch (e) {
      return ApiResponse.error(_mapDioError(e));
    }
  }

  Future<ApiResponse<T>> upload<T>(
    String path, {
    required FormData formData,
    required T Function(dynamic) parser,
    void Function(int, int)? onSendProgress,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: formData,
        onSendProgress: onSendProgress,
        options: Options(contentType: 'multipart/form-data'),
      );
      return ApiResponse.success(parser(response.data['data']));
    } on DioException catch (e) {
      return ApiResponse.error(_mapDioError(e));
    }
  }

  ApiError _mapDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        throw const NetworkException(message: 'Connection timed out');
      case DioExceptionType.connectionError:
        throw const NetworkException();
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final data = e.response?.data;
        final message = data is Map ? data['message'] ?? 'Server error' : 'Server error';
        if (statusCode == 401) {
          throw UnauthorizedException(message: message);
        }
        throw ServerException(message: message, statusCode: statusCode);
      default:
        throw const ServerException(message: 'An unexpected error occurred');
    }
  }
}
