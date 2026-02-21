import '../entities/enums.dart';
import '../entities/transaction.dart';
import '../repositories/account_repository.dart';
import '../repositories/transaction_repository.dart';

/// Validates and logs a new transaction, updating the affected account balance.
class LogTransaction {
  final TransactionRepository _transactionRepository;
  final AccountRepository _accountRepository;

  LogTransaction(this._transactionRepository, this._accountRepository);

  /// Logs a [transaction] and adjusts the account balance accordingly.
  ///
  /// - **Expense**: Deducts from the source account.
  /// - **Income**: Adds to the source account.
  /// - **Transfer**: Deducts from source, adds to destination.
  ///
  /// Throws [ArgumentError] if the referenced accounts don't exist.
  Future<Transaction> call(Transaction transaction) async {
    // Validate source account exists
    final sourceAccount = await _accountRepository.getById(
      transaction.accountId,
    );
    if (sourceAccount == null) {
      throw ArgumentError('Source account not found: ${transaction.accountId}');
    }

    switch (transaction.type) {
      case TransactionType.expense:
        // For credit card expenses: increase the liability (balance goes up).
        // For debit/cash expenses: decrease the balance.
        if (sourceAccount.isLiability) {
          await _accountRepository.updateBalance(
            sourceAccount.id,
            sourceAccount.balance + transaction.amount,
          );
        } else {
          await _accountRepository.updateBalance(
            sourceAccount.id,
            sourceAccount.balance - transaction.amount,
          );
        }

      case TransactionType.income:
        await _accountRepository.updateBalance(
          sourceAccount.id,
          sourceAccount.balance + transaction.amount,
        );

      case TransactionType.transfer:
        if (transaction.toAccountId == null) {
          throw ArgumentError('Transfer requires a destination account');
        }
        final destAccount = await _accountRepository.getById(
          transaction.toAccountId!,
        );
        if (destAccount == null) {
          throw ArgumentError(
            'Destination account not found: ${transaction.toAccountId}',
          );
        }

        // Deduct from source
        await _accountRepository.updateBalance(
          sourceAccount.id,
          sourceAccount.balance - transaction.amount,
        );
        // Add to destination
        await _accountRepository.updateBalance(
          destAccount.id,
          destAccount.balance + transaction.amount,
        );
    }

    return _transactionRepository.insert(transaction);
  }
}
