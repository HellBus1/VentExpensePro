import 'package:vent_expense_pro/models/wallet.dart';

abstract class WalletRepository {
  Future<List<Wallet>> getAllWallets();
  Future<Wallet?> getWallet(int id);
  Future<int> createWallet(Wallet wallet);
  Future<int> updateWallet(Wallet wallet);
  Future<int> deleteWallet(int id);
}