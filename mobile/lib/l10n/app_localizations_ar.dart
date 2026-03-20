// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'ميد أوردر';

  @override
  String get welcomeTitle => 'مرحباً بك في ميد أوردر';

  @override
  String get welcomeSubtitle => 'منصتك الموثوقة للمستلزمات الطبية';

  @override
  String get loginTitle => 'تسجيل الدخول';

  @override
  String get loginEmail => 'البريد الإلكتروني';

  @override
  String get loginPassword => 'كلمة المرور';

  @override
  String get loginButton => 'تسجيل الدخول';

  @override
  String get loginForgotPassword => 'نسيت كلمة المرور؟';

  @override
  String get loginNoAccount => 'ليس لديك حساب؟';

  @override
  String get registerTitle => 'إنشاء حساب';

  @override
  String get registerButton => 'إنشاء حساب';

  @override
  String get registerFullName => 'الاسم الكامل';

  @override
  String get registerPhone => 'رقم الهاتف';

  @override
  String get registerSpecialty => 'التخصص الطبي';

  @override
  String get registerLicenseNumber => 'رقم الترخيص';

  @override
  String get registerClinicName => 'اسم العيادة / المستشفى';

  @override
  String get registerClinicAddress => 'عنوان العيادة';

  @override
  String get registerHaveAccount => 'لديك حساب بالفعل؟';

  @override
  String get otpTitle => 'تحقق من حسابك';

  @override
  String otpSubtitle(String phone) {
    return 'أدخل الرمز المكون من 6 أرقام المرسل إلى $phone';
  }

  @override
  String get otpResend => 'إعادة إرسال الرمز';

  @override
  String get otpVerify => 'تحقق';

  @override
  String get pendingApprovalTitle => 'الحساب قيد المراجعة';

  @override
  String get pendingApprovalSubtitle =>
      'حسابك قيد المراجعة من قبل فريقنا. سيتم إخطارك بمجرد الموافقة.';

  @override
  String homeGreeting(String name) {
    return 'مرحباً، د. $name';
  }

  @override
  String get homeSearch => 'البحث عن المنتجات...';

  @override
  String get homeCategories => 'الفئات';

  @override
  String get homeFlashSale => 'عرض خاص';

  @override
  String get homeBestSellers => 'الأكثر مبيعاً';

  @override
  String get homeViewAll => 'عرض الكل';

  @override
  String get productDetails => 'تفاصيل المنتج';

  @override
  String get productAddToCart => 'أضف إلى السلة';

  @override
  String get productBuyNow => 'اشتري الآن';

  @override
  String get productDescription => 'الوصف';

  @override
  String get productMedicalInfo => 'المعلومات الطبية';

  @override
  String get productReviews => 'التقييمات';

  @override
  String get productBulkPricing => 'أسعار الجملة';

  @override
  String get productInStock => 'متوفر';

  @override
  String get productOutOfStock => 'غير متوفر';

  @override
  String get cartTitle => 'سلة التسوق';

  @override
  String get cartEmpty => 'سلة التسوق فارغة';

  @override
  String get cartSubtotal => 'المجموع الفرعي';

  @override
  String get cartTotal => 'الإجمالي';

  @override
  String get cartCheckout => 'متابعة الدفع';

  @override
  String get cartRemoveItem => 'إزالة';

  @override
  String get ordersTitle => 'طلباتي';

  @override
  String get ordersEmpty => 'لا توجد طلبات';

  @override
  String get orderDetails => 'تفاصيل الطلب';

  @override
  String get orderTracking => 'تتبع الطلب';

  @override
  String get orderStatus => 'الحالة';

  @override
  String get orderPlaced => 'تم الطلب';

  @override
  String get orderConfirmed => 'مؤكد';

  @override
  String get orderShipped => 'تم الشحن';

  @override
  String get orderDelivered => 'تم التوصيل';

  @override
  String get orderCancelled => 'ملغي';

  @override
  String get profileTitle => 'ملفي الشخصي';

  @override
  String get profileEdit => 'تعديل الملف';

  @override
  String get profileAddresses => 'عناويني';

  @override
  String get profileOrders => 'سجل الطلبات';

  @override
  String get profileWishlist => 'قائمة الرغبات';

  @override
  String get profileNotifications => 'الإشعارات';

  @override
  String get profileLogout => 'تسجيل الخروج';

  @override
  String get profileLogoutConfirm => 'هل أنت متأكد من تسجيل الخروج؟';

  @override
  String get checkoutTitle => 'الدفع';

  @override
  String get checkoutAddress => 'عنوان التوصيل';

  @override
  String get checkoutPayment => 'طريقة الدفع';

  @override
  String get checkoutPlaceOrder => 'تأكيد الطلب';

  @override
  String get checkoutCoupon => 'تطبيق كوبون';

  @override
  String get notificationsTitle => 'الإشعارات';

  @override
  String get notificationsEmpty => 'لا توجد إشعارات';

  @override
  String get wishlistTitle => 'قائمة الرغبات';

  @override
  String get wishlistEmpty => 'قائمة الرغبات فارغة';

  @override
  String get errorGeneric => 'حدث خطأ. يرجى المحاولة مرة أخرى.';

  @override
  String get errorNetwork => 'لا يوجد اتصال بالإنترنت. يرجى التحقق من الشبكة.';

  @override
  String get errorServer => 'خطأ في الخادم. يرجى المحاولة لاحقاً.';

  @override
  String get errorUnauthorized => 'انتهت الجلسة. يرجى تسجيل الدخول مجدداً.';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get cancel => 'إلغاء';

  @override
  String get confirm => 'تأكيد';

  @override
  String get save => 'حفظ';

  @override
  String get delete => 'حذف';

  @override
  String get loading => 'جاري التحميل...';

  @override
  String get searchNoResults => 'لا توجد نتائج';
}
