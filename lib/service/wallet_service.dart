import 'package:vent_expense_pro/models/wallet_model.dart';
import 'package:vent_expense_pro/repository/wallet_repository.dart';

class WalletService {
  final WalletRepository _repository;

  WalletService(this._repository);

  Future<List<WalletModel>> getAllWallets() async {
    return await _repository.getAllWallets();
  }

  Future<WalletModel?> getWallet(int id) async {
    return await _repository.getWallet(id);
  }

  Future<bool> createWallet(WalletModel wallet) async {
    final id = await _repository.createWallet(wallet);
    return id > 0;
  }

  Future<bool> updateWallet(WalletModel wallet) async {
    final rowsAffected = await _repository.updateWallet(wallet);
    return rowsAffected > 0;
  }

  Future<bool> deleteWallet(int id) async {
    final rowsAffected = await _repository.deleteWallet(id);
    return rowsAffected > 0;
  }
}
