import 'package:flutter/foundation.dart';

import '../../domain/entities/account.dart';
import '../../domain/repositories/account_repository.dart';
import '../../domain/usecases/calculate_net_position.dart';

/// Manages account state and net position calculation.
class AccountProvider extends ChangeNotifier {
  final AccountRepository _accountRepository;
  final CalculateNetPosition _calculateNetPosition;

  AccountProvider(this._accountRepository, this._calculateNetPosition);

  List<Account> _accounts = [];
  NetPositionBreakdown? _breakdown;
  bool _isLoading = false;
  String? _error;

  // — Getters —

  List<Account> get accounts => _accounts;
  List<Account> get assetAccounts =>
      _accounts.where((a) => a.isAsset).toList();
  List<Account> get liabilityAccounts =>
      _accounts.where((a) => a.isLiability).toList();
  NetPositionBreakdown? get breakdown => _breakdown;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // — Actions —

  /// Loads all accounts and recalculates net position.
  Future<void> loadAccounts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _accounts = await _accountRepository.getAll();
      _breakdown = await _calculateNetPosition.breakdown();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Adds a new account and refreshes the list.
  Future<void> addAccount(Account account) async {
    try {
      await _accountRepository.insert(account);
      await loadAccounts();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Updates an account and refreshes the list.
  Future<void> updateAccount(Account account) async {
    try {
      await _accountRepository.update(account);
      await loadAccounts();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Archives an account and refreshes the list.
  Future<void> archiveAccount(String id) async {
    try {
      await _accountRepository.archive(id);
      await loadAccounts();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}
