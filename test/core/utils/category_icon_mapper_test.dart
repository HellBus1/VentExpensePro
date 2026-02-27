import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vent_expense_pro/core/utils/category_icon_mapper.dart';
import 'package:vent_expense_pro/domain/entities/enums.dart';

void main() {
  group('CategoryIconMapper', () {
    group('iconFor', () {
      test('should return restaurant icon for food', () {
        expect(
            CategoryIconMapper.iconFor('food'), Icons.restaurant_outlined);
      });

      test('should return bus icon for transport', () {
        expect(CategoryIconMapper.iconFor('transport'),
            Icons.directions_bus_outlined);
      });

      test('should return receipt icon for bills', () {
        expect(CategoryIconMapper.iconFor('bills'), Icons.receipt_outlined);
      });

      test('should return shopping bag icon for shopping', () {
        expect(CategoryIconMapper.iconFor('shopping'),
            Icons.shopping_bag_outlined);
      });

      test('should return movie icon for entertainment', () {
        expect(CategoryIconMapper.iconFor('entertainment'),
            Icons.movie_outlined);
      });

      test('should return heart icon for health', () {
        expect(
            CategoryIconMapper.iconFor('health'), Icons.favorite_outlined);
      });

      test('should return school icon for education', () {
        expect(
            CategoryIconMapper.iconFor('education'), Icons.school_outlined);
      });

      test('should return more icon for other', () {
        expect(CategoryIconMapper.iconFor('other'), Icons.more_horiz_outlined);
      });

      test('should return sync icon for settlement', () {
        expect(CategoryIconMapper.iconFor('settlement'),
            Icons.sync_alt_outlined);
      });

      test('should return category icon for unknown', () {
        expect(CategoryIconMapper.iconFor('unknown_category'),
            Icons.category_outlined);
      });
    });

    group('labelForType', () {
      test('should return "Expense" for expense type', () {
        expect(
            CategoryIconMapper.labelForType(TransactionType.expense),
            'Expense');
      });

      test('should return "Income" for income type', () {
        expect(
            CategoryIconMapper.labelForType(TransactionType.income),
            'Income');
      });

      test('should return "Transfer" for transfer type', () {
        expect(
            CategoryIconMapper.labelForType(TransactionType.transfer),
            'Transfer');
      });
    });

    group('signForType', () {
      test('should return minus sign for expense', () {
        expect(
            CategoryIconMapper.signForType(TransactionType.expense), '− ');
      });

      test('should return plus sign for income', () {
        expect(
            CategoryIconMapper.signForType(TransactionType.income), '+ ');
      });

      test('should return empty string for transfer', () {
        expect(
            CategoryIconMapper.signForType(TransactionType.transfer), '');
      });
    });

    group('colorForType', () {
      test('should return a color for each transaction type', () {
        expect(CategoryIconMapper.colorForType(TransactionType.expense),
            isA<Color>());
        expect(CategoryIconMapper.colorForType(TransactionType.income),
            isA<Color>());
        expect(CategoryIconMapper.colorForType(TransactionType.transfer),
            isA<Color>());
      });

      test('should return different colors for different types', () {
        final expense =
            CategoryIconMapper.colorForType(TransactionType.expense);
        final income =
            CategoryIconMapper.colorForType(TransactionType.income);
        final transfer =
            CategoryIconMapper.colorForType(TransactionType.transfer);
        expect(expense, isNot(equals(income)));
        expect(expense, isNot(equals(transfer)));
      });
    });
  });
}
