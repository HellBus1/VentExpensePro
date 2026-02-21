import 'package:flutter_test/flutter_test.dart';
import 'package:vent_expense_pro/domain/entities/account.dart';
import 'package:vent_expense_pro/domain/entities/enums.dart';
import 'package:vent_expense_pro/domain/repositories/account_repository.dart';
import 'package:vent_expense_pro/domain/usecases/calculate_net_position.dart';

/// A simple in-memory fake of [AccountRepository] for testing.
class FakeAccountRepository implements AccountRepository {
  final List<Account> _accounts = [];

  void seed(List<Account> accounts) {
    _accounts
      ..clear()
      ..addAll(accounts);
  }

  @override
  Future<List<Account>> getAll() async =>
      _accounts.where((a) => !a.isArchived).toList();

  @override
  Future<List<Account>> getByType(AccountType type) async =>
      _accounts.where((a) => a.type == type && !a.isArchived).toList();

  @override
  Future<Account?> getById(String id) async {
    try {
      return _accounts.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Account> insert(Account account) async {
    _accounts.add(account);
    return account;
  }

  @override
  Future<Account> update(Account account) async {
    final index = _accounts.indexWhere((a) => a.id == account.id);
    if (index != -1) _accounts[index] = account;
    return account;
  }

  @override
  Future<void> archive(String id) async {
    final index = _accounts.indexWhere((a) => a.id == id);
    if (index != -1) {
      _accounts[index] = _accounts[index].copyWith(isArchived: true);
    }
  }

  @override
  Future<void> updateBalance(String id, int newBalance) async {
    final index = _accounts.indexWhere((a) => a.id == id);
    if (index != -1) {
      _accounts[index] = _accounts[index].copyWith(balance: newBalance);
    }
  }
}

void main() {
  late FakeAccountRepository fakeRepo;
  late CalculateNetPosition calculateNetPosition;
  final now = DateTime(2026, 2, 21);

  setUp(() {
    fakeRepo = FakeAccountRepository();
    calculateNetPosition = CalculateNetPosition(fakeRepo);
  });

  group('CalculateNetPosition.call', () {
    test('should return zero for no accounts', () async {
      final result = await calculateNetPosition();
      expect(result.cents, 0);
    });

    test('should sum only asset accounts', () async {
      fakeRepo.seed([
        Account(
          id: '1',
          name: 'Debit',
          type: AccountType.debit,
          balance: 300000,
          createdAt: now,
        ),
        Account(
          id: '2',
          name: 'Cash',
          type: AccountType.cash,
          balance: 200000,
          createdAt: now,
        ),
      ]);

      final result = await calculateNetPosition();
      expect(result.cents, 500000);
    });

    test('should subtract liabilities from assets', () async {
      fakeRepo.seed([
        Account(
          id: '1',
          name: 'BCA Debit',
          type: AccountType.debit,
          balance: 500000,
          createdAt: now,
        ),
        Account(
          id: '2',
          name: 'Visa Card',
          type: AccountType.credit,
          balance: 150000,
          createdAt: now,
        ),
      ]);

      final result = await calculateNetPosition();
      expect(result.cents, 350000); // 500K - 150K
    });

    test('should return negative when liabilities exceed assets', () async {
      fakeRepo.seed([
        Account(
          id: '1',
          name: 'Cash',
          type: AccountType.cash,
          balance: 50000,
          createdAt: now,
        ),
        Account(
          id: '2',
          name: 'Credit Card',
          type: AccountType.credit,
          balance: 200000,
          createdAt: now,
        ),
      ]);

      final result = await calculateNetPosition();
      expect(result.cents, -150000);
      expect(result.isNegative, true);
    });
  });

  group('CalculateNetPosition.breakdown', () {
    test('should return correct breakdown with mixed accounts', () async {
      fakeRepo.seed([
        Account(
          id: '1',
          name: 'BCA Debit',
          type: AccountType.debit,
          balance: 500000,
          createdAt: now,
        ),
        Account(
          id: '2',
          name: 'Cash',
          type: AccountType.cash,
          balance: 200000,
          createdAt: now,
        ),
        Account(
          id: '3',
          name: 'Visa Card',
          type: AccountType.credit,
          balance: 150000,
          createdAt: now,
        ),
      ]);

      final breakdown = await calculateNetPosition.breakdown();

      expect(breakdown.totalAssets.cents, 700000);
      expect(breakdown.totalLiabilities.cents, 150000);
      expect(breakdown.netPosition.cents, 550000);
    });

    test('should return zero breakdown for empty accounts', () async {
      final breakdown = await calculateNetPosition.breakdown();

      expect(breakdown.totalAssets.cents, 0);
      expect(breakdown.totalLiabilities.cents, 0);
      expect(breakdown.netPosition.cents, 0);
    });

    test('should exclude archived accounts', () async {
      fakeRepo.seed([
        Account(
          id: '1',
          name: 'Active',
          type: AccountType.debit,
          balance: 500000,
          createdAt: now,
        ),
        Account(
          id: '2',
          name: 'Archived',
          type: AccountType.debit,
          balance: 300000,
          isArchived: true,
          createdAt: now,
        ),
      ]);

      final breakdown = await calculateNetPosition.breakdown();

      // Only the active account should be counted
      expect(breakdown.totalAssets.cents, 500000);
      expect(breakdown.netPosition.cents, 500000);
    });

    test('should handle only liability accounts', () async {
      fakeRepo.seed([
        Account(
          id: '1',
          name: 'Card A',
          type: AccountType.credit,
          balance: 100000,
          createdAt: now,
        ),
        Account(
          id: '2',
          name: 'Card B',
          type: AccountType.credit,
          balance: 200000,
          createdAt: now,
        ),
      ]);

      final breakdown = await calculateNetPosition.breakdown();

      expect(breakdown.totalAssets.cents, 0);
      expect(breakdown.totalLiabilities.cents, 300000);
      expect(breakdown.netPosition.cents, -300000);
    });
  });
}
