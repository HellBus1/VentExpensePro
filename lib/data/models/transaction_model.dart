import '../../domain/entities/enums.dart';
import '../../domain/entities/transaction.dart';

/// SQLite-compatible model for [Transaction].
class TransactionModel extends Transaction {
  const TransactionModel({
    required super.id,
    required super.amount,
    required super.type,
    required super.categoryId,
    required super.accountId,
    super.toAccountId,
    super.note,
    super.isSettlement,
    required super.dateTime,
  });

  /// Creates a [TransactionModel] from a SQLite row map.
  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as String,
      amount: map['amount'] as int,
      type: TransactionType.values[map['type'] as int],
      categoryId: map['category_id'] as String,
      accountId: map['account_id'] as String,
      toAccountId: map['to_account_id'] as String?,
      note: map['note'] as String?,
      isSettlement: (map['is_settlement'] as int) == 1,
      dateTime: DateTime.fromMillisecondsSinceEpoch(map['date_time'] as int),
    );
  }

  /// Creates a [TransactionModel] from a domain [Transaction].
  factory TransactionModel.fromEntity(Transaction transaction) {
    return TransactionModel(
      id: transaction.id,
      amount: transaction.amount,
      type: transaction.type,
      categoryId: transaction.categoryId,
      accountId: transaction.accountId,
      toAccountId: transaction.toAccountId,
      note: transaction.note,
      isSettlement: transaction.isSettlement,
      dateTime: transaction.dateTime,
    );
  }

  /// Converts this model to a SQLite row map.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'type': type.index,
      'category_id': categoryId,
      'account_id': accountId,
      'to_account_id': toAccountId,
      'note': note,
      'is_settlement': isSettlement ? 1 : 0,
      'date_time': dateTime.millisecondsSinceEpoch,
    };
  }
}
