import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/entities/account.dart';
import '../../domain/entities/enums.dart';
import '../painters/paper_background.dart';
import '../providers/account_provider.dart';
import '../widgets/account_card.dart';
import '../widgets/add_edit_account_sheet.dart';
import '../widgets/net_position_card.dart';

/// The accounts overview screen — lists asset and liability accounts.
class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  @override
  void initState() {
    super.initState();
    // Load accounts on first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AccountProvider>().loadAccounts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return PaperBackground(
      child: Stack(
        children: [
          Consumer<AccountProvider>(
            builder: (context, provider, _) {
              if (provider.isLoading && provider.accounts.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.inkBlue),
                );
              }

              if (provider.accounts.isEmpty) {
                return _buildEmptyState();
              }

              return _buildAccountsList(provider);
            },
          ),

          // — FAB —
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton(
              heroTag: 'accounts_fab',
              onPressed: () => _showAddSheet(context),
              tooltip: 'Add Account',
              child: const Icon(Icons.add),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.inkBlue.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.account_balance_wallet_outlined,
                size: 40,
                color: AppColors.inkBlue,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No accounts yet',
              style: AppTypography.titleMedium.copyWith(
                color: AppColors.inkDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap + to add your first debit, cash,\nor credit account',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.inkLight,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountsList(AccountProvider provider) {
    final assets = provider.assetAccounts;
    final liabilities = provider.liabilityAccounts;

    return ListView(
      padding: const EdgeInsets.only(bottom: 80),
      children: [
        // — Net Position Card —
        NetPositionCard(breakdown: provider.breakdown),

        const SizedBox(height: 12),

        // — Assets Section —
        _buildSectionHeader(
          title: 'ASSETS',
          count: assets.length,
          color: AppColors.inkGreen,
        ),

        if (assets.isEmpty)
          _buildSectionEmpty('No asset accounts')
        else
          ...assets.map(
            (account) => AccountCard(
              account: account,
              onTap: () => _showEditSheet(context, account),
              onLongPress: () => _showArchiveDialog(context, account),
            ),
          ),

        const SizedBox(height: 16),

        // — Liabilities Section —
        _buildSectionHeader(
          title: 'LIABILITIES',
          count: liabilities.length,
          color: AppColors.stampRed,
        ),

        if (liabilities.isEmpty)
          _buildSectionEmpty('No liability accounts')
        else
          ...liabilities.map(
            (account) => AccountCard(
              account: account,
              onTap: () => _showEditSheet(context, account),
              onLongPress: () => _showArchiveDialog(context, account),
            ),
          ),
      ],
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required int count,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: AppTypography.label.copyWith(
              letterSpacing: 2.0,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              count.toString(),
              style: AppTypography.label.copyWith(color: color, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionEmpty(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Text(
        message,
        style: AppTypography.bodySmall.copyWith(
          color: AppColors.disabled,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  // — Sheet & Dialog Helpers —

  Future<void> _showAddSheet(BuildContext context) async {
    final provider = context.read<AccountProvider>();
    final result = await showModalBottomSheet<dynamic>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const AddEditAccountSheet(),
    );

    if (result != null && result is Map<String, dynamic> && mounted) {
      await provider.addAccount(
        name: result['name'] as String,
        type: result['type'] as AccountType,
        balance: result['balance'] as int,
        currency: result['currency'] as String,
      );
    }
  }

  Future<void> _showEditSheet(BuildContext context, Account account) async {
    final provider = context.read<AccountProvider>();
    final result = await showModalBottomSheet<dynamic>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AddEditAccountSheet(existingAccount: account),
    );

    if (result != null && result is Account && mounted) {
      await provider.updateAccount(result);
    }
  }

  Future<void> _showArchiveDialog(BuildContext context, Account account) async {
    final provider = context.read<AccountProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.paper,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Archive Account',
          style: AppTypography.titleMedium.copyWith(color: AppColors.inkDark),
        ),
        content: Text(
          'Are you sure you want to archive "${account.name}"?\n\n'
          'The account will be hidden but its transaction history is preserved.',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.inkLight,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Archive',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.stampRed,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await provider.archiveAccount(account.id);
    }
  }
}
