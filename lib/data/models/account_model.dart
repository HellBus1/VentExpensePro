import '../../domain/entities/account.dart';
import '../../domain/entities/enums.dart';

/// SQLite-compatible model for [Account].
class AccountModel extends Account {
  const AccountModel({
    required super.id,
    required super.name,
    required super.type,
    required super.balance,
    super.currency,
    super.isArchived,
    required super.createdAt,
  });

  /// Creates an [AccountModel] from a SQLite row map.
  factory AccountModel.fromMap(Map<String, dynamic> map) {
    return AccountModel(
      id: map['id'] as String,
      name: map['name'] as String,
      type: AccountType.values[map['type'] as int],
      balance: map['balance'] as int,
      currency: (map['currency'] as String?) ?? 'IDR',
      isArchived: (map['is_archived'] as int) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }

  /// Creates an [AccountModel] from a domain [Account].
  factory AccountModel.fromEntity(Account account) {
    return AccountModel(
      id: account.id,
      name: account.name,
      type: account.type,
      balance: account.balance,
      currency: account.currency,
      isArchived: account.isArchived,
      createdAt: account.createdAt,
    );
  }

  /// Converts this model to a SQLite row map.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.index,
      'balance': balance,
      'currency': currency,
      'is_archived': isArchived ? 1 : 0,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }
}
