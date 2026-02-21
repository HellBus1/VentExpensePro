import 'package:flutter/material.dart';

import '../../domain/entities/enums.dart';
import '../theme/app_colors.dart';

/// Maps category icon identifiers to Material [IconData].
class CategoryIconMapper {
  CategoryIconMapper._();

  /// Returns the [IconData] for a given category [iconId].
  static IconData iconFor(String iconId) {
    switch (iconId) {
      case 'food':
        return Icons.restaurant_outlined;
      case 'transport':
        return Icons.directions_bus_outlined;
      case 'bills':
        return Icons.receipt_outlined;
      case 'shopping':
        return Icons.shopping_bag_outlined;
      case 'entertainment':
        return Icons.movie_outlined;
      case 'health':
        return Icons.favorite_outlined;
      case 'education':
        return Icons.school_outlined;
      case 'other':
        return Icons.more_horiz_outlined;
      case 'settlement':
        return Icons.sync_alt_outlined;
      default:
        return Icons.category_outlined;
    }
  }

  /// Returns the accent [Color] for a given [TransactionType].
  static Color colorForType(TransactionType type) {
    switch (type) {
      case TransactionType.expense:
        return AppColors.stampRed;
      case TransactionType.income:
        return AppColors.inkGreen;
      case TransactionType.transfer:
        return AppColors.transferAmber;
    }
  }

  /// Returns a human-readable label for a [TransactionType].
  static String labelForType(TransactionType type) {
    switch (type) {
      case TransactionType.expense:
        return 'Expense';
      case TransactionType.income:
        return 'Income';
      case TransactionType.transfer:
        return 'Transfer';
    }
  }

  /// Returns the prefix sign for display (e.g., "−" for expense, "+" for income).
  static String signForType(TransactionType type) {
    switch (type) {
      case TransactionType.expense:
        return '− ';
      case TransactionType.income:
        return '+ ';
      case TransactionType.transfer:
        return '';
    }
  }
}
