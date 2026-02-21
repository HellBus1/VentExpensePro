import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/entities/enums.dart';
import '../../domain/entities/transaction.dart';
import '../painters/paper_background.dart';
import '../providers/account_provider.dart';
import '../providers/transaction_provider.dart';
import '../widgets/net_position_card.dart';
import '../widgets/quick_add_transaction_sheet.dart';
import '../widgets/receipt_card.dart';
import '../widgets/receipt_date_header.dart';

/// The main ledger screen — a continuous, receipt-style transaction feed.
class LedgerScreen extends StatefulWidget {
  const LedgerScreen({super.key});

  @override
  State<LedgerScreen> createState() => _LedgerScreenState();
}

class _LedgerScreenState extends State<LedgerScreen> {
  /// Which preset filter chip is active. Null = "All" or custom range.
  String _activePreset = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionProvider>().loadAll();
      context.read<AccountProvider>().loadAccounts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return PaperBackground(
      child: Consumer2<TransactionProvider, AccountProvider>(
        builder: (context, txnProvider, accProvider, _) {
          final grouped = txnProvider.filteredGroupedByDate;
          final sortedDates = grouped.keys.toList()
            ..sort((a, b) => b.compareTo(a)); // newest first

          return CustomScrollView(
            slivers: [
              // — Net Position Card —
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                  child: accProvider.breakdown != null
                      ? NetPositionCard(breakdown: accProvider.breakdown!)
                      : const SizedBox.shrink(),
                ),
              ),

              // — Filter Bar —
              SliverToBoxAdapter(
                child: _buildFilterBar(context, txnProvider),
              ),

              // — Loading indicator —
              if (txnProvider.isLoading)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),

              // — Error state —
              if (txnProvider.error != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      txnProvider.error!,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),

              // — Empty state —
              if (!txnProvider.isLoading && grouped.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 24),
                    child: Column(
                      children: [
                        // — Perforated divider —
                        Row(
                          children: List.generate(
                            30,
                            (i) => Expanded(
                              child: Container(
                                height: 1,
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 2),
                                color: i.isEven
                                    ? AppColors.divider
                                    : Colors.transparent,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        const Icon(
                          Icons.receipt_long_outlined,
                          size: 48,
                          color: AppColors.disabled,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          txnProvider.dateFilter != null
                              ? 'No transactions in this range'
                              : 'No transactions yet',
                          style: AppTypography.bodyLarge.copyWith(
                            color: AppColors.inkLight,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          txnProvider.dateFilter != null
                              ? 'Try adjusting the filter'
                              : 'Tap + to log your first entry',
                          style: AppTypography.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),

              // — Receipt feed —
              if (!txnProvider.isLoading && grouped.isNotEmpty)
                ...sortedDates.expand((date) {
                  final txns = grouped[date]!
                    ..sort(
                        (a, b) => b.dateTime.compareTo(a.dateTime));
                  return [
                    SliverToBoxAdapter(
                      child: ReceiptDateHeader(date: date),
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final txn = txns[index];
                          final category =
                              txnProvider.getCategoryById(txn.categoryId);
                          return ReceiptCard(
                            transaction: txn,
                            category: category,
                            onTap: () => _editTransaction(txn),
                            onDelete: () => _deleteTransaction(txn),
                          );
                        },
                        childCount: txns.length,
                      ),
                    ),
                  ];
                }),

              // — Bottom padding —
              const SliverToBoxAdapter(
                child: SizedBox(height: 80),
              ),
            ],
          );
        },
      ),
    );
  }

  // ——— Filter Bar ———

  Widget _buildFilterBar(BuildContext context, TransactionProvider provider) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final presets = <String, DateTimeRange?>{
      'All': null,
      'Today': DateTimeRange(start: today, end: today),
      'This Week': DateTimeRange(
        start: today.subtract(Duration(days: today.weekday - 1)),
        end: today,
      ),
      'This Month': DateTimeRange(
        start: DateTime(now.year, now.month, 1),
        end: today,
      ),
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // — Preset chips —
            ...presets.entries.map((entry) {
              final label = entry.key;
              final range = entry.value;
              final isActive = _activePreset == label.toLowerCase();
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () {
                    setState(() => _activePreset = label.toLowerCase());
                    if (range == null) {
                      provider.clearDateFilter();
                    } else {
                      provider.setDateFilter(range);
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.inkBlue.withValues(alpha: 0.12)
                          : AppColors.paperElevated,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isActive
                            ? AppColors.inkBlue
                            : AppColors.divider,
                        width: isActive ? 1.5 : 0.5,
                      ),
                    ),
                    child: Text(
                      label,
                      style: AppTypography.label.copyWith(
                        color: isActive
                            ? AppColors.inkBlue
                            : AppColors.inkLight,
                        fontWeight:
                            isActive ? FontWeight.w600 : FontWeight.w400,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              );
            }),

            // — Custom Range chip —
            GestureDetector(
              onTap: () => _pickCustomRange(context, provider),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: _activePreset == 'custom'
                      ? AppColors.inkBlue.withValues(alpha: 0.12)
                      : AppColors.paperElevated,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _activePreset == 'custom'
                        ? AppColors.inkBlue
                        : AppColors.divider,
                    width: _activePreset == 'custom' ? 1.5 : 0.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.date_range_outlined,
                      size: 14,
                      color: _activePreset == 'custom'
                          ? AppColors.inkBlue
                          : AppColors.inkLight,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _activePreset == 'custom'
                          ? _formatRange(provider.dateFilter!)
                          : 'Custom',
                      style: AppTypography.label.copyWith(
                        color: _activePreset == 'custom'
                            ? AppColors.inkBlue
                            : AppColors.inkLight,
                        fontWeight: _activePreset == 'custom'
                            ? FontWeight.w600
                            : FontWeight.w400,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatRange(DateTimeRange range) {
    String fmt(DateTime d) =>
        '${d.day}/${d.month}';
    return '${fmt(range.start)} – ${fmt(range.end)}';
  }

  Future<void> _pickCustomRange(
    BuildContext context,
    TransactionProvider provider,
  ) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: provider.dateFilter,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.inkBlue,
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() => _activePreset = 'custom');
      provider.setDateFilter(picked);
    }
  }

  // ——— Transaction Actions ———

  Future<void> _editTransaction(Transaction txn) async {
    final txnProvider = context.read<TransactionProvider>();
    final accProvider = context.read<AccountProvider>();

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => QuickAddTransactionSheet(
        categories: txnProvider.categories,
        accounts: accProvider.accounts
            .where((a) => !a.isArchived)
            .toList(),
        initialValues: {
          'type': txn.type,
          'categoryId': txn.categoryId,
          'amount': txn.amount,
          'accountId': txn.accountId,
          'toAccountId': txn.toAccountId,
          'note': txn.note,
          'dateTime': txn.dateTime,
        },
      ),
    );

    if (result != null && mounted) {
      final newTxn = Transaction(
        id: txn.id,
        amount: result['amount'] as int,
        type: result['type'] as TransactionType,
        categoryId: result['categoryId'] as String,
        accountId: result['accountId'] as String,
        toAccountId: result['toAccountId'] as String?,
        note: result['note'] as String?,
        dateTime: result['dateTime'] as DateTime,
      );

      await txnProvider.updateTransaction(txn, newTxn);
      if (mounted) await accProvider.loadAccounts();
    }
  }

  Future<void> _deleteTransaction(Transaction txn) async {
    final txnProvider = context.read<TransactionProvider>();
    final accProvider = context.read<AccountProvider>();

    await txnProvider.deleteTransaction(txn);
    if (mounted) await accProvider.loadAccounts();
  }
}
