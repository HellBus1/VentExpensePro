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

  group('Reports Feature Integration Tests', () {
    testWidgets('Generate professional PDF report: verify Debt Summary, Credit Card Billing, and PDF export', (tester) async {
      // 1. Launch application
      await tester.pumpWidget(const VentExpenseApp());
      await tester.pumpAndSettle();

      // 2. Setup Debt Account & Credit Card in Accounts
      await tester.tap(find.text('Accounts'));
      await tester.pumpAndSettle();

      // Create Checking Account
      await tester.tap(find.byKey(const ValueKey('accounts_fab')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('account_name_input')), 'Checking Account');
      await tester.enterText(find.byKey(const ValueKey('account_balance_input')), '2500000');
      await tester.tap(find.byKey(const ValueKey('account_submit_button')));
      await tester.pumpAndSettle();

      // Create Debt Account
      await tester.tap(find.byKey(const ValueKey('accounts_fab')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('account_name_input')), 'Alex Pratama');
      await tester.tap(find.byKey(const ValueKey('account_type_debt')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('account_balance_input')), '500000');
      await tester.tap(find.byKey(const ValueKey('account_submit_button')));
      await tester.pumpAndSettle();

      // Create Credit Card with statement close day
      await tester.tap(find.byKey(const ValueKey('accounts_fab')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('account_name_input')), 'BCA Credit Card');
      await tester.tap(find.byKey(const ValueKey('account_type_credit')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('account_balance_input')), '450000');
      
      final closeDayDropdown = find.byKey(const ValueKey('statement_close_day_dropdown'));
      await tester.ensureVisible(closeDayDropdown);
      await tester.pumpAndSettle();
      await tester.tap(closeDayDropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('1st of each month').last);
      await tester.pumpAndSettle();

      final submitBtn = find.byKey(const ValueKey('account_submit_button'));
      await tester.ensureVisible(submitBtn);
      await tester.pumpAndSettle();
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      // Log a transaction in Ledger
      await tester.tap(find.text('Ledger'));
      await tester.pumpAndSettle();

      final mainFab = find.byKey(const ValueKey('main_fab_add_transaction'));
      await tester.tap(mainFab);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Food'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('quick_add_amount_input')), '45000');
      await tester.enterText(find.byKey(const ValueKey('quick_add_note_input')), 'Dinner');
      await tester.tap(find.byKey(const ValueKey('quick_add_submit_button')));
      await tester.pumpAndSettle();

      // 3. Switch to Reports tab
      await tester.tap(find.text('Reports'));
      await tester.pumpAndSettle();

      // 4. Verify Reports headers & filters
      expect(find.text('Professional Reports'), findsOneWidget);
      expect(find.text('REPORT FILTERS'), findsOneWidget);
      expect(find.text('All Time'), findsOneWidget);
      expect(find.text('All Accounts'), findsOneWidget);

      // 5. Verify Enhanced Sections
      expect(find.byKey(const ValueKey('reports_debt_summary_section')), findsOneWidget);
      expect(find.text('DEBT & LENDING SUMMARY'), findsOneWidget);
      expect(find.text('RECEIVABLE'), findsOneWidget);
      expect(find.text('Alex Pratama'), findsOneWidget);

      expect(find.byKey(const ValueKey('reports_credit_billing_section')), findsOneWidget);
      expect(find.text('CREDIT CARD BILLING BREAKDOWN'), findsOneWidget);
      expect(find.text('BCA Credit Card'), findsOneWidget);
      expect(find.text('Closes 1st'), findsOneWidget);
      expect(find.text('TOTAL ALL CREDIT CARDS'), findsOneWidget);

      // 6. Generate PDF Statement
      final generateBtn = find.text('Generate PDF Statement');
      await tester.ensureVisible(generateBtn);
      await tester.pumpAndSettle();
      await tester.tap(generateBtn);
      await tester.pumpAndSettle();

      // 7. Verify generated PDF status
      expect(find.text('Ready to Save!'), findsOneWidget);
      expect(find.text('Report generated successfully.'), findsOneWidget);
      expect(find.text('Share or Save to Files'), findsOneWidget);
    });
  });
}
