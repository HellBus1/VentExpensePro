import 'package:flutter/material.dart';

import '../../domain/entities/account.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/enums.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/repositories/account_repository.dart';
import '../../domain/repositories/category_repository.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../../domain/usecases/manage_transaction.dart';
import '../../domain/value_objects/transaction_filter.dart';

/// Manages transaction and category state for the receipt feed.
class TransactionProvider extends ChangeNotifier {
  final TransactionRepository _transactionRepository;
  final CategoryRepository _categoryRepository;
  final ManageTransaction _manageTransaction;
  final AccountRepository? _accountRepository;

  TransactionProvider(
    this._transactionRepository,
    this._categoryRepository,
    this._manageTransaction, [
    this._accountRepository,
  ]);

  List<Transaction> _transactions = [];
  List<Category> _categories = [];
  Map<String, AccountType> _accountTypeMap = {};
  bool _isLoading = false;
  String? _error;

  /// Active filter criteria.
  TransactionFilter _filter = TransactionFilter.empty;

  // — Cached Computations —
  int _todaysSpending = 0;
  int _thisMonthsSpending = 0;
  List<Transaction> _filteredTransactions = [];
  Map<DateTime, List<Transaction>> _filteredGroupedByDate = {};
  final Map<DateTime, List<Transaction>> _groupedByDate = {};

  // — Getters —

  List<Transaction> get transactions => _transactions;
  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Active filter object.
  TransactionFilter get filter => _filter;

  /// Whether any filter dimension is actively filtering.
  bool get hasActiveFilter => _filter.isActive;

  /// Number of active filter dimensions.
  int get activeFilterCount => _filter.activeFilterCount;

  /// Legacy date filter getter for backward compatibility.
  DateTimeRange? get dateFilter => _filter.dateRange;

  int get todaysSpending => _todaysSpending;
  int get thisMonthsSpending => _thisMonthsSpending;
  List<Transaction> get filteredTransactions => _filteredTransactions;
  Map<DateTime, List<Transaction>> get filteredGroupedByDate =>
      _filteredGroupedByDate;
  Map<DateTime, List<Transaction>> get groupedByDate => _groupedByDate;

  /// Returns a category by [id] from the in-memory list, or `null`.
  Category? getCategoryById(String id) {
    try {
      return _categories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Updates cached account type mappings used for filtering by account type.
  void updateAccountTypes(List<Account> accounts) {
    _accountTypeMap = {for (final a in accounts) a.id: a.type};
    if (_filter.accountTypes != null && _filter.accountTypes!.isNotEmpty) {
      _recomputeFiltered();
      notifyListeners();
    }
  }

  // — Recomputation Logic —

  void _recomputeStats() {
    final now = DateTime.now();
    int todaySum = 0;
    int thisMonthSum = 0;

    _groupedByDate.clear();

    for (final txn in _transactions) {
      if (txn.type == TransactionType.expense) {
        if (txn.dateTime.year == now.year && txn.dateTime.month == now.month) {
          thisMonthSum += txn.amount;
          if (txn.dateTime.day == now.day) {
            todaySum += txn.amount;
          }
        }
      }

      final dateKey = DateTime(
        txn.dateTime.year,
        txn.dateTime.month,
        txn.dateTime.day,
      );
      _groupedByDate.putIfAbsent(dateKey, () => []).add(txn);
    }

    _todaysSpending = todaySum;
    _thisMonthsSpending = thisMonthSum;
    _recomputeFiltered();
  }

  bool _matchesFilter(Transaction txn, TransactionFilter filter) {
    // 1. Date range filter (inclusive of full start and end days)
    if (filter.dateRange != null) {
      final start = DateTime(
        filter.dateRange!.start.year,
        filter.dateRange!.start.month,
        filter.dateRange!.start.day,
      );
      final end = DateTime(
        filter.dateRange!.end.year,
        filter.dateRange!.end.month,
        filter.dateRange!.end.day,
        23,
        59,
        59,
      );
      if (txn.dateTime.isBefore(start) || txn.dateTime.isAfter(end)) {
        return false;
      }
    }

    // 2. Text search (case-insensitive on note/description)
    if (filter.searchText != null && filter.searchText!.trim().isNotEmpty) {
      final query = filter.searchText!.trim().toLowerCase();
      final note = txn.note?.toLowerCase() ?? '';
      if (!note.contains(query)) return false;
    }

    // 3. Specific Accounts filter (matches source OR destination account)
    if (filter.accountIds != null && filter.accountIds!.isNotEmpty) {
      final matchesSource = filter.accountIds!.contains(txn.accountId);
      final matchesDest = txn.toAccountId != null &&
          filter.accountIds!.contains(txn.toAccountId);
      if (!matchesSource && !matchesDest) return false;
    }

    // 4. Account Type filter (matches if source OR destination is of this type)
    if (filter.accountTypes != null && filter.accountTypes!.isNotEmpty) {
      final sourceType = _accountTypeMap[txn.accountId];
      final destType =
          txn.toAccountId != null ? _accountTypeMap[txn.toAccountId] : null;
      final sourceMatches =
          sourceType != null && filter.accountTypes!.contains(sourceType);
      final destMatches =
          destType != null && filter.accountTypes!.contains(destType);
      if (!sourceMatches && !destMatches) return false;
    }

    // 5. Transaction Type filter
    if (filter.transactionTypes != null && filter.transactionTypes!.isNotEmpty) {
      if (!filter.transactionTypes!.contains(txn.type)) return false;
    }

    // 6. Category filter
    if (filter.categoryIds != null && filter.categoryIds!.isNotEmpty) {
      if (!filter.categoryIds!.contains(txn.categoryId)) return false;
    }

    // 7. Amount Range filter
    if (filter.minAmount != null && txn.amount < filter.minAmount!) {
      return false;
    }
    if (filter.maxAmount != null && txn.amount > filter.maxAmount!) {
      return false;
    }

    return true;
  }

  void _recomputeFiltered() {
    _filteredGroupedByDate.clear();

    if (!_filter.isActive) {
      _filteredTransactions = List.from(_transactions);
      _filteredGroupedByDate = Map.from(_groupedByDate);
      return;
    }

    _filteredTransactions =
        _transactions.where((t) => _matchesFilter(t, _filter)).toList();

    for (final txn in _filteredTransactions) {
      final dateKey = DateTime(
        txn.dateTime.year,
        txn.dateTime.month,
        txn.dateTime.day,
      );
      _filteredGroupedByDate.putIfAbsent(dateKey, () => []).add(txn);
    }
  }

  /// Calculates the count of transactions matching [filter] without altering active filter.
  int countMatching(TransactionFilter filter) {
    if (!filter.isActive) return _transactions.length;
    return _transactions.where((t) => _matchesFilter(t, filter)).length;
  }

  // — Filter Actions —

  /// Sets the full transaction filter and recomputes the list.
  void setFilter(TransactionFilter filter) {
    _filter = filter;
    _recomputeFiltered();
    notifyListeners();
  }

  /// Clears all filters and resets to showing all transactions.
  void clearFilter() {
    _filter = TransactionFilter.empty;
    _recomputeFiltered();
    notifyListeners();
  }

  /// Sets the date filter (for backward compatibility).
  void setDateFilter(DateTimeRange range) {
    _filter = _filter.copyWith(dateRange: range);
    _recomputeFiltered();
    notifyListeners();
  }

  /// Clears the date filter (for backward compatibility).
  void clearDateFilter() {
    _filter = _filter.copyWith(clearDateRange: true);
    _recomputeFiltered();
    notifyListeners();
  }

  // — Data Actions —

  /// Loads all transactions, categories, and account types.
  Future<void> loadAll() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _transactions = await _transactionRepository.getAll();
      _categories = await _categoryRepository.getAll();
      if (_accountRepository != null) {
        final accounts = await _accountRepository.getAll();
        _accountTypeMap = {for (final a in accounts) a.id: a.type};
      }
      _recomputeStats();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Loads all transactions only.
  Future<void> loadTransactions() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _transactions = await _transactionRepository.getAll();
      if (_accountRepository != null && _accountTypeMap.isEmpty) {
        final accounts = await _accountRepository.getAll();
        _accountTypeMap = {for (final a in accounts) a.id: a.type};
      }
      _recomputeStats();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Logs a new transaction and refreshes the list.
  Future<void> addTransaction(Transaction transaction) async {
    try {
      await _manageTransaction.create(transaction);
      await loadTransactions();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Updates a transaction (with balance reversal) and refreshes the list.
  Future<void> updateTransaction(
    Transaction oldTxn,
    Transaction newTxn,
  ) async {
    try {
      await _manageTransaction.update(oldTxn, newTxn);
      await loadTransactions();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Deletes a transaction (with balance reversal) and refreshes the list.
  Future<void> deleteTransaction(Transaction transaction) async {
    try {
      await _manageTransaction.delete(transaction);
      await loadTransactions();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}
