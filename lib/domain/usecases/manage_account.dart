import 'package:uuid/uuid.dart';

import '../entities/account.dart';
import '../entities/enums.dart';
import '../repositories/account_repository.dart';

/// Encapsulates account CRUD operations with validation.
class ManageAccount {
  final AccountRepository _accountRepository;
  final Uuid _uuid;

  ManageAccount(this._accountRepository, {Uuid? uuid})
    : _uuid = uuid ?? const Uuid();

  /// Creates a new account after validation.
  ///
  /// - [name] must not be empty.
  /// - [balance] must be ≥ 0.
  /// - Generates a UUID and sets `createdAt` to now.
  Future<Account> createAccount({
    required String name,
    required AccountType type,
    required int balance,
    String currency = 'IDR',
    int? statementCloseDay,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError('Account name must not be empty');
    }
    if (type != AccountType.debt && balance < 0) {
      throw ArgumentError('Initial balance must not be negative');
    }
    if (statementCloseDay != null &&
        (statementCloseDay < 1 || statementCloseDay > 28)) {
      throw ArgumentError('Statement close day must be between 1 and 28');
    }

    final account = Account(
      id: _uuid.v4(),
      name: trimmedName,
      type: type,
      balance: balance,
      currency: currency,
      createdAt: DateTime.now(),
      statementCloseDay: type == AccountType.credit ? statementCloseDay : null,
    );

    return _accountRepository.insert(account);
  }

  /// Updates an existing account after validation.
  ///
  /// - [account.name] must not be empty.
  Future<Account> updateAccount(Account account) async {
    if (account.name.trim().isEmpty) {
      throw ArgumentError('Account name must not be empty');
    }

    return _accountRepository.update(
      account.copyWith(name: account.name.trim()),
    );
  }

  /// Archives (soft-deletes) an account by [id].
  Future<void> archiveAccount(String id) async {
    final account = await _accountRepository.getById(id);
    if (account == null) {
      throw ArgumentError('Account not found: $id');
    }
    return _accountRepository.archive(id);
  }
}
