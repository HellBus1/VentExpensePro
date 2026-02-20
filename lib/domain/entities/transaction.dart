import 'package:equatable/equatable.dart';

import 'enums.dart';

/// A single financial transaction logged in the ledger.
class Transaction extends Equatable {
  /// Unique identifier.
  final String id;

  /// Amount in the smallest currency unit (cents / sen).
  final int amount;

  /// Whether this is an expense, income, or transfer.
  final TransactionType type;

  /// Reference to the [Category] this transaction belongs to.
  final String categoryId;

  /// The primary account affected (source for expenses, target for income).
  final String accountId;

  /// For transfers / settlements: the destination account.
  final String? toAccountId;

  /// Optional user note.
  final String? note;

  /// Whether this transaction is a credit-card bill settlement.
  final bool isSettlement;

  /// When this transaction occurred.
  final DateTime dateTime;

  const Transaction({
    required this.id,
    required this.amount,
    required this.type,
    required this.categoryId,
    required this.accountId,
    this.toAccountId,
    this.note,
    this.isSettlement = false,
    required this.dateTime,
  });

  /// Returns a copy with the given fields replaced.
  Transaction copyWith({
    String? id,
    int? amount,
    TransactionType? type,
    String? categoryId,
    String? accountId,
    String? toAccountId,
    String? note,
    bool? isSettlement,
    DateTime? dateTime,
  }) {
    return Transaction(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      accountId: accountId ?? this.accountId,
      toAccountId: toAccountId ?? this.toAccountId,
      note: note ?? this.note,
      isSettlement: isSettlement ?? this.isSettlement,
      dateTime: dateTime ?? this.dateTime,
    );
  }

  @override
  List<Object?> get props => [
        id,
        amount,
        type,
        categoryId,
        accountId,
        toAccountId,
        note,
        isSettlement,
        dateTime,
      ];
}
