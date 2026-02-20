import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/entities/account.dart';
import '../../domain/entities/enums.dart';

/// Bottom sheet for creating or editing an account.
///
/// In edit mode, fields are pre-filled with the existing account data.
class AddEditAccountSheet extends StatefulWidget {
  /// If provided, the sheet operates in edit mode.
  final Account? existingAccount;

  const AddEditAccountSheet({super.key, this.existingAccount});

  @override
  State<AddEditAccountSheet> createState() => _AddEditAccountSheetState();
}

class _AddEditAccountSheetState extends State<AddEditAccountSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _balanceController;
  late final TextEditingController _currencyController;
  late AccountType _selectedType;

  bool get _isEditing => widget.existingAccount != null;

  @override
  void initState() {
    super.initState();
    final account = widget.existingAccount;
    _nameController = TextEditingController(text: account?.name ?? '');
    _balanceController = TextEditingController(
      text: account != null ? account.balance.toString() : '',
    );
    _currencyController = TextEditingController(
      text: account?.currency ?? 'IDR',
    );
    _selectedType = account?.type ?? AccountType.debit;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    _currencyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
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
              _isEditing ? 'Edit Account' : 'New Account',
              style: AppTypography.titleLarge.copyWith(
                color: AppColors.inkBlue,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // — Name field —
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Account Name',
                hintText: 'e.g. BCA Debit, Cash Wallet',
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter an account name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // — Type selector —
            Text(
              'ACCOUNT TYPE',
              style: AppTypography.label.copyWith(letterSpacing: 1.5),
            ),
            const SizedBox(height: 8),
            Row(
              children: AccountType.values.map((type) {
                final isSelected = _selectedType == type;
                final color = (type == AccountType.credit)
                    ? AppColors.stampRed
                    : AppColors.inkGreen;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: type != AccountType.credit ? 8 : 0,
                    ),
                    child: GestureDetector(
                      onTap: _isEditing
                          ? null
                          : () => setState(() => _selectedType = type),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? color.withValues(alpha: 0.1)
                              : AppColors.paper,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? color : AppColors.divider,
                            width: isSelected ? 1.5 : 0.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              _iconForType(type),
                              size: 20,
                              color: isSelected ? color : AppColors.disabled,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _labelForType(type),
                              style: AppTypography.label.copyWith(
                                color: isSelected
                                    ? color
                                    : AppColors.disabled,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // — Balance field —
            Row(
              children: [
                // Currency
                SizedBox(
                  width: 80,
                  child: TextFormField(
                    controller: _currencyController,
                    decoration: const InputDecoration(
                      labelText: 'Currency',
                    ),
                    textAlign: TextAlign.center,
                    textCapitalization: TextCapitalization.characters,
                    enabled: !_isEditing,
                  ),
                ),
                const SizedBox(width: 12),
                // Amount
                Expanded(
                  child: TextFormField(
                    controller: _balanceController,
                    decoration: InputDecoration(
                      labelText: _isEditing ? 'Balance' : 'Initial Balance',
                      hintText: '0',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    style: AppTypography.amountMedium,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Enter a balance';
                      }
                      final parsed = int.tryParse(value);
                      if (parsed == null) {
                        return 'Invalid number';
                      }
                      if (!_isEditing && parsed < 0) {
                        return 'Balance cannot be negative';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // — Submit button —
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.inkBlue,
                  foregroundColor: AppColors.paper,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: AppTypography.titleMedium.copyWith(
                    color: AppColors.paper,
                  ),
                ),
                child: Text(
                  _isEditing ? 'Save Changes' : 'Create Account',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final balance = int.parse(_balanceController.text.trim());
    final currency = _currencyController.text.trim().toUpperCase();

    if (_isEditing) {
      final updated = widget.existingAccount!.copyWith(
        name: name,
        balance: balance,
      );
      Navigator.of(context).pop(updated);
    } else {
      // Return a map with the create params
      Navigator.of(context).pop({
        'name': name,
        'type': _selectedType,
        'balance': balance,
        'currency': currency,
      });
    }
  }

  IconData _iconForType(AccountType type) {
    switch (type) {
      case AccountType.debit:
        return Icons.account_balance_outlined;
      case AccountType.cash:
        return Icons.payments_outlined;
      case AccountType.credit:
        return Icons.credit_card_outlined;
    }
  }

  String _labelForType(AccountType type) {
    switch (type) {
      case AccountType.debit:
        return 'DEBIT';
      case AccountType.cash:
        return 'CASH';
      case AccountType.credit:
        return 'CREDIT';
    }
  }
}
