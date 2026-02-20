import 'package:flutter_test/flutter_test.dart';
import 'package:vent_expense_pro/domain/entities/enums.dart';
import 'package:vent_expense_pro/domain/entities/transaction.dart';

void main() {
  group('Transaction', () {
    final now = DateTime(2026, 2, 21, 14, 30);

    test('should create a valid expense transaction', () {
      final txn = Transaction(
        id: 'txn-1',
        amount: 50000,
        type: TransactionType.expense,
        categoryId: 'food',
        accountId: 'acc-1',
        dateTime: now,
      );

      expect(txn.id, 'txn-1');
      expect(txn.amount, 50000);
      expect(txn.type, TransactionType.expense);
      expect(txn.categoryId, 'food');
      expect(txn.toAccountId, isNull);
      expect(txn.note, isNull);
      expect(txn.isSettlement, false);
    });

    test('should create a transfer with destination account', () {
      final txn = Transaction(
        id: 'txn-2',
        amount: 100000,
        type: TransactionType.transfer,
        categoryId: 'settlement',
        accountId: 'acc-1',
        toAccountId: 'acc-2',
        isSettlement: true,
        dateTime: now,
      );

      expect(txn.toAccountId, 'acc-2');
      expect(txn.isSettlement, true);
    });

    test('should support value equality via Equatable', () {
      final a = Transaction(
        id: 'txn-1',
        amount: 50000,
        type: TransactionType.expense,
        categoryId: 'food',
        accountId: 'acc-1',
        dateTime: now,
      );
      final b = Transaction(
        id: 'txn-1',
        amount: 50000,
        type: TransactionType.expense,
        categoryId: 'food',
        accountId: 'acc-1',
        dateTime: now,
      );

      expect(a, equals(b));
    });

    test('should support copyWith', () {
      final original = Transaction(
        id: 'txn-1',
        amount: 50000,
        type: TransactionType.expense,
        categoryId: 'food',
        accountId: 'acc-1',
        dateTime: now,
      );
      final updated = original.copyWith(amount: 75000, note: 'Lunch');

      expect(updated.amount, 75000);
      expect(updated.note, 'Lunch');
      expect(updated.id, 'txn-1'); // unchanged
    });
  });
}
