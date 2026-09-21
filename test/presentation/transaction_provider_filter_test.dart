import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vent_expense_pro/domain/entities/account.dart';
import 'package:vent_expense_pro/domain/entities/category.dart';
import 'package:vent_expense_pro/domain/entities/enums.dart';
import 'package:vent_expense_pro/domain/entities/transaction.dart';
import 'package:vent_expense_pro/domain/repositories/account_repository.dart';
import 'package:vent_expense_pro/domain/repositories/category_repository.dart';
import 'package:vent_expense_pro/domain/repositories/transaction_repository.dart';
import 'package:vent_expense_pro/domain/usecases/log_transaction.dart';
import 'package:vent_expense_pro/domain/usecases/manage_transaction.dart';
import 'package:vent_expense_pro/domain/value_objects/transaction_filter.dart';
import 'package:vent_expense_pro/presentation/providers/transaction_provider.dart';

class TestTransactionRepo implements TransactionRepository {
  List<Transaction> txns = [];

  @override
  Future<List<Transaction>> getAll() async => List.from(txns);

  @override
  Future<List<Transaction>> getByAccount(String accountId) async =>
      txns.where((t) => t.accountId == accountId || t.toAccountId == accountId).toList();

  @override
  Future<List<Transaction>> getByDateRange(DateTime start, DateTime end) async =>
      txns.where((t) => !t.dateTime.isBefore(start) && !t.dateTime.isAfter(end)).toList();

  @override
  Future<Transaction?> getById(String id) async =>
      txns.firstWhere((t) => t.id == id);

  @override
  Future<Transaction> insert(Transaction transaction) async {
    txns.add(transaction);
    return transaction;
  }

  @override
  Future<Transaction> update(Transaction transaction) async {
    final idx = txns.indexWhere((t) => t.id == transaction.id);
    if (idx != -1) txns[idx] = transaction;
    return transaction;
  }

  @override
  Future<void> delete(String id) async {
    txns.removeWhere((t) => t.id == id);
  }
}

class TestCategoryRepo implements CategoryRepository {
  List<Category> cats = [
    const Category(id: 'cat_food', name: 'Food', icon: 'food'),
    const Category(id: 'cat_transport', name: 'Transport', icon: 'transport'),
    const Category(id: 'cat_bills', name: 'Bills', icon: 'bills'),
  ];

  @override
  Future<List<Category>> getAll() async => List.from(cats);

  @override
  Future<Category?> getById(String id) async =>
      cats.firstWhere((c) => c.id == id);

  @override
  Future<Category> insert(Category category) async {
    cats.add(category);
    return category;
  }

  @override
  Future<Category> update(Category category) async => category;

  @override
  Future<void> delete(String id) async {
    cats.removeWhere((c) => c.id == id);
  }
}

class TestAccountRepo implements AccountRepository {
  List<Account> accounts = [
    Account(
      id: 'acc_bca',
      name: 'BCA Debit',
      type: AccountType.debit,
      balance: 1000000,
      createdAt: DateTime(2026, 1, 1),
    ),
    Account(
      id: 'acc_cc',
      name: 'Gold CC',
      type: AccountType.credit,
      balance: 500000,
      createdAt: DateTime(2026, 1, 1),
    ),
    Account(
      id: 'acc_cash',
      name: 'Wallet Cash',
      type: AccountType.cash,
      balance: 200000,
      createdAt: DateTime(2026, 1, 1),
    ),
    Account(
      id: 'acc_debt',
      name: 'Friend Bob',
      type: AccountType.debt,
      balance: 300000,
      createdAt: DateTime(2026, 1, 1),
    ),
  ];

  @override
  Future<List<Account>> getAll() async => List.from(accounts);
  @override
  Future<List<Account>> getByType(AccountType type) async =>
      accounts.where((a) => a.type == type).toList();
  @override
  Future<Account?> getById(String id) async =>
      accounts.firstWhere((a) => a.id == id);
  @override
  Future<Account> insert(Account account) async => account;
  @override
  Future<Account> update(Account account) async => account;
  @override
  Future<void> archive(String id) async {}
  @override
  Future<void> updateBalance(String id, int newBalance) async {}
}

void main() {
  late TestTransactionRepo txnRepo;
  late TestCategoryRepo catRepo;
  late TestAccountRepo accRepo;
  late ManageTransaction manageTxn;
  late TransactionProvider provider;

  final t1 = Transaction(
    id: 'tx1',
    amount: 50000,
    type: TransactionType.expense,
    categoryId: 'cat_food',
    accountId: 'acc_bca',
    note: 'Lunch at Warung Padang',
    dateTime: DateTime(2026, 9, 10, 12, 0),
  );

  final t2 = Transaction(
    id: 'tx2',
    amount: 120000,
    type: TransactionType.expense,
    categoryId: 'cat_transport',
    accountId: 'acc_cc',
    note: 'Taxi ride to office',
    dateTime: DateTime(2026, 9, 12, 8, 30),
  );

  final t3 = Transaction(
    id: 'tx3',
    amount: 500000,
    type: TransactionType.income,
    categoryId: 'cat_bills',
    accountId: 'acc_cash',
    note: 'Freelance bonus',
    dateTime: DateTime(2026, 9, 15, 17, 0),
  );

  final t4 = Transaction(
    id: 'tx4',
    amount: 200000,
    type: TransactionType.transfer,
    categoryId: 'cat_bills',
    accountId: 'acc_bca',
    toAccountId: 'acc_cash',
    note: 'ATM cash withdrawal',
    dateTime: DateTime(2026, 9, 18, 10, 0),
  );

  setUp(() {
    txnRepo = TestTransactionRepo();
    txnRepo.txns = [t1, t2, t3, t4];
    catRepo = TestCategoryRepo();
    accRepo = TestAccountRepo();
    final logTxn = LogTransaction(txnRepo, accRepo);
    manageTxn = ManageTransaction(txnRepo, accRepo, logTxn);
    provider = TransactionProvider(txnRepo, catRepo, manageTxn, accRepo);
  });

  group('TransactionProvider Multi-Criteria Filtering Tests', () {
    test('initial state has no active filters and loads all items', () async {
      await provider.loadAll();
      expect(provider.hasActiveFilter, isFalse);
      expect(provider.activeFilterCount, equals(0));
      expect(provider.filteredTransactions.length, equals(4));
    });

    test('filters by text search in note case-insensitively', () async {
      await provider.loadAll();

      provider.setFilter(const TransactionFilter(searchText: 'padang'));
      expect(provider.filteredTransactions.length, equals(1));
      expect(provider.filteredTransactions.first.id, equals('tx1'));

      provider.setFilter(const TransactionFilter(searchText: 'OFFICE'));
      expect(provider.filteredTransactions.length, equals(1));
      expect(provider.filteredTransactions.first.id, equals('tx2'));

      provider.setFilter(const TransactionFilter(searchText: 'nonexistent'));
      expect(provider.filteredTransactions, isEmpty);
    });

    test('filters by specific accounts (source or destination)', () async {
      await provider.loadAll();

      // Only transactions involving acc_cc
      provider.setFilter(const TransactionFilter(accountIds: ['acc_cc']));
      expect(provider.filteredTransactions.length, equals(1));
      expect(provider.filteredTransactions.first.id, equals('tx2'));

      // Transactions involving acc_cash (t3 source, t4 destination)
      provider.setFilter(const TransactionFilter(accountIds: ['acc_cash']));
      expect(provider.filteredTransactions.length, equals(2));
      expect(provider.filteredTransactions.map((t) => t.id), containsAll(['tx3', 'tx4']));
    });

    test('filters by account types', () async {
      await provider.loadAll();

      // Only credit card transactions
      provider.setFilter(const TransactionFilter(accountTypes: [AccountType.credit]));
      expect(provider.filteredTransactions.length, equals(1));
      expect(provider.filteredTransactions.first.id, equals('tx2'));

      // Debit accounts
      provider.setFilter(const TransactionFilter(accountTypes: [AccountType.debit]));
      expect(provider.filteredTransactions.length, equals(2));
      expect(provider.filteredTransactions.map((t) => t.id), containsAll(['tx1', 'tx4']));
    });

    test('filters by transaction types', () async {
      await provider.loadAll();

      provider.setFilter(const TransactionFilter(transactionTypes: [TransactionType.expense]));
      expect(provider.filteredTransactions.length, equals(2));
      expect(provider.filteredTransactions.map((t) => t.id), containsAll(['tx1', 'tx2']));

      provider.setFilter(const TransactionFilter(transactionTypes: [TransactionType.transfer]));
      expect(provider.filteredTransactions.length, equals(1));
      expect(provider.filteredTransactions.first.id, equals('tx4'));
    });

    test('filters by category IDs', () async {
      await provider.loadAll();

      provider.setFilter(const TransactionFilter(categoryIds: ['cat_food']));
      expect(provider.filteredTransactions.length, equals(1));
      expect(provider.filteredTransactions.first.id, equals('tx1'));
    });

    test('filters by amount range (min and max)', () async {
      await provider.loadAll();

      // Amount >= 100,000
      provider.setFilter(const TransactionFilter(minAmount: 100000));
      expect(provider.filteredTransactions.length, equals(3)); // t2 (120k), t3 (500k), t4 (200k)

      // Amount <= 150,000
      provider.setFilter(const TransactionFilter(maxAmount: 150000));
      expect(provider.filteredTransactions.length, equals(2)); // t1 (50k), t2 (120k)

      // 80,000 <= Amount <= 250,000
      provider.setFilter(const TransactionFilter(minAmount: 80000, maxAmount: 250000));
      expect(provider.filteredTransactions.length, equals(2)); // t2 (120k), t4 (200k)
    });

    test('combines multiple criteria with AND logic', () async {
      await provider.loadAll();

      // Expense AND Credit Card AND Amount > 100k
      provider.setFilter(const TransactionFilter(
        transactionTypes: [TransactionType.expense],
        accountTypes: [AccountType.credit],
        minAmount: 100000,
      ));
      expect(provider.filteredTransactions.length, equals(1));
      expect(provider.filteredTransactions.first.id, equals('tx2'));

      // Expense AND Debit AND Amount > 100k (t1 is Debit Expense, but 50k -> should be empty)
      provider.setFilter(const TransactionFilter(
        transactionTypes: [TransactionType.expense],
        accountTypes: [AccountType.debit],
        minAmount: 100000,
      ));
      expect(provider.filteredTransactions, isEmpty);
    });

    test('countMatching previews count without changing active filter', () async {
      await provider.loadAll();

      const previewFilter = TransactionFilter(transactionTypes: [TransactionType.expense]);
      final count = provider.countMatching(previewFilter);

      expect(count, equals(2));
      expect(provider.hasActiveFilter, isFalse);
      expect(provider.filteredTransactions.length, equals(4));
    });

    test('clearFilter resets filter and restores all transactions', () async {
      await provider.loadAll();

      provider.setFilter(const TransactionFilter(searchText: 'padang'));
      expect(provider.filteredTransactions.length, equals(1));
      expect(provider.hasActiveFilter, isTrue);

      provider.clearFilter();
      expect(provider.filteredTransactions.length, equals(4));
      expect(provider.hasActiveFilter, isFalse);
    });

    test('legacy date filter methods work seamlessly', () async {
      await provider.loadAll();

      final range = DateTimeRange(
        start: DateTime(2026, 9, 9),
        end: DateTime(2026, 9, 11),
      );

      provider.setDateFilter(range);
      expect(provider.hasActiveFilter, isTrue);
      expect(provider.dateFilter, equals(range));
      expect(provider.filteredTransactions.length, equals(1)); // only t1 on Sep 10

      provider.clearDateFilter();
      expect(provider.hasActiveFilter, isFalse);
      expect(provider.dateFilter, isNull);
      expect(provider.filteredTransactions.length, equals(4));
    });
  });
}
