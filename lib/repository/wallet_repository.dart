import 'package:vent_expense_pro/models/wallet_model.dart';

abstract class WalletRepository {
  Future<List<WalletModel>> getAllWallets();
  Future<WalletModel?> getWallet(int id);
  Future<int> createWallet(WalletModel wallet);
  Future<int> updateWallet(WalletModel wallet);
  Future<int> deleteWallet(int id);
}
