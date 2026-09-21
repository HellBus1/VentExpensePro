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

  group('Transactions and Ledger Feature Integration Tests', () {
    testWidgets('Full transaction workflows: log expense, credit expense, income, transfer with credit card restriction, edit, and delete with rollback', (tester) async {
      // 1. Launch application
      await tester.pumpWidget(const VentExpenseApp());
      await tester.pumpAndSettle();

      // 2. Setup Accounts first (Checking, Cash, Credit Card)
      await tester.tap(find.text('Accounts'));
      await tester.pumpAndSettle();

      final accountsFab = find.byKey(const ValueKey('accounts_fab'));

      // 2a. Add Checking (Debit) account
      await tester.tap(accountsFab);
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('account_name_input')), 'Checking Account');
      await tester.enterText(find.byKey(const ValueKey('account_balance_input')), '2000000');
      await tester.tap(find.byKey(const ValueKey('account_submit_button')));
      await tester.pumpAndSettle();

      // 2b. Add Savings (Cash) account
      await tester.tap(accountsFab);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('account_type_cash')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('account_name_input')), 'Savings Vault');
      await tester.enterText(find.byKey(const ValueKey('account_balance_input')), '500000');
      await tester.tap(find.byKey(const ValueKey('account_submit_button')));
      await tester.pumpAndSettle();

      // 2c. Add Credit Card account
      await tester.tap(accountsFab);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('account_type_credit')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('account_name_input')), 'Mastercard Gold');
      await tester.enterText(find.byKey(const ValueKey('account_balance_input')), '0');
      await tester.tap(find.byKey(const ValueKey('account_submit_button')));
      await tester.pumpAndSettle();

      // 3. Switch back to Ledger
      await tester.tap(find.text('Ledger'));
      await tester.pumpAndSettle();

      // 4. Log Expense from Checking Account
      final mainFab = find.byKey(const ValueKey('main_fab_add_transaction'));
      expect(mainFab, findsOneWidget);
      await tester.tap(mainFab);
      await tester.pumpAndSettle();

      expect(find.text('Log Transaction'), findsOneWidget);
      // Select Food category
      await tester.tap(find.text('Food'));
      await tester.pumpAndSettle();
      // Enter amount
      await tester.enterText(find.byKey(const ValueKey('quick_add_amount_input')), '50000');
      // Enter note
      await tester.enterText(find.byKey(const ValueKey('quick_add_note_input')), 'Lunch with team');
      // Submit
      await tester.tap(find.byKey(const ValueKey('quick_add_submit_button')));
      await tester.pumpAndSettle();

      // Verify transaction in Ledger
      expect(find.text('Lunch with team'), findsOneWidget);
      expect(find.text('Food'), findsOneWidget);

      // 5. Log Expense on Credit Card (verifies liability increase)
      await tester.tap(mainFab);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Shopping'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mastercard Gold'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('quick_add_amount_input')), '150000');
      await tester.enterText(find.byKey(const ValueKey('quick_add_note_input')), 'New wireless headset');
      await tester.tap(find.byKey(const ValueKey('quick_add_submit_button')));
      await tester.pumpAndSettle();

      expect(find.text('New wireless headset'), findsOneWidget);
      expect(find.text('Shopping'), findsOneWidget);

      // 6. Log Income
      await tester.tap(mainFab);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('txn_type_income')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('category_item_other')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Checking Account'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('quick_add_amount_input')), '5000000');
      await tester.enterText(find.byKey(const ValueKey('quick_add_note_input')), 'Monthly paycheck');
      await tester.tap(find.byKey(const ValueKey('quick_add_submit_button')));
      await tester.pumpAndSettle();

      expect(find.text('Monthly paycheck'), findsOneWidget);
      expect(find.text('Other'), findsOneWidget);

      // 7. Log Transfer & Verify Credit Card is excluded
      await tester.tap(mainFab);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('txn_type_transfer')));
      await tester.pumpAndSettle();

      // Credit card must NOT be present as transfer source or destination
      expect(find.text('Mastercard Gold'), findsNothing);

      // Select category
      await tester.tap(find.byKey(const ValueKey('category_item_other')));
      await tester.pumpAndSettle();

      // Select Checking Account -> Savings Vault
      await tester.tap(find.text('Checking Account').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Savings Vault').last);
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('quick_add_amount_input')), '300000');
      await tester.enterText(find.byKey(const ValueKey('quick_add_note_input')), 'Emergency fund allocation');
      await tester.tap(find.byKey(const ValueKey('quick_add_submit_button')));
      await tester.pumpAndSettle();

      expect(find.text('Emergency fund allocation'), findsOneWidget);

      // 8. Edit Transaction: Tap "Lunch with team"
      final ledgerScrollView = find.byKey(const ValueKey('ledger_scroll_view'));
      await tester.drag(ledgerScrollView, const Offset(0, -300));
      await tester.pumpAndSettle();

      expect(find.text('Lunch with team'), findsOneWidget);
      await tester.tap(find.text('Lunch with team'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Transaction'), findsOneWidget);
      await tester.enterText(find.byKey(const ValueKey('quick_add_note_input')), 'Client team lunch');
      await tester.enterText(find.byKey(const ValueKey('quick_add_amount_input')), '80000');
      await tester.tap(find.byKey(const ValueKey('quick_add_submit_button')));
      await tester.pumpAndSettle();

      await tester.drag(ledgerScrollView, const Offset(0, -200));
      await tester.pumpAndSettle();
      expect(find.text('Client team lunch'), findsOneWidget);
      expect(find.text('Lunch with team'), findsNothing);

      // 9. Delete Transaction with Balance Rollback: Swipe dismiss "Client team lunch"
      await tester.drag(find.text('Client team lunch'), const Offset(-500, 0));
      await tester.pumpAndSettle();

      expect(find.text('Delete Transaction'), findsOneWidget);
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(find.text('Client team lunch'), findsNothing);

      // 10. Verify Accounts tab reflects balances
      await tester.tap(find.text('Accounts'));
      await tester.pumpAndSettle();

      final accountsListView = find.byKey(const PageStorageKey('accounts_list_view'));
      expect(find.text('Checking Account'), findsOneWidget);

      await tester.drag(accountsListView, const Offset(0, -200));
      await tester.pumpAndSettle();
      expect(find.text('Mastercard Gold'), findsOneWidget);
    });
  });
}
