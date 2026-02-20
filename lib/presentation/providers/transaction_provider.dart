import 'package:flutter/foundation.dart';

import '../../domain/entities/transaction.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../../domain/usecases/log_transaction.dart';

/// Manages transaction state for the receipt feed.
class TransactionProvider extends ChangeNotifier {
  final TransactionRepository _transactionRepository;
  final LogTransaction _logTransaction;

  TransactionProvider(this._transactionRepository, this._logTransaction);

  List<Transaction> _transactions = [];
  bool _isLoading = false;
  String? _error;

  // — Getters —

  List<Transaction> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Transactions grouped by date (for the receipt feed).
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

  // — Actions —

  /// Loads all transactions.
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
      await _logTransaction(transaction);
      await loadTransactions();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Deletes a transaction and refreshes the list.
  Future<void> deleteTransaction(String id) async {
    try {
      await _transactionRepository.delete(id);
      await loadTransactions();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}
