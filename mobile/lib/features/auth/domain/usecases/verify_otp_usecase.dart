import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/auth_repository.dart';

class VerifyOtpUseCase extends UseCase<bool, VerifyOtpParams> {
  final AuthRepository _repository;

  VerifyOtpUseCase(this._repository);

  @override
  Future<Either<Failure, bool>> call(VerifyOtpParams params) {
    return _repository.verifyOtp(email: params.email, otp: params.otp);
  }
}

class VerifyOtpParams {
  final String email;
  final String otp;

  const VerifyOtpParams({required this.email, required this.otp});
}
