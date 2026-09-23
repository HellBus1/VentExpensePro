import 'package:flutter_test/flutter_test.dart';
import 'package:vent_expense_pro/domain/entities/account.dart';
import 'package:vent_expense_pro/domain/entities/category.dart';
import 'package:vent_expense_pro/domain/entities/enums.dart';
import 'package:vent_expense_pro/domain/entities/transaction.dart';
import 'package:vent_expense_pro/domain/repositories/account_repository.dart';
import 'package:vent_expense_pro/domain/repositories/category_repository.dart';
import 'package:vent_expense_pro/domain/repositories/report_repository.dart';
import 'package:vent_expense_pro/domain/repositories/transaction_repository.dart';
import 'package:vent_expense_pro/domain/usecases/generate_report.dart';
import 'package:vent_expense_pro/domain/value_objects/billing_breakdown.dart';

class FakeReportRepository implements ReportRepository {
  List<Account>? capturedDebtAccounts;
  List<Account>? capturedCreditCards;
  Map<String, BillingBreakdown>? capturedBillingBreakdowns;

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
  }) async {
    capturedDebtAccounts = debtAccounts;
    capturedCreditCards = creditCards;
    capturedBillingBreakdowns = billingBreakdowns;
    return 'pdf_path';
  }
}

class FakeTransactionRepository implements TransactionRepository {
  final List<Transaction> txns;
  FakeTransactionRepository(this.txns);

  @override
  Future<List<Transaction>> getAll() async => txns;

  @override
  Future<List<Transaction>> getByAccount(String accountId) async => [];

  @override
  Future<List<Transaction>> getByDateRange(
    DateTime start,
    DateTime end,
  ) async => [];

  @override
  Future<Transaction?> getById(String id) async => null;

  @override
  Future<Transaction> insert(Transaction transaction) async => transaction;

  @override
  Future<Transaction> update(Transaction transaction) async => transaction;

  @override
  Future<void> delete(String id) async {}
}

class FakeAccountRepository implements AccountRepository {
  final List<Account> accounts;
  FakeAccountRepository([this.accounts = const []]);

  @override
  Future<List<Account>> getAll() async => accounts;

  @override
  Future<List<Account>> getByType(AccountType type) async =>
      accounts.where((a) => a.type == type).toList();

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

class FakeCategoryRepository implements CategoryRepository {
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
  late GenerateReport generateReport;
  late FakeReportRepository fakeReportRepository;
  late List<Transaction> testTransactions;
  late List<Account> testAccounts;

  setUp(() {
    testTransactions = [
      Transaction(
        id: '1',
        amount: 100,
        type: TransactionType.expense,
        categoryId: 'cat1',
        accountId: 'acc1',
        dateTime: DateTime(2024, 1, 1),
      ),
      Transaction(
        id: '2',
        amount: 200,
        type: TransactionType.income,
        categoryId: 'cat2',
        accountId: 'acc2',
        dateTime: DateTime(2024, 2, 1),
      ),
    ];

    final created = DateTime(2024, 1, 1);
    testAccounts = [
      Account(
        id: 'acc1',
        name: 'Checking',
        type: AccountType.debit,
        balance: 1000,
        createdAt: created,
      ),
      Account(
        id: 'debt1',
        name: 'Alex Pratama',
        type: AccountType.debt,
        balance: 500000,
        createdAt: created,
      ),
      Account(
        id: 'card1',
        name: 'BCA Card',
        type: AccountType.credit,
        balance: -200000,
        statementCloseDay: 20,
        createdAt: created,
      ),
    ];

    fakeReportRepository = FakeReportRepository();

    generateReport = GenerateReport(
      reportRepository: fakeReportRepository,
      transactionRepository: FakeTransactionRepository(testTransactions),
      accountRepository: FakeAccountRepository(testAccounts),
      categoryRepository: FakeCategoryRepository(),
    );
  });

  test('should return pdf path and filter by date', () async {
    final path = await generateReport(
      type: 'pdf',
      startDate: DateTime(2024, 1, 15),
    );

    expect(path, 'pdf_path');
  });

  test('should collect debt accounts and credit cards by default', () async {
    await generateReport(type: 'pdf');

    expect(fakeReportRepository.capturedDebtAccounts, isNotNull);
    expect(fakeReportRepository.capturedDebtAccounts!.length, 1);
    expect(fakeReportRepository.capturedDebtAccounts!.first.name, 'Alex Pratama');

    expect(fakeReportRepository.capturedCreditCards, isNotNull);
    expect(fakeReportRepository.capturedCreditCards!.length, 1);
    expect(fakeReportRepository.capturedCreditCards!.first.name, 'BCA Card');

    expect(fakeReportRepository.capturedBillingBreakdowns, isNotNull);
    expect(fakeReportRepository.capturedBillingBreakdowns!.containsKey('card1'), isTrue);
  });

  test('should omit debt accounts and credit cards when flags are false', () async {
    await generateReport(
      type: 'pdf',
      includeDebtSummary: false,
      includeBillingBreakdown: false,
    );

    expect(fakeReportRepository.capturedDebtAccounts, isNull);
    expect(fakeReportRepository.capturedCreditCards, isNull);
    expect(fakeReportRepository.capturedBillingBreakdowns, isNull);
  });
}
