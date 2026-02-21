import '../entities/transaction.dart';

/// Contract for transaction persistence operations.
abstract class TransactionRepository {
  /// Returns all transactions, newest first.
  Future<List<Transaction>> getAll();

  /// Returns transactions for a specific account.
  Future<List<Transaction>> getByAccount(String accountId);

  /// Returns transactions within a date range (inclusive).
  Future<List<Transaction>> getByDateRange(DateTime start, DateTime end);

  /// Returns a single transaction by [id], or `null` if not found.
  Future<Transaction?> getById(String id);

  /// Inserts a new transaction. Returns the inserted transaction.
  Future<Transaction> insert(Transaction transaction);

  /// Updates an existing transaction. Returns the updated transaction.
  Future<Transaction> update(Transaction transaction);

  /// Deletes a transaction by [id].
  Future<void> delete(String id);
}
