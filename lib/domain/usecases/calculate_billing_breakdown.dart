import 'package:flutter/material.dart';

import '../entities/account.dart';
import '../entities/enums.dart';
import '../entities/transaction.dart';
import '../value_objects/billing_breakdown.dart';

/// Calculates billed and unbilled financial aggregates for a credit card.
class CalculateBillingBreakdown {
  const CalculateBillingBreakdown();

  BillingBreakdown call(
    Account creditCard,
    List<Transaction> transactions, [
    DateTime? now,
  ]) {
    if (!creditCard.hasBillingCycle) {
      return const BillingBreakdown(
        billedAmount: 0,
        unbilledAmount: 0,
      );
    }

    final effectiveNow = now ?? DateTime.now();
    final billedPeriod = creditCard.previousBillingPeriod(effectiveNow);
    final unbilledPeriod = creditCard.currentBillingPeriod(effectiveNow);

    int billedAmount = 0;
    int unbilledAmount = 0;

    for (final txn in transactions) {
      if (txn.accountId != creditCard.id) continue;
      if (txn.type != TransactionType.expense) continue;

      if (billedPeriod != null && _isInRange(txn.dateTime, billedPeriod)) {
        billedAmount += txn.amount;
      }
      if (unbilledPeriod != null && _isInRange(txn.dateTime, unbilledPeriod)) {
        unbilledAmount += txn.amount;
      }
    }

    return BillingBreakdown(
      billedAmount: billedAmount,
      unbilledAmount: unbilledAmount,
      billedPeriod: billedPeriod,
      unbilledPeriod: unbilledPeriod,
      dueDate: billedPeriod?.end,
    );
  }

  static bool _isInRange(DateTime date, DateTimeRange range) {
    return !date.isBefore(range.start) && !date.isAfter(range.end);
  }
}
