import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/category_icon_mapper.dart';
import '../../domain/entities/category.dart';
import '../providers/category_provider.dart';
import '../providers/transaction_provider.dart';

/// Available icon options for category creation/editing.
const _availableIcons = [
  'food',
  'transport',
  'bills',
  'shopping',
  'entertainment',
  'health',
  'education',
  'other',
];

/// Full-screen bottom sheet for managing categories (add, edit, delete).
class ManageCategoriesSheet extends StatefulWidget {
  const ManageCategoriesSheet({super.key});

  @override
  State<ManageCategoriesSheet> createState() => _ManageCategoriesSheetState();
}

class _ManageCategoriesSheetState extends State<ManageCategoriesSheet> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final catProv = context.read<CategoryProvider>();
      if (catProv.categories.isEmpty) catProv.loadCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Consumer<CategoryProvider>(
          builder: (context, provider, _) {
            return RepaintBoundary(
              child: Column(
              children: [
                // — Handle bar —
                Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 8),
                  child: Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.divider,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),

                // — Title —
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Manage Categories',
                        style: AppTypography.titleLarge.copyWith(
                          color: AppColors.inkBlue,
                        ),
                      ),
                      IconButton(
                        onPressed: () => _showAddEditDialog(context),
                        icon: const Icon(Icons.add_circle_outline),
                        color: AppColors.inkBlue,
                        tooltip: 'Add Category',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // — Category List —
                Expanded(
                  child: provider.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.separated(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          itemCount: provider.categories.length,
                          separatorBuilder: (_, index) =>
                              const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final cat = provider.categories[index];
                            // Hide settlement from management
                            if (cat.id == 'settlement') {
                              return const SizedBox.shrink();
                            }
                            return _buildCategoryTile(context, cat);
                          },
                        ),
                ),
              ],
            ));
          },
        );
      },
    );
  }

  Widget _buildCategoryTile(BuildContext context, Category cat) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.inkBlue.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          CategoryIconMapper.iconFor(cat.icon),
          size: 20,
          color: AppColors.inkBlue,
        ),
      ),
      title: Text(cat.name, style: AppTypography.bodyMedium),
      subtitle: cat.isCustom
          ? const Text('Custom', style: AppTypography.bodySmall)
          : const Text('Default', style: AppTypography.bodySmall),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: () => _showAddEditDialog(context, category: cat),
            icon: const Icon(Icons.edit_outlined, size: 20),
            color: AppColors.inkLight,
            tooltip: 'Edit',
          ),
          if (cat.isCustom)
            IconButton(
              onPressed: () => _confirmDelete(context, cat),
              icon: const Icon(Icons.delete_outline, size: 20),
              color: AppColors.stampRed,
              tooltip: 'Delete',
            ),
        ],
      ),
    );
  }

  Future<void> _showAddEditDialog(
    BuildContext context, {
    Category? category,
  }) async {
    final isEditing = category != null;
    final nameController = TextEditingController(text: category?.name ?? '');
    String selectedIcon = category?.icon ?? _availableIcons.first;

    final txnProvider = context.read<TransactionProvider>();
    final catProvider = context.read<CategoryProvider>();
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.paper,
              title: Text(
                isEditing ? 'Edit Category' : 'New Category',
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.inkBlue,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // — Name field —
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Category Name',
                      hintText: 'e.g. Groceries',
                    ),
                    textCapitalization: TextCapitalization.words,
                    autofocus: true,
                  ),
                  const SizedBox(height: 16),

                  // — Icon picker —
                  Text(
                    'ICON',
                    style:
                        AppTypography.label.copyWith(letterSpacing: 1.5),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _availableIcons.map((iconId) {
                      final isSelected = selectedIcon == iconId;
                      return GestureDetector(
                        onTap: () =>
                            setDialogState(() => selectedIcon = iconId),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.inkBlue
                                    .withValues(alpha: 0.12)
                                : AppColors.paperElevated,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.inkBlue
                                  : Colors.transparent,
                              width: isSelected ? 1.5 : 0,
                            ),
                          ),
                          child: Icon(
                            CategoryIconMapper.iconFor(iconId),
                            size: 20,
                            color: isSelected
                                ? AppColors.inkBlue
                                : AppColors.inkLight,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;
                    Navigator.of(ctx).pop({
                      'name': name,
                      'icon': selectedIcon,
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.inkBlue,
                    foregroundColor: AppColors.paper,
                  ),
                  child: Text(isEditing ? 'Save' : 'Create'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null && mounted) {
      if (isEditing) {
        await catProvider.updateCategory(
          category.copyWith(
            name: result['name'],
            icon: result['icon'],
          ),
        );
      } else {
        await catProvider.addCategory(
          id: const Uuid().v4(),
          name: result['name']!,
          icon: result['icon']!,
        );
      }
      // Refresh transaction provider's category cache
      if (mounted) {
        txnProvider.loadAll();
      }
    }
  }

  Future<void> _confirmDelete(BuildContext context, Category cat) async {
    final catProvider = context.read<CategoryProvider>();
    final txnProvider = context.read<TransactionProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text(
          'Delete "${cat.name}"? Existing transactions will keep this category ID but it won\'t appear in the picker.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.stampRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await catProvider.deleteCategory(cat.id);
      if (mounted) {
        txnProvider.loadAll();
      }
    }
  }
}
