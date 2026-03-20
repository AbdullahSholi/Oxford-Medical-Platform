import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../models/auth_response_model.dart';

abstract class AuthLocalDataSource {
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  });
  Future<void> saveUserData(DoctorModel doctor);
  Future<DoctorModel?> getCachedUser();
  Future<String?> getAccessToken();
  Future<void> clearAll();
  Future<bool> hasToken();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final FlutterSecureStorage _storage;
  final ApiClient? _apiClient;

  AuthLocalDataSourceImpl(this._storage, {ApiClient? apiClient}) : _apiClient = apiClient;

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    // Update in-memory cache immediately for web compatibility
    _apiClient?.authInterceptor.updateTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
    await Future.wait([
      _storage.write(key: AppConstants.accessTokenKey, value: accessToken),
      _storage.write(key: AppConstants.refreshTokenKey, value: refreshToken),
    ]);
  }

  @override
  Future<void> saveUserData(DoctorModel doctor) async {
    await _storage.write(
      key: AppConstants.userDataKey,
      value: jsonEncode(doctor.toJson()),
    );
  }

  @override
  Future<DoctorModel?> getCachedUser() async {
    final data = await _storage.read(key: AppConstants.userDataKey);
    if (data == null) return null;
    try {
      return DoctorModel.fromJson(jsonDecode(data));
    } catch (_) {
      throw const CacheException(message: 'Failed to parse cached user data');
    }
  }

  @override
  Future<String?> getAccessToken() {
    return _storage.read(key: AppConstants.accessTokenKey);
  }

  @override
  Future<void> clearAll() async {
    _apiClient?.authInterceptor.clearTokens();
    await Future.wait([
      _storage.delete(key: AppConstants.accessTokenKey),
      _storage.delete(key: AppConstants.refreshTokenKey),
      _storage.delete(key: AppConstants.userDataKey),
    ]);
  }

  @override
  Future<bool> hasToken() async {
    final token = await _storage.read(key: AppConstants.accessTokenKey);
    return token != null;
  }
}
