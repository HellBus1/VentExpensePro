import 'package:uuid/uuid.dart';

import '../entities/enums.dart';
import '../entities/transaction.dart';
import '../repositories/account_repository.dart';
import '../repositories/transaction_repository.dart';

/// One-touch credit card bill settlement.
///
/// Transfers funds from a debit/cash account to a credit account,
/// reducing the credit liability and deducting from the asset.
class SettleCreditBill {
  final TransactionRepository _transactionRepository;
  final AccountRepository _accountRepository;
  final Uuid _uuid;

  SettleCreditBill(
    this._transactionRepository,
    this._accountRepository, {
    Uuid? uuid,
  }) : _uuid = uuid ?? const Uuid();

  /// Settles [amount] (in cents) from [sourceAccountId] to [creditAccountId].
  ///
  /// - The source account must be debit or cash (an asset).
  /// - The credit account must be a credit card (a liability).
  /// - [amount] must be > 0 and ≤ source account balance.
  ///
  /// Returns the settlement transaction.
  Future<Transaction> call({
    required String sourceAccountId,
    required String creditAccountId,
    required int amount,
  }) async {
    if (amount <= 0) {
      throw ArgumentError('Settlement amount must be positive');
    }

    final source = await _accountRepository.getById(sourceAccountId);
    if (source == null) {
      throw ArgumentError('Source account not found: $sourceAccountId');
    }
    if (!source.isAsset) {
      throw ArgumentError('Source must be a debit or cash account');
    }

    final credit = await _accountRepository.getById(creditAccountId);
    if (credit == null) {
      throw ArgumentError('Credit account not found: $creditAccountId');
    }
    if (!credit.isLiability) {
      throw ArgumentError('Target must be a credit account');
    }

    if (amount > source.balance) {
      throw ArgumentError(
        'Insufficient balance: have ${source.balance}, need $amount',
      );
    }

    // Deduct from asset
    await _accountRepository.updateBalance(source.id, source.balance - amount);

    // Reduce credit liability
    await _accountRepository.updateBalance(credit.id, credit.balance - amount);

    // Log as a settlement transfer
    final settlement = Transaction(
      id: _uuid.v4(),
      amount: amount,
      type: TransactionType.transfer,
      categoryId: 'settlement',
      accountId: sourceAccountId,
      toAccountId: creditAccountId,
      note: 'Bill payment: ${source.name} → ${credit.name}',
      isSettlement: true,
      dateTime: DateTime.now(),
    );

    return _transactionRepository.insert(settlement);
  }
}
