import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/entities/enums.dart';
import '../../domain/value_objects/transaction_filter.dart';
import '../../core/utils/category_icon_mapper.dart';
import '../providers/account_provider.dart';
import '../providers/currency_provider.dart';
import '../providers/transaction_provider.dart';

/// Full-screen modal to configure multi-dimensional transaction filters.
class TransactionFilterScreen extends StatefulWidget {
  final TransactionFilter initialFilter;
  final ValueChanged<TransactionFilter>? onApply;

  const TransactionFilterScreen({
    super.key,
    this.initialFilter = TransactionFilter.empty,
    this.onApply,
  });

  @override
  State<TransactionFilterScreen> createState() =>
      _TransactionFilterScreenState();
}

class _TransactionFilterScreenState extends State<TransactionFilterScreen> {
  late TransactionFilter _filter;
  late final TextEditingController _searchController;
  late final TextEditingController _minAmountController;
  late final TextEditingController _maxAmountController;

  @override
  void initState() {
    super.initState();
    _filter = widget.initialFilter;
    _searchController = TextEditingController(text: _filter.searchText ?? '');
    _minAmountController = TextEditingController(
      text: _filter.minAmount != null ? _filter.minAmount.toString() : '',
    );
    _maxAmountController = TextEditingController(
      text: _filter.maxAmount != null ? _filter.maxAmount.toString() : '',
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _minAmountController.dispose();
    _maxAmountController.dispose();
    super.dispose();
  }

  void _resetFilters() {
    setState(() {
      _filter = TransactionFilter.empty;
      _searchController.clear();
      _minAmountController.clear();
      _maxAmountController.clear();
    });
  }

  void _applyFilters() {
    if (widget.onApply != null) {
      widget.onApply!(_filter);
    } else {
      context.read<TransactionProvider>().setFilter(_filter);
    }
    Navigator.of(context).pop(_filter);
  }

  @override
  Widget build(BuildContext context) {
    final txnProvider = context.watch<TransactionProvider>();
    final accProvider = context.watch<AccountProvider>();
    final currencySymbol = context.watch<CurrencyProvider>().symbol.trim();

    final matchCount = txnProvider.countMatching(_filter);
    final totalTransactions = txnProvider.transactions.length;

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        title: const Text('Filter Transactions'),
        leading: IconButton(
          key: const ValueKey('filter_close_button'),
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (_filter.isActive)
            TextButton(
              key: const ValueKey('filter_reset_button'),
              onPressed: _resetFilters,
              child: const Text('Reset'),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                key: const ValueKey('filter_scroll_view'),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Search Query
                    _buildSectionHeader('SEARCH DESCRIPTION', Icons.search),
                    const SizedBox(height: 8),
                    TextField(
                      key: const ValueKey('filter_search_input'),
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search by note, merchant, or tag...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _filter =
                                        _filter.copyWith(clearSearchText: true);
                                  });
                                },
                              )
                            : null,
                      ),
                      onChanged: (val) {
                        setState(() {
                          _filter = val.trim().isEmpty
                              ? _filter.copyWith(clearSearchText: true)
                              : _filter.copyWith(searchText: val.trim());
                        });
                      },
                    ),

                    const SizedBox(height: 20),

                    // 2. Date Range
                    _buildSectionHeader('DATE RANGE', Icons.date_range),
                    const SizedBox(height: 8),
                    _buildDateRangePicker(context),

                    const SizedBox(height: 20),

                    // 3. Accounts
                    if (accProvider.accounts.isNotEmpty) ...[
                      _buildSectionHeader(
                          'ACCOUNTS', Icons.account_balance_wallet_outlined),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: accProvider.accounts.map((acc) {
                          final isSelected =
                              _filter.accountIds?.contains(acc.id) ?? false;
                          return FilterChip(
                            key: ValueKey('filter_account_chip_${acc.name}'),
                            label: Text(acc.name),
                            selected: isSelected,
                            onSelected: (selected) {
                              final current =
                                  List<String>.from(_filter.accountIds ?? []);
                              if (selected) {
                                current.add(acc.id);
                              } else {
                                current.remove(acc.id);
                              }
                              setState(() {
                                _filter = current.isEmpty
                                    ? _filter.copyWith(clearAccountIds: true)
                                    : _filter.copyWith(accountIds: current);
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // 4. Account Types
                    _buildSectionHeader('ACCOUNT TYPE', Icons.category_outlined),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: AccountType.values.map((type) {
                        final isSelected =
                            _filter.accountTypes?.contains(type) ?? false;
                        return FilterChip(
                          key: ValueKey('filter_account_type_${type.name}'),
                          label: Text(_formatAccountType(type)),
                          selected: isSelected,
                          onSelected: (selected) {
                            final current = List<AccountType>.from(
                                _filter.accountTypes ?? []);
                            if (selected) {
                              current.add(type);
                            } else {
                              current.remove(type);
                            }
                            setState(() {
                              _filter = current.isEmpty
                                  ? _filter.copyWith(clearAccountTypes: true)
                                  : _filter.copyWith(accountTypes: current);
                            });
                          },
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 20),

                    // 5. Transaction Types
                    _buildSectionHeader('TRANSACTION TYPE', Icons.swap_horiz),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: TransactionType.values.map((type) {
                        final isSelected =
                            _filter.transactionTypes?.contains(type) ?? false;
                        return FilterChip(
                          key: ValueKey('filter_transaction_type_${type.name}'),
                          label: Text(_formatTransactionType(type)),
                          selected: isSelected,
                          onSelected: (selected) {
                            final current = List<TransactionType>.from(
                                _filter.transactionTypes ?? []);
                            if (selected) {
                              current.add(type);
                            } else {
                              current.remove(type);
                            }
                            setState(() {
                              _filter = current.isEmpty
                                  ? _filter.copyWith(clearTransactionTypes: true)
                                  : _filter.copyWith(transactionTypes: current);
                            });
                          },
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 20),

                    // 6. Categories
                    if (txnProvider.categories.isNotEmpty) ...[
                      _buildSectionHeader(
                          'CATEGORIES', Icons.label_outline_rounded),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: txnProvider.categories.map((cat) {
                          final isSelected =
                              _filter.categoryIds?.contains(cat.id) ?? false;
                          return FilterChip(
                            key: ValueKey('filter_category_chip_${cat.name}'),
                            avatar: Icon(
                              CategoryIconMapper.iconFor(cat.icon),
                              size: 16,
                              color: isSelected
                                  ? AppColors.inkBlue
                                  : AppColors.inkLight,
                            ),
                            label: Text(cat.name),
                            selected: isSelected,
                            onSelected: (selected) {
                              final current = List<String>.from(
                                  _filter.categoryIds ?? []);
                              if (selected) {
                                current.add(cat.id);
                              } else {
                                current.remove(cat.id);
                              }
                              setState(() {
                                _filter = current.isEmpty
                                    ? _filter.copyWith(clearCategoryIds: true)
                                    : _filter.copyWith(categoryIds: current);
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // 7. Amount Range
                    _buildSectionHeader('AMOUNT RANGE', Icons.attach_money),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            key: const ValueKey('filter_min_amount_input'),
                            controller: _minAmountController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Min Amount',
                              prefixText: '$currencySymbol ',
                              hintText: '0',
                            ),
                            onChanged: (val) {
                              final parsed = int.tryParse(val.trim());
                              setState(() {
                                _filter = parsed == null
                                    ? _filter.copyWith(clearMinAmount: true)
                                    : _filter.copyWith(minAmount: parsed);
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            key: const ValueKey('filter_max_amount_input'),
                            controller: _maxAmountController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Max Amount',
                              prefixText: '$currencySymbol ',
                              hintText: 'No limit',
                            ),
                            onChanged: (val) {
                              final parsed = int.tryParse(val.trim());
                              setState(() {
                                _filter = parsed == null
                                    ? _filter.copyWith(clearMaxAmount: true)
                                    : _filter.copyWith(maxAmount: parsed);
                              });
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),

            // — Sticky Bottom Action Bar —
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: AppColors.paperElevated,
                border: Border(top: BorderSide(color: AppColors.divider)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 8,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$matchCount of $totalTransactions matches',
                          key: const ValueKey('filter_match_count'),
                          style: AppTypography.titleMedium.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          _filter.isActive
                              ? '${_filter.activeFilterCount} active filters'
                              : 'No filters applied',
                          style: AppTypography.label.copyWith(
                            color: _filter.isActive
                                ? AppColors.inkBlue
                                : AppColors.inkLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    key: const ValueKey('filter_apply_button'),
                    onPressed: _applyFilters,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Apply Filters'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.inkLight),
        const SizedBox(width: 6),
        Text(
          title,
          style: AppTypography.label.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: AppColors.inkLight,
          ),
        ),
      ],
    );
  }

  Widget _buildDateRangePicker(BuildContext context) {
    final hasRange = _filter.dateRange != null;
    final rangeText = hasRange
        ? '${DateFormat('MMM d, y').format(_filter.dateRange!.start)} – ${DateFormat('MMM d, y').format(_filter.dateRange!.end)}'
        : 'All Time';

    return Row(
      children: [
        Expanded(
          child: InkWell(
            key: const ValueKey('filter_date_range_picker'),
            onTap: () async {
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime(DateTime.now().year + 5),
                initialDateRange: _filter.dateRange,
              );
              if (picked != null) {
                setState(() {
                  _filter = _filter.copyWith(dateRange: picked);
                });
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: hasRange
                    ? AppColors.inkBlue.withValues(alpha: 0.08)
                    : AppColors.paperElevated,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: hasRange ? AppColors.inkBlue : AppColors.divider,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: hasRange ? AppColors.inkBlue : AppColors.inkLight,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      rangeText,
                      style: AppTypography.bodyMedium.copyWith(
                        color: hasRange ? AppColors.inkBlue : AppColors.inkDark,
                        fontWeight:
                            hasRange ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (hasRange) ...[
          const SizedBox(width: 8),
          IconButton(
            key: const ValueKey('filter_clear_date_button'),
            icon: const Icon(Icons.clear, size: 20),
            onPressed: () {
              setState(() {
                _filter = _filter.copyWith(clearDateRange: true);
              });
            },
          ),
        ],
      ],
    );
  }

  String _formatAccountType(AccountType type) {
    switch (type) {
      case AccountType.debit:
        return 'Debit';
      case AccountType.credit:
        return 'Credit Card';
      case AccountType.cash:
        return 'Cash';
      case AccountType.debt:
        return 'Personal Debt';
    }
  }

  String _formatTransactionType(TransactionType type) {
    switch (type) {
      case TransactionType.expense:
        return 'Expense';
      case TransactionType.income:
        return 'Income';
      case TransactionType.transfer:
        return 'Transfer';
    }
  }
}
