import 'package:flutter_test/flutter_test.dart';
import 'package:vent_expense_pro/domain/entities/account.dart';
import 'package:vent_expense_pro/domain/entities/enums.dart';
import 'package:vent_expense_pro/domain/entities/transaction.dart';
import 'package:vent_expense_pro/domain/repositories/account_repository.dart';
import 'package:vent_expense_pro/domain/repositories/transaction_repository.dart';
import 'package:vent_expense_pro/domain/usecases/log_transaction.dart';
import 'package:vent_expense_pro/domain/usecases/manage_transaction.dart';

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
  Future<List<Transaction>> getAll() async => _transactions.values.toList();

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

  @override
  Future<List<Transaction>> getByDateRange(DateTime start, DateTime end) async =>
      _transactions.values.toList();

  @override
  Future<List<Transaction>> getByAccount(String accountId) async =>
      _transactions.values
          .where((t) => t.accountId == accountId || t.toAccountId == accountId)
          .toList();
}

void main() {
  late FakeAccountRepository accountRepo;
  late FakeTransactionRepository txnRepo;
  late LogTransaction logTransaction;
  late ManageTransaction manageTransaction;

  final now = DateTime.now();

  setUp(() {
    accountRepo = FakeAccountRepository();
    txnRepo = FakeTransactionRepository();
    logTransaction = LogTransaction(
      txnRepo,
      accountRepo,
    );
    manageTransaction = ManageTransaction(
      txnRepo,
      accountRepo,
      logTransaction,
    );
  });

  group('Credit Account Transfer Restrictions', () {
    late Account creditCard;
    late Account debitAccount;

    setUp(() {
      creditCard = Account(
        id: 'acc_cc',
        name: 'Credit Card',
        type: AccountType.credit,
        balance: 500000,
        currency: 'IDR',
        createdAt: now,
      );
      debitAccount = Account(
        id: 'acc_debit',
        name: 'Debit Card',
        type: AccountType.debit,
        balance: 1000000,
        currency: 'IDR',
        createdAt: now,
      );
      accountRepo.seed([creditCard, debitAccount]);
    });

    test('LogTransaction throws ArgumentError when credit card is transfer source and not settlement', () async {
      final txn = Transaction(
        id: 'txn_1',
        amount: 100000,
        type: TransactionType.transfer,
        categoryId: 'cat_transfer',
        accountId: 'acc_cc',
        toAccountId: 'acc_debit',
        isSettlement: false,
        dateTime: now,
      );

      expect(
        () => logTransaction(txn),
        throwsA(isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          contains('Credit accounts cannot participate in transfers'),
        )),
      );
    });

    test('LogTransaction throws ArgumentError when credit card is transfer destination and not settlement', () async {
      final txn = Transaction(
        id: 'txn_2',
        amount: 100000,
        type: TransactionType.transfer,
        categoryId: 'cat_transfer',
        accountId: 'acc_debit',
        toAccountId: 'acc_cc',
        isSettlement: false,
        dateTime: now,
      );

      expect(
        () => logTransaction(txn),
        throwsA(isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          contains('Cannot transfer to a credit account'),
        )),
      );
    });

    test('LogTransaction allows transfer when isSettlement is true', () async {
      final settlementTxn = Transaction(
        id: 'txn_settle',
        amount: 200000,
        type: TransactionType.transfer,
        categoryId: 'cat_settlement',
        accountId: 'acc_debit',
        toAccountId: 'acc_cc',
        isSettlement: true,
        dateTime: now,
      );

      await logTransaction(settlementTxn);

      // Debit balance should decrease by 200k
      expect(accountRepo.accountById('acc_debit')!.balance, equals(800000));
      // Credit card balance should decrease by 200k (liability reduced)
      expect(accountRepo.accountById('acc_cc')!.balance, equals(300000));
    });
  });

  group('Credit Account Expense & Income Semantics', () {
    late Account creditCard;

    setUp(() {
      creditCard = Account(
        id: 'acc_cc',
        name: 'Credit Card',
        type: AccountType.credit,
        balance: 100000,
        currency: 'IDR',
        createdAt: now,
      );
      accountRepo.seed([creditCard]);
    });

    test('credit card expense increases account balance (liability)', () async {
      final expense = Transaction(
        id: 'txn_exp',
        amount: 50000,
        type: TransactionType.expense,
        categoryId: 'cat_food',
        accountId: 'acc_cc',
        dateTime: now,
      );

      await logTransaction(expense);

      // 100,000 + 50,000 = 150,000
      expect(accountRepo.accountById('acc_cc')!.balance, equals(150000));
    });

    test('credit card income (cashback/refund) decreases account balance (liability)', () async {
      final refund = Transaction(
        id: 'txn_refund',
        amount: 30000,
        type: TransactionType.income,
        categoryId: 'cat_refund',
        accountId: 'acc_cc',
        dateTime: now,
      );

      await logTransaction(refund);

      // 100,000 - 30,000 = 70,000
      expect(accountRepo.accountById('acc_cc')!.balance, equals(70000));
    });

    test('deleting credit card expense correctly rolls back (decreases liability)', () async {
      final expense = Transaction(
        id: 'txn_exp',
        amount: 50000,
        type: TransactionType.expense,
        categoryId: 'cat_food',
        accountId: 'acc_cc',
        dateTime: now,
      );

      await logTransaction(expense);
      expect(accountRepo.accountById('acc_cc')!.balance, equals(150000));

      await manageTransaction.delete(expense);
      expect(accountRepo.accountById('acc_cc')!.balance, equals(100000));
    });

    test('deleting credit card income correctly rolls back (increases liability)', () async {
      final refund = Transaction(
        id: 'txn_refund',
        amount: 20000,
        type: TransactionType.income,
        categoryId: 'cat_refund',
        accountId: 'acc_cc',
        dateTime: now,
      );

      await logTransaction(refund);
      expect(accountRepo.accountById('acc_cc')!.balance, equals(80000));

      await manageTransaction.delete(refund);
      expect(accountRepo.accountById('acc_cc')!.balance, equals(100000));
    });
  });
}
