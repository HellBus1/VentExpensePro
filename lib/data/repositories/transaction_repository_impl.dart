import '../../domain/entities/transaction.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../datasources/local_database.dart';
import '../models/transaction_model.dart';

/// Concrete [TransactionRepository] backed by local SQLite.
class TransactionRepositoryImpl implements TransactionRepository {
  @override
  Future<List<Transaction>> getAll() async {
    final db = await LocalDatabase.database;
    final maps = await db.query(
      'transactions',
      orderBy: 'date_time DESC',
    );
    return maps.map(TransactionModel.fromMap).toList();
  }

  @override
  Future<List<Transaction>> getByAccount(String accountId) async {
    final db = await LocalDatabase.database;
    final maps = await db.query(
      'transactions',
      where: 'account_id = ? OR to_account_id = ?',
      whereArgs: [accountId, accountId],
      orderBy: 'date_time DESC',
    );
    return maps.map(TransactionModel.fromMap).toList();
  }

  @override
  Future<List<Transaction>> getByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final db = await LocalDatabase.database;
    final maps = await db.query(
      'transactions',
      where: 'date_time >= ? AND date_time <= ?',
      whereArgs: [
        start.millisecondsSinceEpoch,
        end.millisecondsSinceEpoch,
      ],
      orderBy: 'date_time DESC',
    );
    return maps.map(TransactionModel.fromMap).toList();
  }

  @override
  Future<Transaction?> getById(String id) async {
    final db = await LocalDatabase.database;
    final maps = await db.query(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return TransactionModel.fromMap(maps.first);
  }

  @override
  Future<Transaction> insert(Transaction transaction) async {
    final db = await LocalDatabase.database;
    final model = TransactionModel.fromEntity(transaction);
    await db.insert('transactions', model.toMap());
    return model;
  }

  @override
  Future<Transaction> update(Transaction transaction) async {
    final db = await LocalDatabase.database;
    final model = TransactionModel.fromEntity(transaction);
    await db.update(
      'transactions',
      model.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
    return model;
  }

  @override
  Future<void> delete(String id) async {
    final db = await LocalDatabase.database;
    await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
