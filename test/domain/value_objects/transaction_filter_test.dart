import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vent_expense_pro/domain/entities/enums.dart';
import 'package:vent_expense_pro/domain/value_objects/transaction_filter.dart';

void main() {
  group('TransactionFilter Value Object Tests', () {
    test('empty filter should be inactive with 0 active count', () {
      const filter = TransactionFilter.empty;
      expect(filter.isActive, isFalse);
      expect(filter.activeFilterCount, equals(0));
      expect(filter.dateRange, isNull);
      expect(filter.searchText, isNull);
      expect(filter.accountIds, isNull);
      expect(filter.accountTypes, isNull);
      expect(filter.transactionTypes, isNull);
      expect(filter.categoryIds, isNull);
      expect(filter.minAmount, isNull);
      expect(filter.maxAmount, isNull);
    });

    test('isActive and activeFilterCount report correctly for each field', () {
      final now = DateTime.now();

      // Date range
      final f1 = TransactionFilter(
        dateRange: DateTimeRange(start: now, end: now),
      );
      expect(f1.isActive, isTrue);
      expect(f1.activeFilterCount, equals(1));

      // Search text (whitespace only should be inactive)
      const f2Empty = TransactionFilter(searchText: '   ');
      expect(f2Empty.isActive, isFalse);
      expect(f2Empty.activeFilterCount, equals(0));

      const f2 = TransactionFilter(searchText: 'lunch');
      expect(f2.isActive, isTrue);
      expect(f2.activeFilterCount, equals(1));

      // Account IDs
      const f3 = TransactionFilter(accountIds: ['acc1']);
      expect(f3.isActive, isTrue);
      expect(f3.activeFilterCount, equals(1));

      // Account Types
      const f4 = TransactionFilter(accountTypes: [AccountType.credit]);
      expect(f4.isActive, isTrue);
      expect(f4.activeFilterCount, equals(1));

      // Transaction Types
      const f5 = TransactionFilter(transactionTypes: [TransactionType.expense]);
      expect(f5.isActive, isTrue);
      expect(f5.activeFilterCount, equals(1));

      // Category IDs
      const f6 = TransactionFilter(categoryIds: ['cat1', 'cat2']);
      expect(f6.isActive, isTrue);
      expect(f6.activeFilterCount, equals(1));

      // Min amount
      const f7 = TransactionFilter(minAmount: 50000);
      expect(f7.isActive, isTrue);
      expect(f7.activeFilterCount, equals(1));

      // Max amount
      const f8 = TransactionFilter(maxAmount: 200000);
      expect(f8.isActive, isTrue);
      expect(f8.activeFilterCount, equals(1));

      // Combined
      final fAll = TransactionFilter(
        dateRange: DateTimeRange(start: now, end: now),
        searchText: 'dinner',
        accountIds: const ['acc1'],
        accountTypes: const [AccountType.debit],
        transactionTypes: const [TransactionType.expense],
        categoryIds: const ['food'],
        minAmount: 10000,
        maxAmount: 50000,
      );
      expect(fAll.isActive, isTrue);
      expect(fAll.activeFilterCount, equals(7)); // min/max counts as 1 dimension
    });

    test('copyWith updates fields and clears fields accurately', () {
      final now = DateTime.now();
      final original = TransactionFilter(
        dateRange: DateTimeRange(start: now, end: now),
        searchText: 'coffee',
        accountIds: const ['acc1'],
        accountTypes: const [AccountType.cash],
        transactionTypes: const [TransactionType.expense],
        categoryIds: const ['cat1'],
        minAmount: 20000,
        maxAmount: 50000,
      );

      // Copy with updated search text
      final updated = original.copyWith(searchText: 'tea');
      expect(updated.searchText, equals('tea'));
      expect(updated.accountIds, equals(['acc1']));

      // Copy with clears
      final cleared = original.copyWith(
        clearDateRange: true,
        clearSearchText: true,
        clearAccountIds: true,
        clearAccountTypes: true,
        clearTransactionTypes: true,
        clearCategoryIds: true,
        clearMinAmount: true,
        clearMaxAmount: true,
      );
      expect(cleared.isActive, isFalse);
      expect(cleared.activeFilterCount, equals(0));
    });

    test('equality and props support', () {
      final now = DateTime(2026, 9, 21);
      final range = DateTimeRange(start: now, end: now);

      final f1 = TransactionFilter(
        dateRange: range,
        searchText: 'groceries',
        accountIds: const ['acc1'],
      );
      final f2 = TransactionFilter(
        dateRange: range,
        searchText: 'groceries',
        accountIds: const ['acc1'],
      );
      final f3 = TransactionFilter(
        dateRange: range,
        searchText: 'groceries',
        accountIds: const ['acc2'],
      );

      expect(f1, equals(f2));
      expect(f1 == f3, isFalse);
      expect(f1.hashCode, equals(f2.hashCode));
    });
  });
}
