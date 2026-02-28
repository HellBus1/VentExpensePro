import 'package:flutter/material.dart';

import '../../domain/entities/category.dart';
import '../../domain/entities/enums.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/repositories/category_repository.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../../domain/usecases/manage_transaction.dart';

/// Manages transaction and category state for the receipt feed.
class TransactionProvider extends ChangeNotifier {
  final TransactionRepository _transactionRepository;
  final CategoryRepository _categoryRepository;
  final ManageTransaction _manageTransaction;

  TransactionProvider(
    this._transactionRepository,
    this._categoryRepository,
    this._manageTransaction,
  );

  List<Transaction> _transactions = [];
  List<Category> _categories = [];
  bool _isLoading = false;
  String? _error;

  /// Active date filter. Null means "show all".
  DateTimeRange? _dateFilter;

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
  DateTimeRange? get dateFilter => _dateFilter;

  int get todaysSpending => _todaysSpending;
  int get thisMonthsSpending => _thisMonthsSpending;
  List<Transaction> get filteredTransactions => _filteredTransactions;
  Map<DateTime, List<Transaction>> get filteredGroupedByDate => _filteredGroupedByDate;
  Map<DateTime, List<Transaction>> get groupedByDate => _groupedByDate;

  /// Returns a category by [id] from the in-memory list, or `null`.
  Category? getCategoryById(String id) {
    try {
      return _categories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
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

  void _recomputeFiltered() {
    _filteredGroupedByDate.clear();
    
    if (_dateFilter == null) {
      _filteredTransactions = List.from(_transactions);
      _filteredGroupedByDate = Map.from(_groupedByDate);
      return;
    }

    final start = DateTime(
      _dateFilter!.start.year,
      _dateFilter!.start.month,
      _dateFilter!.start.day,
    );
    final end = DateTime(
      _dateFilter!.end.year,
      _dateFilter!.end.month,
      _dateFilter!.end.day,
      23, 59, 59,
    );

    _filteredTransactions = _transactions
        .where((t) => !t.dateTime.isBefore(start) && !t.dateTime.isAfter(end))
        .toList();

    for (final txn in _filteredTransactions) {
      final dateKey = DateTime(
        txn.dateTime.year,
        txn.dateTime.month,
        txn.dateTime.day,
      );
      _filteredGroupedByDate.putIfAbsent(dateKey, () => []).add(txn);
    }
  }

  // — Filter Actions —

  /// Sets the date filter and notifies listeners.
  void setDateFilter(DateTimeRange range) {
    _dateFilter = range;
    _recomputeFiltered();
    notifyListeners();
  }

  /// Clears the date filter (show all).
  void clearDateFilter() {
    _dateFilter = null;
    _recomputeFiltered();
    notifyListeners();
  }

  // — Data Actions —

  /// Loads all transactions and categories.
  Future<void> loadAll() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _transactions = await _transactionRepository.getAll();
      _categories = await _categoryRepository.getAll();
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
