import 'package:flutter/foundation.dart';

import '../../domain/entities/account.dart';
import '../../domain/entities/enums.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/repositories/account_repository.dart';
import '../../domain/usecases/calculate_net_position.dart';
import '../../domain/usecases/manage_account.dart';
import '../../domain/usecases/settle_credit_bill.dart';
import '../../domain/usecases/settle_debt.dart';

/// Manages account state and net position calculation.
class AccountProvider extends ChangeNotifier {
  final AccountRepository _accountRepository;
  final CalculateNetPosition _calculateNetPosition;
  final ManageAccount _manageAccount;
  final SettleCreditBill _settleCreditBill;
  final SettleDebt _settleDebt;

  AccountProvider(
    this._accountRepository,
    this._calculateNetPosition,
    this._manageAccount,
    this._settleCreditBill,
    this._settleDebt,
  );

  List<Account> _accounts = [];
  NetPositionBreakdown? _breakdown;
  bool _isLoading = false;
  String? _error;

  // — Getters —

  List<Account> get accounts => _accounts;
  List<Account> get assetAccounts => _accounts.where((a) => a.isAsset).toList();
  List<Account> get liabilityAccounts =>
      _accounts.where((a) => a.isLiability).toList();
  List<Account> get creditAccounts =>
      _accounts.where((a) => a.type == AccountType.credit).toList();
  List<Account> get debtAccounts =>
      _accounts.where((a) => a.type == AccountType.debt).toList();

  /// Total amount others owe me (positive debt balances).
  int get totalReceivable => debtAccounts
      .where((a) => a.balance > 0)
      .fold(0, (sum, a) => sum + a.balance);

  /// Total amount I owe others (absolute value of negative debt balances).
  int get totalPayable => debtAccounts
      .where((a) => a.balance < 0)
      .fold(0, (sum, a) => sum + a.balance.abs());

  /// Net debt position.
  int get netDebtPosition => totalReceivable - totalPayable;

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
    int? statementCloseDay,
  }) async {
    try {
      await _manageAccount.createAccount(
        name: name,
        type: type,
        balance: balance,
        currency: currency,
        statementCloseDay: statementCloseDay,
      );
      await loadAccounts();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
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
      rethrow;
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

  /// Settles a credit card bill and refreshes the list.
  ///
  /// Returns the settlement [Transaction] on success, or `null` on failure.
  Future<Transaction?> settleBill({
    required String sourceAccountId,
    required String creditAccountId,
    required int amount,
  }) async {
    try {
      final txn = await _settleCreditBill.call(
        sourceAccountId: sourceAccountId,
        creditAccountId: creditAccountId,
        amount: amount,
      );
      await loadAccounts();
      return txn;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Settles a personal debt (either receiving repayment or paying back) and refreshes accounts.
  ///
  /// Returns the settlement [Transaction] on success, or `null` on failure.
  Future<Transaction?> settleDebt({
    required String debtAccountId,
    required String assetAccountId,
    required int amount,
  }) async {
    try {
      final txn = await _settleDebt.call(
        debtAccountId: debtAccountId,
        assetAccountId: assetAccountId,
        amount: amount,
      );
      await loadAccounts();
      return txn;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }
}
