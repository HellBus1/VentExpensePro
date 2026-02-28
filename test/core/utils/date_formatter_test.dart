import 'package:flutter_test/flutter_test.dart';
import 'package:vent_expense_pro/core/utils/date_formatter.dart';

void main() {
  group('DateFormatter', () {
    test('full should format as "d MMMM yyyy"', () {
      final date = DateTime(2026, 2, 21);
      expect(DateFormatter.full(date), '21 February 2026');
    });

    test('short should format as "d MMM yyyy"', () {
      final date = DateTime(2026, 2, 21);
      expect(DateFormatter.short(date), '21 Feb 2026');
    });

    test('dayMonth should format as "d MMM"', () {
      final date = DateTime(2026, 12, 25);
      expect(DateFormatter.dayMonth(date), '25 Dec');
    });

    test('time should format as "HH:mm"', () {
      final date = DateTime(2026, 2, 21, 14, 30);
      expect(DateFormatter.time(date), '14:30');
    });

    test('time should pad single digit hours and minutes', () {
      final date = DateTime(2026, 1, 1, 8, 5);
      expect(DateFormatter.time(date), '08:05');
    });

    group('relative', () {
      test('should return "Today" for today', () {
        final now = DateTime.now();
        expect(DateFormatter.relative(now), 'Today');
      });

      test('should return "Yesterday" for yesterday', () {
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        expect(DateFormatter.relative(yesterday), 'Yesterday');
      });

      test('should return day name for dates within a week', () {
        final threeDaysAgo = DateTime.now().subtract(const Duration(days: 3));
        final result = DateFormatter.relative(threeDaysAgo);
        // Should be a day name (Monday, Tuesday, etc.), not a date
        expect(result, isNot(contains('2026')));
        expect(result.length, greaterThan(3));
      });

      test('should return short date for dates older than a week', () {
        final oldDate = DateTime.now().subtract(const Duration(days: 10));
        final result = DateFormatter.relative(oldDate);
        // Should contain a year
        expect(result, contains('202'));
      });
    });

    group('receiptHeader', () {
      test('should return "Today, d MMM" for today', () {
        final now = DateTime.now();
        final result = DateFormatter.receiptHeader(now);
        expect(result, startsWith('Today'));
        expect(result, contains(','));
      });

      test('should return "Yesterday, d MMM" for yesterday', () {
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        final result = DateFormatter.receiptHeader(yesterday);
        expect(result, startsWith('Yesterday'));
        expect(result, contains(','));
      });

      test('should return "DayName, d MMM" for older dates', () {
        final old = DateTime.now().subtract(const Duration(days: 5));
        final result = DateFormatter.receiptHeader(old);
        expect(result, contains(','));
        // Should NOT start with Today or Yesterday
        expect(result, isNot(startsWith('Today')));
        expect(result, isNot(startsWith('Yesterday')));
      });
    });
  });
}
