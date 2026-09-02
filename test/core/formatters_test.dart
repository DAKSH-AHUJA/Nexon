import 'package:flutter_test/flutter_test.dart';
import 'package:nexon_erp/core/utils/formatters.dart';

void main() {
  group('currency', () {
    test('formats with the rupee symbol and no decimals', () {
      expect(Formatters.currency(1234), '\u20B91,234');
      expect(Formatters.currency(0), '\u20B90');
    });

    test('rounds fractional values', () {
      expect(Formatters.currency(1234.6), '\u20B91,235');
    });

    test('groups in the Indian lakh/crore style', () {
      expect(Formatters.currency(100000), '\u20B91,00,000');
      expect(Formatters.currency(10000000), '\u20B91,00,00,000');
    });

    test('keeps the sign for negative amounts', () {
      expect(Formatters.currency(-500), contains('500'));
      expect(Formatters.currency(-500), isNot(Formatters.currency(500)));
    });
  });

  group('currencyWithDecimals', () {
    test('always shows two decimals', () {
      expect(Formatters.currencyWithDecimals(1234.5), '\u20B91,234.50');
      expect(Formatters.currencyWithDecimals(10), '\u20B910.00');
    });
  });

  group('currencyCompact', () {
    test('abbreviates large amounts', () {
      final lakh = Formatters.currencyCompact(150000);

      expect(lakh, startsWith('\u20B9'));
      expect(lakh.length, lessThan('\u20B91,50,000'.length));
      expect(Formatters.currencyCompact(500), contains('500'));
    });
  });

  group('number', () {
    test('groups in lakhs without a currency symbol', () {
      expect(Formatters.number(1234567), '12,34,567');
      expect(Formatters.number(0), '0');
      expect(Formatters.number(12.7), '13');
    });
  });

  group('date and time', () {
    final moment = DateTime(2024, 6, 5, 14, 30);

    test('date uses a day-month-year pattern', () {
      expect(Formatters.date(moment), '05 Jun 2024');
    });

    test('dateTime appends a 12-hour clock time', () {
      expect(Formatters.dateTime(moment), '05 Jun 2024, 02:30 PM');
    });

    test('time formats a 12-hour clock time', () {
      expect(Formatters.time(moment), '02:30 PM');
      expect(Formatters.time(DateTime(2024, 6, 5, 9, 5)), '09:05 AM');
    });
  });

  group('relativeTime', () {
    test('reports seconds as "Just now"', () {
      final now = DateTime.now();

      expect(Formatters.relativeTime(now), 'Just now');
      expect(
        Formatters.relativeTime(now.subtract(const Duration(seconds: 30))),
        'Just now',
      );
    });

    test('reports minutes within the hour', () {
      final timestamp =
          DateTime.now().subtract(const Duration(minutes: 5, seconds: 1));

      expect(Formatters.relativeTime(timestamp), '5m ago');
    });

    test('reports hours within the day', () {
      final timestamp =
          DateTime.now().subtract(const Duration(hours: 3, seconds: 1));

      expect(Formatters.relativeTime(timestamp), '3h ago');
    });

    test('reports days within the week', () {
      final timestamp =
          DateTime.now().subtract(const Duration(days: 3, seconds: 1));

      expect(Formatters.relativeTime(timestamp), '3d ago');
    });

    test('falls back to an absolute date beyond a week', () {
      final timestamp = DateTime(2020, 1, 2);

      expect(Formatters.relativeTime(timestamp), '02 Jan 2020');
    });
  });
}
