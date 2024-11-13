import 'package:flutter/material.dart';
import 'package:vent_expense_pro/models/wallet_model.dart';
import 'package:vent_expense_pro/service/wallet_service.dart';

class WalletProvider extends ChangeNotifier {
  final WalletService _walletService;
  List<WalletModel> _wallets = [];
  bool _isLoading = false;
  String? _errorMessage;

  WalletProvider(this._walletService);

  List<WalletModel> get wallets => _wallets;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void setErrorMessage(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  Future<void> loadWallets() async {
    _isLoading = true;
    notifyListeners();

    try {
      _wallets = await _walletService.getAllWallets();
      setErrorMessage(null);
    } catch (e) {
      setErrorMessage(e.toString());
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addWallet(WalletModel wallet) async {
    try {
      final success = await _walletService.createWallet(wallet);
      if (success) {
        await loadWallets();
      }
      return success;
    } catch (e) {
      setErrorMessage(e.toString());
      return false;
    }
  }

  Future<bool> updateWallet(WalletModel wallet) async {
    try {
      final success = await _walletService.updateWallet(wallet);
      if (success) {
        await loadWallets();
      }
      return success;
    } catch (e) {
      setErrorMessage(e.toString());
      return false;
    }
  }

  Future<bool> deleteWallet(int id) async {
    try {
      final success = await _walletService.deleteWallet(id);
      if (success) {
        await loadWallets();
      }
      return success;
    } catch (e) {
      setErrorMessage(e.toString());
      return false;
    }
  }
}
