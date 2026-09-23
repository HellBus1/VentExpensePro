import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/entities/enums.dart';
import '../../domain/entities/transaction.dart';
import '../painters/paper_background.dart';
import '../providers/account_provider.dart';
import '../providers/reports_provider.dart';
import '../providers/transaction_provider.dart';
import 'package:fl_chart/fl_chart.dart';

/// The reports screen — PDF / Excel generation and viewing.
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  Object? _lastAccountsToken;
  Object? _lastTransactionsToken;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ReportsProvider>().loadReportData();
      }
    });
  }

  void _checkAndReloadData(List<dynamic> accounts, List<dynamic> transactions) {
    final accountsToken = Object.hash(
      accounts.length,
      accounts.isEmpty ? 0 : (accounts.first.balance ?? 0),
      accounts.isEmpty ? 0 : (accounts.last.balance ?? 0),
    );
    final transactionsToken = Object.hash(
      transactions.length,
      transactions.isEmpty ? 0 : transactions.first.id,
    );

    if (_lastAccountsToken != accountsToken || _lastTransactionsToken != transactionsToken) {
      _lastAccountsToken = accountsToken;
      _lastTransactionsToken = transactionsToken;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<ReportsProvider>().loadReportData();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PaperBackground(
      child: Consumer2<ReportsProvider, AccountProvider>(
        builder: (context, reportsProvider, accountProvider, child) {
          final transactionProvider = context.watch<TransactionProvider>();
          _checkAndReloadData(
            accountProvider.accounts,
            transactionProvider.transactions,
          );

          final DateFormat formatter = DateFormat('dd MMM yyyy');
          final String dateRangeLabel =
              reportsProvider.startDate != null &&
                  reportsProvider.endDate != null
              ? '${formatter.format(reportsProvider.startDate!)} - ${formatter.format(reportsProvider.endDate!)}'
              : 'All Time';

          return RefreshIndicator(
            onRefresh: () => context.read<ReportsProvider>().loadReportData(),
            child: SingleChildScrollView(
              key: const ValueKey('reports_scroll_view'),
              physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Professional Reports',
                  style: AppTypography.displayMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Generate bank-ready statements and spreadsheets for your records.',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.inkLight,
                  ),
                ),
                const SizedBox(height: 32),

                // — Filter Section —
                _buildSectionTitle('REPORT FILTERS'),
                const SizedBox(height: 12),

                // Date Range Selector
                _buildFilterTile(
                  context,
                  label: 'PERIOD',
                  value: dateRangeLabel,
                  onTap: () async {
                    final range = await showDateRangePicker(
                      context: context,
                      initialDateRange:
                          reportsProvider.startDate != null &&
                              reportsProvider.endDate != null
                          ? DateTimeRange(
                              start: reportsProvider.startDate!,
                              end: reportsProvider.endDate!,
                            )
                          : null,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(DateTime.now().year + 5),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.light(
                              primary: AppColors.inkBlue,
                              onPrimary: AppColors.paper,
                              onSurface: AppColors.inkDark,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (range != null) {
                      reportsProvider.setDateRange(range.start, range.end);
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Account Selector
                _buildFilterTile(
                  context,
                  label: 'ACCOUNT',
                  value: reportsProvider.selectedAccountId == null
                      ? 'All Accounts'
                      : accountProvider.accounts
                            .firstWhere(
                              (a) => a.id == reportsProvider.selectedAccountId,
                            )
                            .name,
                  onTap: () {
                    _showAccountSelector(
                      context,
                      accountProvider,
                      reportsProvider,
                    );
                  },
                ),

                const SizedBox(height: 40),

                // — Statistics & Action Section —
                _buildStatisticsCard(
                  context,
                  reportsProvider,
                  transactionProvider,
                ),
                const SizedBox(height: 32),

                // — Debt & Lending Summary Section —
                _buildDebtSummarySection(context, reportsProvider),

                // — Credit Card Billing Breakdown Section —
                _buildCreditCardBillingSection(context, reportsProvider),

                if (reportsProvider.status == ReportStatus.loading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: CircularProgressIndicator(
                        color: AppColors.inkBlue,
                      ),
                    ),
                  )
                else
                  _buildExportButton(
                    context,
                    label: 'Generate PDF Statement',
                    icon: Icons.picture_as_pdf_outlined,
                    onTap: () => _generate(context, reportsProvider, 'pdf'),
                  ),

                if (reportsProvider.status == ReportStatus.success) ...[
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.paperElevated,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.inkGreen.withValues(alpha: 0.2),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: AppColors.inkGreen,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Ready to Save!',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: AppColors.inkDark,
                                    ),
                                  ),
                                  Text(
                                    'Report generated successfully.',
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.inkLight,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final box =
                                  context.findRenderObject() as RenderBox?;
                              // ignore: deprecated_member_use
                              await Share.shareXFiles(
                                [XFile(reportsProvider.generatedFilePath!)],
                                text: 'VentExpense Report',
                                sharePositionOrigin:
                                    box!.localToGlobal(Offset.zero) & box.size,
                              );
                            },
                            icon: const Icon(Icons.share, size: 20),
                            label: const Text('Share or Save to Files'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.inkBlue,
                              foregroundColor: AppColors.paper,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                if (reportsProvider.status == ReportStatus.error) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Error: ${reportsProvider.errorMessage}',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.stampRed,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
      ),
    );
  }

  Widget _buildStatisticsCard(
    BuildContext context,
    ReportsProvider rProvider,
    TransactionProvider tProvider,
  ) {
    if (rProvider.status == ReportStatus.loading || tProvider.isLoading) {
      return const SizedBox.shrink();
    }

    final transactions = tProvider.transactions.where((t) {
      final matchAccount =
          rProvider.selectedAccountId == null ||
          t.accountId == rProvider.selectedAccountId;
      final matchDate =
          rProvider.startDate == null ||
          rProvider.endDate == null ||
          (!t.dateTime.isBefore(rProvider.startDate!) &&
              !t.dateTime.isAfter(
                rProvider.endDate!.add(const Duration(days: 1)),
              ));
      return matchAccount && matchDate;
    }).toList();

    if (transactions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        child: Text(
          'No transactions found for this period.',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.inkLight),
        ),
      );
    }

    double totalIncome = 0;
    double totalExpense = 0;
    final Map<String, double> expenseByCategory = {};

    for (var t in transactions) {
      if (t.type == TransactionType.income) {
        totalIncome += t.amount;
      } else if (t.type == TransactionType.expense) {
        totalExpense += t.amount;
        expenseByCategory[t.categoryId] =
            (expenseByCategory[t.categoryId] ?? 0) +
            (t.amount as num).toDouble();
      }
    }
    final netBalance = totalIncome - totalExpense;

    final chartColors = [
      AppColors.inkBlue,
      AppColors.inkGreen,
      AppColors.stampRed,
      Colors.amber[700]!,
      Colors.teal,
      Colors.purple,
    ];
    int colorIndex = 0;
    final List<PieChartSectionData> pieSections = [];
    final List<Widget> legendWidgets = [];
    final currencyFormatter = NumberFormat.currency(
      symbol: '',
      decimalDigits: 0,
    );

    expenseByCategory.forEach((catId, amount) {
      final category = tProvider.getCategoryById(catId);
      final String categoryName =
          (category != null && category.name != 'Unknown')
          ? category.name
          : 'Unknown ($catId)';

      final color = chartColors[colorIndex % chartColors.length];

      final percent = (amount / totalExpense * 100).toStringAsFixed(1);

      pieSections.add(
        PieChartSectionData(
          color: color,
          value: amount,
          title: '$percent%',
          titleStyle: const TextStyle(
            fontSize: 8,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          radius: 16, // slightly thicker doughnut to fit title
        ),
      );
      legendWidgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$categoryName (${currencyFormatter.format(amount)})',
                  style: AppTypography.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
      colorIndex++;
    });

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.paperElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('STATISTICS SUMMARY'),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Income', style: AppTypography.bodyMedium),
              Text(
                '+${currencyFormatter.format(totalIncome)}',
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.inkGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Expense', style: AppTypography.bodyMedium),
              Text(
                '-${currencyFormatter.format(totalExpense)}',
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.stampRed,
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Net Balance', style: AppTypography.titleMedium),
              Text(
                '${netBalance >= 0 ? '+' : ''}${currencyFormatter.format(netBalance)}',
                style: AppTypography.titleLarge.copyWith(
                  color: netBalance >= 0
                      ? AppColors.inkGreen
                      : AppColors.stampRed,
                ),
              ),
            ],
          ),
          if (expenseByCategory.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildSectionTitle('EXPENSE BREAKDOWN'),
            const SizedBox(height: 16),
            Row(
              children: [
                SizedBox(
                  height: 100,
                  width: 100,
                  child: PieChart(
                    PieChartData(
                      sections: pieSections,
                      sectionsSpace: 2,
                      centerSpaceRadius: 36,
                      borderData: FlBorderData(show: false),
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: legendWidgets,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTypography.label.copyWith(
        color: AppColors.inkLight,
        letterSpacing: 2,
      ),
    );
  }

  Widget _buildFilterTile(
    BuildContext context, {
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.paperElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider, width: 0.5),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTypography.label.copyWith(fontSize: 9)),
                  const SizedBox(height: 4),
                  Text(value, style: AppTypography.titleMedium),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.inkLight),
          ],
        ),
      ),
    );
  }

  Widget _buildExportButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 20),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.inkBlue,
          side: const BorderSide(color: AppColors.inkBlue),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: AppTypography.titleMedium,
        ),
      ),
    );
  }

  void _showAccountSelector(
    BuildContext context,
    AccountProvider accProvider,
    ReportsProvider reportsProvider,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Select Account', style: AppTypography.titleLarge),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('All Accounts'),
              trailing: reportsProvider.selectedAccountId == null
                  ? const Icon(Icons.check, color: AppColors.inkBlue)
                  : null,
              onTap: () {
                reportsProvider.setSelectedAccount(null);
                Navigator.pop(context);
              },
            ),
            const Divider(height: 1),
            ...accProvider.accounts.map(
              (account) => ListTile(
                title: Text(account.name),
                trailing: reportsProvider.selectedAccountId == account.id
                    ? const Icon(Icons.check, color: AppColors.inkBlue)
                    : null,
                onTap: () {
                  reportsProvider.setSelectedAccount(account.id);
                  Navigator.pop(context);
                },
              ),
            ),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  void _generate(
    BuildContext context,
    ReportsProvider provider,
    String type,
  ) async {
    await provider.generate(type);
    if (!context.mounted) return;

    if (provider.status == ReportStatus.success) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Report generated successfully!'),
            backgroundColor: AppColors.inkGreen,
            action: SnackBarAction(
              label: 'OK',
              textColor: AppColors.paper,
              onPressed: () {},
            ),
          ),
        );
      }
    } else if (provider.status == ReportStatus.error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to generate report: ${provider.errorMessage}',
            ),
            backgroundColor: AppColors.stampRed,
          ),
        );
      }
    }
  }

  Widget _buildDebtSummarySection(
    BuildContext context,
    ReportsProvider rProvider,
  ) {
    final debtSummary = rProvider.debtSummary;
    if (debtSummary == null || !debtSummary.hasDebts) {
      return const SizedBox.shrink();
    }

    final currencyFormatter = NumberFormat.currency(
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    final receivables = debtSummary.people.where((p) => p.balance > 0).toList();
    final payables = debtSummary.people.where((p) => p.balance < 0).toList();

    return Container(
      key: const ValueKey('reports_debt_summary_section'),
      margin: const EdgeInsets.only(bottom: 32),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.paperElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.handshake_outlined,
                color: AppColors.inkBlue,
                size: 20,
              ),
              const SizedBox(width: 8),
              _buildSectionTitle('DEBT & LENDING SUMMARY'),
            ],
          ),
          const SizedBox(height: 16),

          // Overview Strip
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  label: 'RECEIVABLE',
                  sublabel: 'They owe you',
                  amount:
                      '+${currencyFormatter.format(debtSummary.totalReceivable)}',
                  color: AppColors.inkGreen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricTile(
                  label: 'PAYABLE',
                  sublabel: 'You owe',
                  amount:
                      '-${currencyFormatter.format(debtSummary.totalPayable)}',
                  color: AppColors.stampRed,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.paper,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.divider, width: 0.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Net Debt Position', style: AppTypography.label),
                Text(
                  '${debtSummary.netPosition >= 0 ? '+' : ''}${currencyFormatter.format(debtSummary.netPosition)}',
                  style: AppTypography.titleMedium.copyWith(
                    color: debtSummary.netPosition >= 0
                        ? AppColors.inkGreen
                        : AppColors.stampRed,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Receivables list
          if (receivables.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              'RECEIVABLE (PIUTANG)',
              style: AppTypography.label.copyWith(
                fontSize: 10,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            ...receivables.map(
              (p) => _buildDebtPersonTile(
                p,
                currencyFormatter,
                isReceivable: true,
              ),
            ),
          ],

          // Payables list
          if (payables.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              'PAYABLE (HUTANG)',
              style: AppTypography.label.copyWith(
                fontSize: 10,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            ...payables.map(
              (p) => _buildDebtPersonTile(
                p,
                currencyFormatter,
                isReceivable: false,
              ),
            ),
          ],

          // Settlements history
          if (debtSummary.settlementHistory.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Divider(height: 1),
            const SizedBox(height: 16),
            Text(
              'RECENT SETTLEMENTS',
              style: AppTypography.label.copyWith(
                fontSize: 10,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            ...debtSummary.settlementHistory
                .take(5)
                .map((s) => _buildSettlementTile(s, currencyFormatter)),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String sublabel,
    required String amount,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.label.copyWith(fontSize: 9)),
          const SizedBox(height: 2),
          Text(
            sublabel,
            style: AppTypography.bodySmall.copyWith(
              fontSize: 11,
              color: AppColors.inkLight,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            amount,
            style: AppTypography.titleMedium.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDebtPersonTile(
    DebtPersonSummary person,
    NumberFormat formatter, {
    required bool isReceivable,
  }) {
    final amountColor = isReceivable ? AppColors.inkGreen : AppColors.stampRed;
    final prefix = isReceivable ? '+' : '-';
    final count = person.transactionCount;
    final dateStr = person.latestTransaction != null
        ? DateFormat('dd MMM').format(person.latestTransaction!.dateTime)
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.divider, width: 0.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  person.account.name,
                  style: AppTypography.titleMedium.copyWith(fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  '$count item${count != 1 ? 's' : ''}${dateStr != null ? ' • Latest: $dateStr' : ''}',
                  style: AppTypography.bodySmall.copyWith(
                    fontSize: 11,
                    color: AppColors.inkLight,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '$prefix${formatter.format(person.balance.abs())}',
            style: AppTypography.titleMedium.copyWith(
              color: amountColor,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettlementTile(Transaction settlement, NumberFormat formatter) {
    final dateStr = DateFormat('dd MMM yyyy').format(settlement.dateTime);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_outline,
            size: 16,
            color: AppColors.inkGreen,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$dateStr • ${settlement.note ?? 'Settlement'}',
              style: AppTypography.bodySmall.copyWith(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            formatter.format(settlement.amount),
            style: AppTypography.bodySmall.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: AppColors.inkDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreditCardBillingSection(
    BuildContext context,
    ReportsProvider rProvider,
  ) {
    final billingReports = rProvider.billingReports;
    if (billingReports.isEmpty) {
      return const SizedBox.shrink();
    }

    final currencyFormatter = NumberFormat.currency(
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final dateFormatter = DateFormat('dd MMM');

    int totalAllCards = 0;
    for (final report in billingReports) {
      totalAllCards += report.breakdown.totalOutstanding;
    }

    return Container(
      key: const ValueKey('reports_credit_billing_section'),
      margin: const EdgeInsets.only(bottom: 32),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.paperElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.credit_card, color: AppColors.inkBlue, size: 20),
              const SizedBox(width: 8),
              _buildSectionTitle('CREDIT CARD BILLING BREAKDOWN'),
            ],
          ),
          const SizedBox(height: 16),

          ...billingReports.map((report) {
            final card = report.account;
            final breakdown = report.breakdown;
            final billedRange = breakdown.billedPeriod != null
                ? '${dateFormatter.format(breakdown.billedPeriod!.start)} – ${dateFormatter.format(breakdown.billedPeriod!.end)}'
                : 'Closed Period';
            final unbilledRange = breakdown.unbilledPeriod != null
                ? '${dateFormatter.format(breakdown.unbilledPeriod!.start)} – ${dateFormatter.format(breakdown.unbilledPeriod!.end)}'
                : 'Current Period';

            final total = breakdown.totalOutstanding;
            final billedRatio = total > 0
                ? (breakdown.billedAmount / total).clamp(0.0, 1.0)
                : 0.0;

            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.paper,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider, width: 0.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(card.name, style: AppTypography.titleMedium),
                      if (card.statementCloseDay != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.inkBlue.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Closes ${card.statementCloseDay}${_getDaySuffix(card.statementCloseDay!)}',
                            style: AppTypography.label.copyWith(
                              fontSize: 9,
                              color: AppColors.inkBlue,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Progress bar comparison
                  if (total > 0)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: SizedBox(
                        height: 6,
                        child: Row(
                          children: [
                            if (breakdown.billedAmount > 0)
                              Expanded(
                                flex: (billedRatio * 100).round().clamp(1, 100),
                                child: Container(color: AppColors.stampRed),
                              ),
                            if (breakdown.unbilledAmount > 0)
                              Expanded(
                                flex: ((1.0 - billedRatio) * 100)
                                    .round()
                                    .clamp(1, 100),
                                child: Container(
                                  color: AppColors.inkBlue.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    )
                  else
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Container(height: 6, color: AppColors.divider),
                    ),
                  const SizedBox(height: 12),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Billed ($billedRange)',
                            style: AppTypography.label.copyWith(fontSize: 9),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            currencyFormatter.format(breakdown.billedAmount),
                            style: AppTypography.bodySmall.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.stampRed,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Unbilled ($unbilledRange)',
                            style: AppTypography.label.copyWith(fontSize: 9),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            currencyFormatter.format(breakdown.unbilledAmount),
                            style: AppTypography.bodySmall.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Card Balance',
                        style: AppTypography.label,
                      ),
                      Text(
                        currencyFormatter.format(breakdown.totalOutstanding),
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.stampRed,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),

          // Aggregate All Cards Footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.inkBlue,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'TOTAL ALL CREDIT CARDS',
                  style: AppTypography.label.copyWith(
                    color: AppColors.paper,
                    letterSpacing: 1.1,
                  ),
                ),
                Text(
                  currencyFormatter.format(totalAllCards),
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.paper,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getDaySuffix(int day) {
    if (day >= 11 && day <= 13) return 'th';
    switch (day % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }
}
