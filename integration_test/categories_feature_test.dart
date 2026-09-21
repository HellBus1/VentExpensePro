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

  group('Categories Management Feature Integration Tests', () {
    testWidgets('Complete category lifecycle: open manager, view defaults, add custom category, verify in transaction sheet, edit, and delete', (tester) async {
      // 1. Launch application
      await tester.pumpWidget(const VentExpenseApp());
      await tester.pumpAndSettle();

      // 2. Open overflow menu
      final overflowMenu = find.byKey(const ValueKey('app_bar_overflow_menu'));
      expect(overflowMenu, findsOneWidget);
      await tester.tap(overflowMenu);
      await tester.pumpAndSettle();

      // 3. Select 'Manage Categories'
      final categoriesMenuItem = find.byKey(const ValueKey('menu_categories'));
      expect(categoriesMenuItem, findsOneWidget);
      await tester.tap(categoriesMenuItem);
      await tester.pumpAndSettle();

      // 4. Verify Manage Categories sheet and default categories
      expect(find.text('Manage Categories'), findsOneWidget);
      expect(find.text('Food'), findsOneWidget);
      expect(find.text('Transport'), findsOneWidget);
      expect(find.text('Bills'), findsOneWidget);
      expect(find.text('Shopping'), findsOneWidget);

      // 5. Add Custom Category
      final addCatBtn = find.byKey(const ValueKey('add_category_button'));
      expect(addCatBtn, findsOneWidget);
      await tester.tap(addCatBtn);
      await tester.pumpAndSettle();

      expect(find.text('New Category'), findsOneWidget);
      await tester.enterText(find.byKey(const ValueKey('category_name_input')), 'Freelance');
      await tester.tap(find.byKey(const ValueKey('category_save_button')));
      await tester.pumpAndSettle();

      // Verify custom category is displayed
      expect(find.text('Freelance'), findsOneWidget);
      expect(find.text('Custom'), findsWidgets);

      // 6. Close category sheet
      Navigator.of(tester.element(find.text('Manage Categories'))).pop();
      await tester.pumpAndSettle();

      // First create an account so quick add sheet can open
      await tester.tap(find.text('Accounts'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('accounts_fab')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('account_name_input')), 'Main Cash');
      await tester.enterText(find.byKey(const ValueKey('account_balance_input')), '1000000');
      await tester.tap(find.byKey(const ValueKey('account_submit_button')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ledger'));
      await tester.pumpAndSettle();

      // 7. Verify newly created category appears in QuickAddTransactionSheet
      final mainFab = find.byKey(const ValueKey('main_fab_add_transaction'));
      await tester.tap(mainFab);
      await tester.pumpAndSettle();

      expect(find.text('Freelance'), findsOneWidget);

      // Close quick add sheet
      Navigator.of(tester.element(find.text('Log Transaction'))).pop();
      await tester.pumpAndSettle();

      // 8. Reopen Manage Categories to Edit
      await tester.tap(overflowMenu);
      await tester.pumpAndSettle();
      await tester.tap(categoriesMenuItem);
      await tester.pumpAndSettle();

      // Scroll categories list down to reveal Freelance
      final categoriesListView = find.byKey(const ValueKey('categories_list_view'));
      await tester.drag(categoriesListView, const Offset(0, -200));
      await tester.pumpAndSettle();

      final editBtn = find.byKey(const ValueKey('category_edit_btn_Freelance'));
      expect(editBtn, findsOneWidget);
      await tester.tap(editBtn);
      await tester.pumpAndSettle();

      expect(find.text('Edit Category'), findsOneWidget);
      await tester.enterText(find.byKey(const ValueKey('category_name_input')), 'Consulting Work');
      await tester.tap(find.byKey(const ValueKey('category_save_button')));
      await tester.pumpAndSettle();

      expect(find.text('Consulting Work'), findsOneWidget);
      expect(find.text('Freelance'), findsNothing);

      // 9. Delete Custom Category
      final deleteBtn = find.byKey(const ValueKey('category_delete_btn_Consulting Work'));
      expect(deleteBtn, findsOneWidget);
      await tester.tap(deleteBtn);
      await tester.pumpAndSettle();

      expect(find.text('Delete Category'), findsOneWidget);
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(find.text('Consulting Work'), findsNothing);
    });
  });
}
