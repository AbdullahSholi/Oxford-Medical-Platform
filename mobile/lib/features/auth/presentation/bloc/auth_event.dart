import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

class AuthLoginSubmitted extends AuthEvent {
  final String email;
  final String password;

  const AuthLoginSubmitted({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

class AuthRegisterSubmitted extends AuthEvent {
  final String fullName;
  final String email;
  final String password;
  final String phone;
  final String? specialty;
  final String? licenseNumber;
  final String? clinicName;
  final String? clinicAddress;

  const AuthRegisterSubmitted({
    required this.fullName,
    required this.email,
    required this.password,
    required this.phone,
    this.specialty,
    this.licenseNumber,
    this.clinicName,
    this.clinicAddress,
  });

  @override
  List<Object?> get props => [email, phone];
}

class AuthOtpSubmitted extends AuthEvent {
  final String email;
  final String otp;

  const AuthOtpSubmitted({required this.email, required this.otp});

  @override
  List<Object?> get props => [email, otp];
}

class AuthOtpResendRequested extends AuthEvent {
  final String email;

  const AuthOtpResendRequested({required this.email});

  @override
  List<Object?> get props => [email];
}

class AuthForgotPasswordRequested extends AuthEvent {
  final String email;

  const AuthForgotPasswordRequested({required this.email});

  @override
  List<Object?> get props => [email];
}

class AuthResetPasswordSubmitted extends AuthEvent {
  final String email;
  final String otp;
  final String newPassword;

  const AuthResetPasswordSubmitted({
    required this.email,
    required this.otp,
    required this.newPassword,
  });

  @override
  List<Object?> get props => [email, otp, newPassword];
}

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}
