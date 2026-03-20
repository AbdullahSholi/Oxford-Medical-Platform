import '../constants/app_constants.dart';

abstract final class Validators {
  static final _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  static final _phoneRegex = RegExp(r'^\+?[0-9]{10,15}$');

  static String? email(String? value) {
    if (value == null || value.isEmpty) return 'Email is required';
    if (!_emailRegex.hasMatch(value.trim())) return 'Enter a valid email';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < AppConstants.minPasswordLength) {
      return 'Password must be at least ${AppConstants.minPasswordLength} characters';
    }
    if (value.length > AppConstants.maxPasswordLength) {
      return 'Password is too long';
    }
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.isEmpty) return 'Phone number is required';
    if (!_phoneRegex.hasMatch(value.trim())) return 'Enter a valid phone number';
    return null;
  }

  static String? required(String? value, [String fieldName = 'This field']) {
    if (value == null || value.trim().isEmpty) return '$fieldName is required';
    return null;
  }

  static String? licenseNumber(String? value) {
    if (value == null || value.isEmpty) return 'License number is required';
    if (value.length < AppConstants.licenseNumberMinLength) {
      return 'Enter a valid license number';
    }
    return null;
  }

  static String? otp(String? value) {
    if (value == null || value.isEmpty) return 'OTP is required';
    if (value.length != AppConstants.otpLength) {
      return 'Enter ${AppConstants.otpLength}-digit code';
    }
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) return 'Confirm your password';
    if (value != password) return 'Passwords do not match';
    return null;
  }
}
