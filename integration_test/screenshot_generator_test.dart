import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vent_expense_pro/core/di/service_locator.dart';
import 'package:vent_expense_pro/data/datasources/local_database.dart';
import 'package:vent_expense_pro/data/models/account_model.dart';
import 'package:vent_expense_pro/data/models/transaction_model.dart';
import 'package:vent_expense_pro/domain/entities/enums.dart';
import 'package:vent_expense_pro/domain/repositories/sync_repository.dart';
import 'package:vent_expense_pro/domain/usecases/sync_data.dart';
import 'package:vent_expense_pro/main.dart';

class _FakeSyncRepo implements SyncRepository {
  @override
  Future<String> signIn() async => 'syubban.fakhriya@gmail.com';

  @override
  Future<void> signOut() async {}

  @override
  Future<bool> isSignedIn() async => true;

  @override
  Future<String?> getSignedInEmail() async => 'syubban.fakhriya@gmail.com';

  @override
  Future<String?> getSignedInDisplayName() async => 'Syubban Fakhriya';

  @override
  Future<DateTime> backup() async => DateTime.now();

  @override
  Future<void> restore() async {}

  @override
  Future<DateTime?> getLastBackupTime() async =>
      DateTime.now().subtract(const Duration(minutes: 8));
}

Future<void> _notifyHost(String name) async {
  final ready = File('/sdcard/Download/$name.ready');
  final done = File('/sdcard/Download/$name.done');
  if (done.existsSync()) done.deleteSync();
  await ready.writeAsString('ready');

  // Wait until host signals done
  while (!done.existsSync()) {
    await Future.delayed(const Duration(milliseconds: 100));
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Generate Play Store screenshots and test process captures',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    sl.allowReassignment = true;

    if (!sl.isRegistered<SyncRepository>()) {
      await initServiceLocator();
    }
    sl.registerLazySingleton<SyncRepository>(() => _FakeSyncRepo());
    sl.registerFactory<SyncData>(() => SyncData(_FakeSyncRepo()));

    await LocalDatabase.resetForTesting();
    final db = await LocalDatabase.database;

    final now = DateTime.now();

    // 1. Seed Accounts
    final accounts = [
      AccountModel(
        id: 'acc_mandiri',
        name: 'Bank Mandiri',
        type: AccountType.debit,
        balance: 14500000,
        currency: 'IDR',
        createdAt: now.subtract(const Duration(days: 60)),
      ),
      AccountModel(
        id: 'acc_cash',
        name: 'Cash Wallet',
        type: AccountType.cash,
        balance: 1250000,
        currency: 'IDR',
        createdAt: now.subtract(const Duration(days: 60)),
      ),
      AccountModel(
        id: 'acc_bca_cc',
        name: 'BCA Everyday Card',
        type: AccountType.credit,
        balance: 1850000,
        statementCloseDay: 20,
        currency: 'IDR',
        createdAt: now.subtract(const Duration(days: 60)),
      ),
      AccountModel(
        id: 'acc_mandiri_cc',
        name: 'Mandiri Signature',
        type: AccountType.credit,
        balance: 3400000,
        statementCloseDay: 5,
        currency: 'IDR',
        createdAt: now.subtract(const Duration(days: 60)),
      ),
      AccountModel(
        id: 'acc_debt_alex',
        name: 'Alex Pratama',
        type: AccountType.debt,
        balance: 2500000,
        currency: 'IDR',
        createdAt: now.subtract(const Duration(days: 30)),
      ),
      AccountModel(
        id: 'acc_debt_budi',
        name: 'Budi Santoso',
        type: AccountType.debt,
        balance: -1000000,
        currency: 'IDR',
        createdAt: now.subtract(const Duration(days: 30)),
      ),
    ];

    for (final acc in accounts) {
      await db.insert('accounts', acc.toMap());
    }

    // 2. Seed Transactions
    final transactions = [
      TransactionModel(
        id: 't1',
        amount: 650000,
        type: TransactionType.expense,
        categoryId: 'food',
        accountId: 'acc_bca_cc',
        note: 'Team Dinner at Botanica',
        dateTime: now.subtract(const Duration(hours: 2)),
      ),
      TransactionModel(
        id: 't2',
        amount: 1200000,
        type: TransactionType.expense,
        categoryId: 'shopping',
        accountId: 'acc_bca_cc',
        note: 'Mechanical Keyboard',
        dateTime: now.subtract(const Duration(days: 1)),
      ),
      TransactionModel(
        id: 't3',
        amount: 2400000,
        type: TransactionType.expense,
        categoryId: 'transport',
        accountId: 'acc_mandiri_cc',
        note: 'Jakarta-Bali Roundtrip Flight',
        dateTime: now.subtract(const Duration(days: 2)),
      ),
      TransactionModel(
        id: 't4',
        amount: 850000,
        type: TransactionType.expense,
        categoryId: 'bills',
        accountId: 'acc_mandiri',
        note: 'Monthly Fiber Internet & Utilities',
        dateTime: now.subtract(const Duration(days: 3)),
      ),
      TransactionModel(
        id: 't5',
        amount: 8500000,
        type: TransactionType.income,
        categoryId: 'other',
        accountId: 'acc_mandiri',
        note: 'Freelance UI/UX Mobile App',
        dateTime: now.subtract(const Duration(days: 4)),
      ),
      TransactionModel(
        id: 't6',
        amount: 150000,
        type: TransactionType.expense,
        categoryId: 'food',
        accountId: 'acc_cash',
        note: 'Specialty Pour-over Coffee',
        dateTime: now.subtract(const Duration(days: 4)),
      ),
      TransactionModel(
        id: 't7',
        amount: 500000,
        type: TransactionType.transfer,
        categoryId: 'settlement',
        accountId: 'acc_debt_alex',
        toAccountId: 'acc_mandiri',
        note: 'Partial loan repayment from Alex',
        isSettlement: true,
        dateTime: now.subtract(const Duration(days: 5)),
      ),
    ];

    for (final txn in transactions) {
      await db.insert('transactions', txn.toMap());
    }

    // Launch App
    await tester.pumpWidget(const VentExpenseApp());
    await tester.pumpAndSettle();

    // -------------------------------------------------------------
    // Screen 1: Main Ledger with Credit Card Billing Carousel
    // -------------------------------------------------------------
    await tester.pumpAndSettle();
    await _notifyHost('01_ledger_main');

    // -------------------------------------------------------------
    // Screen 2: Transaction Filter Modal
    // -------------------------------------------------------------
    final filterBtn = find.byKey(const ValueKey('ledger_filter_button'));
    await tester.tap(filterBtn);
    await tester.pumpAndSettle();

    // Select Food category
    final foodFilterChip = find.text('Food').last;
    await tester.tap(foodFilterChip);
    await tester.pumpAndSettle();

    // Enter search text "Dinner"
    await tester.enterText(
        find.byKey(const ValueKey('filter_search_input')), 'Dinner');
    await tester.pumpAndSettle();

    // Dismiss keyboard
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();

    await _notifyHost('02_transaction_filter_modal');

    // -------------------------------------------------------------
    // Screen 3: Ledger with Active Filter Badges
    // -------------------------------------------------------------
    await tester.tap(find.byKey(const ValueKey('filter_apply_button')));
    await tester.pumpAndSettle();

    await _notifyHost('03_ledger_filtered');

    // Clear filters to restore full ledger
    final clearAllChip =
        find.byKey(const ValueKey('ledger_clear_all_filters_chip'));
    await tester.tap(clearAllChip);
    await tester.pumpAndSettle();

    // -------------------------------------------------------------
    // Screen 4: Accounts and Net Worth
    // -------------------------------------------------------------
    await tester.tap(find.text('Accounts'));
    await tester.pumpAndSettle();

    await _notifyHost('04_accounts_main');

    // -------------------------------------------------------------
    // Screen 5: Personal Debts Section (Scrolled)
    // -------------------------------------------------------------
    final accountsList = find.byType(Scrollable).last;
    await tester.drag(accountsList, const Offset(0, -380));
    await tester.pumpAndSettle();

    await _notifyHost('05_personal_debts');

    // -------------------------------------------------------------
    // Screen 6: Settle Debt Sheet
    // -------------------------------------------------------------
    final settleAlexBtn =
        find.byKey(const ValueKey('account_settle_debt_btn_Alex Pratama'));
    if (settleAlexBtn.evaluate().isNotEmpty) {
      await tester.ensureVisible(settleAlexBtn);
      await tester.pumpAndSettle();
      await tester.tap(settleAlexBtn);
      await tester.pumpAndSettle();

      await _notifyHost('06_settle_debt_sheet');

      // Dismiss settle sheet
      Navigator.of(tester.element(find.byType(Navigator).last)).pop();
      await tester.pumpAndSettle();
    }

    // -------------------------------------------------------------
    // Screen 7: Quick Add Transaction Sheet
    // -------------------------------------------------------------
    await tester.tap(find.text('Ledger'));
    await tester.pumpAndSettle();

    final mainFab = find.byKey(const ValueKey('main_fab_add_transaction'));
    await tester.tap(mainFab);
    await tester.pumpAndSettle();

    await _notifyHost('07_quick_add_transaction');

    // Dismiss quick add sheet
    Navigator.of(tester.element(find.byType(Navigator).last)).pop();
    await tester.pumpAndSettle();

    // -------------------------------------------------------------
    // Screen 8: Reports and Analytics
    // -------------------------------------------------------------
    await tester.tap(find.text('Reports'));
    await tester.pumpAndSettle();

    await _notifyHost('08_reports_analytics');
  });
}
