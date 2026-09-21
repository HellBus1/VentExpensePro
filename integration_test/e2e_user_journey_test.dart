import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:vent_expense_pro/main.dart';

import 'test_helper.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await setupIntegrationTestEnvironment();
  });

  group('End-to-End Holistic User Journey Integration Test', () {
    testWidgets('Seamless cross-feature flow: accounts setup -> custom category -> income -> credit expense -> credit bill settlement -> personal debt -> partial repayment -> reports -> cloud backup', (tester) async {
      // 1. Launch application
      await tester.pumpWidget(const VentExpenseApp());
      await tester.pumpAndSettle();

      // 2. Setup Accounts: Checking Account + Credit Card
      await tester.tap(find.text('Accounts'));
      await tester.pumpAndSettle();

      final accountsFab = find.byKey(const ValueKey('accounts_fab'));

      // 2a. Add Bank Checking Account
      await tester.tap(accountsFab);
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('account_name_input')), 'Primary Bank');
      await tester.enterText(find.byKey(const ValueKey('account_balance_input')), '3000000');
      await tester.tap(find.byKey(const ValueKey('account_submit_button')));
      await tester.pumpAndSettle();

      // 2b. Add Credit Card
      await tester.tap(accountsFab);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('account_type_credit')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('account_name_input')), 'Gold Credit Card');
      await tester.enterText(find.byKey(const ValueKey('account_balance_input')), '500000');
      await tester.tap(find.byKey(const ValueKey('account_submit_button')));
      await tester.pumpAndSettle();

      expect(find.text('Primary Bank'), findsOneWidget);
      expect(find.text('Gold Credit Card'), findsOneWidget);

      // 3. Create Custom Category via Overflow Menu
      final overflowMenu = find.byKey(const ValueKey('app_bar_overflow_menu'));
      await tester.tap(overflowMenu);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('menu_categories')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('add_category_button')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('category_name_input')), 'Design Client');
      await tester.tap(find.byKey(const ValueKey('category_save_button')));
      await tester.pumpAndSettle();

      expect(find.text('Design Client'), findsOneWidget);

      // Dismiss categories modal
      Navigator.of(tester.element(find.text('Manage Categories'))).pop();
      await tester.pumpAndSettle();

      // 4. Log Income to Primary Bank using new custom category
      await tester.tap(find.text('Ledger'));
      await tester.pumpAndSettle();

      final mainFab = find.byKey(const ValueKey('main_fab_add_transaction'));
      await tester.tap(mainFab);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('txn_type_income')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Design Client'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Primary Bank'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('quick_add_amount_input')), '2500000');
      await tester.enterText(find.byKey(const ValueKey('quick_add_note_input')), 'Logo Design Milestone');
      await tester.tap(find.byKey(const ValueKey('quick_add_submit_button')));
      await tester.pumpAndSettle();

      expect(find.text('Logo Design Milestone'), findsOneWidget);

      // 5. Log Expense on Credit Card (Shopping)
      await tester.tap(mainFab);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Shopping'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Gold Credit Card'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('quick_add_amount_input')), '450000');
      await tester.enterText(find.byKey(const ValueKey('quick_add_note_input')), 'Hardware Tools');
      await tester.tap(find.byKey(const ValueKey('quick_add_submit_button')));
      await tester.pumpAndSettle();

      expect(find.text('Hardware Tools'), findsOneWidget);

      // 6. Settle Credit Card Bill via Accounts Screen
      await tester.tap(find.text('Accounts'));
      await tester.pumpAndSettle();

      final accountsListView = find.byKey(const PageStorageKey('accounts_list_view'));
      await tester.drag(accountsListView, const Offset(0, -150));
      await tester.pumpAndSettle();

      final payBillBtn = find.byKey(const ValueKey('account_pay_bill_btn_Gold Credit Card'));
      expect(payBillBtn, findsOneWidget);
      await tester.tap(payBillBtn);
      await tester.pumpAndSettle();

      expect(find.text('Pay Bill'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('pay_bill_settle_button')));
      await tester.pumpAndSettle();
      // Wait for floating SnackBar to dismiss so accountsFab is unobstructed
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();

      // 7. Add Personal Debt (Friend Diana owes 500,000)
      await tester.tap(accountsFab);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('account_type_debt')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('account_name_input')), 'Diana');
      await tester.tap(find.byKey(const ValueKey('debt_direction_they_owe_me')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('account_balance_input')), '500000');
      await tester.tap(find.byKey(const ValueKey('account_submit_button')));
      await tester.pumpAndSettle();

      await tester.drag(accountsListView, const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(find.text('Diana'), findsOneWidget);
      expect(find.text('OWES YOU'), findsWidgets);

      // 8. Settle Partial Debt (Diana repays 200,000)
      final dianaSettleBtn = find.byKey(const ValueKey('account_settle_debt_btn_Diana'));
      expect(dianaSettleBtn, findsOneWidget);
      await tester.tap(dianaSettleBtn);
      await tester.pumpAndSettle();

      expect(find.text('Receive Repayment'), findsOneWidget);
      await tester.enterText(find.byKey(const ValueKey('settle_debt_amount_input')), '200000');
      await tester.tap(find.byKey(const ValueKey('settle_debt_button')));
      await tester.pumpAndSettle();
      // Wait for floating SnackBar to dismiss
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();

      // 9. Check Reports and Generate PDF
      await tester.tap(find.text('Reports'));
      await tester.pumpAndSettle();

      expect(find.text('Professional Reports'), findsOneWidget);
      final reportsScrollView = find.byKey(const ValueKey('reports_scroll_view'));
      await tester.drag(reportsScrollView, const Offset(0, -300));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Generate PDF Statement'));
      await tester.pumpAndSettle();

      expect(find.text('Ready to Save!'), findsOneWidget);

      // 10. Open Backup & Sync and test Cloud Backup
      await tester.tap(overflowMenu);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('menu_backup_sync')));
      await tester.pumpAndSettle();

      expect(find.text('Sign in with Google'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('sync_signin_button')));
      await tester.pumpAndSettle();

      expect(find.text('test.user@gmail.com'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('sync_backup_button')));
      await tester.pumpAndSettle();

      expect(find.textContaining('Last backup: Just now'), findsOneWidget);
    });
  });
}
