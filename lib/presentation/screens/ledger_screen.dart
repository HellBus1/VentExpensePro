import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/entities/enums.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/value_objects/transaction_filter.dart';
import '../painters/paper_background.dart';
import '../providers/account_provider.dart';
import '../providers/sync_provider.dart';
import '../providers/transaction_provider.dart';
import '../widgets/billing_summary_widget.dart';
import '../widgets/net_position_card.dart';
import '../widgets/quick_add_transaction_sheet.dart';
import '../widgets/quick_stats_strip.dart';
import '../widgets/receipt_card.dart';
import '../widgets/receipt_date_header.dart';
import '../widgets/sync_status_chip.dart';
import 'transaction_filter_screen.dart';

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
      final txnProv = context.read<TransactionProvider>();
      final accProv = context.read<AccountProvider>();
      final syncProv = context.read<SyncProvider>();

      if (txnProv.transactions.isEmpty) txnProv.loadAll();
      if (accProv.accounts.isEmpty) accProv.loadAccounts();
      syncProv.loadStatus();
      txnProv.updateAccountTypes(accProv.accounts);
    });
  }

  @override
  Widget build(BuildContext context) {
    return PaperBackground(
      child: Consumer3<TransactionProvider, AccountProvider, SyncProvider>(
        builder: (context, txnProvider, accProvider, syncProvider, _) {
          final grouped = txnProvider.filteredGroupedByDate;
          final sortedDates = grouped.keys.toList()
            ..sort((a, b) => b.compareTo(a)); // newest first

          final creditCards = accProvider.creditAccounts
              .where((a) => a.hasBillingCycle)
              .toList();

          return CustomScrollView(
            key: const ValueKey('ledger_scroll_view'),
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

              // — Sync Status Chip —
              const SliverToBoxAdapter(
                child: SyncStatusChip(),
              ),

              // — Quick Stats Strip —
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: QuickStatsStrip(
                    todaysSpending: txnProvider.todaysSpending,
                    thisMonthsSpending: txnProvider.thisMonthsSpending,
                  ),
                ),
              ),

              // — Credit Card Billing Cycles Summary —
              if (creditCards.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: SizedBox(
                      height: 168,
                      child: ListView.separated(
                        key: const ValueKey('billing_summary_list_view'),
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: creditCards.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(width: 12),
                        itemBuilder: (_, i) => BillingSummaryWidget(
                          account: creditCards[i],
                          transactions: txnProvider.transactions,
                        ),
                      ),
                    ),
                  ),
                ),

              // — Filter Bar —
              SliverToBoxAdapter(
                child: _buildFilterBar(context, txnProvider, accProvider),
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
                          txnProvider.hasActiveFilter
                              ? 'No transactions match your filters'
                              : 'No transactions yet',
                          style: AppTypography.bodyLarge.copyWith(
                            color: AppColors.inkLight,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          txnProvider.hasActiveFilter
                              ? 'Try adjusting or clearing your filters'
                              : 'Tap + to log your first entry',
                          style: AppTypography.bodySmall,
                        ),
                        if (txnProvider.hasActiveFilter) ...[
                          const SizedBox(height: 12),
                          TextButton.icon(
                            key: const ValueKey('empty_clear_filters_button'),
                            icon: const Icon(Icons.clear, size: 16),
                            label: const Text('Clear Filters'),
                            onPressed: () {
                              setState(() => _activePreset = 'all');
                              txnProvider.clearFilter();
                            },
                          ),
                        ],
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

  Widget _buildFilterBar(
    BuildContext context,
    TransactionProvider provider,
    AccountProvider accProvider,
  ) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
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
                            key: ValueKey(
                                'ledger_preset_${label.toLowerCase().replaceAll(' ', '_')}'),
                            onTap: () {
                              setState(
                                  () => _activePreset = label.toLowerCase());
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
                                  fontWeight: isActive
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),

                      // — Custom Range chip —
                      GestureDetector(
                        key: const ValueKey('ledger_preset_custom'),
                        onTap: () => _pickCustomRange(context, provider),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
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
                                _activePreset == 'custom' &&
                                        provider.dateFilter != null
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
              ),

              const SizedBox(width: 8),

              // — Filter Modal Trigger Button with Badge —
              GestureDetector(
                key: const ValueKey('ledger_filter_button'),
                onTap: () => _openFilterScreen(context),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: provider.hasActiveFilter
                        ? AppColors.inkBlue.withValues(alpha: 0.12)
                        : AppColors.paperElevated,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: provider.hasActiveFilter
                          ? AppColors.inkBlue
                          : AppColors.divider,
                      width: provider.hasActiveFilter ? 1.5 : 0.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Badge.count(
                        count: provider.activeFilterCount,
                        isLabelVisible: provider.hasActiveFilter,
                        backgroundColor: AppColors.inkBlue,
                        child: Icon(
                          Icons.tune_rounded,
                          size: 16,
                          color: provider.hasActiveFilter
                              ? AppColors.inkBlue
                              : AppColors.inkLight,
                        ),
                      ),
                      if (provider.hasActiveFilter) ...[
                        const SizedBox(width: 6),
                        Text(
                          'Filter',
                          style: AppTypography.label.copyWith(
                            color: AppColors.inkBlue,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),

          // — Active Filter Tokens Row —
          if (provider.hasActiveFilter) ...[
            const SizedBox(height: 10),
            _buildActiveFilterChips(context, provider, accProvider),
          ],
        ],
      ),
    );
  }

  Widget _buildActiveFilterChips(
    BuildContext context,
    TransactionProvider provider,
    AccountProvider accProvider,
  ) {
    final filter = provider.filter;
    final chips = <Widget>[];

    // Search query token
    if (filter.searchText != null && filter.searchText!.isNotEmpty) {
      chips.add(
        _buildFilterToken(
          label: 'Search: "${filter.searchText}"',
          icon: Icons.search,
          onRemove: () =>
              provider.setFilter(filter.copyWith(clearSearchText: true)),
        ),
      );
    }

    // Accounts tokens
    if (filter.accountIds != null && filter.accountIds!.isNotEmpty) {
      for (final accId in filter.accountIds!) {
        final acc = accProvider.getAccountById(accId);
        final name = acc?.name ?? 'Account';
        chips.add(
          _buildFilterToken(
            label: name,
            icon: Icons.account_balance_wallet_outlined,
            onRemove: () {
              final next = List<String>.from(filter.accountIds!)..remove(accId);
              provider.setFilter(
                next.isEmpty
                    ? filter.copyWith(clearAccountIds: true)
                    : filter.copyWith(accountIds: next),
              );
            },
          ),
        );
      }
    }

    // Account types tokens
    if (filter.accountTypes != null && filter.accountTypes!.isNotEmpty) {
      for (final type in filter.accountTypes!) {
        chips.add(
          _buildFilterToken(
            label: type.name.toUpperCase(),
            icon: Icons.category_outlined,
            onRemove: () {
              final next = List<AccountType>.from(filter.accountTypes!)
                ..remove(type);
              provider.setFilter(
                next.isEmpty
                    ? filter.copyWith(clearAccountTypes: true)
                    : filter.copyWith(accountTypes: next),
              );
            },
          ),
        );
      }
    }

    // Transaction types tokens
    if (filter.transactionTypes != null &&
        filter.transactionTypes!.isNotEmpty) {
      for (final type in filter.transactionTypes!) {
        chips.add(
          _buildFilterToken(
            label: type.name.toUpperCase(),
            icon: Icons.swap_horiz,
            onRemove: () {
              final next = List<TransactionType>.from(filter.transactionTypes!)
                ..remove(type);
              provider.setFilter(
                next.isEmpty
                    ? filter.copyWith(clearTransactionTypes: true)
                    : filter.copyWith(transactionTypes: next),
              );
            },
          ),
        );
      }
    }

    // Categories tokens
    if (filter.categoryIds != null && filter.categoryIds!.isNotEmpty) {
      for (final catId in filter.categoryIds!) {
        final cat = provider.getCategoryById(catId);
        final name = cat?.name ?? 'Category';
        chips.add(
          _buildFilterToken(
            label: name,
            icon: Icons.label_outline,
            onRemove: () {
              final next = List<String>.from(filter.categoryIds!)..remove(catId);
              provider.setFilter(
                next.isEmpty
                    ? filter.copyWith(clearCategoryIds: true)
                    : filter.copyWith(categoryIds: next),
              );
            },
          ),
        );
      }
    }

    // Amount range token
    if (filter.minAmount != null || filter.maxAmount != null) {
      final minStr = filter.minAmount != null ? '≥ ${filter.minAmount}' : '';
      final maxStr = filter.maxAmount != null ? '≤ ${filter.maxAmount}' : '';
      final label = [minStr, maxStr].where((s) => s.isNotEmpty).join(' & ');
      chips.add(
        _buildFilterToken(
          label: label,
          icon: Icons.attach_money,
          onRemove: () => provider.setFilter(
            filter.copyWith(clearMinAmount: true, clearMaxAmount: true),
          ),
        ),
      );
    }

    // Clear all token
    chips.add(
      GestureDetector(
        key: const ValueKey('ledger_clear_all_filters_chip'),
        onTap: () {
          setState(() => _activePreset = 'all');
          provider.clearFilter();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.stampRed.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.stampRed.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.close, size: 12, color: AppColors.stampRed),
              const SizedBox(width: 4),
              Text(
                'Clear All',
                style: AppTypography.label.copyWith(
                  color: AppColors.stampRed,
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: chips
            .map((c) => Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: c,
                ))
            .toList(),
      ),
    );
  }

  Widget _buildFilterToken({
    required String label,
    required IconData icon,
    required VoidCallback onRemove,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.paperElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.inkLight),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.label.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.inkDark,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close, size: 14, color: AppColors.inkLight),
          ),
        ],
      ),
    );
  }

  String _formatRange(DateTimeRange range) {
    String fmt(DateTime d) => '${d.day}/${d.month}';
    return '${fmt(range.start)} – ${fmt(range.end)}';
  }

  Future<void> _pickCustomRange(
    BuildContext context,
    TransactionProvider provider,
  ) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(DateTime.now().year + 5),
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

  Future<void> _openFilterScreen(BuildContext context) async {
    final txnProvider = context.read<TransactionProvider>();
    final accProvider = context.read<AccountProvider>();

    txnProvider.updateAccountTypes(accProvider.accounts);

    final newFilter = await Navigator.push<TransactionFilter>(
      context,
      MaterialPageRoute(
        builder: (_) => TransactionFilterScreen(
          initialFilter: txnProvider.filter,
        ),
      ),
    );

    if (newFilter != null && mounted) {
      txnProvider.setFilter(newFilter);
      if (newFilter.dateRange == null) {
        setState(() => _activePreset = 'all');
      } else {
        setState(() => _activePreset = 'custom');
      }
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
        accounts:
            accProvider.accounts.where((a) => !a.isArchived).toList(),
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
        isSettlement: txn.isSettlement,
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
