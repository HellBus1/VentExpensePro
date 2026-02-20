import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../painters/paper_background.dart';

/// The main ledger screen — a continuous, receipt-style transaction feed.
class LedgerScreen extends StatelessWidget {
  const LedgerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PaperBackground(
      child: CustomScrollView(
        slivers: [
          // — Net Position Card placeholder —
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        'NET POSITION',
                        style: AppTypography.label.copyWith(
                          letterSpacing: 2.0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Rp 0',
                        style: AppTypography.amountLarge.copyWith(
                          color: AppColors.inkBlue,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildSummaryItem(
                            'Assets',
                            'Rp 0',
                            AppColors.inkGreen,
                          ),
                          Container(
                            width: 1,
                            height: 32,
                            color: AppColors.divider,
                          ),
                          _buildSummaryItem(
                            'Liabilities',
                            'Rp 0',
                            AppColors.stampRed,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // — Receipt feed placeholder —
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Column(
                children: [
                  // — Perforated divider —
                  Row(
                    children: List.generate(
                      30,
                      (i) => Expanded(
                        child: Container(
                          height: 1,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          color: i.isEven
                              ? AppColors.divider
                              : Colors.transparent,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Icon(
                    Icons.receipt_long_outlined,
                    size: 48,
                    color: AppColors.disabled,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No transactions yet',
                    style: AppTypography.bodyLarge.copyWith(
                      color: AppColors.inkLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Tap + to log your first entry',
                    style: AppTypography.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String amount, Color color) {
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: AppTypography.label,
        ),
        const SizedBox(height: 4),
        Text(
          amount,
          style: AppTypography.amountMedium.copyWith(color: color),
        ),
      ],
    );
  }
}
