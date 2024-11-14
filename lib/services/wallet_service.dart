import 'package:vent_expense_pro/models/wallet_model.dart';
import 'package:vent_expense_pro/repositories/wallet_repository.dart';
import 'package:vent_expense_pro/commons/constants/constants.dart' as Constants;

class WalletService {
  final WalletRepository _repository;

  WalletService(this._repository);

  Future<List<WalletModel>> getAllWallets() async {
    try {
      return await _repository.getAllWallets();
    } catch (e) {
      throw Exception(Constants.FAILED_TO_GET_LIST_OF_WALLET);
    }
  }

  Future<WalletModel?> getWallet(int id) async {
    try {
      return await _repository.getWallet(id);
    } catch (e) {
      throw Exception(Constants.FAILED_TO_GET_WALLET);
    }
  }

  Future<bool> createWallet(WalletModel wallet) async {
    try {
      final id = await _repository.createWallet(wallet);
      return id > 0;
    } catch (e) {
      throw Exception(Constants.FAILED_TO_CREATE_WALLET);
    }
  }

  Future<bool> updateWallet(WalletModel wallet) async {
    try {
      final rowsAffected = await _repository.updateWallet(wallet);
      return rowsAffected > 0;
    } catch (e) {
      throw Exception(Constants.FAILED_TO_UPDATE_WALLET);
    }
  }

  Future<bool> deleteWallet(int id) async {
    try {
      final rowsAffected = await _repository.deleteWallet(id);
      return rowsAffected > 0;
    } catch (e) {
      throw Exception(Constants.FAILED_TO_DELETE_WALLET);
    }
  }
}
