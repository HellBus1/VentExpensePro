import '../entities/enums.dart';
import '../repositories/report_repository.dart';
import '../repositories/transaction_repository.dart';
import '../repositories/account_repository.dart';
import '../repositories/category_repository.dart';
import '../usecases/calculate_billing_breakdown.dart';
import '../value_objects/billing_breakdown.dart';

/// Orchestrates the generation of bank-ready reports.
class GenerateReport {
  final ReportRepository reportRepository;
  final TransactionRepository transactionRepository;
  final AccountRepository accountRepository;
  final CategoryRepository categoryRepository;
  final CalculateBillingBreakdown calculateBillingBreakdown;

  GenerateReport({
    required this.reportRepository,
    required this.transactionRepository,
    required this.accountRepository,
    required this.categoryRepository,
    this.calculateBillingBreakdown = const CalculateBillingBreakdown(),
  });

  /// Generates a report of the specified [type] ('pdf').
  Future<String> call({
    required String type,
    String? accountId,
    DateTime? startDate,
    DateTime? endDate,
    bool includeDebtSummary = true,
    bool includeBillingBreakdown = true,
  }) async {
    // 1. Fetch all required data
    final transactions = await transactionRepository.getAll();
    final accounts = await accountRepository.getAll();
    final categories = await categoryRepository.getAll();

    // 2. Filter transactions based on criteria
    final filteredTransactions = transactions.where((t) {
      if (accountId != null && t.accountId != accountId && t.toAccountId != accountId) {
        return false;
      }
      if (startDate != null && t.dateTime.isBefore(startDate)) {
        return false;
      }
      if (endDate != null && t.dateTime.isAfter(endDate)) {
        return false;
      }
      return true;
    }).toList();

    // 3. Gather debt accounts & credit card billing breakdowns
    final debtAccounts = accounts
        .where((a) => a.type == AccountType.debt)
        .toList();
    final creditCards = accounts
        .where((a) => a.type == AccountType.credit && a.hasBillingCycle)
        .toList();

    final Map<String, BillingBreakdown> breakdowns = {};
    if (includeBillingBreakdown) {
      for (final card in creditCards) {
        breakdowns[card.id] = calculateBillingBreakdown(card, transactions);
      }
    }

    // 4. Delegate to repository
    return reportRepository.generatePdf(
      transactions: filteredTransactions,
      accounts: accounts,
      categories: categories,
      accountId: accountId,
      startDate: startDate,
      endDate: endDate,
      debtAccounts: includeDebtSummary ? debtAccounts : null,
      creditCards: includeBillingBreakdown ? creditCards : null,
      billingBreakdowns: includeBillingBreakdown ? breakdowns : null,
    );
  }
}
