import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/currency_formatter.dart';
import '../../domain/entities/account.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/usecases/calculate_billing_breakdown.dart';
import '../providers/currency_provider.dart';

/// Card widget displaying the statement billing breakdown (billed vs unbilled) for a credit card.
class BillingSummaryWidget extends StatelessWidget {
  final Account account;
  final List<Transaction> transactions;
  final DateTime? now;
  final VoidCallback? onTap;

  const BillingSummaryWidget({
    super.key,
    required this.account,
    required this.transactions,
    this.now,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const calculator = CalculateBillingBreakdown();
    final breakdown = calculator(account, transactions, now);
    final currency = context.watch<CurrencyProvider>().currency;

    final billedFormatted =
        CurrencyFormatter.formatCents(breakdown.billedAmount, currency: currency);
    final unbilledFormatted = CurrencyFormatter.formatCents(
        breakdown.unbilledAmount,
        currency: currency);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        key: ValueKey('billing_summary_card_${account.id}'),
        width: 290,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.paperElevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: breakdown.hasBilledCharges
                ? AppColors.stampRed.withValues(alpha: 0.35)
                : AppColors.divider,
            width: breakdown.hasBilledCharges ? 1.2 : 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // — Header: Icon, Name & Close Day —
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.inkBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.credit_card,
                    size: 16,
                    color: AppColors.inkBlue,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    account.name,
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (account.statementCloseDay != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.paper,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Text(
                      'Closes ${_ordinal(account.statementCloseDay!)}',
                      style: AppTypography.label.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: AppColors.inkLight,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 10),

            // — Billed Section (Previous period) —
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: breakdown.hasBilledCharges
                    ? AppColors.stampRed.withValues(alpha: 0.08)
                    : AppColors.paper.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'BILLED',
                            style: AppTypography.label.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              color: breakdown.hasBilledCharges
                                  ? AppColors.stampRed
                                  : AppColors.inkLight,
                            ),
                          ),
                          if (breakdown.dueDate != null &&
                              breakdown.hasBilledCharges) ...[
                            const SizedBox(width: 4),
                            Text(
                              '• Due ${DateFormat('MMM d').format(breakdown.dueDate!)}',
                              style: AppTypography.label.copyWith(
                                fontSize: 10,
                                color: AppColors.stampRed,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        billedFormatted,
                        style: AppTypography.amountSmall.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: breakdown.hasBilledCharges
                              ? AppColors.stampRed
                              : AppColors.inkLight,
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    breakdown.hasBilledCharges
                        ? Icons.warning_amber_rounded
                        : Icons.check_circle_outline,
                    size: 18,
                    color: breakdown.hasBilledCharges
                        ? AppColors.stampRed
                        : AppColors.inkGreen,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // — Unbilled Section (Current open cycle) —
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'UNBILLED (Current)',
                        style: AppTypography.label.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.inkLight,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        unbilledFormatted,
                        style: AppTypography.amountSmall.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.inkBlue,
                        ),
                      ),
                    ],
                  ),
                ),
                if (breakdown.unbilledPeriod != null)
                  Text(
                    _formatRange(breakdown.unbilledPeriod!),
                    style: AppTypography.label.copyWith(
                      fontSize: 10,
                      color: AppColors.inkLight,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatRange(DateTimeRange range) {
    final startStr = DateFormat('MMM d').format(range.start);
    final endStr = DateFormat('MMM d').format(range.end);
    return '$startStr – $endStr';
  }

  String _ordinal(int n) {
    if (n >= 11 && n <= 13) return '${n}th';
    switch (n % 10) {
      case 1:
        return '${n}st';
      case 2:
        return '${n}nd';
      case 3:
        return '${n}rd';
      default:
        return '${n}th';
    }
  }
}
