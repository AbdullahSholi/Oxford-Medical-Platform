import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/doctor.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/login_request_model.dart';
import '../models/register_request_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remote;
  final AuthLocalDataSource _local;
  final NetworkInfo _networkInfo;

  AuthRepositoryImpl({
    required AuthRemoteDataSource remote,
    required AuthLocalDataSource local,
    required NetworkInfo networkInfo,
  })  : _remote = remote,
        _local = local,
        _networkInfo = networkInfo;

  @override
  Future<Either<Failure, Doctor>> login({
    required String email,
    required String password,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final result = await _remote.login(
        LoginRequestModel(email: email, password: password),
      );
      await _local.saveTokens(
        accessToken: result.accessToken,
        refreshToken: result.refreshToken,
      );
      await _local.saveUserData(result.doctor);
      return Right(result.doctor);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on NetworkException {
      return const Left(NetworkFailure());
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> register({
    required String fullName,
    required String email,
    required String password,
    required String phone,
    String? specialty,
    String? licenseNumber,
    String? clinicName,
    String? clinicAddress,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      await _remote.register(RegisterRequestModel(
        fullName: fullName,
        email: email,
        password: password,
        phone: phone,
        specialty: specialty,
        licenseNumber: licenseNumber,
        clinicName: clinicName,
        clinicAddress: clinicAddress,
      ));
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on NetworkException {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, bool>> verifyOtp({
    required String email,
    required String otp,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final result = await _remote.verifyOtp(email: email, otp: otp);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on NetworkException {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, void>> sendOtp({required String email}) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      await _remote.sendOtp(email: email);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  Future<Either<Failure, void>> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      await _remote.resetPassword(email: email, otp: otp, newPassword: newPassword);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await _remote.logout();
    } catch (_) {
      // Best-effort server logout
    }
    await _local.clearAll();
    return const Right(null);
  }

  @override
  Future<Either<Failure, Doctor>> getCurrentUser() async {
    if (!await _networkInfo.isConnected) {
      final cached = await _local.getCachedUser();
      if (cached != null) return Right(cached);
      return const Left(NetworkFailure());
    }
    try {
      final doctor = await _remote.getCurrentUser();
      await _local.saveUserData(doctor);
      return Right(doctor);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on UnauthorizedException {
      await _local.clearAll();
      return const Left(AuthFailure(message: 'Session expired', statusCode: 401));
    }
  }

  @override
  Future<bool> isLoggedIn() => _local.hasToken();
}
