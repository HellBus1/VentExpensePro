import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import 'core/di/service_locator.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_typography.dart';
import 'domain/entities/enums.dart';
import 'domain/entities/transaction.dart';
import 'domain/repositories/account_repository.dart';
import 'domain/repositories/category_repository.dart';
import 'domain/repositories/transaction_repository.dart';
import 'domain/usecases/calculate_net_position.dart';
import 'domain/usecases/manage_account.dart';
import 'domain/usecases/manage_transaction.dart';
import 'presentation/providers/account_provider.dart';
import 'presentation/providers/category_provider.dart';
import 'presentation/providers/transaction_provider.dart';
import 'domain/usecases/settle_credit_bill.dart';
import 'presentation/screens/accounts_screen.dart';
import 'presentation/screens/ledger_screen.dart';
import 'presentation/screens/reports_screen.dart';
import 'presentation/widgets/manage_categories_sheet.dart';
import 'presentation/widgets/quick_add_transaction_sheet.dart';

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
            sl<ManageAccount>(),
            sl<SettleCreditBill>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => TransactionProvider(
            sl<TransactionRepository>(),
            sl<CategoryRepository>(),
            sl<ManageTransaction>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => CategoryProvider(sl<CategoryRepository>()),
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

  static const _screens = [LedgerScreen(), AccountsScreen(), ReportsScreen()];

  static const _titles = ['Ledger', 'Accounts', 'Reports'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _titles[_currentIndex],
          style: AppTypography.titleLarge.copyWith(color: AppColors.inkBlue),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppColors.inkLight),
            onSelected: (value) {
              if (value == 'categories') _openCategoryManager(context);
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'categories',
                child: Row(
                  children: [
                    Icon(Icons.category_outlined, size: 20),
                    SizedBox(width: 8),
                    Text('Manage Categories'),
                  ],
                ),
              ),
            ],
          ),
        ],
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
      floatingActionButton: _currentIndex == 1
          ? null // Accounts screen manages its own FAB
          : FloatingActionButton(
              onPressed: () => _openQuickAdd(context),
              tooltip: 'Log Transaction',
              child: const Icon(Icons.add),
            ),
    );
  }

  void _openQuickAdd(BuildContext context) async {
    final txnProvider = context.read<TransactionProvider>();
    final accProvider = context.read<AccountProvider>();

    // Ensure data is loaded
    if (txnProvider.categories.isEmpty) await txnProvider.loadAll();
    if (accProvider.accounts.isEmpty) await accProvider.loadAccounts();

    if (!mounted) return;

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => QuickAddTransactionSheet(
        categories: txnProvider.categories,
        accounts: accProvider.accounts
            .where((a) => !a.isArchived)
            .toList(),
      ),
    );

    if (result != null && mounted) {
      final transaction = Transaction(
        id: const Uuid().v4(),
        amount: result['amount'] as int,
        type: result['type'] as TransactionType,
        categoryId: result['categoryId'] as String,
        accountId: result['accountId'] as String,
        toAccountId: result['toAccountId'] as String?,
        note: result['note'] as String?,
        dateTime: result['dateTime'] as DateTime,
      );

      await txnProvider.addTransaction(transaction);
      if (mounted) await accProvider.loadAccounts();
    }
  }

  void _openCategoryManager(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const ManageCategoriesSheet(),
    );
  }
}
