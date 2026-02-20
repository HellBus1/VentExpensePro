import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../painters/paper_background.dart';

/// The accounts overview screen — lists asset and liability accounts.
class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PaperBackground(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.account_balance_wallet_outlined,
                size: 48,
                color: AppColors.disabled,
              ),
              const SizedBox(height: 16),
              Text(
                'No accounts yet',
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.inkLight,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Add your first debit, cash, or credit account',
                style: AppTypography.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
