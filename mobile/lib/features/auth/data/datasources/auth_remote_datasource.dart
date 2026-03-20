import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../models/auth_response_model.dart';
import '../models/login_request_model.dart';
import '../models/register_request_model.dart';

abstract class AuthRemoteDataSource {
  Future<AuthResponseModel> login(LoginRequestModel request);
  Future<void> register(RegisterRequestModel request);
  Future<bool> verifyOtp({required String email, required String otp});
  Future<void> sendOtp({required String email});
  Future<void> resetPassword({required String email, required String otp, required String newPassword});
  Future<void> logout();
  Future<DoctorModel> getCurrentUser();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient _apiClient;

  AuthRemoteDataSourceImpl(this._apiClient);

  @override
  Future<AuthResponseModel> login(LoginRequestModel request) async {
    final response = await _apiClient.post<AuthResponseModel>(
      ApiEndpoints.login,
      data: request.toJson(),
      parser: (data) => AuthResponseModel.fromJson(data),
    );
    if (response.success && response.data != null) {
      return response.data!;
    }
    throw ServerException(
      message: response.error?.message ?? 'Login failed',
      statusCode: response.error?.statusCode,
    );
  }

  @override
  Future<void> register(RegisterRequestModel request) async {
    final response = await _apiClient.post<void>(
      ApiEndpoints.register,
      data: request.toJson(),
      parser: (_) {},
    );
    if (!response.success) {
      throw ServerException(
        message: response.error?.message ?? 'Registration failed',
        statusCode: response.error?.statusCode,
      );
    }
  }

  @override
  Future<bool> verifyOtp({
    required String email,
    required String otp,
  }) async {
    final response = await _apiClient.post<void>(
      ApiEndpoints.verifyOtp,
      data: {'email': email, 'otp': otp},
      parser: (_) {},
    );
    if (response.success) {
      return true;
    }
    throw ServerException(
      message: response.error?.message ?? 'OTP verification failed',
      statusCode: response.error?.statusCode,
    );
  }

  @override
  Future<void> sendOtp({required String email}) async {
    final response = await _apiClient.post<void>(
      ApiEndpoints.resendOtp,
      data: {'email': email},
      parser: (_) {},
    );
    if (!response.success) {
      throw ServerException(
        message: response.error?.message ?? 'Failed to send OTP',
        statusCode: response.error?.statusCode,
      );
    }
  }

  @override
  Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    final response = await _apiClient.post<void>(
      ApiEndpoints.resetPassword,
      data: {'email': email, 'otp': otp, 'newPassword': newPassword},
      parser: (_) {},
    );
    if (!response.success) {
      throw ServerException(
        message: response.error?.message ?? 'Password reset failed',
        statusCode: response.error?.statusCode,
      );
    }
  }

  @override
  Future<void> logout() async {
    final response = await _apiClient.post<void>(
      ApiEndpoints.logout,
      parser: (_) {},
    );
    if (!response.success) {
      throw ServerException(
        message: response.error?.message ?? 'Logout failed',
        statusCode: response.error?.statusCode,
      );
    }
  }

  @override
  Future<DoctorModel> getCurrentUser() async {
    final response = await _apiClient.get<DoctorModel>(
      ApiEndpoints.doctorProfile,
      parser: (data) => DoctorModel.fromJson(data),
    );
    if (response.success && response.data != null) {
      return response.data!;
    }
    throw ServerException(
      message: response.error?.message ?? 'Failed to get user data',
      statusCode: response.error?.statusCode,
    );
  }
}
