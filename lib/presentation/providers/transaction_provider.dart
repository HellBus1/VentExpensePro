import 'package:flutter/material.dart';

import '../../domain/entities/category.dart';
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

  // — Getters —

  List<Transaction> get transactions => _transactions;
  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTimeRange? get dateFilter => _dateFilter;

  /// Transactions filtered by the active date range (or all if no filter).
  List<Transaction> get filteredTransactions {
    if (_dateFilter == null) return _transactions;
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
    return _transactions
        .where((t) =>
            !t.dateTime.isBefore(start) && !t.dateTime.isAfter(end))
        .toList();
  }

  /// Filtered transactions grouped by date (for the receipt feed).
  Map<DateTime, List<Transaction>> get filteredGroupedByDate {
    final grouped = <DateTime, List<Transaction>>{};
    for (final txn in filteredTransactions) {
      final dateKey = DateTime(
        txn.dateTime.year,
        txn.dateTime.month,
        txn.dateTime.day,
      );
      grouped.putIfAbsent(dateKey, () => []).add(txn);
    }
    return grouped;
  }

  /// Transactions grouped by date (unfiltered — kept for backwards compat).
  Map<DateTime, List<Transaction>> get groupedByDate {
    final grouped = <DateTime, List<Transaction>>{};
    for (final txn in _transactions) {
      final dateKey = DateTime(
        txn.dateTime.year,
        txn.dateTime.month,
        txn.dateTime.day,
      );
      grouped.putIfAbsent(dateKey, () => []).add(txn);
    }
    return grouped;
  }

  /// Returns a category by [id] from the in-memory list, or `null`.
  Category? getCategoryById(String id) {
    try {
      return _categories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  // — Filter Actions —

  /// Sets the date filter and notifies listeners.
  void setDateFilter(DateTimeRange range) {
    _dateFilter = range;
    notifyListeners();
  }

  /// Clears the date filter (show all).
  void clearDateFilter() {
    _dateFilter = null;
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
