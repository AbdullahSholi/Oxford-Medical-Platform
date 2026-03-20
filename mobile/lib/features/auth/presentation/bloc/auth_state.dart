import 'package:equatable/equatable.dart';
import '../../domain/entities/doctor.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final Doctor doctor;

  const AuthAuthenticated(this.doctor);

  @override
  List<Object?> get props => [doctor];
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthPendingApproval extends AuthState {
  final Doctor doctor;

  const AuthPendingApproval(this.doctor);

  @override
  List<Object?> get props => [doctor];
}

class AuthOtpSent extends AuthState {
  final String email;

  const AuthOtpSent(this.email);

  @override
  List<Object?> get props => [email];
}

class AuthRegistrationSuccess extends AuthState {
  final String email;

  const AuthRegistrationSuccess(this.email);

  @override
  List<Object?> get props => [email];
}

class AuthOtpVerified extends AuthState {
  final String email;
  final String otp;

  const AuthOtpVerified({required this.email, required this.otp});

  @override
  List<Object?> get props => [email, otp];
}

class AuthPasswordResetSuccess extends AuthState {
  const AuthPasswordResetSuccess();
}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}
