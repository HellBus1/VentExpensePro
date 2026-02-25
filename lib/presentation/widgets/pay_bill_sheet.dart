import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/entities/account.dart';
import '../../domain/value_objects/money.dart';

/// Bottom sheet for one-touch credit card bill settlement.
///
/// Shows the credit card's outstanding balance, lets the user pick a source
/// asset account, enter an amount (or tap "Pay Full Balance"), and settle.
class PayBillSheet extends StatefulWidget {
  /// The credit card account to pay.
  final Account creditAccount;

  /// Available source accounts (assets only, non-archived).
  final List<Account> assetAccounts;

  const PayBillSheet({
    super.key,
    required this.creditAccount,
    required this.assetAccounts,
  });

  @override
  State<PayBillSheet> createState() => _PayBillSheetState();
}

class _PayBillSheetState extends State<PayBillSheet> {
  String? _selectedSourceId;
  final _amountController = TextEditingController();
  String? _errorText;

  @override
  void initState() {
    super.initState();
    // Pre-select the first asset account if available
    if (widget.assetAccounts.isNotEmpty) {
      _selectedSourceId = widget.assetAccounts.first.id;
    }
    // Pre-fill with full outstanding balance
    _amountController.text = widget.creditAccount.balance.toString();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Account? get _selectedSource {
    if (_selectedSourceId == null) return null;
    try {
      return widget.assetAccounts.firstWhere((a) => a.id == _selectedSourceId);
    } catch (_) {
      return null;
    }
  }

  void _onPayFullBalance() {
    _amountController.text = widget.creditAccount.balance.toString();
    setState(() => _errorText = null);
  }

  void _onSettle() {
    final amountText = _amountController.text.trim();
    final amount = int.tryParse(amountText);

    if (_selectedSourceId == null) {
      setState(() => _errorText = 'Select a source account');
      return;
    }
    if (amount == null || amount <= 0) {
      setState(() => _errorText = 'Enter a valid amount');
      return;
    }

    final source = _selectedSource;
    if (source != null && amount > source.balance) {
      final formatted = Money(cents: source.balance, currency: source.currency).formatted;
      setState(() => _errorText = 'Insufficient balance ($formatted available)');
      return;
    }

    if (amount > widget.creditAccount.balance) {
      final formatted = Money(
        cents: widget.creditAccount.balance,
        currency: widget.creditAccount.currency,
      ).formatted;
      setState(() =>
          _errorText = 'Amount exceeds outstanding balance ($formatted)');
      return;
    }

    // Return result
    Navigator.of(context).pop({
      'sourceAccountId': _selectedSourceId,
      'creditAccountId': widget.creditAccount.id,
      'amount': amount,
    });
  }

  @override
  Widget build(BuildContext context) {
    final outstandingBalance = Money(
      cents: widget.creditAccount.balance,
      currency: widget.creditAccount.currency,
    );

    return RepaintBoundary(
      child: Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // — Handle bar —
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // — Header —
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.transferAmber.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.payments_outlined,
                  color: AppColors.transferAmber,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pay Bill',
                      style: AppTypography.titleLarge.copyWith(
                        color: AppColors.inkBlue,
                      ),
                    ),
                    Text(
                      widget.creditAccount.name,
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'OUTSTANDING',
                    style: AppTypography.label.copyWith(
                      fontSize: 9,
                      letterSpacing: 1.5,
                      color: AppColors.stampRed,
                    ),
                  ),
                  Text(
                    outstandingBalance.formatted,
                    style: AppTypography.amountMedium.copyWith(
                      color: AppColors.stampRed,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // — Source Account Label —
          Text(
            'PAY FROM',
            style: AppTypography.label.copyWith(
              letterSpacing: 2.0,
              color: AppColors.inkLight,
            ),
          ),
          const SizedBox(height: 8),

          // — Source Account Chips —
          if (widget.assetAccounts.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No asset accounts available',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.disabled,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: widget.assetAccounts.map((account) {
                final isSelected = account.id == _selectedSourceId;
                final balance = Money(
                  cents: account.balance,
                  currency: account.currency,
                );
                return ChoiceChip(
                  label: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        account.name,
                        style: AppTypography.bodySmall.copyWith(
                          color: isSelected
                              ? AppColors.paper
                              : AppColors.inkDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        balance.formatted,
                        style: AppTypography.label.copyWith(
                          fontSize: 10,
                          color: isSelected
                              ? AppColors.paper.withValues(alpha: 0.8)
                              : AppColors.inkGreen,
                        ),
                      ),
                    ],
                  ),
                  selected: isSelected,
                  onSelected: (_) {
                    setState(() {
                      _selectedSourceId = account.id;
                      _errorText = null;
                    });
                  },
                  selectedColor: AppColors.inkGreen,
                  backgroundColor: AppColors.inkGreenLight,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: isSelected
                          ? AppColors.inkGreen
                          : AppColors.divider,
                    ),
                  ),
                  showCheckmark: false,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                );
              }).toList(),
            ),
          const SizedBox(height: 20),

          // — Amount Label + Pay Full Balance —
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'AMOUNT',
                style: AppTypography.label.copyWith(
                  letterSpacing: 2.0,
                  color: AppColors.inkLight,
                ),
              ),
              GestureDetector(
                onTap: _onPayFullBalance,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.transferAmber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AppColors.transferAmber.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    'Pay Full Balance',
                    style: AppTypography.label.copyWith(
                      color: AppColors.transferAmber,
                      fontSize: 10,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // — Amount Input —
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: AppTypography.amountLarge.copyWith(
              color: AppColors.inkDark,
              fontSize: 24,
            ),
            decoration: InputDecoration(
              prefixText: 'Rp ',
              prefixStyle: AppTypography.amountLarge.copyWith(
                color: AppColors.inkLight,
                fontSize: 24,
              ),
              hintText: '0',
              hintStyle: AppTypography.amountLarge.copyWith(
                color: AppColors.disabled,
                fontSize: 24,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.divider),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: AppColors.transferAmber,
                  width: 1.5,
                ),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              errorText: _errorText,
              errorStyle: AppTypography.bodySmall.copyWith(
                color: AppColors.error,
              ),
            ),
            onChanged: (_) {
              if (_errorText != null) setState(() => _errorText = null);
            },
          ),
          const SizedBox(height: 24),

          // — Settle Button —
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: widget.assetAccounts.isEmpty ? null : _onSettle,
              icon: const Icon(Icons.check_circle_outline, size: 20),
              label: Text(
                'Settle',
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.paper,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.transferAmber,
                foregroundColor: AppColors.paper,
                disabledBackgroundColor: AppColors.disabled,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    ));
  }
}
