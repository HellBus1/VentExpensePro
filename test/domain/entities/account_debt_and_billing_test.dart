import 'package:flutter_test/flutter_test.dart';
import 'package:vent_expense_pro/domain/entities/account.dart';
import 'package:vent_expense_pro/domain/entities/enums.dart';

void main() {
  final now = DateTime(2026, 9, 15);

  group('Account - Debt Classification', () {
    test('positive balance is receivable (treated as asset)', () {
      final account = Account(
        id: 'debt_1',
        name: 'Friend',
        type: AccountType.debt,
        balance: 250000,
        currency: 'IDR',
        createdAt: now,
      );

      expect(account.isDebt, isTrue);
      expect(account.isAsset, isTrue);
      expect(account.isLiability, isFalse);
    });

    test('negative balance is payable (treated as liability)', () {
      final account = Account(
        id: 'debt_2',
        name: 'Borrowing',
        type: AccountType.debt,
        balance: -150000,
        currency: 'IDR',
        createdAt: now,
      );

      expect(account.isDebt, isTrue);
      expect(account.isAsset, isFalse);
      expect(account.isLiability, isTrue);
    });

    test('zero balance is neither asset nor liability', () {
      final account = Account(
        id: 'debt_3',
        name: 'Settled Friend',
        type: AccountType.debt,
        balance: 0,
        currency: 'IDR',
        createdAt: now,
      );

      expect(account.isDebt, isTrue);
      expect(account.isAsset, isFalse);
      expect(account.isLiability, isFalse);
    });
  });

  group('Account - Credit Card Billing Cycle', () {
    test('hasBillingCycle is true only for credit cards with statementCloseDay', () {
      final creditWithCycle = Account(
        id: 'cc_1',
        name: 'BCA Visa',
        type: AccountType.credit,
        balance: 1000000,
        currency: 'IDR',
        statementCloseDay: 20,
        createdAt: now,
      );
      final creditNoCycle = Account(
        id: 'cc_2',
        name: 'Mandiri Card',
        type: AccountType.credit,
        balance: 500000,
        currency: 'IDR',
        createdAt: now,
      );
      final debit = Account(
        id: 'deb_1',
        name: 'Debit',
        type: AccountType.debit,
        balance: 500000,
        currency: 'IDR',
        statementCloseDay: 20,
        createdAt: now,
      );

      expect(creditWithCycle.hasBillingCycle, isTrue);
      expect(creditNoCycle.hasBillingCycle, isFalse);
      expect(debit.hasBillingCycle, isFalse);
    });

    test('calculates current billing period when today is after statement close day', () {
      // statement close day is 20th. Today is 21st September 2026.
      // Current cycle starts Sep 21st, closes Oct 20th.
      final cc = Account(
        id: 'cc_1',
        name: 'Credit Card',
        type: AccountType.credit,
        balance: 0,
        currency: 'USD',
        statementCloseDay: 20,
        createdAt: now,
      );

      final period = cc.currentBillingPeriod(DateTime(2026, 9, 21));
      expect(period, isNotNull);
      expect(period!.start, equals(DateTime(2026, 9, 21)));
      expect(period.end.year, equals(2026));
      expect(period.end.month, equals(10));
      expect(period.end.day, equals(20));
    });

    test('calculates current billing period when today is on statement close day', () {
      // statement close day is 20th. Today is 20th September 2026.
      // Current cycle started Aug 21st, closes Sep 20th.
      final cc = Account(
        id: 'cc_1',
        name: 'Credit Card',
        type: AccountType.credit,
        balance: 0,
        currency: 'USD',
        statementCloseDay: 20,
        createdAt: now,
      );

      final period = cc.currentBillingPeriod(DateTime(2026, 9, 20));
      expect(period, isNotNull);
      expect(period!.start, equals(DateTime(2026, 8, 21)));
      expect(period.end.year, equals(2026));
      expect(period.end.month, equals(9));
      expect(period.end.day, equals(20));
    });

    test('calculates current billing period when today is before statement close day', () {
      // statement close day is 20th. Today is 10th September 2026.
      // Current cycle started Aug 21st, closes Sep 20th.
      final cc = Account(
        id: 'cc_1',
        name: 'Credit Card',
        type: AccountType.credit,
        balance: 0,
        currency: 'USD',
        statementCloseDay: 20,
        createdAt: now,
      );

      final period = cc.currentBillingPeriod(DateTime(2026, 9, 10));
      expect(period, isNotNull);
      expect(period!.start, equals(DateTime(2026, 8, 21)));
      expect(period.end.year, equals(2026));
      expect(period.end.month, equals(9));
      expect(period.end.day, equals(20));
    });

    test('calculates previous billed period correctly', () {
      // Today is 25th September 2026.
      // Current period: Sep 21 to Oct 20.
      // Previous period (billed): Aug 21 to Sep 20.
      final cc = Account(
        id: 'cc_1',
        name: 'Credit Card',
        type: AccountType.credit,
        balance: 0,
        currency: 'USD',
        statementCloseDay: 20,
        createdAt: now,
      );

      final prevPeriod = cc.previousBillingPeriod(DateTime(2026, 9, 25));
      expect(prevPeriod, isNotNull);
      expect(prevPeriod!.start, equals(DateTime(2026, 8, 21)));
      expect(prevPeriod.end.year, equals(2026));
      expect(prevPeriod.end.month, equals(9));
      expect(prevPeriod.end.day, equals(20));
    });

    test('handles year rollover (January) correctly', () {
      // Today is 5th January 2026. Close day is 20th.
      // Current period started Dec 21st 2025, closes Jan 20th 2026.
      final cc = Account(
        id: 'cc_1',
        name: 'Credit Card',
        type: AccountType.credit,
        balance: 0,
        currency: 'USD',
        statementCloseDay: 20,
        createdAt: now,
      );

      final period = cc.currentBillingPeriod(DateTime(2026, 1, 5));
      expect(period, isNotNull);
      expect(period!.start, equals(DateTime(2025, 12, 21)));
      expect(period.end.year, equals(2026));
      expect(period.end.month, equals(1));
      expect(period.end.day, equals(20));
    });

    test('returns null for non-credit accounts or accounts without close day', () {
      final debit = Account(
        id: 'deb',
        name: 'Debit',
        type: AccountType.debit,
        balance: 100,
        currency: 'USD',
        createdAt: now,
      );

      expect(debit.currentBillingPeriod(), isNull);
      expect(debit.previousBillingPeriod(), isNull);
    });
  });
}
