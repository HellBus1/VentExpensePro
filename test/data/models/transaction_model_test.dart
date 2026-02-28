import 'package:flutter_test/flutter_test.dart';
import 'package:vent_expense_pro/data/models/transaction_model.dart';
import 'package:vent_expense_pro/domain/entities/enums.dart';
import 'package:vent_expense_pro/domain/entities/transaction.dart';

void main() {
  group('TransactionModel', () {
    final now = DateTime(2026, 2, 21, 14, 30);

    group('fromMap', () {
      test('should create an expense TransactionModel from map', () {
        final map = {
          'id': 'txn-1',
          'amount': 50000,
          'type': TransactionType.expense.index,
          'category_id': 'food',
          'account_id': 'acc-1',
          'to_account_id': null,
          'note': 'Lunch',
          'is_settlement': 0,
          'date_time': now.millisecondsSinceEpoch,
        };

        final model = TransactionModel.fromMap(map);

        expect(model.id, 'txn-1');
        expect(model.amount, 50000);
        expect(model.type, TransactionType.expense);
        expect(model.categoryId, 'food');
        expect(model.accountId, 'acc-1');
        expect(model.toAccountId, isNull);
        expect(model.note, 'Lunch');
        expect(model.isSettlement, false);
        expect(model.dateTime, now);
      });

      test('should create a settlement transfer from map', () {
        final map = {
          'id': 'txn-2',
          'amount': 1500000,
          'type': TransactionType.transfer.index,
          'category_id': 'settlement',
          'account_id': 'acc-1',
          'to_account_id': 'acc-2',
          'note': 'Pay CC Bill',
          'is_settlement': 1,
          'date_time': now.millisecondsSinceEpoch,
        };

        final model = TransactionModel.fromMap(map);

        expect(model.type, TransactionType.transfer);
        expect(model.toAccountId, 'acc-2');
        expect(model.isSettlement, true);
      });

      test('should handle null note and toAccountId', () {
        final map = {
          'id': 'txn-3',
          'amount': 100000,
          'type': TransactionType.income.index,
          'category_id': 'other',
          'account_id': 'acc-1',
          'to_account_id': null,
          'note': null,
          'is_settlement': 0,
          'date_time': now.millisecondsSinceEpoch,
        };

        final model = TransactionModel.fromMap(map);
        expect(model.toAccountId, isNull);
        expect(model.note, isNull);
      });
    });

    group('fromEntity', () {
      test('should create a TransactionModel from domain Transaction', () {
        final txn = Transaction(
          id: 'txn-1',
          amount: 50000,
          type: TransactionType.expense,
          categoryId: 'food',
          accountId: 'acc-1',
          note: 'Dinner',
          dateTime: now,
        );

        final model = TransactionModel.fromEntity(txn);

        expect(model.id, txn.id);
        expect(model.amount, txn.amount);
        expect(model.type, txn.type);
        expect(model.categoryId, txn.categoryId);
        expect(model.accountId, txn.accountId);
        expect(model.note, txn.note);
        expect(model.isSettlement, txn.isSettlement);
        expect(model.dateTime, txn.dateTime);
      });
    });

    group('toMap', () {
      test('should convert to a valid SQLite map', () {
        final model = TransactionModel(
          id: 'txn-1',
          amount: 75000,
          type: TransactionType.expense,
          categoryId: 'shopping',
          accountId: 'acc-1',
          note: 'New shoes',
          dateTime: now,
        );

        final map = model.toMap();

        expect(map['id'], 'txn-1');
        expect(map['amount'], 75000);
        expect(map['type'], TransactionType.expense.index);
        expect(map['category_id'], 'shopping');
        expect(map['account_id'], 'acc-1');
        expect(map['to_account_id'], isNull);
        expect(map['note'], 'New shoes');
        expect(map['is_settlement'], 0);
        expect(map['date_time'], now.millisecondsSinceEpoch);
      });

      test('should set is_settlement to 1 for settlement transactions', () {
        final model = TransactionModel(
          id: 'txn-s',
          amount: 500000,
          type: TransactionType.transfer,
          categoryId: 'settlement',
          accountId: 'acc-1',
          toAccountId: 'acc-2',
          isSettlement: true,
          dateTime: now,
        );

        final map = model.toMap();
        expect(map['is_settlement'], 1);
        expect(map['to_account_id'], 'acc-2');
      });
    });

    group('round-trip', () {
      test('fromMap → toMap should produce equivalent data', () {
        final original = {
          'id': 'txn-rt',
          'amount': 250000,
          'type': TransactionType.income.index,
          'category_id': 'other',
          'account_id': 'acc-1',
          'to_account_id': null,
          'note': 'Bonus',
          'is_settlement': 0,
          'date_time': now.millisecondsSinceEpoch,
        };

        final model = TransactionModel.fromMap(original);
        final result = model.toMap();

        expect(result['id'], original['id']);
        expect(result['amount'], original['amount']);
        expect(result['type'], original['type']);
        expect(result['category_id'], original['category_id']);
        expect(result['account_id'], original['account_id']);
        expect(result['to_account_id'], original['to_account_id']);
        expect(result['note'], original['note']);
        expect(result['is_settlement'], original['is_settlement']);
        expect(result['date_time'], original['date_time']);
      });
    });
  });
}
