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

  group('Accounts and Debt Management Integration Tests', () {
    testWidgets('Complete lifecycle: create diverse accounts, verify net position, settle debt, pay credit bill, edit, and archive', (tester) async {
      // 1. Launch application
      await tester.pumpWidget(const VentExpenseApp());
      await tester.pumpAndSettle();

      // 2. Navigate to Accounts tab
      final accountsTab = find.text('Accounts');
      expect(accountsTab, findsOneWidget);
      await tester.tap(accountsTab);
      await tester.pumpAndSettle();

      // Verify empty state
      expect(find.text('No accounts yet'), findsOneWidget);

      // 3. Create Checking Account (Debit)
      final accountsFab = find.byKey(const ValueKey('accounts_fab'));
      expect(accountsFab, findsOneWidget);
      await tester.tap(accountsFab);
      await tester.pumpAndSettle();

      expect(find.text('New Account'), findsOneWidget);
      await tester.enterText(find.byKey(const ValueKey('account_name_input')), 'BCA Checking');
      await tester.enterText(find.byKey(const ValueKey('account_balance_input')), '5000000');
      await tester.tap(find.byKey(const ValueKey('account_submit_button')));
      await tester.pumpAndSettle();

      expect(find.text('BCA Checking'), findsOneWidget);

      // 4. Create Cash Account
      await tester.tap(accountsFab);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('account_type_cash')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('account_name_input')), 'Pocket Cash');
      await tester.enterText(find.byKey(const ValueKey('account_balance_input')), '500000');
      await tester.tap(find.byKey(const ValueKey('account_submit_button')));
      await tester.pumpAndSettle();

      expect(find.text('Pocket Cash'), findsOneWidget);

      // 5. Create Credit Card Account
      await tester.tap(accountsFab);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('account_type_credit')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('account_name_input')), 'Visa Platinum');
      await tester.enterText(find.byKey(const ValueKey('account_balance_input')), '1000000');
      await tester.tap(find.byKey(const ValueKey('account_submit_button')));
      await tester.pumpAndSettle();

      expect(find.text('Visa Platinum'), findsOneWidget);
      expect(find.text('LIABILITIES'), findsOneWidget);

      // 6. Create Personal Debt - Receivable ("They owe me")
      await tester.tap(accountsFab);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('account_type_debt')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('account_name_input')), 'Alex');
      await tester.tap(find.byKey(const ValueKey('debt_direction_they_owe_me')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('account_balance_input')), '300000');
      await tester.tap(find.byKey(const ValueKey('account_submit_button')));
      await tester.pumpAndSettle();

      // 7. Create Personal Debt - Payable ("I owe them")
      await tester.tap(accountsFab);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('account_type_debt')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('account_name_input')), 'Charlie');
      await tester.tap(find.byKey(const ValueKey('debt_direction_i_owe_them')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('account_balance_input')), '200000');
      await tester.tap(find.byKey(const ValueKey('account_submit_button')));
      await tester.pumpAndSettle();

      final accountsListView = find.byKey(const PageStorageKey('accounts_list_view'));

      // 8. Scroll to Personal Debts and verify debts strip and debt cards
      await tester.drag(accountsListView, const Offset(0, -350));
      await tester.pumpAndSettle();

      expect(find.text('PERSONAL DEBTS'), findsOneWidget);
      expect(find.text('THEY OWE YOU'), findsWidgets);
      expect(find.text('Alex'), findsOneWidget);
      expect(find.text('OWES YOU'), findsWidgets);
      expect(find.text('Charlie'), findsOneWidget);
      expect(find.text('YOU OWE'), findsWidgets);

      // 9. Settle Receivable Debt (Alex pays back)
      final alexSettleBtn = find.byKey(const ValueKey('account_settle_debt_btn_Alex'));
      expect(alexSettleBtn, findsOneWidget);
      await tester.tap(alexSettleBtn);
      await tester.pumpAndSettle();

      expect(find.text('Receive Repayment'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('settle_debt_button')));
      await tester.pumpAndSettle();

      // Alex is now settled
      expect(find.text('SETTLED'), findsOneWidget);

      // 10. Pay Credit Card Bill (scroll up to Visa Platinum in LIABILITIES)
      await tester.drag(accountsListView, const Offset(0, 500));
      await tester.pumpAndSettle();

      final visaPayBtn = find.byKey(const ValueKey('account_pay_bill_btn_Visa Platinum'));
      expect(visaPayBtn, findsOneWidget);
      await tester.tap(visaPayBtn);
      await tester.pumpAndSettle();

      expect(find.text('Pay Bill'), findsOneWidget);
      await tester.enterText(find.byKey(const ValueKey('pay_bill_amount_input')), '500000');
      await tester.tap(find.byKey(const ValueKey('pay_bill_settle_button')));
      await tester.pumpAndSettle();

      // 11. Edit Account: Scroll up to Pocket Cash and update name
      await tester.drag(accountsListView, const Offset(0, 400));
      await tester.pumpAndSettle();

      expect(find.text('Pocket Cash'), findsOneWidget);
      await tester.tap(find.text('Pocket Cash'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Account'), findsOneWidget);
      await tester.enterText(find.byKey(const ValueKey('account_name_input')), 'Emergency Cash');
      await tester.tap(find.byKey(const ValueKey('account_submit_button')));
      await tester.pumpAndSettle();

      expect(find.text('Emergency Cash'), findsOneWidget);
      expect(find.text('Pocket Cash'), findsNothing);

      // 12. Archive Account: Long press Emergency Cash and confirm
      await tester.longPress(find.text('Emergency Cash'));
      await tester.pumpAndSettle();

      expect(find.text('Archive Account'), findsOneWidget);
      await tester.tap(find.text('Archive'));
      await tester.pumpAndSettle();

      expect(find.text('Emergency Cash'), findsNothing);
    });
  });
}
