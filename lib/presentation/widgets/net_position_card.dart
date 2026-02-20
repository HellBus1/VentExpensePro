import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/usecases/calculate_net_position.dart';
import '../../domain/value_objects/money.dart';

/// Displays the Net Position breakdown: Total Assets, Total Liabilities, Net.
class NetPositionCard extends StatelessWidget {
  final NetPositionBreakdown? breakdown;

  const NetPositionCard({super.key, required this.breakdown});

  @override
  Widget build(BuildContext context) {
    final assets = breakdown?.totalAssets ?? const Money(cents: 0);
    final liabilities = breakdown?.totalLiabilities ?? const Money(cents: 0);
    final net = breakdown?.netPosition ?? const Money(cents: 0);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.paperElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.inkDark.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // — Header —
          Text(
            'NET POSITION',
            style: AppTypography.label.copyWith(
              letterSpacing: 2.0,
              color: AppColors.inkLight,
            ),
          ),
          const SizedBox(height: 8),

          // — Net Position amount —
          Text(
            net.formatted,
            style: AppTypography.amountLarge.copyWith(
              color: net.isNegative ? AppColors.stampRed : AppColors.inkGreen,
              fontSize: 32,
            ),
          ),
          const SizedBox(height: 16),

          // — Dotted divider —
          _buildDottedDivider(),
          const SizedBox(height: 12),

          // — Assets row —
          _buildBreakdownRow(
            label: 'Total Assets',
            amount: assets,
            color: AppColors.inkGreen,
            icon: Icons.arrow_upward_rounded,
          ),
          const SizedBox(height: 8),

          // — Liabilities row —
          _buildBreakdownRow(
            label: 'Total Liabilities',
            amount: liabilities,
            color: AppColors.stampRed,
            icon: Icons.arrow_downward_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow({
    required String label,
    required Money amount,
    required Color color,
    required IconData icon,
  }) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Text(label, style: AppTypography.bodyMedium),
        const Spacer(),
        Text(
          amount.formatted,
          style: AppTypography.amountSmall.copyWith(color: color),
        ),
      ],
    );
  }

  Widget _buildDottedDivider() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final dashWidth = 4.0;
        final dashSpace = 3.0;
        final dashCount =
            (constraints.maxWidth / (dashWidth + dashSpace)).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: dashWidth,
              height: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(color: AppColors.divider),
              ),
            );
          }),
        );
      },
    );
  }
}
