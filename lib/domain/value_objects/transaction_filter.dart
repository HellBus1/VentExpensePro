import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../entities/enums.dart';

/// Encapsulates multi-dimensional filter criteria for transaction queries.
/// All fields are optional — null means "no filter on this dimension".
/// Different dimensions combine with AND logic; collections within a dimension
/// combine with OR logic.
class TransactionFilter extends Equatable {
  /// Filter by date range (inclusive).
  final DateTimeRange? dateRange;

  /// Case-insensitive search on transaction notes/descriptions.
  final String? searchText;

  /// Matches transactions where source or destination is one of these accounts.
  final List<String>? accountIds;

  /// Matches transactions where source or destination account is of one of these types.
  final List<AccountType>? accountTypes;

  /// Matches transactions having one of these transaction types.
  final List<TransactionType>? transactionTypes;

  /// Matches transactions associated with one of these category IDs.
  final List<String>? categoryIds;

  /// Minimum transaction amount (inclusive).
  final int? minAmount;

  /// Maximum transaction amount (inclusive).
  final int? maxAmount;

  const TransactionFilter({
    this.dateRange,
    this.searchText,
    this.accountIds,
    this.accountTypes,
    this.transactionTypes,
    this.categoryIds,
    this.minAmount,
    this.maxAmount,
  });

  /// An empty filter matching all transactions.
  static const empty = TransactionFilter();

  /// Whether any filter dimension is actively filtering.
  bool get isActive =>
      dateRange != null ||
      (searchText != null && searchText!.trim().isNotEmpty) ||
      (accountIds != null && accountIds!.isNotEmpty) ||
      (accountTypes != null && accountTypes!.isNotEmpty) ||
      (transactionTypes != null && transactionTypes!.isNotEmpty) ||
      (categoryIds != null && categoryIds!.isNotEmpty) ||
      minAmount != null ||
      maxAmount != null;

  /// Total count of active filter dimensions (used for badges).
  int get activeFilterCount {
    int count = 0;
    if (dateRange != null) count++;
    if (searchText != null && searchText!.trim().isNotEmpty) count++;
    if (accountIds != null && accountIds!.isNotEmpty) count++;
    if (accountTypes != null && accountTypes!.isNotEmpty) count++;
    if (transactionTypes != null && transactionTypes!.isNotEmpty) count++;
    if (categoryIds != null && categoryIds!.isNotEmpty) count++;
    if (minAmount != null || maxAmount != null) count++;
    return count;
  }

  /// Creates a copy of this filter with the given fields replaced.
  /// Pass `clearDateRange: true`, `clearSearchText: true`, etc. to explicitly remove a filter.
  TransactionFilter copyWith({
    DateTimeRange? dateRange,
    bool clearDateRange = false,
    String? searchText,
    bool clearSearchText = false,
    List<String>? accountIds,
    bool clearAccountIds = false,
    List<AccountType>? accountTypes,
    bool clearAccountTypes = false,
    List<TransactionType>? transactionTypes,
    bool clearTransactionTypes = false,
    List<String>? categoryIds,
    bool clearCategoryIds = false,
    int? minAmount,
    bool clearMinAmount = false,
    int? maxAmount,
    bool clearMaxAmount = false,
  }) {
    return TransactionFilter(
      dateRange: clearDateRange ? null : (dateRange ?? this.dateRange),
      searchText: clearSearchText ? null : (searchText ?? this.searchText),
      accountIds: clearAccountIds ? null : (accountIds ?? this.accountIds),
      accountTypes:
          clearAccountTypes ? null : (accountTypes ?? this.accountTypes),
      transactionTypes: clearTransactionTypes
          ? null
          : (transactionTypes ?? this.transactionTypes),
      categoryIds: clearCategoryIds ? null : (categoryIds ?? this.categoryIds),
      minAmount: clearMinAmount ? null : (minAmount ?? this.minAmount),
      maxAmount: clearMaxAmount ? null : (maxAmount ?? this.maxAmount),
    );
  }

  @override
  List<Object?> get props => [
        dateRange,
        searchText,
        accountIds,
        accountTypes,
        transactionTypes,
        categoryIds,
        minAmount,
        maxAmount,
      ];
}
