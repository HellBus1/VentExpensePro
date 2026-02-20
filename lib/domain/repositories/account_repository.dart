import '../entities/account.dart';
import '../entities/enums.dart';

/// Contract for account persistence operations.
abstract class AccountRepository {
  /// Returns all non-archived accounts.
  Future<List<Account>> getAll();

  /// Returns all accounts of the given [type].
  Future<List<Account>> getByType(AccountType type);

  /// Returns a single account by [id], or `null` if not found.
  Future<Account?> getById(String id);

  /// Inserts a new account. Returns the inserted account.
  Future<Account> insert(Account account);

  /// Updates an existing account. Returns the updated account.
  Future<Account> update(Account account);

  /// Soft-deletes (archives) an account by [id].
  Future<void> archive(String id);

  /// Updates just the balance of a given account.
  Future<void> updateBalance(String id, int newBalance);
}
