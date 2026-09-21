import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:vent_expense_pro/domain/entities/account.dart';
import 'package:vent_expense_pro/domain/entities/enums.dart';
import 'package:vent_expense_pro/domain/entities/transaction.dart';
import 'package:vent_expense_pro/presentation/providers/currency_provider.dart';
import 'package:vent_expense_pro/presentation/widgets/billing_summary_widget.dart';

void main() {
  Widget createTestWidget({
    required Account account,
    required List<Transaction> transactions,
    DateTime? now,
    VoidCallback? onTap,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: ChangeNotifierProvider(
          create: (_) => CurrencyProvider(),
          child: BillingSummaryWidget(
            account: account,
            transactions: transactions,
            now: now,
            onTap: onTap,
          ),
        ),
      ),
    );
  }

  group('BillingSummaryWidget Widget Tests', () {
    testWidgets('renders account name, statement close day badge, and amounts',
        (tester) async {
      final card = Account(
        id: 'acc_cc_gold',
        name: 'Gold Mastercard',
        type: AccountType.credit,
        balance: 750000,
        statementCloseDay: 20,
        createdAt: DateTime(2026, 1, 1),
      );

      final now = DateTime(2026, 9, 15);
      final transactions = [
        // Billed transaction (Aug 10)
        Transaction(
          id: 'tx1',
          amount: 500000,
          type: TransactionType.expense,
          categoryId: 'food',
          accountId: 'acc_cc_gold',
          dateTime: DateTime(2026, 8, 10),
        ),
        // Unbilled transaction (Aug 25)
        Transaction(
          id: 'tx2',
          amount: 250000,
          type: TransactionType.expense,
          categoryId: 'shopping',
          accountId: 'acc_cc_gold',
          dateTime: DateTime(2026, 8, 25),
        ),
      ];

      await tester.pumpWidget(createTestWidget(
        account: card,
        transactions: transactions,
        now: now,
      ));

      expect(find.text('Gold Mastercard'), findsOneWidget);
      expect(find.text('Closes 20th'), findsOneWidget);
      expect(find.text('BILLED'), findsOneWidget);
      expect(find.textContaining('Due Aug 20'), findsOneWidget);
      expect(find.textContaining('500.000'), findsOneWidget);
      expect(find.text('UNBILLED (Current)'), findsOneWidget);
      expect(find.textContaining('250.000'), findsOneWidget);
      expect(find.text('Aug 21 – Sep 20'), findsOneWidget);
    });

    testWidgets('renders Rp 0 with checkmark when there are no billed charges',
        (tester) async {
      final card = Account(
        id: 'acc_cc_zero',
        name: 'Clean Card',
        type: AccountType.credit,
        balance: 0,
        statementCloseDay: 15,
        createdAt: DateTime(2026, 1, 1),
      );

      final now = DateTime(2026, 9, 10);

      await tester.pumpWidget(createTestWidget(
        account: card,
        transactions: [],
        now: now,
      ));

      expect(find.text('Clean Card'), findsOneWidget);
      expect(find.text('Closes 15th'), findsOneWidget);
      expect(find.textContaining('0'), findsWidgets); // billed and unbilled both 0
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    });

    testWidgets('triggers onTap callback when tapped', (tester) async {
      bool tapped = false;
      final card = Account(
        id: 'acc_cc_tap',
        name: 'Tap Card',
        type: AccountType.credit,
        balance: 100000,
        statementCloseDay: 5,
        createdAt: DateTime(2026, 1, 1),
      );

      await tester.pumpWidget(createTestWidget(
        account: card,
        transactions: [],
        now: DateTime(2026, 9, 10),
        onTap: () => tapped = true,
      ));

      await tester.tap(find.byKey(const ValueKey('billing_summary_card_acc_cc_tap')));
      expect(tapped, isTrue);
    });
  });
}
