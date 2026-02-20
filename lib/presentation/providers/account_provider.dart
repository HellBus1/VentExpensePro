import 'package:flutter/foundation.dart';

import '../../domain/entities/account.dart';
import '../../domain/entities/enums.dart';
import '../../domain/repositories/account_repository.dart';
import '../../domain/usecases/calculate_net_position.dart';
import '../../domain/usecases/manage_account.dart';

/// Manages account state and net position calculation.
class AccountProvider extends ChangeNotifier {
  final AccountRepository _accountRepository;
  final CalculateNetPosition _calculateNetPosition;
  final ManageAccount _manageAccount;

  AccountProvider(
    this._accountRepository,
    this._calculateNetPosition,
    this._manageAccount,
  );

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

  /// Returns an account by [id] from the in-memory list, or `null`.
  Account? getAccountById(String id) {
    try {
      return _accounts.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

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

  /// Creates a new account via the use case and refreshes the list.
  Future<void> addAccount({
    required String name,
    required AccountType type,
    required int balance,
    String currency = 'IDR',
  }) async {
    try {
      await _manageAccount.createAccount(
        name: name,
        type: type,
        balance: balance,
        currency: currency,
      );
      await loadAccounts();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Updates an account via the use case and refreshes the list.
  Future<void> updateAccount(Account account) async {
    try {
      await _manageAccount.updateAccount(account);
      await loadAccounts();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Archives an account via the use case and refreshes the list.
  Future<void> archiveAccount(String id) async {
    try {
      await _manageAccount.archiveAccount(id);
      await loadAccounts();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Restores an archived account and refreshes the list.
  Future<void> unarchiveAccount(String id) async {
    try {
      final account = await _accountRepository.getById(id);
      if (account != null) {
        await _accountRepository.update(account.copyWith(isArchived: false));
        await loadAccounts();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}
