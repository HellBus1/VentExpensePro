import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:vent_expense_pro/domain/entities/account.dart';
import 'package:vent_expense_pro/domain/entities/category.dart';
import 'package:vent_expense_pro/domain/entities/enums.dart';
import 'package:vent_expense_pro/domain/entities/transaction.dart';
import 'package:vent_expense_pro/domain/repositories/account_repository.dart';
import 'package:vent_expense_pro/domain/repositories/category_repository.dart';
import 'package:vent_expense_pro/domain/repositories/transaction_repository.dart';
import 'package:vent_expense_pro/domain/usecases/calculate_net_position.dart';
import 'package:vent_expense_pro/domain/usecases/log_transaction.dart';
import 'package:vent_expense_pro/domain/usecases/manage_account.dart';
import 'package:vent_expense_pro/domain/usecases/manage_transaction.dart';
import 'package:vent_expense_pro/domain/usecases/settle_credit_bill.dart';
import 'package:vent_expense_pro/domain/usecases/settle_debt.dart';
import 'package:vent_expense_pro/domain/value_objects/transaction_filter.dart';
import 'package:vent_expense_pro/presentation/providers/account_provider.dart';
import 'package:vent_expense_pro/presentation/providers/currency_provider.dart';
import 'package:vent_expense_pro/presentation/providers/transaction_provider.dart';
import 'package:vent_expense_pro/presentation/screens/transaction_filter_screen.dart';

class MockAccRepo implements AccountRepository {
  List<Account> accounts = [
    Account(
      id: 'acc1',
      name: 'BCA Debit',
      type: AccountType.debit,
      balance: 1000000,
      createdAt: DateTime(2026, 1, 1),
    ),
    Account(
      id: 'acc2',
      name: 'Gold Card',
      type: AccountType.credit,
      balance: 500000,
      createdAt: DateTime(2026, 1, 1),
    ),
  ];
  @override
  Future<List<Account>> getAll() async => accounts;
  @override
  Future<List<Account>> getByType(AccountType type) async => [];
  @override
  Future<Account?> getById(String id) async => null;
  @override
  Future<Account> insert(Account account) async => account;
  @override
  Future<Account> update(Account account) async => account;
  @override
  Future<void> archive(String id) async {}
  @override
  Future<void> updateBalance(String id, int newBalance) async {}
}

class MockTxnRepo implements TransactionRepository {
  List<Transaction> txns = [
    Transaction(
      id: 'tx1',
      amount: 50000,
      type: TransactionType.expense,
      categoryId: 'food',
      accountId: 'acc1',
      note: 'Lunch ramen',
      dateTime: DateTime(2026, 9, 10),
    ),
    Transaction(
      id: 'tx2',
      amount: 150000,
      type: TransactionType.expense,
      categoryId: 'shopping',
      accountId: 'acc2',
      note: 'Books',
      dateTime: DateTime(2026, 9, 12),
    ),
  ];
  @override
  Future<List<Transaction>> getAll() async => txns;
  @override
  Future<List<Transaction>> getByAccount(String accountId) async => [];
  @override
  Future<List<Transaction>> getByDateRange(DateTime start, DateTime end) async => [];
  @override
  Future<Transaction?> getById(String id) async => null;
  @override
  Future<Transaction> insert(Transaction transaction) async => transaction;
  @override
  Future<Transaction> update(Transaction transaction) async => transaction;
  @override
  Future<void> delete(String id) async {}
}

class MockCatRepo implements CategoryRepository {
  List<Category> cats = [
    const Category(id: 'food', name: 'Food', icon: 'food'),
    const Category(id: 'shopping', name: 'Shopping', icon: 'shopping'),
  ];
  @override
  Future<List<Category>> getAll() async => cats;
  @override
  Future<Category?> getById(String id) async => null;
  @override
  Future<Category> insert(Category category) async => category;
  @override
  Future<Category> update(Category category) async => category;
  @override
  Future<void> delete(String id) async {}
}

void main() {
  late MockAccRepo accRepo;
  late MockTxnRepo txnRepo;
  late MockCatRepo catRepo;
  late AccountProvider accProv;
  late TransactionProvider txnProv;

  setUp(() {
    accRepo = MockAccRepo();
    txnRepo = MockTxnRepo();
    catRepo = MockCatRepo();

    accProv = AccountProvider(
      accRepo,
      CalculateNetPosition(accRepo),
      ManageAccount(accRepo),
      SettleCreditBill(txnRepo, accRepo),
      SettleDebt(txnRepo, accRepo),
    );

    final logTxn = LogTransaction(txnRepo, accRepo);
    final manageTxn = ManageTransaction(txnRepo, accRepo, logTxn);
    txnProv = TransactionProvider(txnRepo, catRepo, manageTxn, accRepo);
  });

  Widget createTestWidget({
    TransactionFilter initialFilter = TransactionFilter.empty,
    ValueChanged<TransactionFilter>? onApply,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: accProv),
        ChangeNotifierProvider.value(value: txnProv),
        ChangeNotifierProvider(create: (_) => CurrencyProvider()),
      ],
      child: MaterialApp(
        home: TransactionFilterScreen(
          initialFilter: initialFilter,
          onApply: onApply,
        ),
      ),
    );
  }

  group('TransactionFilterScreen Widget Tests', () {
    testWidgets('renders all filter controls and applies selected criteria',
        (tester) async {
      await accProv.loadAccounts();
      await txnProv.loadAll();

      TransactionFilter? appliedFilter;

      await tester.pumpWidget(createTestWidget(
        onApply: (f) => appliedFilter = f,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Filter Transactions'), findsOneWidget);
      expect(find.byKey(const ValueKey('filter_search_input')), findsOneWidget);
      expect(find.byKey(const ValueKey('filter_date_range_picker')), findsOneWidget);
      expect(find.byKey(const ValueKey('filter_account_chip_BCA Debit')), findsOneWidget);
      expect(find.byKey(const ValueKey('filter_account_type_credit')), findsOneWidget);
      expect(find.byKey(const ValueKey('filter_transaction_type_expense')), findsOneWidget);
      expect(find.byKey(const ValueKey('filter_category_chip_Food')), findsOneWidget);
      expect(find.byKey(const ValueKey('filter_min_amount_input')), findsOneWidget);
      expect(find.byKey(const ValueKey('filter_max_amount_input')), findsOneWidget);
      expect(find.text('2 of 2 matches'), findsOneWidget);

      // 1. Enter search text 'ramen'
      await tester.enterText(
          find.byKey(const ValueKey('filter_search_input')), 'ramen');
      await tester.pumpAndSettle();

      expect(find.text('1 of 2 matches'), findsOneWidget);

      // 2. Select category chip 'Food'
      final foodChip = find.byKey(const ValueKey('filter_category_chip_Food'));
      await tester.ensureVisible(foodChip);
      await tester.pumpAndSettle();
      await tester.tap(foodChip);
      await tester.pumpAndSettle();

      // 3. Tap Apply Filters button
      await tester.tap(find.byKey(const ValueKey('filter_apply_button')));
      await tester.pumpAndSettle();

      expect(appliedFilter, isNotNull);
      expect(appliedFilter!.searchText, equals('ramen'));
      expect(appliedFilter!.categoryIds, equals(['food']));
    });

    testWidgets('Reset button clears active filter selections',
        (tester) async {
      await accProv.loadAccounts();
      await txnProv.loadAll();

      await tester.pumpWidget(createTestWidget(
        initialFilter: const TransactionFilter(
          searchText: 'lunch',
          accountIds: ['acc1'],
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('filter_reset_button')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('filter_reset_button')));
      await tester.pumpAndSettle();

      expect(find.text('2 of 2 matches'), findsOneWidget);
      expect(find.text('No filters applied'), findsOneWidget);
    });
  });
}
