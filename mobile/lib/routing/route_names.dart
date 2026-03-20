abstract final class RouteNames {
  // Auth
  static const welcome = '/auth/welcome';
  static const login = '/auth/login';
  static const register = '/auth/register';
  static const otp = '/auth/otp';
  static const pendingApproval = '/auth/pending';

  // Main tabs
  static const home = '/home';
  static const categories = '/categories';
  static const cart = '/cart';
  static const orders = '/orders';
  static const profile = '/profile';

  // Product
  static const products = '/products';
  static String productDetail(String id) => '/products/$id';
  static const search = '/search';

  // Order
  static String orderDetail(String id) => '/orders/$id';
  static String orderTracking(String id) => '/orders/$id/tracking';
  static const checkout = '/checkout';

  // Other
  static const notifications = '/notifications';
  static const wishlist = '/wishlist';
}
