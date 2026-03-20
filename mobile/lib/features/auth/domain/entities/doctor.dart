import 'package:equatable/equatable.dart';

enum DoctorStatus { pending, approved, rejected, suspended }

class Doctor extends Equatable {
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final String? specialty;
  final String? licenseNumber;
  final String? city;
  final String? clinicName;
  final String? clinicAddress;
  final String? profileImageUrl;
  final DoctorStatus status;
  final bool isEmailVerified;
  final bool isPhoneVerified;
  final DateTime createdAt;

  const Doctor({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    this.specialty,
    this.licenseNumber,
    this.city,
    this.clinicName,
    this.clinicAddress,
    this.profileImageUrl,
    required this.status,
    required this.isEmailVerified,
    required this.isPhoneVerified,
    required this.createdAt,
  });

  bool get isApproved => status == DoctorStatus.approved;
  bool get isPending => status == DoctorStatus.pending;

  @override
  List<Object?> get props => [id, email, status];
}
