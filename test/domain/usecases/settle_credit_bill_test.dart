import 'package:flutter_test/flutter_test.dart';
import 'package:vent_expense_pro/domain/entities/account.dart';
import 'package:vent_expense_pro/domain/entities/enums.dart';
import 'package:vent_expense_pro/domain/entities/transaction.dart';
import 'package:vent_expense_pro/domain/repositories/account_repository.dart';
import 'package:vent_expense_pro/domain/repositories/transaction_repository.dart';
import 'package:vent_expense_pro/domain/usecases/settle_credit_bill.dart';

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
  late SettleCreditBill settleCreditBill;

  final now = DateTime(2026, 2, 21, 14, 30);

  final debitAccount = Account(
    id: 'acc-debit',
    name: 'BCA Debit',
    type: AccountType.debit,
    balance: 500000,
    currency: 'IDR',
    createdAt: now,
  );

  final cashAccount = Account(
    id: 'acc-cash',
    name: 'Cash Wallet',
    type: AccountType.cash,
    balance: 200000,
    currency: 'IDR',
    createdAt: now,
  );

  final creditAccount = Account(
    id: 'acc-credit',
    name: 'BCA Credit Card',
    type: AccountType.credit,
    balance: 150000, // Rp 150,000 outstanding
    currency: 'IDR',
    createdAt: now,
  );

  setUp(() {
    accountRepo = FakeAccountRepository();
    transactionRepo = FakeTransactionRepository();
    settleCreditBill = SettleCreditBill(transactionRepo, accountRepo);

    accountRepo.seed([debitAccount, cashAccount, creditAccount]);
  });

  group('SettleCreditBill — happy path', () {
    test('should settle full balance from debit account', () async {
      final txn = await settleCreditBill.call(
        sourceAccountId: 'acc-debit',
        creditAccountId: 'acc-credit',
        amount: 150000,
      );

      // Source deducted
      expect(accountRepo.accountById('acc-debit')!.balance, 350000);
      // Credit liability cleared
      expect(accountRepo.accountById('acc-credit')!.balance, 0);
      // Settlement transaction logged
      expect(txn.isSettlement, true);
      expect(txn.type, TransactionType.transfer);
      expect(txn.amount, 150000);
      expect(txn.accountId, 'acc-debit');
      expect(txn.toAccountId, 'acc-credit');
      expect(txn.categoryId, 'settlement');
      // Persisted
      final stored = await transactionRepo.getById(txn.id);
      expect(stored, isNotNull);
    });

    test('should settle partial amount', () async {
      final txn = await settleCreditBill.call(
        sourceAccountId: 'acc-debit',
        creditAccountId: 'acc-credit',
        amount: 50000,
      );

      expect(accountRepo.accountById('acc-debit')!.balance, 450000);
      expect(accountRepo.accountById('acc-credit')!.balance, 100000);
      expect(txn.amount, 50000);
    });

    test('should settle from cash account', () async {
      final txn = await settleCreditBill.call(
        sourceAccountId: 'acc-cash',
        creditAccountId: 'acc-credit',
        amount: 100000,
      );

      expect(accountRepo.accountById('acc-cash')!.balance, 100000);
      expect(accountRepo.accountById('acc-credit')!.balance, 50000);
      expect(txn.accountId, 'acc-cash');
    });
  });

  group('SettleCreditBill — validation', () {
    test('should throw when amount is zero', () {
      expect(
        () => settleCreditBill.call(
          sourceAccountId: 'acc-debit',
          creditAccountId: 'acc-credit',
          amount: 0,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should throw when amount is negative', () {
      expect(
        () => settleCreditBill.call(
          sourceAccountId: 'acc-debit',
          creditAccountId: 'acc-credit',
          amount: -10000,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should throw when source is a credit account (not asset)', () {
      expect(
        () => settleCreditBill.call(
          sourceAccountId: 'acc-credit',
          creditAccountId: 'acc-credit',
          amount: 50000,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should throw when target is a debit account (not liability)', () {
      expect(
        () => settleCreditBill.call(
          sourceAccountId: 'acc-debit',
          creditAccountId: 'acc-cash',
          amount: 50000,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should throw when source account not found', () {
      expect(
        () => settleCreditBill.call(
          sourceAccountId: 'nonexistent',
          creditAccountId: 'acc-credit',
          amount: 50000,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should throw when credit account not found', () {
      expect(
        () => settleCreditBill.call(
          sourceAccountId: 'acc-debit',
          creditAccountId: 'nonexistent',
          amount: 50000,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should throw when insufficient balance', () {
      expect(
        () => settleCreditBill.call(
          sourceAccountId: 'acc-debit',
          creditAccountId: 'acc-credit',
          amount: 600000, // source only has 500000
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
