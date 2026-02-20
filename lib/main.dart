import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/di/service_locator.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_typography.dart';
import 'domain/repositories/account_repository.dart';
import 'domain/repositories/transaction_repository.dart';
import 'domain/usecases/calculate_net_position.dart';
import 'domain/usecases/log_transaction.dart';
import 'presentation/providers/account_provider.dart';
import 'presentation/providers/transaction_provider.dart';
import 'presentation/screens/accounts_screen.dart';
import 'presentation/screens/ledger_screen.dart';
import 'presentation/screens/reports_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize dependency injection
  await initServiceLocator();

  runApp(const VentExpenseApp());
}

/// Root application widget.
class VentExpenseApp extends StatelessWidget {
  const VentExpenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AccountProvider(
            sl<AccountRepository>(),
            sl<CalculateNetPosition>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => TransactionProvider(
            sl<TransactionRepository>(),
            sl<LogTransaction>(),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'VentExpense Pro',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const HomeShell(),
      ),
    );
  }
}

/// The main shell with bottom navigation.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;

  static const _screens = [
    LedgerScreen(),
    AccountsScreen(),
    ReportsScreen(),
  ];

  static const _titles = ['Ledger', 'Accounts', 'Reports'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _titles[_currentIndex],
          style: AppTypography.titleLarge.copyWith(
            color: AppColors.inkBlue,
          ),
        ),
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long),
            label: 'Ledger',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_outlined),
            activeIcon: Icon(Icons.account_balance_wallet),
            label: 'Accounts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.description_outlined),
            activeIcon: Icon(Icons.description),
            label: 'Reports',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Open Quick-Add bottom sheet
        },
        tooltip: 'Log Transaction',
        child: const Icon(Icons.add),
      ),
    );
  }
}
