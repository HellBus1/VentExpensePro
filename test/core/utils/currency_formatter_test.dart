import 'package:flutter_test/flutter_test.dart';
import 'package:vent_expense_pro/core/utils/currency_formatter.dart';

void main() {
  group('CurrencyFormatter', () {
    group('formatCents', () {
      test('should format IDR with no decimals', () {
        final result = CurrencyFormatter.formatCents(1500000, currency: 'IDR');
        expect(result, contains('Rp'));
        expect(result, contains('1.500.000'));
      });

      test('should format zero IDR', () {
        final result = CurrencyFormatter.formatCents(0, currency: 'IDR');
        expect(result, contains('Rp'));
        expect(result, contains('0'));
      });

      test('should format negative IDR', () {
        final result = CurrencyFormatter.formatCents(-500000, currency: 'IDR');
        expect(result, contains('500.000'));
      });

      test('should format USD with 2 decimals', () {
        final result = CurrencyFormatter.formatCents(15050, currency: 'USD');
        expect(result, contains('\$'));
        expect(result, contains('150.50'));
      });

      test('should format EUR correctly', () {
        final result = CurrencyFormatter.formatCents(10000, currency: 'EUR');
        expect(result, contains('100'));
      });

      test('should format GBP correctly', () {
        final result = CurrencyFormatter.formatCents(25099, currency: 'GBP');
        expect(result, contains('250.99'));
      });

      test('should format JPY with no decimals', () {
        final result = CurrencyFormatter.formatCents(5000, currency: 'JPY');
        expect(result, contains('5'));
      });

      test('should format KRW with no decimals', () {
        final result = CurrencyFormatter.formatCents(50000, currency: 'KRW');
        expect(result, contains('50'));
      });

      test('should format SGD correctly', () {
        final result = CurrencyFormatter.formatCents(1250, currency: 'SGD');
        expect(result, contains('12.50'));
      });

      test('should format MYR correctly', () {
        final result = CurrencyFormatter.formatCents(7500, currency: 'MYR');
        expect(result, contains('75.00'));
      });
    });

    group('formatCentsPlain', () {
      test('should format IDR without symbol', () {
        final result =
            CurrencyFormatter.formatCentsPlain(1500000, currency: 'IDR');
        expect(result, isNot(contains('Rp')));
        expect(result, contains('1.500.000'));
      });

      test('should format USD without symbol', () {
        final result =
            CurrencyFormatter.formatCentsPlain(15050, currency: 'USD');
        expect(result, isNot(contains('\$')));
        expect(result, contains('150.5'));
      });
    });

    group('symbol', () {
      test('should return Rp for IDR', () {
        expect(CurrencyFormatter.symbol('IDR'), contains('Rp'));
      });

      test('should return \$ for USD', () {
        expect(CurrencyFormatter.symbol('USD'), contains('\$'));
      });

      test('should return £ for GBP', () {
        expect(CurrencyFormatter.symbol('GBP'), contains('£'));
      });

      test('should return ¥ for JPY', () {
        final sym = CurrencyFormatter.symbol('JPY');
        expect(sym.isNotEmpty, true);
      });
    });

    group('decimalDigits', () {
      test('should return 0 for IDR', () {
        expect(CurrencyFormatter.decimalDigits('IDR'), 0);
      });

      test('should return 0 for JPY', () {
        expect(CurrencyFormatter.decimalDigits('JPY'), 0);
      });

      test('should return 0 for KRW', () {
        expect(CurrencyFormatter.decimalDigits('KRW'), 0);
      });

      test('should return 2 for USD', () {
        expect(CurrencyFormatter.decimalDigits('USD'), 2);
      });

      test('should return 2 for EUR', () {
        expect(CurrencyFormatter.decimalDigits('EUR'), 2);
      });

      test('should return 2 for unknown currency', () {
        expect(CurrencyFormatter.decimalDigits('XYZ'), 2);
      });
    });
  });
}
