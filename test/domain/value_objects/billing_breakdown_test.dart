import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vent_expense_pro/domain/value_objects/billing_breakdown.dart';

void main() {
  group('BillingBreakdown Value Object Tests', () {
    test('computes totalOutstanding, hasBilledCharges, and hasCharges correctly', () {
      final now = DateTime(2026, 9, 21);
      final billedRange = DateTimeRange(
        start: DateTime(2026, 7, 21),
        end: DateTime(2026, 8, 20, 23, 59, 59),
      );
      final unbilledRange = DateTimeRange(
        start: DateTime(2026, 8, 21),
        end: DateTime(2026, 9, 20, 23, 59, 59),
      );

      final breakdown = BillingBreakdown(
        billedAmount: 1500000,
        unbilledAmount: 450000,
        billedPeriod: billedRange,
        unbilledPeriod: unbilledRange,
        dueDate: now,
      );

      expect(breakdown.billedAmount, equals(1500000));
      expect(breakdown.unbilledAmount, equals(450000));
      expect(breakdown.totalOutstanding, equals(1950000));
      expect(breakdown.hasBilledCharges, isTrue);
      expect(breakdown.hasCharges, isTrue);
      expect(breakdown.dueDate, equals(now));
    });

    test('handles zero charges cleanly', () {
      const breakdown = BillingBreakdown(
        billedAmount: 0,
        unbilledAmount: 0,
      );

      expect(breakdown.totalOutstanding, equals(0));
      expect(breakdown.hasBilledCharges, isFalse);
      expect(breakdown.hasCharges, isFalse);
      expect(breakdown.dueDate, isNull);
    });

    test('supports Equatable equality', () {
      const b1 = BillingBreakdown(billedAmount: 100, unbilledAmount: 200);
      const b2 = BillingBreakdown(billedAmount: 100, unbilledAmount: 200);
      const b3 = BillingBreakdown(billedAmount: 100, unbilledAmount: 300);

      expect(b1, equals(b2));
      expect(b1 == b3, isFalse);
      expect(b1.hashCode, equals(b2.hashCode));
    });
  });
}
