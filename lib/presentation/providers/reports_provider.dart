import 'package:flutter/material.dart';
import '../../domain/entities/account.dart';
import '../../domain/entities/enums.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/repositories/account_repository.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../../domain/usecases/calculate_billing_breakdown.dart';
import '../../domain/usecases/generate_report.dart';
import '../../domain/value_objects/billing_breakdown.dart';

enum ReportStatus { idle, loading, success, error }

/// Debt summary report containing receivables, payables, and settlement history.
class DebtSummaryReport {
  final int totalReceivable;
  final int totalPayable;
  final int netPosition;
  final List<DebtPersonSummary> people;
  final List<Transaction> settlementHistory;

  const DebtSummaryReport({
    required this.totalReceivable,
    required this.totalPayable,
    required this.netPosition,
    required this.people,
    required this.settlementHistory,
  });

  bool get isEmpty => people.isEmpty && settlementHistory.isEmpty;
  bool get hasDebts => people.isNotEmpty;
}

/// Individual debt account summary for reporting.
class DebtPersonSummary {
  final Account account;
  final int balance;
  final int transactionCount;
  final Transaction? latestTransaction;

  const DebtPersonSummary({
    required this.account,
    required this.balance,
    required this.transactionCount,
    this.latestTransaction,
  });
}

/// Credit card billing report item.
class CreditCardBillingReport {
  final Account account;
  final BillingBreakdown breakdown;

  const CreditCardBillingReport({
    required this.account,
    required this.breakdown,
  });
}

class ReportsProvider extends ChangeNotifier {
  final GenerateReport generateReportUseCase;
  final AccountRepository accountRepository;
  final TransactionRepository transactionRepository;
  final CalculateBillingBreakdown calculateBillingBreakdown;

  ReportsProvider({
    required this.generateReportUseCase,
    required this.accountRepository,
    required this.transactionRepository,
    this.calculateBillingBreakdown = const CalculateBillingBreakdown(),
  }) {
    loadReportData();
  }

  ReportStatus _status = ReportStatus.idle;
  ReportStatus get status => _status;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _generatedFilePath;
  String? get generatedFilePath => _generatedFilePath;

  DateTime? _startDate;
  DateTime? get startDate => _startDate;

  DateTime? _endDate;
  DateTime? get endDate => _endDate;

  String? _selectedAccountId;
  String? get selectedAccountId => _selectedAccountId;

  DebtSummaryReport? _debtSummary;
  DebtSummaryReport? get debtSummary => _debtSummary;

  List<CreditCardBillingReport> _billingReports = [];
  List<CreditCardBillingReport> get billingReports => _billingReports;

  bool _isLoadingReportData = false;
  bool get isLoadingReportData => _isLoadingReportData;

  void setDateRange(DateTime? start, DateTime? end) {
    _startDate = start;
    _endDate = end;
    notifyListeners();
  }

  void setSelectedAccount(String? accountId) {
    _selectedAccountId = accountId;
    notifyListeners();
  }

  /// Refreshes all enhanced reporting data (debt summary & billing breakdowns).
  Future<void> loadReportData() async {
    _isLoadingReportData = true;
    notifyListeners();

    try {
      _debtSummary = await getDebtSummary();
      _billingReports = await getBillingReport();
    } catch (_) {
      // Retain existing state on error
    } finally {
      _isLoadingReportData = false;
      notifyListeners();
    }
  }

  /// Computes the comprehensive debt & settlement summary.
  Future<DebtSummaryReport> getDebtSummary() async {
    final debtAccounts = await accountRepository.getByType(AccountType.debt);
    final allTransactions = await transactionRepository.getAll();

    final people = debtAccounts.map((account) {
      final txns = allTransactions.where(
        (t) => t.accountId == account.id || t.toAccountId == account.id,
      ).toList();

      final nonSettlements = txns.where((t) => !t.isSettlement).toList();

      return DebtPersonSummary(
        account: account,
        balance: account.balance,
        transactionCount: nonSettlements.length,
        latestTransaction: txns.isNotEmpty ? txns.first : null,
      );
    }).toList()
      ..sort((a, b) => b.balance.abs().compareTo(a.balance.abs()));

    final debtIds = debtAccounts.map((a) => a.id).toSet();
    final settlements = allTransactions
        .where(
          (t) =>
              t.isSettlement &&
              (debtIds.contains(t.accountId) ||
                  debtIds.contains(t.toAccountId)),
        )
        .toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));

    final totalReceivable = debtAccounts
        .where((a) => a.balance > 0)
        .fold<int>(0, (sum, a) => sum + a.balance);

    final totalPayable = debtAccounts
        .where((a) => a.balance < 0)
        .fold<int>(0, (sum, a) => sum + a.balance.abs());

    final netPosition = totalReceivable - totalPayable;

    return DebtSummaryReport(
      totalReceivable: totalReceivable,
      totalPayable: totalPayable,
      netPosition: netPosition,
      people: people,
      settlementHistory: settlements,
    );
  }

  /// Computes the billing breakdown for all configured credit cards.
  Future<List<CreditCardBillingReport>> getBillingReport() async {
    final creditCards = (await accountRepository.getByType(AccountType.credit))
        .where((a) => a.hasBillingCycle)
        .toList();
    final allTransactions = await transactionRepository.getAll();

    return creditCards.map((card) {
      final breakdown = calculateBillingBreakdown(card, allTransactions);
      return CreditCardBillingReport(
        account: card,
        breakdown: breakdown,
      );
    }).toList();
  }

  Future<void> generate(
    String type, {
    bool includeDebtSummary = true,
    bool includeBillingBreakdown = true,
  }) async {
    _status = ReportStatus.loading;
    _errorMessage = null;
    _generatedFilePath = null;
    notifyListeners();

    try {
      final path = await generateReportUseCase(
        type: type,
        accountId: _selectedAccountId,
        startDate: _startDate,
        endDate: _endDate,
        includeDebtSummary: includeDebtSummary,
        includeBillingBreakdown: includeBillingBreakdown,
      );
      _generatedFilePath = path;
      _status = ReportStatus.success;
    } catch (e) {
      _errorMessage = e.toString();
      _status = ReportStatus.error;
    } finally {
      notifyListeners();
    }
  }

  void reset() {
    _status = ReportStatus.idle;
    _errorMessage = null;
    _generatedFilePath = null;
    notifyListeners();
  }
}
