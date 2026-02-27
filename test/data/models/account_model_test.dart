import 'package:flutter_test/flutter_test.dart';
import 'package:vent_expense_pro/data/models/account_model.dart';
import 'package:vent_expense_pro/domain/entities/account.dart';
import 'package:vent_expense_pro/domain/entities/enums.dart';

void main() {
  group('AccountModel', () {
    final now = DateTime(2026, 2, 21, 12, 0);

    group('fromMap', () {
      test('should create an AccountModel from a valid SQLite map', () {
        final map = {
          'id': 'acc-1',
          'name': 'BCA Payroll',
          'type': AccountType.debit.index,
          'balance': 15000000,
          'currency': 'IDR',
          'is_archived': 0,
          'created_at': now.millisecondsSinceEpoch,
        };

        final model = AccountModel.fromMap(map);

        expect(model.id, 'acc-1');
        expect(model.name, 'BCA Payroll');
        expect(model.type, AccountType.debit);
        expect(model.balance, 15000000);
        expect(model.currency, 'IDR');
        expect(model.isArchived, false);
        expect(model.createdAt, now);
      });

      test('should handle archived accounts', () {
        final map = {
          'id': 'acc-2',
          'name': 'Old Card',
          'type': AccountType.credit.index,
          'balance': 0,
          'currency': 'USD',
          'is_archived': 1,
          'created_at': now.millisecondsSinceEpoch,
        };

        final model = AccountModel.fromMap(map);
        expect(model.isArchived, true);
        expect(model.type, AccountType.credit);
        expect(model.currency, 'USD');
      });

      test('should default currency to IDR when null', () {
        final map = {
          'id': 'acc-3',
          'name': 'Cash',
          'type': AccountType.cash.index,
          'balance': 500000,
          'currency': null,
          'is_archived': 0,
          'created_at': now.millisecondsSinceEpoch,
        };

        final model = AccountModel.fromMap(map);
        expect(model.currency, 'IDR');
      });
    });

    group('fromEntity', () {
      test('should create an AccountModel from a domain Account', () {
        final account = Account(
          id: 'acc-1',
          name: 'Mandiri',
          type: AccountType.debit,
          balance: 8000000,
          currency: 'IDR',
          createdAt: now,
        );

        final model = AccountModel.fromEntity(account);

        expect(model.id, account.id);
        expect(model.name, account.name);
        expect(model.type, account.type);
        expect(model.balance, account.balance);
        expect(model.currency, account.currency);
        expect(model.isArchived, account.isArchived);
        expect(model.createdAt, account.createdAt);
      });
    });

    group('toMap', () {
      test('should convert to a valid SQLite map', () {
        final model = AccountModel(
          id: 'acc-1',
          name: 'BCA',
          type: AccountType.debit,
          balance: 1000000,
          currency: 'IDR',
          createdAt: now,
        );

        final map = model.toMap();

        expect(map['id'], 'acc-1');
        expect(map['name'], 'BCA');
        expect(map['type'], AccountType.debit.index);
        expect(map['balance'], 1000000);
        expect(map['currency'], 'IDR');
        expect(map['is_archived'], 0);
        expect(map['created_at'], now.millisecondsSinceEpoch);
      });

      test('should set is_archived to 1 for archived accounts', () {
        final model = AccountModel(
          id: 'acc-old',
          name: 'Closed',
          type: AccountType.cash,
          balance: 0,
          isArchived: true,
          createdAt: now,
        );

        final map = model.toMap();
        expect(map['is_archived'], 1);
      });
    });

    group('round-trip', () {
      test('fromMap → toMap should produce equivalent data', () {
        final original = {
          'id': 'acc-rt',
          'name': 'Round Trip',
          'type': AccountType.debit.index,
          'balance': 999,
          'currency': 'USD',
          'is_archived': 0,
          'created_at': now.millisecondsSinceEpoch,
        };

        final model = AccountModel.fromMap(original);
        final result = model.toMap();

        expect(result['id'], original['id']);
        expect(result['name'], original['name']);
        expect(result['type'], original['type']);
        expect(result['balance'], original['balance']);
        expect(result['currency'], original['currency']);
        expect(result['is_archived'], original['is_archived']);
        expect(result['created_at'], original['created_at']);
      });
    });
  });
}
