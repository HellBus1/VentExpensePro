import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:vent_expense_pro/domain/entities/account.dart';
import 'package:vent_expense_pro/domain/entities/category.dart';
import 'package:vent_expense_pro/domain/entities/enums.dart';
import 'package:vent_expense_pro/domain/entities/transaction.dart';
import 'package:vent_expense_pro/domain/repositories/account_repository.dart';
import 'package:vent_expense_pro/domain/repositories/category_repository.dart';
import 'package:vent_expense_pro/domain/repositories/report_repository.dart';
import 'package:vent_expense_pro/domain/repositories/transaction_repository.dart';
import 'package:vent_expense_pro/domain/usecases/calculate_billing_breakdown.dart';
import 'package:vent_expense_pro/domain/usecases/calculate_net_position.dart';
import 'package:vent_expense_pro/domain/usecases/generate_report.dart';
import 'package:vent_expense_pro/domain/usecases/log_transaction.dart';
import 'package:vent_expense_pro/domain/usecases/manage_account.dart';
import 'package:vent_expense_pro/domain/usecases/manage_transaction.dart';
import 'package:vent_expense_pro/domain/usecases/settle_credit_bill.dart';
import 'package:vent_expense_pro/domain/usecases/settle_debt.dart';
import 'package:vent_expense_pro/domain/value_objects/billing_breakdown.dart';
import 'package:vent_expense_pro/presentation/providers/account_provider.dart';
import 'package:vent_expense_pro/presentation/providers/reports_provider.dart';
import 'package:vent_expense_pro/presentation/providers/transaction_provider.dart';
import 'package:vent_expense_pro/presentation/screens/reports_screen.dart';

class MockReportRepository implements ReportRepository {
  @override
  Future<String> generatePdf({
    required List<Transaction> transactions,
    required List<Account> accounts,
    required List<Category> categories,
    String? accountId,
    DateTime? startDate,
    DateTime? endDate,
    List<Account>? debtAccounts,
    List<Account>? creditCards,
    Map<String, BillingBreakdown>? billingBreakdowns,
  }) async => '/mock/report.pdf';
}

class MockAccountRepository implements AccountRepository {
  final List<Account> accounts;
  MockAccountRepository(this.accounts);

  @override
  Future<List<Account>> getAll() async => accounts;

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

class MockTransactionRepository implements TransactionRepository {
  final List<Transaction> transactions;
  MockTransactionRepository(this.transactions);

  @override
  Future<List<Transaction>> getAll() async => transactions;

  @override
  Future<List<Transaction>> getByAccount(String accountId) async =>
      transactions.where((t) => t.accountId == accountId || t.toAccountId == accountId).toList();

  @override
  Future<List<Transaction>> getByDateRange(DateTime start, DateTime end) async =>
      transactions.where((t) => !t.dateTime.isBefore(start) && !t.dateTime.isAfter(end)).toList();

  @override
  Future<Transaction?> getById(String id) async =>
      transactions.firstWhere((t) => t.id == id);

  @override
  Future<Transaction> insert(Transaction transaction) async => transaction;

  @override
  Future<Transaction> update(Transaction transaction) async => transaction;

  @override
  Future<void> delete(String id) async {}
}

class MockCategoryRepository implements CategoryRepository {
  @override
  Future<List<Category>> getAll() async => [
        const Category(id: 'cat1', name: 'Food', icon: 'food'),
      ];

  @override
  Future<Category?> getById(String id) async =>
      const Category(id: 'cat1', name: 'Food', icon: 'food');

  @override
  Future<Category> insert(Category category) async => category;

  @override
  Future<Category> update(Category category) async => category;

  @override
  Future<void> delete(String id) async {}
}

void main() {
  final now = DateTime(2026, 9, 22);

  Widget createWidgetUnderTest({
    required List<Account> accounts,
    required List<Transaction> transactions,
  }) {
    final accountRepo = MockAccountRepository(accounts);
    final txnRepo = MockTransactionRepository(transactions);
    final catRepo = MockCategoryRepository();

    final accountProvider = AccountProvider(
      accountRepo,
      CalculateNetPosition(accountRepo),
      ManageAccount(accountRepo),
      SettleCreditBill(txnRepo, accountRepo),
      SettleDebt(txnRepo, accountRepo),
    )..loadAccounts();

    final transactionProvider = TransactionProvider(
      txnRepo,
      catRepo,
      ManageTransaction(
        txnRepo,
        accountRepo,
        LogTransaction(txnRepo, accountRepo),
      ),
    )..loadTransactions();

    final reportsProvider = ReportsProvider(
      generateReportUseCase: GenerateReport(
        reportRepository: MockReportRepository(),
        transactionRepository: txnRepo,
        accountRepository: accountRepo,
        categoryRepository: catRepo,
        calculateBillingBreakdown: const CalculateBillingBreakdown(),
      ),
      accountRepository: accountRepo,
      transactionRepository: txnRepo,
      calculateBillingBreakdown: const CalculateBillingBreakdown(),
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: accountProvider),
        ChangeNotifierProvider.value(value: transactionProvider),
        ChangeNotifierProvider.value(value: reportsProvider),
      ],
      child: const MaterialApp(
        home: Scaffold(body: ReportsScreen()),
      ),
    );
  }

  testWidgets('renders ReportsScreen with filters and export button', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest(
      accounts: [
        Account(
          id: 'acc1',
          name: 'Main Wallet',
          type: AccountType.cash,
          balance: 1000000,
          createdAt: now,
        ),
      ],
      transactions: [],
    ));
    await tester.pumpAndSettle();

    expect(find.text('Professional Reports'), findsOneWidget);
    expect(find.text('REPORT FILTERS'), findsOneWidget);
    expect(find.text('PERIOD'), findsOneWidget);
    expect(find.text('ACCOUNT'), findsOneWidget);
    expect(find.text('Generate PDF Statement'), findsOneWidget);
  });

  testWidgets('renders Debt Summary section when debt accounts exist', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest(
      accounts: [
        Account(
          id: 'debt1',
          name: 'Budi Santoso',
          type: AccountType.debt,
          balance: 500000,
          createdAt: now,
        ),
      ],
      transactions: [],
    ));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('reports_debt_summary_section')), findsOneWidget);
    expect(find.text('DEBT & LENDING SUMMARY'), findsOneWidget);
    expect(find.text('RECEIVABLE'), findsOneWidget);
    expect(find.text('Budi Santoso'), findsOneWidget);
  });

  testWidgets('renders Credit Card Billing section when credit card with billing cycle exists', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest(
      accounts: [
        Account(
          id: 'cc1',
          name: 'BCA Everyday Card',
          type: AccountType.credit,
          balance: -750000,
          statementCloseDay: 20,
          createdAt: now,
        ),
      ],
      transactions: [
        Transaction(
          id: 'tx1',
          amount: 750000,
          type: TransactionType.expense,
          categoryId: 'cat1',
          accountId: 'cc1',
          dateTime: now,
        ),
      ],
    ));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('reports_credit_billing_section')), findsOneWidget);
    expect(find.text('CREDIT CARD BILLING BREAKDOWN'), findsOneWidget);
    expect(find.text('BCA Everyday Card'), findsOneWidget);
    expect(find.text('Closes 20th'), findsOneWidget);
    expect(find.text('TOTAL ALL CREDIT CARDS'), findsOneWidget);
  });
}
