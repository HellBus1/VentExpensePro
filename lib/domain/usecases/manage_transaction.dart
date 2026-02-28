import '../entities/enums.dart';
import '../entities/transaction.dart';
import '../repositories/account_repository.dart';
import '../repositories/transaction_repository.dart';
import 'log_transaction.dart';

/// Encapsulates create, update, and delete operations for transactions,
/// ensuring account balances are always kept in sync.
class ManageTransaction {
  final TransactionRepository _transactionRepository;
  final AccountRepository _accountRepository;
  final LogTransaction _logTransaction;

  ManageTransaction(
    this._transactionRepository,
    this._accountRepository,
    this._logTransaction,
  );

  /// Creates a new transaction — delegates to [LogTransaction].
  Future<Transaction> create(Transaction transaction) {
    return _logTransaction(transaction);
  }

  /// Updates an existing transaction: reverses old balance changes,
  /// applies new ones, and persists the update.
  Future<Transaction> update(
    Transaction oldTxn,
    Transaction newTxn,
  ) async {
    // 1. Reverse the old transaction's balance effects
    await _reverseBalance(oldTxn);

    // 2. Apply the new transaction's balance effects
    await _applyBalance(newTxn);

    // 3. Persist the updated transaction
    return _transactionRepository.update(newTxn);
  }

  /// Deletes a transaction: reverses its balance changes and removes the record.
  Future<void> delete(Transaction transaction) async {
    await _reverseBalance(transaction);
    await _transactionRepository.delete(transaction.id);
  }

  // ——— Private helpers ———

  /// Reverses the balance effects of a transaction (undo).
  Future<void> _reverseBalance(Transaction txn) async {
    final source = await _accountRepository.getById(txn.accountId);
    if (source == null) return; // account may have been archived / deleted

    switch (txn.type) {
      case TransactionType.expense:
        if (source.isLiability) {
          // Was increased → decrease it back
          await _accountRepository.updateBalance(
            source.id,
            source.balance - txn.amount,
          );
        } else {
          // Was decreased → increase it back
          await _accountRepository.updateBalance(
            source.id,
            source.balance + txn.amount,
          );
        }

      case TransactionType.income:
        // Was increased → decrease it back
        await _accountRepository.updateBalance(
          source.id,
          source.balance - txn.amount,
        );

      case TransactionType.transfer:
        // Reverse source (was decreased → increase)
        await _accountRepository.updateBalance(
          source.id,
          source.balance + txn.amount,
        );
        // Reverse destination (was increased → decrease)
        if (txn.toAccountId != null) {
          final dest = await _accountRepository.getById(txn.toAccountId!);
          if (dest != null) {
            await _accountRepository.updateBalance(
              dest.id,
              dest.balance - txn.amount,
            );
          }
        }
    }
  }

  /// Applies the balance effects of a transaction (same logic as LogTransaction).
  Future<void> _applyBalance(Transaction txn) async {
    final source = await _accountRepository.getById(txn.accountId);
    if (source == null) {
      throw ArgumentError('Source account not found: ${txn.accountId}');
    }

    switch (txn.type) {
      case TransactionType.expense:
        if (source.isLiability) {
          await _accountRepository.updateBalance(
            source.id,
            source.balance + txn.amount,
          );
        } else {
          await _accountRepository.updateBalance(
            source.id,
            source.balance - txn.amount,
          );
        }

      case TransactionType.income:
        await _accountRepository.updateBalance(
          source.id,
          source.balance + txn.amount,
        );

      case TransactionType.transfer:
        if (txn.toAccountId == null) {
          throw ArgumentError('Transfer requires a destination account');
        }
        final dest = await _accountRepository.getById(txn.toAccountId!);
        if (dest == null) {
          throw ArgumentError(
            'Destination account not found: ${txn.toAccountId}',
          );
        }
        await _accountRepository.updateBalance(
          source.id,
          source.balance - txn.amount,
        );
        await _accountRepository.updateBalance(
          dest.id,
          dest.balance + txn.amount,
        );
    }
  }
}
