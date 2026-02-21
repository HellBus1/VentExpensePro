import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';

/// An immutable representation of a monetary amount.
///
/// Internally stored as an [int] in the smallest currency unit (e.g. cents)
/// to avoid floating-point precision issues.
class Money extends Equatable {
  /// The amount in the smallest currency unit (e.g. 15000 = Rp 150.00).
  final int cents;

  /// ISO 4217 currency code.
  final String currency;

  const Money({required this.cents, this.currency = 'IDR'});

  /// Creates a [Money] from a whole-unit double (e.g. 150.00 → 15000 cents).
  factory Money.fromDouble(double amount, {String currency = 'IDR'}) {
    return Money(cents: (amount * 100).round(), currency: currency);
  }

  /// The amount as a double (e.g. 15000 → 150.00).
  double get asDouble => cents / 100.0;

  /// Formatted display string (e.g. "Rp 150.00" or "$1,500.00").
  String get formatted {
    final format = NumberFormat.currency(
      locale: _localeForCurrency(currency),
      symbol: _symbolForCurrency(currency),
      decimalDigits: currency == 'IDR' ? 0 : 2,
    );
    return format.format(currency == 'IDR' ? cents : asDouble);
  }

  // — Arithmetic —

  Money operator +(Money other) {
    assert(currency == other.currency, 'Cannot add different currencies');
    return Money(cents: cents + other.cents, currency: currency);
  }

  Money operator -(Money other) {
    assert(currency == other.currency, 'Cannot subtract different currencies');
    return Money(cents: cents - other.cents, currency: currency);
  }

  Money operator -() => Money(cents: -cents, currency: currency);

  bool get isNegative => cents < 0;
  bool get isZero => cents == 0;
  bool get isPositive => cents > 0;

  // — Helpers —

  static String _localeForCurrency(String currency) {
    switch (currency) {
      case 'IDR':
        return 'id_ID';
      case 'USD':
        return 'en_US';
      default:
        return 'en_US';
    }
  }

  static String _symbolForCurrency(String currency) {
    switch (currency) {
      case 'IDR':
        return 'Rp ';
      case 'USD':
        return '\$';
      default:
        return currency;
    }
  }

  @override
  List<Object?> get props => [cents, currency];

  @override
  String toString() => formatted;
}
