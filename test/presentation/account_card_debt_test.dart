import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vent_expense_pro/domain/entities/account.dart';
import 'package:vent_expense_pro/domain/entities/enums.dart';
import 'package:vent_expense_pro/presentation/widgets/account_card.dart';

void main() {
  final now = DateTime.now();

  Widget createSubject(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: child,
      ),
    );
  }

  group('AccountCard - Debt Display and Actions', () {
    testWidgets('renders receivable debt account with OWES YOU and triggers onSettleDebt', (tester) async {
      bool settleTapped = false;
      final account = Account(
        id: 'debt_budi',
        name: 'Budi (Lent)',
        type: AccountType.debt,
        balance: 250000,
        currency: 'IDR',
        createdAt: now,
      );

      await tester.pumpWidget(
        createSubject(
          AccountCard(
            account: account,
            onSettleDebt: () => settleTapped = true,
          ),
        ),
      );

      expect(find.text('Budi (Lent)'), findsOneWidget);
      expect(find.text('OWES YOU'), findsOneWidget);
      expect(find.textContaining('250.000'), findsOneWidget);
      expect(find.byIcon(Icons.handshake_outlined), findsNWidgets(2));

      await tester.tap(find.byIcon(Icons.handshake_outlined).last);
      expect(settleTapped, isTrue);
    });

    testWidgets('renders payable debt account with YOU OWE', (tester) async {
      final account = Account(
        id: 'debt_ani',
        name: 'Ani (Borrowed)',
        type: AccountType.debt,
        balance: -150000,
        currency: 'IDR',
        createdAt: now,
      );

      await tester.pumpWidget(
        createSubject(
          AccountCard(
            account: account,
          ),
        ),
      );

      expect(find.text('Ani (Borrowed)'), findsOneWidget);
      expect(find.text('YOU OWE'), findsOneWidget);
      expect(find.textContaining('150.000'), findsOneWidget);
    });

    testWidgets('renders credit card with statement close badge and pay bill button', (tester) async {
      bool payBillTapped = false;
      final credit = Account(
        id: 'cc_1',
        name: 'BCA Visa',
        type: AccountType.credit,
        balance: 500000,
        currency: 'IDR',
        statementCloseDay: 20,
        createdAt: now,
      );

      await tester.pumpWidget(
        createSubject(
          AccountCard(
            account: credit,
            onPayBill: () => payBillTapped = true,
          ),
        ),
      );

      expect(find.text('BCA Visa'), findsOneWidget);
      expect(find.text('CREDIT'), findsOneWidget);
      expect(find.text('Closes 20th'), findsOneWidget);
      expect(find.byIcon(Icons.payments_outlined), findsOneWidget);

      await tester.tap(find.byIcon(Icons.payments_outlined));
      expect(payBillTapped, isTrue);
    });
  });
}
