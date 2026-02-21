import 'package:flutter_test/flutter_test.dart';
import 'package:vent_expense_pro/domain/entities/account.dart';
import 'package:vent_expense_pro/domain/entities/enums.dart';
import 'package:vent_expense_pro/domain/repositories/account_repository.dart';
import 'package:vent_expense_pro/domain/usecases/manage_account.dart';

/// A simple in-memory fake of [AccountRepository] for testing.
class FakeAccountRepository implements AccountRepository {
  final List<Account> _accounts = [];

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
    if (index != -1) {
      _accounts[index] = account;
    }
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
  late ManageAccount manageAccount;

  setUp(() {
    fakeRepo = FakeAccountRepository();
    manageAccount = ManageAccount(fakeRepo);
  });

  group('ManageAccount.createAccount', () {
    test('should create an account with valid inputs', () async {
      final account = await manageAccount.createAccount(
        name: 'BCA Debit',
        type: AccountType.debit,
        balance: 500000,
      );

      expect(account.name, 'BCA Debit');
      expect(account.type, AccountType.debit);
      expect(account.balance, 500000);
      expect(account.currency, 'IDR');
      expect(account.isArchived, false);
      expect(account.id, isNotEmpty);
    });

    test('should trim whitespace from name', () async {
      final account = await manageAccount.createAccount(
        name: '  Cash Wallet  ',
        type: AccountType.cash,
        balance: 100000,
      );

      expect(account.name, 'Cash Wallet');
    });

    test('should throw when name is empty', () async {
      expect(
        () => manageAccount.createAccount(
          name: '',
          type: AccountType.debit,
          balance: 0,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should throw when name is only whitespace', () async {
      expect(
        () => manageAccount.createAccount(
          name: '   ',
          type: AccountType.debit,
          balance: 0,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should throw when balance is negative', () async {
      expect(
        () => manageAccount.createAccount(
          name: 'Test',
          type: AccountType.debit,
          balance: -100,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should accept zero balance', () async {
      final account = await manageAccount.createAccount(
        name: 'Empty Account',
        type: AccountType.cash,
        balance: 0,
      );

      expect(account.balance, 0);
    });

    test('should accept custom currency', () async {
      final account = await manageAccount.createAccount(
        name: 'USD Account',
        type: AccountType.debit,
        balance: 1000,
        currency: 'USD',
      );

      expect(account.currency, 'USD');
    });

    test('should generate unique IDs', () async {
      final a = await manageAccount.createAccount(
        name: 'Account A',
        type: AccountType.debit,
        balance: 100,
      );
      final b = await manageAccount.createAccount(
        name: 'Account B',
        type: AccountType.cash,
        balance: 200,
      );

      expect(a.id, isNot(equals(b.id)));
    });

    test('should persist to repository', () async {
      await manageAccount.createAccount(
        name: 'Persisted',
        type: AccountType.debit,
        balance: 300,
      );

      final allAccounts = await fakeRepo.getAll();
      expect(allAccounts, hasLength(1));
      expect(allAccounts.first.name, 'Persisted');
    });
  });

  group('ManageAccount.updateAccount', () {
    test('should update account name', () async {
      final original = await manageAccount.createAccount(
        name: 'Old Name',
        type: AccountType.debit,
        balance: 100,
      );

      final updated = await manageAccount.updateAccount(
        original.copyWith(name: 'New Name'),
      );

      expect(updated.name, 'New Name');
    });

    test('should throw when updated name is empty', () async {
      final original = await manageAccount.createAccount(
        name: 'Valid',
        type: AccountType.debit,
        balance: 100,
      );

      expect(
        () => manageAccount.updateAccount(original.copyWith(name: '')),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should trim updated name', () async {
      final original = await manageAccount.createAccount(
        name: 'Original',
        type: AccountType.debit,
        balance: 100,
      );

      final updated = await manageAccount.updateAccount(
        original.copyWith(name: '  Trimmed  '),
      );

      expect(updated.name, 'Trimmed');
    });
  });

  group('ManageAccount.archiveAccount', () {
    test('should archive an existing account', () async {
      final account = await manageAccount.createAccount(
        name: 'To Archive',
        type: AccountType.cash,
        balance: 100,
      );

      await manageAccount.archiveAccount(account.id);

      // Archived accounts don't appear in getAll()
      final all = await fakeRepo.getAll();
      expect(all, isEmpty);

      // But can still be found by ID
      final found = await fakeRepo.getById(account.id);
      expect(found, isNotNull);
      expect(found!.isArchived, true);
    });

    test('should throw when account not found', () async {
      expect(
        () => manageAccount.archiveAccount('nonexistent-id'),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
