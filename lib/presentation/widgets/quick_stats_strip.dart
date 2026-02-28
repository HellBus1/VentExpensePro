import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/currency_formatter.dart';

/// A small strip showing today's and this month's spending.
class QuickStatsStrip extends StatelessWidget {
  final int todaysSpending;
  final int thisMonthsSpending;

  const QuickStatsStrip({
    super.key,
    required this.todaysSpending,
    required this.thisMonthsSpending,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.paper,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.divider,
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem('Today\'s Spend', todaysSpending),
            Container(
              width: 1,
              height: 24,
              color: AppColors.divider,
            ),
            _buildStatItem('This Month', thisMonthsSpending),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, int amount) {
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: AppTypography.label.copyWith(
            color: AppColors.inkLight,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          CurrencyFormatter.formatCents(amount),
          style: AppTypography.amountSmall.copyWith(
            color: AppColors.inkDark,
          ),
        ),
      ],
    );
  }
}
