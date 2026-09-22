import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Financial aggregate of billed and unbilled charges for a credit card account.
class BillingBreakdown extends Equatable {
  /// Total expenses in the previous (closed) billing cycle.
  final int billedAmount;

  /// Total expenses accrued in the current (open) billing cycle.
  final int unbilledAmount;

  /// The previous billing cycle date range.
  final DateTimeRange? billedPeriod;

  /// The current billing cycle date range.
  final DateTimeRange? unbilledPeriod;

  /// The due date for the billed amount (typically the statement close date of the previous period).
  final DateTime? dueDate;

  const BillingBreakdown({
    required this.billedAmount,
    required this.unbilledAmount,
    this.billedPeriod,
    this.unbilledPeriod,
    this.dueDate,
  });

  /// Total credit card spending across both billed and unbilled periods.
  int get totalOutstanding => billedAmount + unbilledAmount;

  /// Whether there are past billed charges awaiting payment.
  bool get hasBilledCharges => billedAmount > 0;

  /// Whether there are any charges (billed or unbilled).
  bool get hasCharges => totalOutstanding > 0;

  @override
  List<Object?> get props => [
        billedAmount,
        unbilledAmount,
        billedPeriod,
        unbilledPeriod,
        dueDate,
      ];
}
