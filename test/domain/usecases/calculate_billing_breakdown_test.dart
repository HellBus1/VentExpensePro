import 'package:flutter_test/flutter_test.dart';
import 'package:vent_expense_pro/domain/entities/account.dart';
import 'package:vent_expense_pro/domain/entities/enums.dart';
import 'package:vent_expense_pro/domain/entities/transaction.dart';
import 'package:vent_expense_pro/domain/usecases/calculate_billing_breakdown.dart';

void main() {
  const calculator = CalculateBillingBreakdown();

  group('CalculateBillingBreakdown Use Case Tests', () {
    test('returns zero breakdown for account without billing cycle', () {
      final debit = Account(
        id: 'acc_debit',
        name: 'BCA Debit',
        type: AccountType.debit,
        balance: 1000000,
        createdAt: DateTime(2026, 1, 1),
      );

      final breakdown = calculator(debit, []);
      expect(breakdown.billedAmount, equals(0));
      expect(breakdown.unbilledAmount, equals(0));
      expect(breakdown.billedPeriod, isNull);
      expect(breakdown.unbilledPeriod, isNull);
      expect(breakdown.dueDate, isNull);
    });

    test('calculates billed and unbilled expenses based on billing periods', () {
      final creditCard = Account(
        id: 'acc_cc',
        name: 'Gold Credit Card',
        type: AccountType.credit,
        balance: 950000,
        statementCloseDay: 20,
        createdAt: DateTime(2026, 1, 1),
      );

      // Current reference date: September 15, 2026
      // Current unbilled period: Aug 21, 2026 -> Sep 20, 2026
      // Previous billed period: Jul 21, 2026 -> Aug 20, 2026
      final now = DateTime(2026, 9, 15, 14, 30);

      final transactions = [
        // Inside previous billed period (Aug 5)
        Transaction(
          id: 'tx1',
          amount: 500000,
          type: TransactionType.expense,
          categoryId: 'food',
          accountId: 'acc_cc',
          dateTime: DateTime(2026, 8, 5, 12, 0),
        ),
        // Inside current unbilled period (Aug 25)
        Transaction(
          id: 'tx2',
          amount: 300000,
          type: TransactionType.expense,
          categoryId: 'shopping',
          accountId: 'acc_cc',
          dateTime: DateTime(2026, 8, 25, 19, 0),
        ),
        // Inside current unbilled period (Sep 10)
        Transaction(
          id: 'tx3',
          amount: 150000,
          type: TransactionType.expense,
          categoryId: 'transport',
          accountId: 'acc_cc',
          dateTime: DateTime(2026, 9, 10, 8, 30),
        ),
        // Older than previous period (Jun 10) -> not in current or previous cycle
        Transaction(
          id: 'tx4',
          amount: 200000,
          type: TransactionType.expense,
          categoryId: 'bills',
          accountId: 'acc_cc',
          dateTime: DateTime(2026, 6, 10, 10, 0),
        ),
        // Non-expense (income refund) -> should not count as expense charge
        Transaction(
          id: 'tx5',
          amount: 50000,
          type: TransactionType.income,
          categoryId: 'refund',
          accountId: 'acc_cc',
          dateTime: DateTime(2026, 9, 5, 11, 0),
        ),
        // Expense on another account -> should not count
        Transaction(
          id: 'tx6',
          amount: 900000,
          type: TransactionType.expense,
          categoryId: 'food',
          accountId: 'acc_other',
          dateTime: DateTime(2026, 9, 8, 12, 0),
        ),
      ];

      final breakdown = calculator(creditCard, transactions, now);

      expect(breakdown.billedAmount, equals(500000));
      expect(breakdown.unbilledAmount, equals(450000));
      expect(breakdown.totalOutstanding, equals(950000));
      expect(breakdown.hasBilledCharges, isTrue);
      expect(breakdown.hasCharges, isTrue);
      expect(breakdown.dueDate?.year, equals(2026));
      expect(breakdown.dueDate?.month, equals(8));
      expect(breakdown.dueDate?.day, equals(20));
    });
  });
}
