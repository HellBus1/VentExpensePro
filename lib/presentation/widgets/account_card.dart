import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/entities/account.dart';
import '../../domain/entities/enums.dart';
import '../../domain/value_objects/money.dart';

/// A card displaying a single account with name, type badge, and balance.
///
/// - Tap to edit
/// - Long press to archive
/// - Optional "Pay" button for credit accounts
class AccountCard extends StatelessWidget {
  final Account account;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onPayBill;
  final VoidCallback? onSettleDebt;

  const AccountCard({
    super.key,
    required this.account,
    this.onTap,
    this.onLongPress,
    this.onPayBill,
    this.onSettleDebt,
  });

  @override
  Widget build(BuildContext context) {
    Color accentColor;
    if (account.isDebt) {
      if (account.balance > 0) {
        accentColor = AppColors.inkGreen;
      } else if (account.balance < 0) {
        accentColor = AppColors.stampRed;
      } else {
        accentColor = AppColors.inkLight;
      }
    } else {
      accentColor = account.isAsset ? AppColors.inkGreen : AppColors.stampRed;
    }

    // Format balance
    String balanceString;
    if (account.isDebt) {
      final absMoney =
          Money(cents: account.balance.abs(), currency: account.currency);
      if (account.balance > 0) {
        balanceString = '+${absMoney.formatted}';
      } else if (account.balance < 0) {
        balanceString = '-${absMoney.formatted}';
      } else {
        balanceString = absMoney.formatted;
      }
    } else {
      balanceString =
          Money(cents: account.balance, currency: account.currency).formatted;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.paper,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.divider, width: 0.5),
            ),
            child: Row(
              children: [
                // — Account icon —
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _iconForType(account.type),
                    color: accentColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),

                // — Name & type badge —
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        account.name,
                        style: AppTypography.titleMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _labelForType(account),
                              style: AppTypography.label.copyWith(
                                color: accentColor,
                                fontSize: 10,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                          if (account.hasBillingCycle) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.inkLight.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Closes ${account.statementCloseDay}th',
                                style: AppTypography.label.copyWith(
                                  color: AppColors.inkLight,
                                  fontSize: 9,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // — Pay Bill button (credit accounts only) —
                if (onPayBill != null) ...[
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 36,
                    height: 36,
                    child: Material(
                      color: AppColors.transferAmber.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      child: InkWell(
                        key: ValueKey('account_pay_bill_btn_${account.name}'),
                        onTap: onPayBill,
                        borderRadius: BorderRadius.circular(8),
                        child: const Icon(
                          Icons.payments_outlined,
                          color: AppColors.transferAmber,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],

                // — Settle button (debt accounts only) —
                if (onSettleDebt != null) ...[
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 36,
                    height: 36,
                    child: Material(
                      color: accentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      child: InkWell(
                        key: ValueKey('account_settle_debt_btn_${account.name}'),
                        onTap: onSettleDebt,
                        borderRadius: BorderRadius.circular(8),
                        child: Icon(
                          Icons.handshake_outlined,
                          color: accentColor,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],

                const SizedBox(width: 8),

                // — Balance —
                Text(
                  balanceString,
                  style: AppTypography.amountMedium.copyWith(
                    color: accentColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _iconForType(AccountType type) {
    switch (type) {
      case AccountType.debit:
        return Icons.account_balance_outlined;
      case AccountType.cash:
        return Icons.payments_outlined;
      case AccountType.credit:
        return Icons.credit_card_outlined;
      case AccountType.debt:
        return Icons.handshake_outlined;
    }
  }

  String _labelForType(Account account) {
    switch (account.type) {
      case AccountType.debit:
        return 'DEBIT';
      case AccountType.cash:
        return 'CASH';
      case AccountType.credit:
        return 'CREDIT';
      case AccountType.debt:
        if (account.balance > 0) return 'OWES YOU';
        if (account.balance < 0) return 'YOU OWE';
        return 'SETTLED';
    }
  }
}
