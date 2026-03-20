import 'package:intl/intl.dart';

abstract final class Formatters {
  static final _currencyFormat = NumberFormat.currency(
    symbol: 'EGP ',
    decimalDigits: 2,
  );

  static final _compactCurrencyFormat = NumberFormat.compactCurrency(
    symbol: 'EGP ',
    decimalDigits: 0,
  );

  static final _dateFormat = DateFormat('dd MMM yyyy');
  static final _dateTimeFormat = DateFormat('dd MMM yyyy, hh:mm a');
  static final _timeFormat = DateFormat('hh:mm a');
  static final _shortDateFormat = DateFormat('dd/MM/yyyy');

  static String price(double amount) => _currencyFormat.format(amount);

  static String compactPrice(double amount) =>
      _compactCurrencyFormat.format(amount);

  static String date(DateTime dateTime) => _dateFormat.format(dateTime);

  static String dateTime(DateTime dateTime) => _dateTimeFormat.format(dateTime);

  static String time(DateTime dateTime) => _timeFormat.format(dateTime);

  static String shortDate(DateTime dateTime) =>
      _shortDateFormat.format(dateTime);

  static String relativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return date(dateTime);
  }

  static String timeAgo(DateTime dateTime) => relativeTime(dateTime);

  static String phone(String phone) {
    if (phone.length == 11) {
      return '${phone.substring(0, 4)} ${phone.substring(4, 7)} ${phone.substring(7)}';
    }
    return phone;
  }

  static String orderNumber(String id) {
    return '#${id.substring(0, 8).toUpperCase()}';
  }

  static String quantity(int qty) {
    if (qty >= 1000) return '${(qty / 1000).toStringAsFixed(1)}k';
    return qty.toString();
  }

  static String percentage(double value) => '${value.toStringAsFixed(0)}%';

  static String discount(double originalPrice, double discountedPrice) {
    final percentage =
        ((originalPrice - discountedPrice) / originalPrice * 100);
    return '-${percentage.toStringAsFixed(0)}%';
  }
}
