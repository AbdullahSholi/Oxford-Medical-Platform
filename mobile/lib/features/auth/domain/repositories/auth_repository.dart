import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/doctor.dart';

abstract class AuthRepository {
  Future<Either<Failure, Doctor>> login({
    required String email,
    required String password,
  });

  Future<Either<Failure, void>> register({
    required String fullName,
    required String email,
    required String password,
    required String phone,
    String? specialty,
    String? licenseNumber,
    String? clinicName,
    String? clinicAddress,
  });

  Future<Either<Failure, bool>> verifyOtp({
    required String email,
    required String otp,
  });

  Future<Either<Failure, void>> sendOtp({required String email});

  Future<Either<Failure, void>> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  });

  Future<Either<Failure, void>> logout();

  Future<Either<Failure, Doctor>> getCurrentUser();

  Future<bool> isLoggedIn();
}
