abstract final class AppConstants {
  static const String appName = 'MedOrder';
  static const String appVersion = '1.0.0';
  static const String baseUrl = 'http://52.1.133.146/api/v1';
  static const String devBaseUrl = 'http://52.1.133.146/api/v1';
  static const String prodBaseUrl = 'http://52.1.133.146/api/v1';

  // Media proxy base URL — nginx proxies R2 images with CORS headers
  static const String mediaBaseUrl = 'http://52.1.133.146/media';

  // R2 public bucket URL (original, has CORS issues on web)
  static const String r2PublicUrl = 'https://pub-e9f05437b08e4c4997ad96709a761250.r2.dev';

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 50;

  // Timeouts
  static const int connectTimeout = 15;
  static const int receiveTimeout = 15;

  // Cache
  static const int imageCacheMaxAge = 7; // days
  static const int dataCacheMaxAge = 5; // minutes

  // OTP
  static const int otpLength = 6;
  static const int otpResendCooldown = 60; // seconds

  // Validation
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 64;
  static const int phoneNumberLength = 11;
  static const int licenseNumberMinLength = 5;

  // Storage Keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userDataKey = 'user_data';
  static const String onboardingCompleteKey = 'onboarding_complete';
  static const String themeKey = 'theme_mode';
  static const String localeKey = 'locale';
}
