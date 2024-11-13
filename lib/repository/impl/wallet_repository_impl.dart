import 'package:sqflite/sqflite.dart';
import 'package:vent_expense_pro/models/wallet.dart';
import 'package:vent_expense_pro/repository/wallet_repository.dart';

class WalletRepositoryImpl implements WalletRepository {
  final Database _db;

  WalletRepositoryImpl(this._db);

  @override
  Future<List<Wallet>> getAllWallets() async {
    final List<Map<String, dynamic>> maps = await _db.query('wallets');
    return List.generate(maps.length, (i) => Wallet.fromMap(maps[i]));
  }

  @override
  Future<Wallet?> getWallet(int id) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      'wallets',
      where: 'wlt_id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Wallet.fromMap(maps.first);
  }

  @override
  Future<int> createWallet(Wallet wallet) async {
    return await _db.insert('wallet', wallet.toMap());
  }

  @override
  Future<int> updateWallet(Wallet wallet) async {
    return await _db.update(
      'wallets',
      wallet.toMap(),
      where: 'wlt_id = ?',
      whereArgs: [wallet.id],
    );
  }

  @override
  Future<int> deleteWallet(int id) async {
    return await _db.delete(
      'wallets',
      where: 'wlt_id = ?',
      whereArgs: [id],
    );
  }
}