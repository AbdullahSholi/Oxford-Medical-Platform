import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// The application title
  ///
  /// In en, this message translates to:
  /// **'MedOrder'**
  String get appTitle;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to MedOrder'**
  String get welcomeTitle;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your trusted medical supply platform'**
  String get welcomeSubtitle;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get loginTitle;

  /// No description provided for @loginEmail.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get loginEmail;

  /// No description provided for @loginPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get loginPassword;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get loginButton;

  /// No description provided for @loginForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get loginForgotPassword;

  /// No description provided for @loginNoAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get loginNoAccount;

  /// No description provided for @registerTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get registerTitle;

  /// No description provided for @registerButton.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get registerButton;

  /// No description provided for @registerFullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get registerFullName;

  /// No description provided for @registerPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get registerPhone;

  /// No description provided for @registerSpecialty.
  ///
  /// In en, this message translates to:
  /// **'Medical Specialty'**
  String get registerSpecialty;

  /// No description provided for @registerLicenseNumber.
  ///
  /// In en, this message translates to:
  /// **'License Number'**
  String get registerLicenseNumber;

  /// No description provided for @registerClinicName.
  ///
  /// In en, this message translates to:
  /// **'Clinic / Hospital Name'**
  String get registerClinicName;

  /// No description provided for @registerClinicAddress.
  ///
  /// In en, this message translates to:
  /// **'Clinic Address'**
  String get registerClinicAddress;

  /// No description provided for @registerHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get registerHaveAccount;

  /// No description provided for @otpTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify Your Account'**
  String get otpTitle;

  /// No description provided for @otpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code sent to {phone}'**
  String otpSubtitle(String phone);

  /// No description provided for @otpResend.
  ///
  /// In en, this message translates to:
  /// **'Resend Code'**
  String get otpResend;

  /// No description provided for @otpVerify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get otpVerify;

  /// No description provided for @pendingApprovalTitle.
  ///
  /// In en, this message translates to:
  /// **'Account Under Review'**
  String get pendingApprovalTitle;

  /// No description provided for @pendingApprovalSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your account is being reviewed by our team. You will be notified once approved.'**
  String get pendingApprovalSubtitle;

  /// No description provided for @homeGreeting.
  ///
  /// In en, this message translates to:
  /// **'Hello, Dr. {name}'**
  String homeGreeting(String name);

  /// No description provided for @homeSearch.
  ///
  /// In en, this message translates to:
  /// **'Search products...'**
  String get homeSearch;

  /// No description provided for @homeCategories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get homeCategories;

  /// No description provided for @homeFlashSale.
  ///
  /// In en, this message translates to:
  /// **'Flash Sale'**
  String get homeFlashSale;

  /// No description provided for @homeBestSellers.
  ///
  /// In en, this message translates to:
  /// **'Best Sellers'**
  String get homeBestSellers;

  /// No description provided for @homeViewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get homeViewAll;

  /// No description provided for @productDetails.
  ///
  /// In en, this message translates to:
  /// **'Product Details'**
  String get productDetails;

  /// No description provided for @productAddToCart.
  ///
  /// In en, this message translates to:
  /// **'Add to Cart'**
  String get productAddToCart;

  /// No description provided for @productBuyNow.
  ///
  /// In en, this message translates to:
  /// **'Buy Now'**
  String get productBuyNow;

  /// No description provided for @productDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get productDescription;

  /// No description provided for @productMedicalInfo.
  ///
  /// In en, this message translates to:
  /// **'Medical Information'**
  String get productMedicalInfo;

  /// No description provided for @productReviews.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get productReviews;

  /// No description provided for @productBulkPricing.
  ///
  /// In en, this message translates to:
  /// **'Bulk Pricing'**
  String get productBulkPricing;

  /// No description provided for @productInStock.
  ///
  /// In en, this message translates to:
  /// **'In Stock'**
  String get productInStock;

  /// No description provided for @productOutOfStock.
  ///
  /// In en, this message translates to:
  /// **'Out of Stock'**
  String get productOutOfStock;

  /// No description provided for @cartTitle.
  ///
  /// In en, this message translates to:
  /// **'Shopping Cart'**
  String get cartTitle;

  /// No description provided for @cartEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your cart is empty'**
  String get cartEmpty;

  /// No description provided for @cartSubtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get cartSubtotal;

  /// No description provided for @cartTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get cartTotal;

  /// No description provided for @cartCheckout.
  ///
  /// In en, this message translates to:
  /// **'Proceed to Checkout'**
  String get cartCheckout;

  /// No description provided for @cartRemoveItem.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get cartRemoveItem;

  /// No description provided for @ordersTitle.
  ///
  /// In en, this message translates to:
  /// **'My Orders'**
  String get ordersTitle;

  /// No description provided for @ordersEmpty.
  ///
  /// In en, this message translates to:
  /// **'No orders yet'**
  String get ordersEmpty;

  /// No description provided for @orderDetails.
  ///
  /// In en, this message translates to:
  /// **'Order Details'**
  String get orderDetails;

  /// No description provided for @orderTracking.
  ///
  /// In en, this message translates to:
  /// **'Track Order'**
  String get orderTracking;

  /// No description provided for @orderStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get orderStatus;

  /// No description provided for @orderPlaced.
  ///
  /// In en, this message translates to:
  /// **'Order Placed'**
  String get orderPlaced;

  /// No description provided for @orderConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get orderConfirmed;

  /// No description provided for @orderShipped.
  ///
  /// In en, this message translates to:
  /// **'Shipped'**
  String get orderShipped;

  /// No description provided for @orderDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get orderDelivered;

  /// No description provided for @orderCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get orderCancelled;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get profileTitle;

  /// No description provided for @profileEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get profileEdit;

  /// No description provided for @profileAddresses.
  ///
  /// In en, this message translates to:
  /// **'My Addresses'**
  String get profileAddresses;

  /// No description provided for @profileOrders.
  ///
  /// In en, this message translates to:
  /// **'Order History'**
  String get profileOrders;

  /// No description provided for @profileWishlist.
  ///
  /// In en, this message translates to:
  /// **'Wishlist'**
  String get profileWishlist;

  /// No description provided for @profileNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get profileNotifications;

  /// No description provided for @profileLogout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get profileLogout;

  /// No description provided for @profileLogoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get profileLogoutConfirm;

  /// No description provided for @checkoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Checkout'**
  String get checkoutTitle;

  /// No description provided for @checkoutAddress.
  ///
  /// In en, this message translates to:
  /// **'Delivery Address'**
  String get checkoutAddress;

  /// No description provided for @checkoutPayment.
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get checkoutPayment;

  /// No description provided for @checkoutPlaceOrder.
  ///
  /// In en, this message translates to:
  /// **'Place Order'**
  String get checkoutPlaceOrder;

  /// No description provided for @checkoutCoupon.
  ///
  /// In en, this message translates to:
  /// **'Apply Coupon'**
  String get checkoutCoupon;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @notificationsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No notifications'**
  String get notificationsEmpty;

  /// No description provided for @wishlistTitle.
  ///
  /// In en, this message translates to:
  /// **'Wishlist'**
  String get wishlistTitle;

  /// No description provided for @wishlistEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your wishlist is empty'**
  String get wishlistEmpty;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorGeneric;

  /// No description provided for @errorNetwork.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Please check your network.'**
  String get errorNetwork;

  /// No description provided for @errorServer.
  ///
  /// In en, this message translates to:
  /// **'Server error. Please try again later.'**
  String get errorServer;

  /// No description provided for @errorUnauthorized.
  ///
  /// In en, this message translates to:
  /// **'Session expired. Please login again.'**
  String get errorUnauthorized;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @searchNoResults.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get searchNoResults;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
