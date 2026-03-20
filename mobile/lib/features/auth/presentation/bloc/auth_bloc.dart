import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/doctor.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/usecases/verify_otp_usecase.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase _loginUseCase;
  final RegisterUseCase _registerUseCase;
  final VerifyOtpUseCase _verifyOtpUseCase;
  final LogoutUseCase _logoutUseCase;
  final AuthRepository _authRepository;

  AuthBloc({
    required LoginUseCase loginUseCase,
    required RegisterUseCase registerUseCase,
    required VerifyOtpUseCase verifyOtpUseCase,
    required LogoutUseCase logoutUseCase,
    required AuthRepository authRepository,
  })  : _loginUseCase = loginUseCase,
        _registerUseCase = registerUseCase,
        _verifyOtpUseCase = verifyOtpUseCase,
        _logoutUseCase = logoutUseCase,
        _authRepository = authRepository,
        super(const AuthInitial()) {
    on<AuthCheckRequested>(_onCheckRequested);
    on<AuthLoginSubmitted>(_onLoginSubmitted);
    on<AuthRegisterSubmitted>(_onRegisterSubmitted);
    on<AuthOtpSubmitted>(_onOtpSubmitted);
    on<AuthOtpResendRequested>(_onOtpResendRequested);
    on<AuthForgotPasswordRequested>(_onForgotPasswordRequested);
    on<AuthResetPasswordSubmitted>(_onResetPasswordSubmitted);
    on<AuthLogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    final isLoggedIn = await _authRepository.isLoggedIn();
    if (!isLoggedIn) {
      emit(const AuthUnauthenticated());
      return;
    }

    final result = await _authRepository.getCurrentUser();
    result.fold(
      (failure) => emit(const AuthUnauthenticated()),
      (doctor) => _emitAuthenticatedState(emit, doctor),
    );
  }

  Future<void> _onLoginSubmitted(
    AuthLoginSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await _loginUseCase(
      LoginParams(email: event.email, password: event.password),
    );
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (doctor) => _emitAuthenticatedState(emit, doctor),
    );
  }

  Future<void> _onRegisterSubmitted(
    AuthRegisterSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await _registerUseCase(RegisterParams(
      fullName: event.fullName,
      email: event.email,
      password: event.password,
      phone: event.phone,
      specialty: event.specialty,
      licenseNumber: event.licenseNumber,
      clinicName: event.clinicName,
      clinicAddress: event.clinicAddress,
    ));
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) => emit(AuthRegistrationSuccess(event.email)),
    );
  }

  Future<void> _onOtpSubmitted(
    AuthOtpSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await _verifyOtpUseCase(
      VerifyOtpParams(email: event.email, otp: event.otp),
    );
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) => emit(AuthOtpVerified(email: event.email, otp: event.otp)),
    );
  }

  Future<void> _onOtpResendRequested(
    AuthOtpResendRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _authRepository.sendOtp(email: event.email);
    emit(AuthOtpSent(event.email));
  }

  Future<void> _onForgotPasswordRequested(
    AuthForgotPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await _authRepository.sendOtp(email: event.email);
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) => emit(AuthOtpSent(event.email)),
    );
  }

  Future<void> _onResetPasswordSubmitted(
    AuthResetPasswordSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await _authRepository.resetPassword(
      email: event.email,
      otp: event.otp,
      newPassword: event.newPassword,
    );
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) => emit(const AuthPasswordResetSuccess()),
    );
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    await _logoutUseCase(const NoParams());
    emit(const AuthUnauthenticated());
  }

  void _emitAuthenticatedState(Emitter<AuthState> emit, Doctor doctor) {
    if (doctor.isPending) {
      emit(AuthPendingApproval(doctor));
    } else {
      emit(AuthAuthenticated(doctor));
    }
  }
}
