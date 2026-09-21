import 'package:uuid/uuid.dart';

import '../entities/enums.dart';
import '../entities/transaction.dart';
import '../repositories/account_repository.dart';
import '../repositories/transaction_repository.dart';

/// Settles a personal debt — either receiving repayment or paying back.
///
/// Automatically determines direction based on the debt account's balance:
/// - Positive balance (they owe me) → money flows FROM debt TO my asset account.
/// - Negative balance (I owe them) → money flows FROM my asset account TO debt.
class SettleDebt {
  final TransactionRepository _transactionRepository;
  final AccountRepository _accountRepository;
  final Uuid _uuid;

  SettleDebt(this._transactionRepository, this._accountRepository, {Uuid? uuid})
      : _uuid = uuid ?? const Uuid();

  /// Settles [amount] (in cents/sen) between [debtAccountId] and [assetAccountId].
  ///
  /// - [debtAccountId] must be a debt-type account.
  /// - [assetAccountId] must be a debit or cash account.
  /// - [amount] must be > 0 and ≤ absolute value of debt balance.
  Future<Transaction> call({
    required String debtAccountId,
    required String assetAccountId,
    required int amount,
  }) async {
    if (amount <= 0) {
      throw ArgumentError('Amount must be positive');
    }

    final debtAccount = await _accountRepository.getById(debtAccountId);
    if (debtAccount == null) {
      throw ArgumentError('Debt account not found: $debtAccountId');
    }
    if (!debtAccount.isDebt) {
      throw ArgumentError('Not a debt account: ${debtAccount.name}');
    }
    if (debtAccount.balance == 0) {
      throw ArgumentError('Debt is already fully settled');
    }

    final assetAccount = await _accountRepository.getById(assetAccountId);
    if (assetAccount == null) {
      throw ArgumentError('Asset account not found: $assetAccountId');
    }
    if (assetAccount.type != AccountType.debit &&
        assetAccount.type != AccountType.cash) {
      throw ArgumentError('Must settle using a debit or cash account');
    }

    if (amount > debtAccount.balance.abs()) {
      throw ArgumentError(
        'Settlement amount ($amount) exceeds outstanding debt (${debtAccount.balance.abs()})',
      );
    }

    String sourceId;
    String destId;

    if (debtAccount.balance > 0) {
      // They owe me (piutang) → they pay me: debt account → my asset account
      sourceId = debtAccountId;
      destId = assetAccountId;

      // Reduce debt balance (closer to 0), increase my cash/bank
      await _accountRepository.updateBalance(
        debtAccountId,
        debtAccount.balance - amount,
      );
      await _accountRepository.updateBalance(
        assetAccountId,
        assetAccount.balance + amount,
      );
    } else {
      // I owe them (hutang) → I pay them: my asset account → debt account
      if (amount > assetAccount.balance) {
        throw ArgumentError(
          'Insufficient balance in ${assetAccount.name} to settle debt',
        );
      }
      sourceId = assetAccountId;
      destId = debtAccountId;

      // Deduct from my cash/bank, increase debt balance (closer to 0)
      await _accountRepository.updateBalance(
        assetAccountId,
        assetAccount.balance - amount,
      );
      await _accountRepository.updateBalance(
        debtAccountId,
        debtAccount.balance + amount,
      );
    }

    final settlement = Transaction(
      id: _uuid.v4(),
      amount: amount,
      type: TransactionType.transfer,
      categoryId: 'settlement',
      accountId: sourceId,
      toAccountId: destId,
      note: 'Debt settlement: ${debtAccount.name}',
      isSettlement: true,
      dateTime: DateTime.now(),
    );

    return _transactionRepository.insert(settlement);
  }
}
