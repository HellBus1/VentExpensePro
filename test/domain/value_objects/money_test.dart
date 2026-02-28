import 'package:flutter_test/flutter_test.dart';
import 'package:vent_expense_pro/domain/value_objects/money.dart';

void main() {
  group('Money', () {
    test('should store cents correctly', () {
      const money = Money(cents: 15000);
      expect(money.cents, 15000);
      expect(money.currency, 'IDR');
    });

    test('should create from double', () {
      final money = Money.fromDouble(150.50, currency: 'USD');
      expect(money.cents, 15050);
    });

    test('should convert to double', () {
      const money = Money(cents: 15050, currency: 'USD');
      expect(money.asDouble, 150.50);
    });

    test('should support addition', () {
      const a = Money(cents: 10000);
      const b = Money(cents: 5000);
      final result = a + b;
      expect(result.cents, 15000);
    });

    test('should support subtraction', () {
      const a = Money(cents: 10000);
      const b = Money(cents: 3000);
      final result = a - b;
      expect(result.cents, 7000);
    });

    test('should support negation', () {
      const money = Money(cents: 5000);
      final negated = -money;
      expect(negated.cents, -5000);
    });

    test('should detect positive, negative, and zero', () {
      const positive = Money(cents: 100);
      const negative = Money(cents: -100);
      const zero = Money(cents: 0);

      expect(positive.isPositive, true);
      expect(positive.isNegative, false);
      expect(negative.isNegative, true);
      expect(zero.isZero, true);
    });

    test('should support value equality', () {
      const a = Money(cents: 5000);
      const b = Money(cents: 5000);
      expect(a, equals(b));
    });

    test('should format IDR correctly', () {
      const money = Money(cents: 1500000);
      final formatted = money.formatted;
      // Should contain "Rp" and "1.500.000" (Indonesian locale)
      expect(formatted, contains('Rp'));
      expect(formatted, contains('1.500.000'));
    });

    test('should format USD correctly', () {
      const money = Money(cents: 15050, currency: 'USD');
      final formatted = money.formatted;
      expect(formatted, contains('\$'));
      expect(formatted, contains('150.50'));
    });
  });
}
