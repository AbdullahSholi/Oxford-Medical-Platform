import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/doctor.dart';
import '../repositories/auth_repository.dart';

class LoginUseCase extends UseCase<Doctor, LoginParams> {
  final AuthRepository _repository;

  LoginUseCase(this._repository);

  @override
  Future<Either<Failure, Doctor>> call(LoginParams params) {
    return _repository.login(
      email: params.email,
      password: params.password,
    );
  }
}

class LoginParams {
  final String email;
  final String password;

  const LoginParams({required this.email, required this.password});
}
