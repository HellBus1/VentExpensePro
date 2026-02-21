import '../../domain/entities/account.dart';
import '../../domain/entities/enums.dart';
import '../../domain/repositories/account_repository.dart';
import '../datasources/local_database.dart';
import '../models/account_model.dart';

/// Concrete [AccountRepository] backed by local SQLite.
class AccountRepositoryImpl implements AccountRepository {
  @override
  Future<List<Account>> getAll() async {
    final db = await LocalDatabase.database;
    final maps = await db.query(
      'accounts',
      where: 'is_archived = ?',
      whereArgs: [0],
      orderBy: 'created_at DESC',
    );
    return maps.map(AccountModel.fromMap).toList();
  }

  @override
  Future<List<Account>> getByType(AccountType type) async {
    final db = await LocalDatabase.database;
    final maps = await db.query(
      'accounts',
      where: 'type = ? AND is_archived = ?',
      whereArgs: [type.index, 0],
      orderBy: 'created_at DESC',
    );
    return maps.map(AccountModel.fromMap).toList();
  }

  @override
  Future<Account?> getById(String id) async {
    final db = await LocalDatabase.database;
    final maps = await db.query(
      'accounts',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return AccountModel.fromMap(maps.first);
  }

  @override
  Future<Account> insert(Account account) async {
    final db = await LocalDatabase.database;
    final model = AccountModel.fromEntity(account);
    await db.insert('accounts', model.toMap());
    return model;
  }

  @override
  Future<Account> update(Account account) async {
    final db = await LocalDatabase.database;
    final model = AccountModel.fromEntity(account);
    await db.update(
      'accounts',
      model.toMap(),
      where: 'id = ?',
      whereArgs: [account.id],
    );
    return model;
  }

  @override
  Future<void> archive(String id) async {
    final db = await LocalDatabase.database;
    await db.update(
      'accounts',
      {'is_archived': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> updateBalance(String id, int newBalance) async {
    final db = await LocalDatabase.database;
    await db.update(
      'accounts',
      {'balance': newBalance},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
