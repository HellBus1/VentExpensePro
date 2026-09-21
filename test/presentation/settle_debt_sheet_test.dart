import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vent_expense_pro/domain/entities/account.dart';
import 'package:vent_expense_pro/domain/entities/enums.dart';
import 'package:vent_expense_pro/presentation/providers/currency_provider.dart';
import 'package:vent_expense_pro/presentation/widgets/settle_debt_sheet.dart';

void main() {
  final now = DateTime.now();

  setUp(() {
    SharedPreferences.setMockInitialValues({'app_currency': 'IDR'});
  });

  Widget createSubject({
    required Account debtAccount,
    required List<Account> assetAccounts,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CurrencyProvider()..loadCurrency()),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: SettleDebtSheet(
            debtAccount: debtAccount,
            assetAccounts: assetAccounts,
          ),
        ),
      ),
    );
  }

  group('SettleDebtSheet Widget Tests', () {
    testWidgets('renders Receive Repayment when debt balance is positive', (tester) async {
      final debt = Account(
        id: 'debt_budi',
        name: 'Budi',
        type: AccountType.debt,
        balance: 300000,
        currency: 'IDR',
        createdAt: now,
      );
      final cash = Account(
        id: 'acc_cash',
        name: 'Cash Pocket',
        type: AccountType.cash,
        balance: 50000,
        currency: 'IDR',
        createdAt: now,
      );

      await tester.pumpWidget(
        createSubject(debtAccount: debt, assetAccounts: [cash]),
      );
      await tester.pumpAndSettle();

      expect(find.text('Receive Repayment'), findsOneWidget);
      expect(find.textContaining('Budi is paying you back'), findsOneWidget);
      expect(find.text('THEY OWE YOU'), findsOneWidget);
      expect(find.text('Cash Pocket'), findsOneWidget);
      expect(find.text('Confirm Repayment'), findsOneWidget);
    });

    testWidgets('renders Pay Back Debt when debt balance is negative', (tester) async {
      final debt = Account(
        id: 'debt_ani',
        name: 'Ani',
        type: AccountType.debt,
        balance: -200000,
        currency: 'IDR',
        createdAt: now,
      );
      final bank = Account(
        id: 'acc_bank',
        name: 'Bank BCA',
        type: AccountType.debit,
        balance: 1000000,
        currency: 'IDR',
        createdAt: now,
      );

      await tester.pumpWidget(
        createSubject(debtAccount: debt, assetAccounts: [bank]),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pay Back Debt'), findsOneWidget);
      expect(find.textContaining('Repaying money to Ani'), findsOneWidget);
      expect(find.text('YOU OWE'), findsOneWidget);
      expect(find.text('Bank BCA'), findsOneWidget);
      expect(find.text('Confirm Payment'), findsOneWidget);
    });
  });
}
