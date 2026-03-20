class RegisterRequestModel {
  final String fullName;
  final String email;
  final String password;
  final String phone;
  final String? specialty;
  final String? licenseNumber;
  final String? clinicName;
  final String? clinicAddress;

  const RegisterRequestModel({
    required this.fullName,
    required this.email,
    required this.password,
    required this.phone,
    this.specialty,
    this.licenseNumber,
    this.clinicName,
    this.clinicAddress,
  });

  Map<String, dynamic> toJson() => {
        'fullName': fullName,
        'email': email,
        'password': password,
        'phone': phone,
        if (specialty != null) 'specialty': specialty,
        if (licenseNumber != null) 'licenseNumber': licenseNumber,
        if (clinicName != null) 'clinicName': clinicName,
        if (clinicAddress != null) 'clinicAddress': clinicAddress,
      };
}
