import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class BottomNav extends StatelessWidget {
  const BottomNav({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final List<Map<String, dynamic>> tabs = [
      {'icon': Icons.list, 'label': l10n?.transactions ?? ""},
      {'icon': Icons.account_balance_wallet, 'label': l10n?.wallets ?? ""},
      {'icon': Icons.bar_chart, 'label': l10n?.reports ?? ""},
      {'icon': Icons.settings, 'label': l10n?.settings ?? ""},
    ];

    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        body: TabBarView(
          children: tabs
              .map((tab) => Center(child: Text(tab['label'] as String)))
              .toList(),
        ),
        bottomNavigationBar: TabBar(
          tabs: tabs
              .map((tab) => Tab(icon: Icon(tab['icon'] as IconData), text: tab['label'] as String))
              .toList(),
        ),
      ),
    );
  }
}
