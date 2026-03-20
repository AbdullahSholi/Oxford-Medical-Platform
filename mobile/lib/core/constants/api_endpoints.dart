abstract final class ApiEndpoints {
  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String verifyOtp = '/auth/otp/verify';
  static const String resendOtp = '/auth/otp/send';
  static const String refreshToken = '/auth/refresh-token';
  static const String logout = '/auth/logout';
  static const String forgotPassword = '/auth/otp/send';
  static const String resetPassword = '/auth/password/reset';

  // Doctor Profile
  static const String doctorProfile = '/doctors/me';
  static const String updateProfile = '/doctors/me';
  static const String uploadLicense = '/doctors/me/license';
  static const String doctorAddresses = '/doctors/me/addresses';

  // Products
  static const String products = '/products';
  static String productById(String id) => '/products/$id';
  static String productReviews(String id) => '/products/$id/reviews';
  static const String productSearch = '/products';

  // Categories
  static const String categories = '/categories';
  static String categoryById(String id) => '/categories/$id';
  static String categoryProducts(String id) => '/categories/$id/products';

  // Cart
  static const String cart = '/cart';
  static const String cartItems = '/cart/items';
  static String cartItem(String id) => '/cart/items/$id';
  static const String cartApplyCoupon = '/cart/coupon';
  static const String cartRemoveCoupon = '/cart/coupon';

  // Orders
  static const String orders = '/orders';
  static String orderById(String id) => '/orders/$id';
  static String orderCancel(String id) => '/orders/$id/cancel';
  static String orderTracking(String id) => '/orders/$id/tracking';
  static const String checkout = '/orders';

  // Reviews
  static const String reviews = '/reviews';
  static String reviewById(String id) => '/reviews/$id';

  // Wishlist
  static const String wishlist = '/wishlist';
  static String wishlistItem(String productId) => '/wishlist/$productId';

  // Notifications
  static const String notifications = '/notifications';
  static String notificationMarkRead(String id) => '/notifications/$id/read';
  static String notificationById(String id) => '/notifications/$id';
  static const String notificationsReadAll = '/notifications/read-all';
  static const String registerFcmToken = '/notifications/fcm-token';

  // Brands
  static const String brands = '/brands';

  // Banners
  static const String banners = '/banners';

  // Flash Sales
  static const String flashSales = '/flash-sales';
  static const String activeFlashSale = '/flash-sales/active';

  // Discounts
  static const String validateCoupon = '/discounts/validate';

  // Upload
  static const String uploadImage = '/upload/image';
}
