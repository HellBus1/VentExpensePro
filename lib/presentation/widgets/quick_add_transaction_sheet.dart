import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/category_icon_mapper.dart';
import '../../domain/entities/account.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/enums.dart';

/// Quick-add bottom sheet: Category → Amount → Source → Log It ✓
///
/// Returns a `Map<String, dynamic>` with keys:
/// `type`, `categoryId`, `amount`, `accountId`, `toAccountId`, `note`, `dateTime`.
class QuickAddTransactionSheet extends StatefulWidget {
  /// Available categories (pre-seeded + custom).
  final List<Category> categories;

  /// Available (non-archived) accounts.
  final List<Account> accounts;

  /// If provided, the sheet operates in edit mode.
  final Map<String, dynamic>? initialValues;

  const QuickAddTransactionSheet({
    super.key,
    required this.categories,
    required this.accounts,
    this.initialValues,
  });

  @override
  State<QuickAddTransactionSheet> createState() =>
      _QuickAddTransactionSheetState();
}

class _QuickAddTransactionSheetState extends State<QuickAddTransactionSheet> {
  late TransactionType _type;
  String? _categoryId;
  final _amountController = TextEditingController();
  String? _accountId;
  String? _toAccountId;
  final _noteController = TextEditingController();
  late DateTime _dateTime;

  String? _validationError;

  bool get _isEditing => widget.initialValues != null;

  @override
  void initState() {
    super.initState();
    final init = widget.initialValues;
    if (init != null) {
      _type = init['type'] as TransactionType;
      _categoryId = init['categoryId'] as String?;
      _amountController.text = (init['amount'] as int).toString();
      _accountId = init['accountId'] as String?;
      _toAccountId = init['toAccountId'] as String?;
      _noteController.text = (init['note'] as String?) ?? '';
      _dateTime = init['dateTime'] as DateTime;
    } else {
      _type = TransactionType.expense;
      _dateTime = DateTime.now();
      // Pre-select first account if available
      if (widget.accounts.isNotEmpty) {
        _accountId = widget.accounts.first.id;
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  /// Filtered categories: hide "settlement" from regular category grid.
  List<Category> get _visibleCategories =>
      widget.categories.where((c) => c.id != 'settlement').toList();

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
        child: SingleChildScrollView(
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
            const SizedBox(height: 12),

            // — Title —
            Text(
              _isEditing ? 'Edit Transaction' : 'Log Transaction',
              style: AppTypography.titleLarge.copyWith(
                color: AppColors.inkBlue,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // — Transaction Type Tabs —
            _buildTypeSelector(),
            const SizedBox(height: 20),

            // — Category Grid —
            Text(
              'CATEGORY',
              style: AppTypography.label.copyWith(letterSpacing: 1.5),
            ),
            const SizedBox(height: 8),
            _buildCategoryGrid(),
            const SizedBox(height: 20),

            // — Amount Field —
            Text(
              'AMOUNT',
              style: AppTypography.label.copyWith(letterSpacing: 1.5),
            ),
            const SizedBox(height: 8),
            _buildAmountField(),
            const SizedBox(height: 16),

            // — Source Account —
            Text(
              _type == TransactionType.transfer ? 'FROM ACCOUNT' : 'ACCOUNT',
              style: AppTypography.label.copyWith(letterSpacing: 1.5),
            ),
            const SizedBox(height: 8),
            _buildAccountChips(
              selectedId: _accountId,
              onSelect: (id) => setState(() => _accountId = id),
            ),

            // — Destination Account (transfer only) —
            if (_type == TransactionType.transfer) ...[
              const SizedBox(height: 16),
              Text(
                'TO ACCOUNT',
                style: AppTypography.label.copyWith(letterSpacing: 1.5),
              ),
              const SizedBox(height: 8),
              _buildAccountChips(
                selectedId: _toAccountId,
                onSelect: (id) => setState(() => _toAccountId = id),
                exclude: _accountId,
              ),
            ],

            const SizedBox(height: 16),

            // — Note Field —
            TextFormField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                hintText: 'e.g. Lunch with friends',
              ),
              textCapitalization: TextCapitalization.sentences,
              maxLines: 1,
            ),

            const SizedBox(height: 12),

            // — Date / Time —
            _buildDateTimePicker(),

            // — Validation Error —
            if (_validationError != null) ...[
              const SizedBox(height: 12),
              Text(
                _validationError!,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.error,
                ),
                textAlign: TextAlign.center,
              ),
            ],

            const SizedBox(height: 20),

            // — Submit Button —
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
                child: Text(_isEditing ? 'Save Changes' : 'Log It ✓'),
              ),
            ),
          ],
        ),
      ),
    ));
  }

  // ——— Sub-widgets ———

  Widget _buildTypeSelector() {
    return Row(
      children: TransactionType.values.map((type) {
        final isSelected = _type == type;
        final color = CategoryIconMapper.colorForType(type);
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: type != TransactionType.transfer ? 8 : 0,
            ),
            child: GestureDetector(
              onTap: () => setState(() {
                _type = type;
                // Clear destination on type change
                if (type != TransactionType.transfer) _toAccountId = null;
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withValues(alpha: 0.12)
                      : AppColors.paper,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? color : AppColors.divider,
                    width: isSelected ? 1.5 : 0.5,
                  ),
                ),
                child: Text(
                  CategoryIconMapper.labelForType(type),
                  style: AppTypography.label.copyWith(
                    color: isSelected ? color : AppColors.disabled,
                    fontSize: 11,
                    letterSpacing: 1.0,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCategoryGrid() {
    final cats = _visibleCategories;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.0,
      ),
      itemCount: cats.length,
      itemBuilder: (context, index) {
        final cat = cats[index];
        final isSelected = _categoryId == cat.id;
        final color = CategoryIconMapper.colorForType(_type);
        return GestureDetector(
          onTap: () => setState(() => _categoryId = cat.id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected
                  ? color.withValues(alpha: 0.12)
                  : AppColors.paperElevated,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? color : Colors.transparent,
                width: isSelected ? 1.5 : 0,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CategoryIconMapper.iconFor(cat.icon),
                  size: 24,
                  color: isSelected ? color : AppColors.inkLight,
                ),
                const SizedBox(height: 4),
                Text(
                  cat.name,
                  style: AppTypography.label.copyWith(
                    color: isSelected ? color : AppColors.inkLight,
                    fontSize: 9,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAmountField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.paperElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider, width: 0.5),
      ),
      child: Row(
        children: [
          Text(
            'Rp',
            style: AppTypography.amountMedium.copyWith(
              color: AppColors.inkLight,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _amountController,
              style: AppTypography.amountLarge.copyWith(
                color: AppColors.inkDark,
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                hintText: '0',
                hintStyle: AppTypography.amountLarge.copyWith(
                  color: AppColors.disabled,
                ),
                border: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
              autofocus: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountChips({
    required String? selectedId,
    required void Function(String) onSelect,
    String? exclude,
  }) {
    final filtered = widget.accounts
        .where((a) => exclude == null || a.id != exclude)
        .toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filtered.map((account) {
          final isSelected = selectedId == account.id;
          final color = account.isLiability
              ? AppColors.stampRed
              : AppColors.inkGreen;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onSelect(account.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withValues(alpha: 0.12)
                      : AppColors.paperElevated,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? color : AppColors.divider,
                    width: isSelected ? 1.5 : 0.5,
                  ),
                ),
                child: Text(
                  account.name,
                  style: AppTypography.bodySmall.copyWith(
                    color: isSelected ? color : AppColors.inkLight,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDateTimePicker() {
    return GestureDetector(
      onTap: _pickDateTime,
      child: Row(
        children: [
          const Icon(Icons.calendar_today_outlined,
              size: 18, color: AppColors.inkLight),
          const SizedBox(width: 8),
          Text(
            _formatDateTime(_dateTime),
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.inkBlue,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.edit_outlined, size: 14, color: AppColors.disabled),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(target).inDays;

    String dateStr;
    if (diff == 0) {
      dateStr = 'Today';
    } else if (diff == 1) {
      dateStr = 'Yesterday';
    } else {
      dateStr =
          '${dt.day}/${dt.month}/${dt.year}';
    }
    final timeStr =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return '$dateStr, $timeStr';
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dateTime,
      firstDate: DateTime(2020),
      lastDate: DateTime(DateTime.now().year + 5),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dateTime),
    );
    if (time == null || !mounted) return;

    setState(() {
      _dateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  void _submit() {
    // Validate
    if (_categoryId == null) {
      setState(() => _validationError = 'Please select a category');
      return;
    }
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty || int.tryParse(amountText) == null) {
      setState(() => _validationError = 'Please enter a valid amount');
      return;
    }
    final amount = int.parse(amountText);
    if (amount <= 0) {
      setState(() => _validationError = 'Amount must be greater than zero');
      return;
    }
    if (_accountId == null) {
      setState(() => _validationError = 'Please select an account');
      return;
    }
    if (_type == TransactionType.transfer && _toAccountId == null) {
      setState(
          () => _validationError = 'Please select a destination account');
      return;
    }

    final note = _noteController.text.trim();

    Navigator.of(context).pop(<String, dynamic>{
      'type': _type,
      'categoryId': _categoryId,
      'amount': amount,
      'accountId': _accountId,
      'toAccountId': _toAccountId,
      'note': note.isEmpty ? null : note,
      'dateTime': _dateTime,
    });
  }
}
