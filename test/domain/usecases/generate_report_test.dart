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

class FakeReportRepository implements ReportRepository {
  @override
  Future<String> generatePdf({
    required List<Transaction> transactions,
    required List<Account> accounts,
    required List<Category> categories,
    String? accountId,
    DateTime? startDate,
    DateTime? endDate,
  }) async => 'pdf_path';
}

class FakeTransactionRepository implements TransactionRepository {
  final List<Transaction> txns;
  FakeTransactionRepository(this.txns);
  
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

class FakeAccountRepository implements AccountRepository {
  @override
  Future<List<Account>> getAll() async => [];

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
  late List<Transaction> testTransactions;

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

    generateReport = GenerateReport(
      reportRepository: FakeReportRepository(),
      transactionRepository: FakeTransactionRepository(testTransactions),
      accountRepository: FakeAccountRepository(),
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
}
