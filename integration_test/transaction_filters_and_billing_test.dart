import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:vent_expense_pro/main.dart';

import 'test_helper.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Transaction Filters and Credit Card Billing Cycle Integration Tests', () {
    setUp(() async {
      await setupIntegrationTestEnvironment();
    });

    testWidgets(
        'Verify credit billing summary cards, filter modal, active filter chips, and dismissal',
        (tester) async {
      await tester.pumpWidget(const VentExpenseApp());
      await tester.pumpAndSettle();

      // 1. Navigate to Accounts and add a Credit Card with statementCloseDay = 20
      await tester.tap(find.text('Accounts'));
      await tester.pumpAndSettle();

      final accountsFab = find.byKey(const ValueKey('accounts_fab'));
      await tester.tap(accountsFab);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('account_type_credit')));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const ValueKey('account_name_input')), 'Platinum Credit Card');
      await tester.enterText(
          find.byKey(const ValueKey('account_balance_input')), '0');

      // Pick statement close day 1
      final closeDayDropdown =
          find.byKey(const ValueKey('statement_close_day_dropdown'));
      await tester.ensureVisible(closeDayDropdown);
      await tester.pumpAndSettle();
      await tester.tap(closeDayDropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('1st of each month').last);
      await tester.pumpAndSettle();

      final accountSubmitBtn = find.byKey(const ValueKey('account_submit_button'));
      await tester.ensureVisible(accountSubmitBtn);
      await tester.pumpAndSettle();
      await tester.tap(accountSubmitBtn);
      await tester.pumpAndSettle();

      expect(find.text('Platinum Credit Card'), findsOneWidget);

      // 1b. Add Cash Wallet account
      await tester.tap(accountsFab);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('account_type_cash')));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byKey(const ValueKey('account_name_input')), 'Cash Wallet');
      await tester.enterText(
          find.byKey(const ValueKey('account_balance_input')), '500000');
      await tester.tap(find.byKey(const ValueKey('account_submit_button')));
      await tester.pumpAndSettle();

      expect(find.text('Cash Wallet'), findsOneWidget);

      // 2. Return to Ledger
      await tester.tap(find.text('Ledger'));
      await tester.pumpAndSettle();

      // 3. Log a Credit Card expense: 150,000 for "Team Dinner"
      final mainFab = find.byKey(const ValueKey('main_fab_add_transaction'));
      await tester.tap(mainFab);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Food').last);
      await tester.pumpAndSettle();

      final platinumChip = find.text('Platinum Credit Card').last;
      await tester.ensureVisible(platinumChip);
      await tester.pumpAndSettle();
      await tester.tap(platinumChip);
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const ValueKey('quick_add_amount_input')), '150000');
      await tester.enterText(
          find.byKey(const ValueKey('quick_add_note_input')), 'Team Dinner');

      // Dismiss soft keyboard
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();

      final quickSubmit1 = find.byKey(const ValueKey('quick_add_submit_button'));
      await tester.ensureVisible(quickSubmit1);
      await tester.pumpAndSettle();
      await tester.tap(quickSubmit1);
      await tester.pumpAndSettle();

      // 4. Log a Cash/Debit expense: 50,000 for "Morning Coffee"
      await tester.tap(mainFab);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Food').last);
      await tester.pumpAndSettle();

      final cashChip = find.text('Cash Wallet').last;
      await tester.ensureVisible(cashChip);
      await tester.pumpAndSettle();
      await tester.tap(cashChip);
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const ValueKey('quick_add_amount_input')), '50000');
      await tester.enterText(
          find.byKey(const ValueKey('quick_add_note_input')), 'Morning Coffee');

      // Dismiss soft keyboard
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();

      final quickSubmit2 = find.byKey(const ValueKey('quick_add_submit_button'));
      await tester.ensureVisible(quickSubmit2);
      await tester.pumpAndSettle();
      await tester.tap(quickSubmit2);
      await tester.pumpAndSettle();

      // 5. Verify Billing Summary Carousel shows Platinum Credit Card
      expect(find.text('Platinum Credit Card'), findsOneWidget);
      expect(find.text('Closes 1st'), findsOneWidget);
      expect(find.text('UNBILLED (Current)'), findsOneWidget);
      expect(find.textContaining('150.000'), findsWidgets);

      // 6. Tap the Ledger Filter button
      final filterBtn = find.byKey(const ValueKey('ledger_filter_button'));
      expect(filterBtn, findsOneWidget);
      await tester.tap(filterBtn);
      await tester.pumpAndSettle();

      // 7. Verify TransactionFilterScreen opens
      expect(find.text('Filter Transactions'), findsOneWidget);
      expect(find.text('2 of 2 matches'), findsOneWidget);

      // Type search text: "Dinner"
      await tester.enterText(
          find.byKey(const ValueKey('filter_search_input')), 'Dinner');
      await tester.pumpAndSettle();

      // Dismiss soft keyboard
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();

      // Live match preview updates to 1
      expect(find.text('1 of 2 matches'), findsOneWidget);

      // Tap Apply Filters
      await tester.tap(find.byKey(const ValueKey('filter_apply_button')));
      await tester.pumpAndSettle();

      // 8. On Ledger: Active filter chip appears: Search: "Dinner"
      expect(find.text('Search: "Dinner"'), findsOneWidget);

      // Scroll down to view transactions list
      final ledgerScrollView = find.byKey(const ValueKey('ledger_scroll_view'));
      await tester.drag(ledgerScrollView, const Offset(0, -300));
      await tester.pumpAndSettle();

      // Only "Team Dinner" is shown; "Morning Coffee" is filtered out
      expect(find.text('Team Dinner'), findsOneWidget);
      expect(find.text('Morning Coffee'), findsNothing);

      // 9. Scroll back up to tap "Clear All" filter chip
      await tester.drag(ledgerScrollView, const Offset(0, 300));
      await tester.pumpAndSettle();

      final clearAllChip =
          find.byKey(const ValueKey('ledger_clear_all_filters_chip'));
      expect(clearAllChip, findsOneWidget);
      await tester.tap(clearAllChip);
      await tester.pumpAndSettle();

      // 10. Verify filter chip is removed, then scroll down and verify both transactions are restored
      expect(find.text('Search: "Dinner"'), findsNothing);

      await tester.drag(ledgerScrollView, const Offset(0, -300));
      await tester.pumpAndSettle();

      expect(find.text('Team Dinner'), findsOneWidget);
      expect(find.text('Morning Coffee'), findsOneWidget);
    });
  });
}
