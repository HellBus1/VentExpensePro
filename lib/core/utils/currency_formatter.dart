import 'package:intl/intl.dart';

/// Utilities for formatting monetary amounts.
class CurrencyFormatter {
  CurrencyFormatter._();

  /// Formats [cents] as a currency string.
  ///
  /// Example: `formatCents(1500000)` → `"Rp 1.500.000"` for IDR.
  static String formatCents(int cents, {String currency = 'IDR'}) {
    final format = NumberFormat.currency(
      locale: _locale(currency),
      symbol: _symbol(currency),
      decimalDigits: currency == 'IDR' ? 0 : 2,
    );
    // IDR uses whole units (no cents subdivision in practice).
    final value = currency == 'IDR' ? cents.toDouble() : cents / 100.0;
    return format.format(value);
  }

  /// Formats [cents] without the currency symbol (just the number).
  static String formatCentsPlain(int cents, {String currency = 'IDR'}) {
    final format = NumberFormat.decimalPattern(_locale(currency));
    final value = currency == 'IDR' ? cents.toDouble() : cents / 100.0;
    return format.format(value);
  }

  static String _locale(String currency) {
    switch (currency) {
      case 'IDR':
        return 'id_ID';
      case 'USD':
        return 'en_US';
      default:
        return 'en_US';
    }
  }

  static String _symbol(String currency) {
    switch (currency) {
      case 'IDR':
        return 'Rp ';
      case 'USD':
        return '\$';
      default:
        return currency;
    }
  }
}
