import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/network/api_client.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final ApiClient apiClient;
  final FlutterSecureStorage storage;

  AuthCubit({required this.apiClient, required this.storage}) : super(AuthInitial());

  Future<void> checkAuth() async {
    final token = await apiClient.getToken();
    if (token != null) {
      try {
        // Try admin dashboard stats as a health check (admin-only endpoint)
        await apiClient.get('/admin/dashboard/stats');
        emit(Authenticated(user: {'fullName': 'Admin'}));
      } catch (_) {
        await apiClient.clearTokens();
        emit(Unauthenticated());
      }
    } else {
      emit(Unauthenticated());
    }
  }

  Future<void> login(String email, String password) async {
    emit(AuthLoading());
    try {
      final res = await apiClient.post('/auth/admin/login', data: {
        'email': email,
        'password': password,
      });
      final data = res['data'] as Map<String, dynamic>;
      final admin = data['admin'] as Map<String, dynamic>;

      await apiClient.saveTokens(
        data['accessToken'] as String,
        data['refreshToken'] as String,
      );
      emit(Authenticated(user: admin));
    } catch (e) {
      emit(Unauthenticated(error: 'Invalid admin credentials'));
    }
  }

  Future<void> logout() async {
    try {
      await apiClient.post('/auth/logout', data: {});
    } catch (_) {}
    await apiClient.clearTokens();
    emit(Unauthenticated());
  }
}
