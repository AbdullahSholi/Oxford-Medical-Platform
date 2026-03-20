import '../../domain/entities/doctor.dart';

class AuthResponseModel {
  final String accessToken;
  final String refreshToken;
  final DoctorModel doctor;

  const AuthResponseModel({
    required this.accessToken,
    required this.refreshToken,
    required this.doctor,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    return AuthResponseModel(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      doctor: DoctorModel.fromJson(json['doctor'] as Map<String, dynamic>),
    );
  }
}

class DoctorModel extends Doctor {
  const DoctorModel({
    required super.id,
    required super.fullName,
    required super.email,
    required super.phone,
    super.specialty,
    super.licenseNumber,
    super.city,
    super.clinicName,
    super.clinicAddress,
    super.profileImageUrl,
    required super.status,
    required super.isEmailVerified,
    required super.isPhoneVerified,
    required super.createdAt,
  });

  factory DoctorModel.fromJson(Map<String, dynamic> json) {
    return DoctorModel(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      specialty: json['specialty'] as String?,
      licenseNumber: (json['licenseNumber'] ?? json['licenseUrl']) as String?,
      city: json['city'] as String?,
      clinicName: json['clinicName'] as String?,
      clinicAddress: json['clinicAddress'] as String?,
      profileImageUrl: (json['profileImageUrl'] ?? json['avatarUrl']) as String?,
      status: _parseStatus(json['status'] as String),
      isEmailVerified: json['isEmailVerified'] as bool? ?? false,
      isPhoneVerified: json['isPhoneVerified'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'specialty': specialty,
      'licenseNumber': licenseNumber,
      'city': city,
      'clinicName': clinicName,
      'clinicAddress': clinicAddress,
      'profileImageUrl': profileImageUrl,
      'status': status.name,
      'isEmailVerified': isEmailVerified,
      'isPhoneVerified': isPhoneVerified,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  static DoctorStatus _parseStatus(String status) {
    return DoctorStatus.values.firstWhere(
      (e) => e.name == status.toLowerCase(),
      orElse: () => DoctorStatus.pending,
    );
  }
}
