import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/auth_repository.dart';

class RegisterUseCase extends UseCase<void, RegisterParams> {
  final AuthRepository _repository;

  RegisterUseCase(this._repository);

  @override
  Future<Either<Failure, void>> call(RegisterParams params) {
    return _repository.register(
      fullName: params.fullName,
      email: params.email,
      password: params.password,
      phone: params.phone,
      specialty: params.specialty,
      licenseNumber: params.licenseNumber,
      clinicName: params.clinicName,
      clinicAddress: params.clinicAddress,
    );
  }
}

class RegisterParams {
  final String fullName;
  final String email;
  final String password;
  final String phone;
  final String? specialty;
  final String? licenseNumber;
  final String? clinicName;
  final String? clinicAddress;

  const RegisterParams({
    required this.fullName,
    required this.email,
    required this.password,
    required this.phone,
    this.specialty,
    this.licenseNumber,
    this.clinicName,
    this.clinicAddress,
  });
}
