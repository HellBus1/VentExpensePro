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
    testWidgets('Generate professional PDF report: filter by account, generate PDF statement, verify ready to save', (tester) async {
      // 1. Launch application
      await tester.pumpWidget(const VentExpenseApp());
      await tester.pumpAndSettle();

      // 2. Setup initial account & transaction
      await tester.tap(find.text('Accounts'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('accounts_fab')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('account_name_input')), 'Checking Account');
      await tester.enterText(find.byKey(const ValueKey('account_balance_input')), '1500000');
      await tester.tap(find.byKey(const ValueKey('account_submit_button')));
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

      // 4. Verify Reports components
      expect(find.text('Professional Reports'), findsOneWidget);
      expect(find.text('REPORT FILTERS'), findsOneWidget);
      expect(find.text('All Time'), findsOneWidget);
      expect(find.text('All Accounts'), findsOneWidget);
      expect(find.text('Generate PDF Statement'), findsOneWidget);

      // 5. Test Account filter selection
      await tester.tap(find.text('All Accounts'));
      await tester.pumpAndSettle();

      // Select 'Checking Account'
      expect(find.text('Checking Account'), findsOneWidget);
      await tester.tap(find.text('Checking Account'));
      await tester.pumpAndSettle();

      expect(find.text('Checking Account'), findsOneWidget);

      // 6. Generate PDF Statement
      final reportsScrollView = find.byKey(const ValueKey('reports_scroll_view'));
      await tester.drag(reportsScrollView, const Offset(0, -300));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Generate PDF Statement'));
      await tester.pumpAndSettle();

      // 7. Verify generated PDF status
      expect(find.text('Ready to Save!'), findsOneWidget);
      expect(find.text('Report generated successfully.'), findsOneWidget);
      expect(find.text('Share or Save to Files'), findsOneWidget);
    });
  });
}
