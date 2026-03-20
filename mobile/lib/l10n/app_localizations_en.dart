// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'MedOrder';

  @override
  String get welcomeTitle => 'Welcome to MedOrder';

  @override
  String get welcomeSubtitle => 'Your trusted medical supply platform';

  @override
  String get loginTitle => 'Sign In';

  @override
  String get loginEmail => 'Email Address';

  @override
  String get loginPassword => 'Password';

  @override
  String get loginButton => 'Sign In';

  @override
  String get loginForgotPassword => 'Forgot Password?';

  @override
  String get loginNoAccount => 'Don\'t have an account?';

  @override
  String get registerTitle => 'Create Account';

  @override
  String get registerButton => 'Create Account';

  @override
  String get registerFullName => 'Full Name';

  @override
  String get registerPhone => 'Phone Number';

  @override
  String get registerSpecialty => 'Medical Specialty';

  @override
  String get registerLicenseNumber => 'License Number';

  @override
  String get registerClinicName => 'Clinic / Hospital Name';

  @override
  String get registerClinicAddress => 'Clinic Address';

  @override
  String get registerHaveAccount => 'Already have an account?';

  @override
  String get otpTitle => 'Verify Your Account';

  @override
  String otpSubtitle(String phone) {
    return 'Enter the 6-digit code sent to $phone';
  }

  @override
  String get otpResend => 'Resend Code';

  @override
  String get otpVerify => 'Verify';

  @override
  String get pendingApprovalTitle => 'Account Under Review';

  @override
  String get pendingApprovalSubtitle =>
      'Your account is being reviewed by our team. You will be notified once approved.';

  @override
  String homeGreeting(String name) {
    return 'Hello, Dr. $name';
  }

  @override
  String get homeSearch => 'Search products...';

  @override
  String get homeCategories => 'Categories';

  @override
  String get homeFlashSale => 'Flash Sale';

  @override
  String get homeBestSellers => 'Best Sellers';

  @override
  String get homeViewAll => 'View All';

  @override
  String get productDetails => 'Product Details';

  @override
  String get productAddToCart => 'Add to Cart';

  @override
  String get productBuyNow => 'Buy Now';

  @override
  String get productDescription => 'Description';

  @override
  String get productMedicalInfo => 'Medical Information';

  @override
  String get productReviews => 'Reviews';

  @override
  String get productBulkPricing => 'Bulk Pricing';

  @override
  String get productInStock => 'In Stock';

  @override
  String get productOutOfStock => 'Out of Stock';

  @override
  String get cartTitle => 'Shopping Cart';

  @override
  String get cartEmpty => 'Your cart is empty';

  @override
  String get cartSubtotal => 'Subtotal';

  @override
  String get cartTotal => 'Total';

  @override
  String get cartCheckout => 'Proceed to Checkout';

  @override
  String get cartRemoveItem => 'Remove';

  @override
  String get ordersTitle => 'My Orders';

  @override
  String get ordersEmpty => 'No orders yet';

  @override
  String get orderDetails => 'Order Details';

  @override
  String get orderTracking => 'Track Order';

  @override
  String get orderStatus => 'Status';

  @override
  String get orderPlaced => 'Order Placed';

  @override
  String get orderConfirmed => 'Confirmed';

  @override
  String get orderShipped => 'Shipped';

  @override
  String get orderDelivered => 'Delivered';

  @override
  String get orderCancelled => 'Cancelled';

  @override
  String get profileTitle => 'My Profile';

  @override
  String get profileEdit => 'Edit Profile';

  @override
  String get profileAddresses => 'My Addresses';

  @override
  String get profileOrders => 'Order History';

  @override
  String get profileWishlist => 'Wishlist';

  @override
  String get profileNotifications => 'Notifications';

  @override
  String get profileLogout => 'Logout';

  @override
  String get profileLogoutConfirm => 'Are you sure you want to logout?';

  @override
  String get checkoutTitle => 'Checkout';

  @override
  String get checkoutAddress => 'Delivery Address';

  @override
  String get checkoutPayment => 'Payment Method';

  @override
  String get checkoutPlaceOrder => 'Place Order';

  @override
  String get checkoutCoupon => 'Apply Coupon';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsEmpty => 'No notifications';

  @override
  String get wishlistTitle => 'Wishlist';

  @override
  String get wishlistEmpty => 'Your wishlist is empty';

  @override
  String get errorGeneric => 'Something went wrong. Please try again.';

  @override
  String get errorNetwork =>
      'No internet connection. Please check your network.';

  @override
  String get errorServer => 'Server error. Please try again later.';

  @override
  String get errorUnauthorized => 'Session expired. Please login again.';

  @override
  String get retry => 'Retry';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get loading => 'Loading...';

  @override
  String get searchNoResults => 'No results found';
}
