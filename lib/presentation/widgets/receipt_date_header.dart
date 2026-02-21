import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/date_formatter.dart';

/// A date-group header for the receipt-style transaction feed.
///
/// Displays a relative date label (e.g., "Today, 21 Feb") between
/// perforated divider lines, mimicking a receipt tear-off edge.
class ReceiptDateHeader extends StatelessWidget {
  final DateTime date;

  const ReceiptDateHeader({super.key, required this.date});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // — Perforated divider —
          Row(
            children: List.generate(
              30,
              (i) => Expanded(
                child: Container(
                  height: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  color: i.isEven ? AppColors.divider : Colors.transparent,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // — Date label —
          Text(
            DateFormatter.receiptHeader(date).toUpperCase(),
            style: AppTypography.label.copyWith(
              letterSpacing: 2.0,
              color: AppColors.inkLight,
            ),
          ),
        ],
      ),
    );
  }
}
