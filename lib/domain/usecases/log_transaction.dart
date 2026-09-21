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

    // ── Credit account restrictions ──
    // Credit cards can only have: expense (swipe), income (refund/cashback).
    // No transfers except settlements handled by SettleCreditBill.
    if (transaction.type == TransactionType.transfer &&
        !transaction.isSettlement) {
      if (sourceAccount.type == AccountType.credit) {
        throw ArgumentError(
          'Credit accounts cannot participate in transfers. '
          'Use the settlement flow to pay credit card bills.',
        );
      }

      if (transaction.toAccountId != null) {
        final destAccount = await _accountRepository.getById(
          transaction.toAccountId!,
        );
        if (destAccount != null && destAccount.type == AccountType.credit) {
          throw ArgumentError(
            'Cannot transfer to a credit account. '
            'Use the settlement flow to pay credit card bills.',
          );
        }
      }
    }

    switch (transaction.type) {
      case TransactionType.expense:
        // For credit card expenses: increase the liability (balance goes up).
        // For debit/cash/debt expenses: decrease the balance.
        if (sourceAccount.type == AccountType.credit) {
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
        // For credit accounts: income (refund/cashback) reduces the liability.
        // For other accounts: income increases balance.
        if (sourceAccount.type == AccountType.credit) {
          await _accountRepository.updateBalance(
            sourceAccount.id,
            sourceAccount.balance - transaction.amount,
          );
        } else {
          await _accountRepository.updateBalance(
            sourceAccount.id,
            sourceAccount.balance + transaction.amount,
          );
        }

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
        // Add to destination (or reduce liability if credit settlement)
        final newDestBalance =
            destAccount.type == AccountType.credit && transaction.isSettlement
                ? destAccount.balance - transaction.amount
                : destAccount.balance + transaction.amount;
        await _accountRepository.updateBalance(
          destAccount.id,
          newDestBalance,
        );
    }

    return _transactionRepository.insert(transaction);
  }
}
