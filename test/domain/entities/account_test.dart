import 'package:flutter_test/flutter_test.dart';
import 'package:vent_expense_pro/domain/entities/account.dart';
import 'package:vent_expense_pro/domain/entities/enums.dart';

void main() {
  group('Account', () {
    final now = DateTime(2026, 2, 21);

    test('should create a valid debit account', () {
      final account = Account(
        id: 'acc-1',
        name: 'BCA Debit',
        type: AccountType.debit,
        balance: 500000,
        createdAt: now,
      );

      expect(account.id, 'acc-1');
      expect(account.name, 'BCA Debit');
      expect(account.type, AccountType.debit);
      expect(account.balance, 500000);
      expect(account.currency, 'IDR');
      expect(account.isArchived, false);
      expect(account.isAsset, true);
      expect(account.isLiability, false);
    });

    test('should create a valid credit account as liability', () {
      final account = Account(
        id: 'acc-2',
        name: 'Visa Card',
        type: AccountType.credit,
        balance: 150000,
        createdAt: now,
      );

      expect(account.isAsset, false);
      expect(account.isLiability, true);
    });

    test('should create a valid cash account as asset', () {
      final account = Account(
        id: 'acc-3',
        name: 'Cash Wallet',
        type: AccountType.cash,
        balance: 200000,
        createdAt: now,
      );

      expect(account.isAsset, true);
      expect(account.isLiability, false);
    });

    test('should support value equality via Equatable', () {
      final a = Account(
        id: 'acc-1',
        name: 'BCA',
        type: AccountType.debit,
        balance: 100,
        createdAt: now,
      );
      final b = Account(
        id: 'acc-1',
        name: 'BCA',
        type: AccountType.debit,
        balance: 100,
        createdAt: now,
      );

      expect(a, equals(b));
    });

    test('should support copyWith', () {
      final original = Account(
        id: 'acc-1',
        name: 'BCA',
        type: AccountType.debit,
        balance: 100,
        createdAt: now,
      );
      final updated = original.copyWith(balance: 200, name: 'BCA Updated');

      expect(updated.balance, 200);
      expect(updated.name, 'BCA Updated');
      expect(updated.id, 'acc-1'); // unchanged
      expect(updated.type, AccountType.debit); // unchanged
    });
  });
}
