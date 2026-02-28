import 'package:intl/intl.dart';

/// Utilities for formatting monetary amounts.
class CurrencyFormatter {
  CurrencyFormatter._();

  /// Formats [cents] as a currency string.
  ///
  /// Uses the account's [currency] code to determine the symbol and locale.
  /// Example: `formatCents(1500000, currency: 'USD')` → `"$15,000.00"`.
  static String formatCents(int cents, {String currency = 'IDR'}) {
    final format = NumberFormat.currency(
      locale: _locale(currency),
      symbol: _symbol(currency),
      decimalDigits: _decimalDigits(currency),
    );
    final value = _decimalDigits(currency) == 0
        ? cents.toDouble()
        : cents / 100.0;
    return format.format(value);
  }

  /// Formats [cents] without the currency symbol (just the number).
  static String formatCentsPlain(int cents, {String currency = 'IDR'}) {
    final format = NumberFormat.decimalPattern(_locale(currency));
    final value = _decimalDigits(currency) == 0
        ? cents.toDouble()
        : cents / 100.0;
    return format.format(value);
  }

  /// Returns the currency symbol for a given [currency] code.
  static String symbol(String currency) => _symbol(currency);

  /// Number of decimal digits for this currency (0 for IDR/JPY/KRW, 2 for most).
  static int decimalDigits(String currency) => _decimalDigits(currency);

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

  static String _locale(String currency) {
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
      case 'KRW':
        return 'ko_KR';
      case 'SGD':
        return 'en_SG';
      case 'MYR':
        return 'ms_MY';
      default:
        return 'en_US';
    }
  }

  static String _symbol(String currency) {
    // Use NumberFormat to resolve the symbol automatically when possible.
    try {
      return NumberFormat.simpleCurrency(
        locale: _locale(currency),
        name: currency,
      ).currencySymbol;
    } catch (_) {
      // Fallback: just use the code itself (e.g. "BTC").
      return '$currency ';
    }
  }
}
