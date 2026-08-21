import 'package:intl/intl.dart';

abstract final class Formatters {
  static final _currency = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '\u20B9',
    decimalDigits: 0,
  );

  static final _currencyWithDecimals = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '\u20B9',
    decimalDigits: 2,
  );

  static final _compact = NumberFormat.compactCurrency(
    locale: 'en_IN',
    symbol: '\u20B9',
    decimalDigits: 1,
  );

  static final _number = NumberFormat('#,##,##0', 'en_IN');
  static final _date = DateFormat('dd MMM yyyy');
  static final _dateTime = DateFormat('dd MMM yyyy, hh:mm a');
  static final _time = DateFormat('hh:mm a');

  static String currency(num value) => _currency.format(value);
  static String currencyCompact(num value) => _compact.format(value);
  static String currencyWithDecimals(num value) =>
      _currencyWithDecimals.format(value);
  static String number(num value) => _number.format(value);
  static String date(DateTime value) => _date.format(value);
  static String dateTime(DateTime value) => _dateTime.format(value);
  static String time(DateTime value) => _time.format(value);

  static String relativeTime(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return date(timestamp);
  }
}
