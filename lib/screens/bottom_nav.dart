import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:vent_expense_pro/commons/constants/constants.dart' as Constants;
import 'package:vent_expense_pro/screens/wallet/wallet_screen.dart';

class BottomNav extends StatelessWidget {
  const BottomNav({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final List<Map<String, dynamic>> tabs = [
      {
        'icon': Icons.list,
        'label': l10n?.transactions ?? Constants.EMPTY_STRING
      },
      {
        'icon': Icons.account_balance_wallet,
        'label': l10n?.wallets ?? Constants.EMPTY_STRING
      },
      {
        'icon': Icons.bar_chart,
        'label': l10n?.reports ?? Constants.EMPTY_STRING
      },
      {
        'icon': Icons.settings,
        'label': l10n?.settings ?? Constants.EMPTY_STRING
      },
    ];

    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        body: TabBarView(
          children: [
            Center(),
            WalletScreen(),
            Center(),
            Center(),
          ],
        ),
        bottomNavigationBar: TabBar(
          tabs: tabs
              .map((tab) => Tab(
                  icon: Icon(tab['icon'] as IconData),
                  text: tab['label'] as String))
              .toList(),
        ),
      ),
    );
  }
}
