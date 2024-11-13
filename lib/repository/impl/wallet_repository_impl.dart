import 'package:sqflite/sqflite.dart';
import 'package:vent_expense_pro/models/wallet_model.dart';
import 'package:vent_expense_pro/repository/wallet_repository.dart';

class WalletRepositoryImpl implements WalletRepository {
  final Database _db;
  final String walletTable = "wallets";
  final String iconTable = "icons";

  WalletRepositoryImpl(this._db);

  @override
  Future<List<WalletModel>> getAllWallets() async {
    final List<Map<String, dynamic>> results = await _db.rawQuery('''
      SELECT wlt.wlt_id as wlt_id, wlt.wlt_name as wlt_name, wlt.wlt_balance as wlt_balance, 
            wlt.created_at as created_at, wlt.updated_at as updated_at, wlt.wlt_icon as wlt_icon,
            ics.icon_id as icon_id, ics.icon_code as icon_code, ics.icon_color as icon_color
      FROM $walletTable AS wlt
      LEFT JOIN $iconTable AS ics ON wlt.wlt_icon = ics.icon_id
    ''');

    return results.map((map) => WalletModel.fromMap(map)).toList();
  }

  @override
  Future<WalletModel?> getWallet(int id) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      'wallets',
      where: 'wlt_id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return WalletModel.fromMap(maps.first);
  }

  @override
  Future<int> createWallet(WalletModel wallet) async {
    return await _db.insert('wallet', wallet.toMap());
  }

  @override
  Future<int> updateWallet(WalletModel wallet) async {
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
