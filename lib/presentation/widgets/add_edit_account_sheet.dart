import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/entities/account.dart';
import '../../domain/entities/enums.dart';
import '../providers/currency_provider.dart';

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
  late AccountType _selectedType;
  int? _statementCloseDay;
  bool _isIOweThem = false;

  bool get _isEditing => widget.existingAccount != null;

  @override
  void initState() {
    super.initState();
    final account = widget.existingAccount;
    _nameController = TextEditingController(text: account?.name ?? '');
    _selectedType = account?.type ?? AccountType.debit;
    _statementCloseDay = account?.statementCloseDay;

    if (account != null) {
      if (account.isDebt && account.balance < 0) {
        _isIOweThem = true;
        _balanceController = TextEditingController(
          text: account.balance.abs().toString(),
        );
      } else {
        _balanceController = TextEditingController(
          text: account.balance.toString(),
        );
      }
    } else {
      _balanceController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  Color _colorForType(AccountType type) {
    switch (type) {
      case AccountType.debit:
      case AccountType.cash:
        return AppColors.inkGreen;
      case AccountType.credit:
        return AppColors.stampRed;
      case AccountType.debt:
        return AppColors.inkBlue;
    }
  }

  String _getDaySuffix(int day) {
    if (day >= 11 && day <= 13) return 'th';
    switch (day % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Padding(
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
              decoration: InputDecoration(
                labelText: _selectedType == AccountType.debt
                    ? 'Person / Contact Name'
                    : 'Account Name',
                hintText: _selectedType == AccountType.debt
                    ? 'e.g. Budi, Ani'
                    : 'e.g. BCA Debit, Cash Wallet',
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return _selectedType == AccountType.debt
                      ? 'Please enter a contact name'
                      : 'Please enter an account name';
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
                final color = _colorForType(type);
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: GestureDetector(
                      onTap: _isEditing
                          ? null
                          : () => setState(() {
                                _selectedType = type;
                              }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 10),
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
                              size: 18,
                              color: isSelected ? color : AppColors.disabled,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _labelForType(type),
                              style: AppTypography.label.copyWith(
                                color: isSelected ? color : AppColors.disabled,
                                fontSize: 9,
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

            // — Statement Close Day (Credit cards only) —
            if (_selectedType == AccountType.credit) ...[
              Text(
                'BILLING CYCLE STATEMENT CLOSE DAY',
                style: AppTypography.label.copyWith(letterSpacing: 1.5),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.paper,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.divider, width: 0.5),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _statementCloseDay,
                    isExpanded: true,
                    hint: const Text('Select statement close day (1–28)'),
                    items: List.generate(28, (i) => i + 1).map((day) {
                      return DropdownMenuItem<int>(
                        value: day,
                        child: Text('$day${_getDaySuffix(day)} of each month'),
                      );
                    }).toList(),
                    onChanged: (day) =>
                        setState(() => _statementCloseDay = day),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // — Debt Direction (Debt accounts only) —
            if (_selectedType == AccountType.debt) ...[
              Text(
                'DEBT DIRECTION',
                style: AppTypography.label.copyWith(letterSpacing: 1.5),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('They owe me'),
                      selected: !_isIOweThem,
                      selectedColor: AppColors.inkGreen.withValues(alpha: 0.15),
                      labelStyle: AppTypography.bodySmall.copyWith(
                        color: !_isIOweThem
                            ? AppColors.inkGreen
                            : AppColors.inkLight,
                        fontWeight:
                            !_isIOweThem ? FontWeight.w600 : FontWeight.normal,
                      ),
                      onSelected: (selected) {
                        if (selected) setState(() => _isIOweThem = false);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('I owe them'),
                      selected: _isIOweThem,
                      selectedColor: AppColors.stampRed.withValues(alpha: 0.15),
                      labelStyle: AppTypography.bodySmall.copyWith(
                        color: _isIOweThem
                            ? AppColors.stampRed
                            : AppColors.inkLight,
                        fontWeight:
                            _isIOweThem ? FontWeight.w600 : FontWeight.normal,
                      ),
                      onSelected: (selected) {
                        if (selected) setState(() => _isIOweThem = true);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // — Balance field —
            Row(
              children: [
                // Currency symbol (read-only, from global setting)
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
                    context.watch<CurrencyProvider>().symbol.trim(),
                    style: AppTypography.amountMedium.copyWith(
                      color: AppColors.inkLight,
                    ),
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
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: AppTypography.amountMedium,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Enter a balance';
                      }
                      final parsed = int.tryParse(value);
                      if (parsed == null) {
                        return 'Invalid number';
                      }
                      if (parsed < 0) {
                        return 'Enter a positive amount';
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
                child: Text(_isEditing ? 'Save Changes' : 'Create Account'),
              ),
            ),
          ],
        ),
      ),
    ));
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final parsed = int.parse(_balanceController.text.trim());
    final currency = context.read<CurrencyProvider>().currency;

    final int finalBalance;
    if (_selectedType == AccountType.debt && _isIOweThem && parsed > 0) {
      finalBalance = -parsed;
    } else {
      finalBalance = parsed;
    }

    if (_isEditing) {
      final updated = widget.existingAccount!.copyWith(
        name: name,
        balance: finalBalance,
        statementCloseDay:
            _selectedType == AccountType.credit ? _statementCloseDay : null,
        clearStatementCloseDay:
            _selectedType != AccountType.credit || _statementCloseDay == null,
      );
      Navigator.of(context).pop(updated);
    } else {
      Navigator.of(context).pop({
        'name': name,
        'type': _selectedType,
        'balance': finalBalance,
        'currency': currency,
        'statementCloseDay':
            _selectedType == AccountType.credit ? _statementCloseDay : null,
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
      case AccountType.debt:
        return Icons.handshake_outlined;
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
      case AccountType.debt:
        return 'DEBT';
    }
  }
}
