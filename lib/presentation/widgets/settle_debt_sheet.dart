import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/entities/account.dart';
import '../../domain/entities/enums.dart';
import '../../domain/value_objects/money.dart';
import '../providers/currency_provider.dart';

/// Bottom sheet for settling personal debt (repaying or receiving repayment).
class SettleDebtSheet extends StatefulWidget {
  final Account debtAccount;
  final List<Account> assetAccounts;

  const SettleDebtSheet({
    super.key,
    required this.debtAccount,
    required this.assetAccounts,
  });

  @override
  State<SettleDebtSheet> createState() => _SettleDebtSheetState();
}

class _SettleDebtSheetState extends State<SettleDebtSheet> {
  String? _selectedAssetId;
  final _amountController = TextEditingController();
  String? _errorText;

  bool get _isReceiving => widget.debtAccount.balance > 0;
  int get _outstandingDebt => widget.debtAccount.balance.abs();

  @override
  void initState() {
    super.initState();
    if (widget.assetAccounts.isNotEmpty) {
      _selectedAssetId = widget.assetAccounts.first.id;
    }
    _amountController.text = _outstandingDebt.toString();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Account? get _selectedAsset {
    if (_selectedAssetId == null) return null;
    try {
      return widget.assetAccounts.firstWhere((a) => a.id == _selectedAssetId);
    } catch (_) {
      return null;
    }
  }

  void _onSettleFullAmount() {
    _amountController.text = _outstandingDebt.toString();
    setState(() => _errorText = null);
  }

  void _onSettle() {
    final amountText = _amountController.text.trim();
    final amount = int.tryParse(amountText);

    if (_selectedAssetId == null) {
      setState(() => _errorText = 'Select an account');
      return;
    }
    if (amount == null || amount <= 0) {
      setState(() => _errorText = 'Enter a valid amount');
      return;
    }

    if (amount > _outstandingDebt) {
      final formatted = Money(
        cents: _outstandingDebt,
        currency: widget.debtAccount.currency,
      ).formatted;
      setState(() => _errorText = 'Amount exceeds outstanding debt ($formatted)');
      return;
    }

    // If paying debt to others, ensure sufficient asset balance
    if (!_isReceiving) {
      final asset = _selectedAsset;
      if (asset != null && amount > asset.balance) {
        final formatted =
            Money(cents: asset.balance, currency: asset.currency).formatted;
        setState(() => _errorText = 'Insufficient balance ($formatted available)');
        return;
      }
    }

    Navigator.of(context).pop({
      'assetAccountId': _selectedAssetId,
      'amount': amount,
    });
  }

  @override
  Widget build(BuildContext context) {
    final currencySymbol = context.watch<CurrencyProvider>().symbol.trim();
    final debtMoney = Money(
      cents: _outstandingDebt,
      currency: widget.debtAccount.currency,
    );

    return RepaintBoundary(
      child: Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // — Handle bar —
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // — Title —
            Text(
              _isReceiving ? 'Receive Repayment' : 'Pay Back Debt',
              style: AppTypography.titleLarge.copyWith(
                color: _isReceiving ? AppColors.inkGreen : AppColors.stampRed,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              _isReceiving
                  ? '${widget.debtAccount.name} is paying you back'
                  : 'Repaying money to ${widget.debtAccount.name}',
              style: AppTypography.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // — Outstanding Balance Card —
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: (_isReceiving ? AppColors.inkGreen : AppColors.stampRed)
                    .withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: (_isReceiving ? AppColors.inkGreen : AppColors.stampRed)
                      .withValues(alpha: 0.3),
                  width: 0.5,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isReceiving ? 'THEY OWE YOU' : 'YOU OWE',
                        style: AppTypography.label.copyWith(
                          fontSize: 10,
                          letterSpacing: 1.5,
                          color: _isReceiving
                              ? AppColors.inkGreen
                              : AppColors.stampRed,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.debtAccount.name,
                        style: AppTypography.titleMedium,
                      ),
                    ],
                  ),
                  Text(
                    debtMoney.formatted,
                    style: AppTypography.amountMedium.copyWith(
                      color: _isReceiving
                          ? AppColors.inkGreen
                          : AppColors.stampRed,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // — Asset Account Selector —
            Text(
              _isReceiving ? 'DEPOSIT INTO' : 'PAY FROM',
              style: AppTypography.label.copyWith(letterSpacing: 1.5),
            ),
            const SizedBox(height: 8),

            if (widget.assetAccounts.isEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.paperElevated,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'No debit or cash accounts available',
                  style: AppTypography.bodySmall,
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.paper,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.divider, width: 0.5),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedAssetId,
                    isExpanded: true,
                    icon: const Icon(Icons.arrow_drop_down,
                        color: AppColors.inkLight),
                    items: widget.assetAccounts.map((a) {
                      final balance =
                          Money(cents: a.balance, currency: a.currency);
                      return DropdownMenuItem<String>(
                        value: a.id,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  a.type == AccountType.debit
                                      ? Icons.account_balance_outlined
                                      : Icons.payments_outlined,
                                  size: 18,
                                  color: AppColors.inkLight,
                                ),
                                const SizedBox(width: 8),
                                Text(a.name, style: AppTypography.bodyMedium),
                              ],
                            ),
                            Text(
                              balance.formatted,
                              style: AppTypography.amountSmall.copyWith(
                                color: AppColors.inkLight,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (id) => setState(() {
                      _selectedAssetId = id;
                      _errorText = null;
                    }),
                  ),
                ),
              ),
            const SizedBox(height: 16),

            // — Amount Field —
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'SETTLEMENT AMOUNT',
                  style: AppTypography.label.copyWith(letterSpacing: 1.5),
                ),
                GestureDetector(
                  onTap: _onSettleFullAmount,
                  child: Text(
                    'Full Amount',
                    style: AppTypography.label.copyWith(
                      color: AppColors.inkBlue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.paperElevated,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.divider, width: 0.5),
                  ),
                  child: Text(
                    currencySymbol,
                    style: AppTypography.amountMedium.copyWith(
                      color: AppColors.inkLight,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    key: const ValueKey('settle_debt_amount_input'),
                    controller: _amountController,
                    decoration: const InputDecoration(hintText: '0'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: AppTypography.amountMedium,
                    onChanged: (_) {
                      if (_errorText != null) {
                        setState(() => _errorText = null);
                      }
                    },
                  ),
                ),
              ],
            ),

            if (_errorText != null) ...[
              const SizedBox(height: 8),
              Text(
                _errorText!,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.stampRed,
                ),
              ),
            ],
            const SizedBox(height: 24),

            // — Settle Button —
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                key: const ValueKey('settle_debt_button'),
                onPressed: widget.assetAccounts.isNotEmpty ? _onSettle : null,
                icon: const Icon(Icons.check_circle_outline, size: 20),
                label: Text(_isReceiving ? 'Confirm Repayment' : 'Confirm Payment'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isReceiving
                      ? AppColors.inkGreen
                      : AppColors.stampRed,
                  foregroundColor: AppColors.paper,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: AppTypography.titleMedium.copyWith(
                    color: AppColors.paper,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
