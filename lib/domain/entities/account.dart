import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import 'enums.dart';

/// A financial account — either an asset (debit/cash), liability (credit), or personal debt.
class Account extends Equatable {
  /// Unique identifier.
  final String id;

  /// User-facing name, e.g. "BCA Debit", "Cash Wallet", "Budi".
  final String name;

  /// Whether this is a debit, cash, credit, or personal debt account.
  final AccountType type;

  /// Current balance in the smallest currency unit (cents / sen).
  /// Positive for assets, positive for credit = amount owed.
  /// For debt accounts: positive = they owe me, negative = I owe them.
  final int balance;

  /// ISO 4217 currency code, e.g. 'IDR', 'USD'.
  final String currency;

  /// Soft-deleted accounts are archived but retain history.
  final bool isArchived;

  /// When this account was created.
  final DateTime createdAt;

  /// The day of month when the credit card statement closes (1–28).
  /// Only meaningful for [AccountType.credit].
  /// Example: 20 means the billing cycle runs from 21st → 20th.
  final int? statementCloseDay;

  const Account({
    required this.id,
    required this.name,
    required this.type,
    required this.balance,
    this.currency = 'IDR',
    this.isArchived = false,
    required this.createdAt,
    this.statementCloseDay,
  });

  /// Whether this account counts as an asset (debit / cash, or positive debt receivable).
  bool get isAsset =>
      type == AccountType.debit ||
      type == AccountType.cash ||
      (type == AccountType.debt && balance > 0);

  /// Whether this account counts as a liability (credit, or negative debt payable).
  bool get isLiability =>
      type == AccountType.credit || (type == AccountType.debt && balance < 0);

  /// Whether this is a personal debt account.
  bool get isDebt => type == AccountType.debt;

  /// Whether this credit card has a billing cycle configured.
  bool get hasBillingCycle =>
      type == AccountType.credit && statementCloseDay != null;

  /// Calculates the current billing cycle date range based on [statementCloseDay].
  ///
  /// If [statementCloseDay] is 20:
  ///   On Sept 15 → current period is Aug 21 – Sep 20
  ///   On Sept 25 → current period is Sep 21 – Oct 20
  DateTimeRange? currentBillingPeriod([DateTime? now]) {
    if (!hasBillingCycle) return null;
    final effectiveNow = now ?? DateTime.now();
    final closeDay = _clampDay(
      statementCloseDay!,
      effectiveNow.year,
      effectiveNow.month,
    );

    if (effectiveNow.day <= closeDay) {
      // We're in the current statement period
      final prevMonth = DateTime(effectiveNow.year, effectiveNow.month - 1);
      final startDay = _clampDay(
        statementCloseDay! + 1,
        prevMonth.year,
        prevMonth.month,
      );
      return DateTimeRange(
        start: DateTime(prevMonth.year, prevMonth.month, startDay),
        end: DateTime(effectiveNow.year, effectiveNow.month, closeDay, 23, 59, 59),
      );
    } else {
      // Past the close date — new period started
      final nextMonth = DateTime(effectiveNow.year, effectiveNow.month + 1);
      final endDay = _clampDay(
        statementCloseDay!,
        nextMonth.year,
        nextMonth.month,
      );
      return DateTimeRange(
        start: DateTime(effectiveNow.year, effectiveNow.month, statementCloseDay! + 1),
        end: DateTime(nextMonth.year, nextMonth.month, endDay, 23, 59, 59),
      );
    }
  }

  /// Returns the previous billing period (billed, payment due).
  DateTimeRange? previousBillingPeriod([DateTime? now]) {
    if (!hasBillingCycle) return null;
    final effectiveNow = now ?? DateTime.now();
    final current = currentBillingPeriod(effectiveNow);
    if (current == null) return null;

    final prevEnd = current.start.subtract(const Duration(days: 1));
    final prevPrevMonth = DateTime(prevEnd.year, prevEnd.month - 1);
    final startDay = _clampDay(
      statementCloseDay! + 1,
      prevPrevMonth.year,
      prevPrevMonth.month,
    );
    return DateTimeRange(
      start: DateTime(prevPrevMonth.year, prevPrevMonth.month, startDay),
      end: DateTime(prevEnd.year, prevEnd.month, prevEnd.day, 23, 59, 59),
    );
  }

  static int _clampDay(int day, int year, int month) {
    final maxDays = DateTime(year, month + 1, 0).day;
    return day > maxDays ? maxDays : day;
  }

  /// Returns a copy with the given fields replaced.
  Account copyWith({
    String? id,
    String? name,
    AccountType? type,
    int? balance,
    String? currency,
    bool? isArchived,
    DateTime? createdAt,
    int? statementCloseDay,
    bool clearStatementCloseDay = false,
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      balance: balance ?? this.balance,
      currency: currency ?? this.currency,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      statementCloseDay: clearStatementCloseDay
          ? null
          : (statementCloseDay ?? this.statementCloseDay),
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    type,
    balance,
    currency,
    isArchived,
    createdAt,
    statementCloseDay,
  ];
}

