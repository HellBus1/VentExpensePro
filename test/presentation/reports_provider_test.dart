import 'package:flutter_test/flutter_test.dart';
import 'package:vent_expense_pro/domain/entities/account.dart';
import 'package:vent_expense_pro/domain/entities/category.dart';
import 'package:vent_expense_pro/domain/entities/enums.dart';
import 'package:vent_expense_pro/domain/entities/transaction.dart';
import 'package:vent_expense_pro/domain/repositories/account_repository.dart';
import 'package:vent_expense_pro/domain/repositories/category_repository.dart';
import 'package:vent_expense_pro/domain/repositories/report_repository.dart';
import 'package:vent_expense_pro/domain/repositories/transaction_repository.dart';
import 'package:vent_expense_pro/domain/usecases/calculate_billing_breakdown.dart';
import 'package:vent_expense_pro/domain/usecases/generate_report.dart';
import 'package:vent_expense_pro/domain/value_objects/billing_breakdown.dart';
import 'package:vent_expense_pro/presentation/providers/reports_provider.dart';

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
  }) async => '/mock/path/report.pdf';
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
  Future<List<Category>> getAll() async => [];

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
  late ReportsProvider provider;
  late MockAccountRepository accountRepo;
  late MockTransactionRepository txnRepo;
  late GenerateReport generateReportUseCase;

  final now = DateTime(2026, 9, 22);

  setUp(() {
    final accounts = [
      Account(
        id: 'debt_budi',
        name: 'Budi Santoso',
        type: AccountType.debt,
        balance: 500000, // Receivable
        createdAt: now,
      ),
      Account(
        id: 'debt_ani',
        name: 'Ani Wijaya',
        type: AccountType.debt,
        balance: -200000, // Payable
        createdAt: now,
      ),
      Account(
        id: 'card_bca',
        name: 'BCA Credit Card',
        type: AccountType.credit,
        balance: -1500000,
        statementCloseDay: 20,
        createdAt: now,
      ),
      Account(
        id: 'acc_cash',
        name: 'Cash',
        type: AccountType.cash,
        balance: 2000000,
        createdAt: now,
      ),
    ];

    final transactions = [
      Transaction(
        id: 't1',
        amount: 300000,
        type: TransactionType.transfer,
        categoryId: 'cat_transfer',
        accountId: 'acc_cash',
        toAccountId: 'debt_budi',
        note: 'Lunch loan',
        dateTime: now.subtract(const Duration(days: 5)),
      ),
      Transaction(
        id: 't2',
        amount: 100000,
        type: TransactionType.transfer,
        categoryId: 'cat_transfer',
        accountId: 'debt_budi',
        toAccountId: 'acc_cash',
        note: 'Partial repayment',
        isSettlement: true,
        dateTime: now.subtract(const Duration(days: 2)),
      ),
      Transaction(
        id: 't3',
        amount: 500000,
        type: TransactionType.expense,
        categoryId: 'cat_shopping',
        accountId: 'card_bca',
        note: 'Groceries',
        dateTime: now.subtract(const Duration(days: 3)),
      ),
    ];

    accountRepo = MockAccountRepository(accounts);
    txnRepo = MockTransactionRepository(transactions);
    generateReportUseCase = GenerateReport(
      reportRepository: MockReportRepository(),
      transactionRepository: txnRepo,
      accountRepository: accountRepo,
      categoryRepository: MockCategoryRepository(),
      calculateBillingBreakdown: const CalculateBillingBreakdown(),
    );

    provider = ReportsProvider(
      generateReportUseCase: generateReportUseCase,
      accountRepository: accountRepo,
      transactionRepository: txnRepo,
      calculateBillingBreakdown: const CalculateBillingBreakdown(),
    );
  });

  group('ReportsProvider Enhanced Reporting Tests', () {
    test('getDebtSummary calculates receivables, payables, and net position correctly', () async {
      final summary = await provider.getDebtSummary();

      expect(summary.totalReceivable, 500000);
      expect(summary.totalPayable, 200000);
      expect(summary.netPosition, 300000);
      expect(summary.people.length, 2);
      expect(summary.people.first.account.name, 'Budi Santoso');
      expect(summary.people.first.balance, 500000);
      expect(summary.settlementHistory.length, 1);
      expect(summary.settlementHistory.first.isSettlement, isTrue);
      expect(summary.settlementHistory.first.amount, 100000);
    });

    test('getBillingReport calculates billing breakdowns for credit cards', () async {
      final billingReports = await provider.getBillingReport();

      expect(billingReports.length, 1);
      final report = billingReports.first;
      expect(report.account.name, 'BCA Credit Card');
      expect(report.breakdown.totalOutstanding, greaterThanOrEqualTo(0));
    });

    test('loadReportData populates observable properties', () async {
      await provider.loadReportData();

      expect(provider.isLoadingReportData, isFalse);
      expect(provider.debtSummary, isNotNull);
      expect(provider.debtSummary!.hasDebts, isTrue);
      expect(provider.billingReports.length, 1);
    });

    test('generate delegates to GenerateReport use case and updates status', () async {
      await provider.generate('pdf');

      expect(provider.status, ReportStatus.success);
      expect(provider.generatedFilePath, '/mock/path/report.pdf');
    });
  });
}
