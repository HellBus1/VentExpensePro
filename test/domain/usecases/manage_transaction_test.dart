import 'package:flutter_test/flutter_test.dart';
import 'package:vent_expense_pro/domain/entities/account.dart';
import 'package:vent_expense_pro/domain/entities/enums.dart';
import 'package:vent_expense_pro/domain/entities/transaction.dart';
import 'package:vent_expense_pro/domain/repositories/account_repository.dart';
import 'package:vent_expense_pro/domain/repositories/transaction_repository.dart';
import 'package:vent_expense_pro/domain/usecases/log_transaction.dart';
import 'package:vent_expense_pro/domain/usecases/manage_transaction.dart';

// ——— In-memory fakes ———

class FakeAccountRepository implements AccountRepository {
  final Map<String, Account> _accounts = {};

  void seed(List<Account> accounts) {
    for (final a in accounts) {
      _accounts[a.id] = a;
    }
  }

  Account? accountById(String id) => _accounts[id];

  @override
  Future<List<Account>> getAll() async => _accounts.values.toList();

  @override
  Future<Account?> getById(String id) async => _accounts[id];

  @override
  Future<Account> insert(Account account) async {
    _accounts[account.id] = account;
    return account;
  }

  @override
  Future<Account> update(Account account) async {
    _accounts[account.id] = account;
    return account;
  }

  @override
  Future<void> updateBalance(String id, int newBalance) async {
    final account = _accounts[id]!;
    _accounts[id] = account.copyWith(balance: newBalance);
  }

  Future<void> delete(String id) async {
    _accounts.remove(id);
  }

  @override
  Future<void> archive(String id) async {
    final account = _accounts[id]!;
    _accounts[id] = account.copyWith(isArchived: true);
  }

  @override
  Future<List<Account>> getByType(AccountType type) async =>
      _accounts.values.where((a) => a.type == type).toList();
}

class FakeTransactionRepository implements TransactionRepository {
  final Map<String, Transaction> _transactions = {};

  @override
  Future<List<Transaction>> getAll() async =>
      _transactions.values.toList()
        ..sort((a, b) => b.dateTime.compareTo(a.dateTime));

  @override
  Future<List<Transaction>> getByAccount(String accountId) async =>
      _transactions.values
          .where((t) => t.accountId == accountId || t.toAccountId == accountId)
          .toList();

  @override
  Future<List<Transaction>> getByDateRange(
      DateTime start, DateTime end) async =>
      _transactions.values
          .where((t) =>
              t.dateTime.isAfter(start.subtract(const Duration(seconds: 1))) &&
              t.dateTime.isBefore(end.add(const Duration(seconds: 1))))
          .toList();

  @override
  Future<Transaction?> getById(String id) async => _transactions[id];

  @override
  Future<Transaction> insert(Transaction transaction) async {
    _transactions[transaction.id] = transaction;
    return transaction;
  }

  @override
  Future<Transaction> update(Transaction transaction) async {
    _transactions[transaction.id] = transaction;
    return transaction;
  }

  @override
  Future<void> delete(String id) async {
    _transactions.remove(id);
  }
}

// ——— Tests ———

void main() {
  late FakeAccountRepository accountRepo;
  late FakeTransactionRepository transactionRepo;
  late LogTransaction logTransaction;
  late ManageTransaction manageTransaction;

  final now = DateTime(2026, 2, 21, 14, 30);

  final debitAccount = Account(
    id: 'acc-debit',
    name: 'BCA Debit',
    type: AccountType.debit,
    balance: 500000,
    currency: 'IDR',
    isArchived: false,
    createdAt: now,
  );

  final cashAccount = Account(
    id: 'acc-cash',
    name: 'Cash Wallet',
    type: AccountType.cash,
    balance: 200000,
    currency: 'IDR',
    isArchived: false,
    createdAt: now,
  );

  final creditAccount = Account(
    id: 'acc-credit',
    name: 'Credit Card',
    type: AccountType.credit,
    balance: 100000,
    currency: 'IDR',
    isArchived: false,
    createdAt: now,
  );

  setUp(() {
    accountRepo = FakeAccountRepository();
    transactionRepo = FakeTransactionRepository();
    logTransaction = LogTransaction(transactionRepo, accountRepo);
    manageTransaction =
        ManageTransaction(transactionRepo, accountRepo, logTransaction);

    accountRepo.seed([debitAccount, cashAccount, creditAccount]);
  });

  group('ManageTransaction.create', () {
    test('should create an expense and deduct from debit account', () async {
      final txn = Transaction(
        id: 'txn-1',
        amount: 50000,
        type: TransactionType.expense,
        categoryId: 'food',
        accountId: 'acc-debit',
        dateTime: now,
      );

      await manageTransaction.create(txn);

      final account = accountRepo.accountById('acc-debit')!;
      expect(account.balance, 450000); // 500000 - 50000
      expect((await transactionRepo.getById('txn-1')), isNotNull);
    });

    test('should create income and add to debit account', () async {
      final txn = Transaction(
        id: 'txn-2',
        amount: 100000,
        type: TransactionType.income,
        categoryId: 'other',
        accountId: 'acc-debit',
        dateTime: now,
      );

      await manageTransaction.create(txn);

      expect(accountRepo.accountById('acc-debit')!.balance, 600000);
    });

    test('should create expense on credit card (increase liability)', () async {
      final txn = Transaction(
        id: 'txn-3',
        amount: 30000,
        type: TransactionType.expense,
        categoryId: 'shopping',
        accountId: 'acc-credit',
        dateTime: now,
      );

      await manageTransaction.create(txn);

      expect(accountRepo.accountById('acc-credit')!.balance, 130000);
    });
  });

  group('ManageTransaction.delete', () {
    test('should reverse expense on debit account', () async {
      final txn = Transaction(
        id: 'txn-del',
        amount: 50000,
        type: TransactionType.expense,
        categoryId: 'food',
        accountId: 'acc-debit',
        dateTime: now,
      );

      // Create then delete
      await manageTransaction.create(txn);
      expect(accountRepo.accountById('acc-debit')!.balance, 450000);

      await manageTransaction.delete(txn);
      expect(accountRepo.accountById('acc-debit')!.balance, 500000);
      expect(await transactionRepo.getById('txn-del'), isNull);
    });

    test('should reverse income on delete', () async {
      final txn = Transaction(
        id: 'txn-del-inc',
        amount: 100000,
        type: TransactionType.income,
        categoryId: 'other',
        accountId: 'acc-debit',
        dateTime: now,
      );

      await manageTransaction.create(txn);
      expect(accountRepo.accountById('acc-debit')!.balance, 600000);

      await manageTransaction.delete(txn);
      expect(accountRepo.accountById('acc-debit')!.balance, 500000);
    });

    test('should reverse transfer on delete', () async {
      final txn = Transaction(
        id: 'txn-del-xfr',
        amount: 50000,
        type: TransactionType.transfer,
        categoryId: 'other',
        accountId: 'acc-debit',
        toAccountId: 'acc-cash',
        dateTime: now,
      );

      await manageTransaction.create(txn);
      expect(accountRepo.accountById('acc-debit')!.balance, 450000);
      expect(accountRepo.accountById('acc-cash')!.balance, 250000);

      await manageTransaction.delete(txn);
      expect(accountRepo.accountById('acc-debit')!.balance, 500000);
      expect(accountRepo.accountById('acc-cash')!.balance, 200000);
    });

    test('should reverse credit card expense on delete', () async {
      final txn = Transaction(
        id: 'txn-del-cc',
        amount: 30000,
        type: TransactionType.expense,
        categoryId: 'shopping',
        accountId: 'acc-credit',
        dateTime: now,
      );

      await manageTransaction.create(txn);
      expect(accountRepo.accountById('acc-credit')!.balance, 130000);

      await manageTransaction.delete(txn);
      expect(accountRepo.accountById('acc-credit')!.balance, 100000);
    });
  });

  group('ManageTransaction.update', () {
    test('should reverse old expense and apply new amount', () async {
      final oldTxn = Transaction(
        id: 'txn-upd',
        amount: 50000,
        type: TransactionType.expense,
        categoryId: 'food',
        accountId: 'acc-debit',
        dateTime: now,
      );

      await manageTransaction.create(oldTxn);
      expect(accountRepo.accountById('acc-debit')!.balance, 450000);

      final newTxn = oldTxn.copyWith(amount: 75000);
      await manageTransaction.update(oldTxn, newTxn);

      expect(accountRepo.accountById('acc-debit')!.balance, 425000);
      final stored = await transactionRepo.getById('txn-upd');
      expect(stored!.amount, 75000);
    });

    test('should handle type change from expense to income', () async {
      final oldTxn = Transaction(
        id: 'txn-type',
        amount: 50000,
        type: TransactionType.expense,
        categoryId: 'food',
        accountId: 'acc-debit',
        dateTime: now,
      );

      await manageTransaction.create(oldTxn);
      expect(accountRepo.accountById('acc-debit')!.balance, 450000);

      final newTxn = oldTxn.copyWith(type: TransactionType.income);
      await manageTransaction.update(oldTxn, newTxn);

      // Reversed expense (+50k) then applied income (+50k) = 500k + 50k = 550k
      expect(accountRepo.accountById('acc-debit')!.balance, 550000);
    });

    test('should handle account change', () async {
      final oldTxn = Transaction(
        id: 'txn-acc',
        amount: 50000,
        type: TransactionType.expense,
        categoryId: 'food',
        accountId: 'acc-debit',
        dateTime: now,
      );

      await manageTransaction.create(oldTxn);
      expect(accountRepo.accountById('acc-debit')!.balance, 450000);
      expect(accountRepo.accountById('acc-cash')!.balance, 200000);

      final newTxn = oldTxn.copyWith(accountId: 'acc-cash');
      await manageTransaction.update(oldTxn, newTxn);

      // Old debit reversed: 450k + 50k = 500k
      expect(accountRepo.accountById('acc-debit')!.balance, 500000);
      // New cash applied: 200k - 50k = 150k
      expect(accountRepo.accountById('acc-cash')!.balance, 150000);
    });
  });
}
