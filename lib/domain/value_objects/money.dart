import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';

/// An immutable representation of a monetary amount.
///
/// Internally stored as an [int] in the smallest currency unit
/// to avoid floating-point precision issues.
class Money extends Equatable {
  /// The amount in the smallest currency unit.
  final int cents;

  /// ISO 4217 currency code (e.g. 'IDR', 'USD', 'EUR').
  final String currency;

  const Money({required this.cents, this.currency = 'IDR'});

  /// Creates a [Money] from a whole-unit double (e.g. 150.00 → 15000 cents).
  factory Money.fromDouble(double amount, {String currency = 'IDR'}) {
    return Money(cents: (amount * 100).round(), currency: currency);
  }

  /// The amount as a double (e.g. 15000 → 150.00).
  double get asDouble => cents / 100.0;

  /// Formatted display string using the currency's symbol and locale.
  String get formatted {
    final format = NumberFormat.currency(
      locale: _localeForCurrency(currency),
      symbol: _symbolForCurrency(currency),
      decimalDigits: _decimalDigits(currency),
    );
    final value = _decimalDigits(currency) == 0 ? cents : asDouble;
    return format.format(value);
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

  static int _decimalDigits(String currency) {
    switch (currency) {
      case 'IDR':
      case 'JPY':
      case 'KRW':
      case 'VND':
        return 0;
      default:
        return 2;
    }
  }

  static String _localeForCurrency(String currency) {
    switch (currency) {
      case 'IDR':
        return 'id_ID';
      case 'USD':
        return 'en_US';
      case 'EUR':
        return 'de_DE';
      case 'GBP':
        return 'en_GB';
      case 'JPY':
        return 'ja_JP';
      default:
        return 'en_US';
    }
  }

  static String _symbolForCurrency(String currency) {
    try {
      return NumberFormat.simpleCurrency(
        locale: _localeForCurrency(currency),
        name: currency,
      ).currencySymbol;
    } catch (_) {
      return '$currency ';
    }
  }

  @override
  List<Object?> get props => [cents, currency];

  @override
  String toString() => formatted;
}
