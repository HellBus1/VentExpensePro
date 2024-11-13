import 'package:vent_expense_pro/models/wallet.dart';
import 'package:vent_expense_pro/repository/wallet_repository.dart';

class WalletService {
  final WalletRepository _repository;

  WalletService(this._repository);

  Future<List<Wallet>> getAllWallets() async {
    return await _repository.getAllWallets();
  }

  Future<Wallet?> getWallet(int id) async {
    return await _repository.getWallet(id);
  }

  Future<bool> createWallet(Wallet wallet) async {
    final id = await _repository.createWallet(wallet);
    return id > 0;
  }

  Future<bool> updateWallet(Wallet wallet) async {
    final rowsAffected = await _repository.updateWallet(wallet);
    return rowsAffected > 0;
  }

  Future<bool> deleteWallet(int id) async {
    final rowsAffected = await _repository.deleteWallet(id);
    return rowsAffected > 0;
  }
}