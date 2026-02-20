import 'package:equatable/equatable.dart';

import 'enums.dart';

/// A financial account — either an asset (debit/cash) or liability (credit).
class Account extends Equatable {
  /// Unique identifier.
  final String id;

  /// User-facing name, e.g. "BCA Debit", "Cash Wallet".
  final String name;

  /// Whether this is a debit, cash, or credit account.
  final AccountType type;

  /// Current balance in the smallest currency unit (cents / sen).
  /// Positive for assets, positive for credit = amount owed.
  final int balance;

  /// ISO 4217 currency code, e.g. 'IDR', 'USD'.
  final String currency;

  /// Soft-deleted accounts are archived but retain history.
  final bool isArchived;

  /// When this account was created.
  final DateTime createdAt;

  const Account({
    required this.id,
    required this.name,
    required this.type,
    required this.balance,
    this.currency = 'IDR',
    this.isArchived = false,
    required this.createdAt,
  });

  /// Whether this account counts as an asset (debit / cash).
  bool get isAsset => type == AccountType.debit || type == AccountType.cash;

  /// Whether this account counts as a liability (credit).
  bool get isLiability => type == AccountType.credit;

  /// Returns a copy with the given fields replaced.
  Account copyWith({
    String? id,
    String? name,
    AccountType? type,
    int? balance,
    String? currency,
    bool? isArchived,
    DateTime? createdAt,
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      balance: balance ?? this.balance,
      currency: currency ?? this.currency,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        type,
        balance,
        currency,
        isArchived,
        createdAt,
      ];
}
