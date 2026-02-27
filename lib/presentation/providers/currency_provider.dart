import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/utils/currency_formatter.dart';

/// Supported currencies with display labels.
class SupportedCurrency {
  final String code;
  final String label;

  const SupportedCurrency(this.code, this.label);
}

/// App-wide currency setting, persisted via SharedPreferences.
class CurrencyProvider extends ChangeNotifier {
  static const _key = 'app_currency';

  String _currency = 'IDR';

  /// All supported currencies.
  static const supported = [
    SupportedCurrency('IDR', 'IDR — Indonesian Rupiah'),
    SupportedCurrency('USD', 'USD — US Dollar'),
    SupportedCurrency('EUR', 'EUR — Euro'),
    SupportedCurrency('GBP', 'GBP — British Pound'),
    SupportedCurrency('SGD', 'SGD — Singapore Dollar'),
    SupportedCurrency('MYR', 'MYR — Malaysian Ringgit'),
    SupportedCurrency('JPY', 'JPY — Japanese Yen'),
    SupportedCurrency('KRW', 'KRW — Korean Won'),
    SupportedCurrency('AUD', 'AUD — Australian Dollar'),
    SupportedCurrency('THB', 'THB — Thai Baht'),
  ];

  // — Getters —

  /// The active currency code (e.g. 'IDR', 'USD').
  String get currency => _currency;

  /// The currency symbol (e.g. 'Rp', '$', '€').
  String get symbol => CurrencyFormatter.symbol(_currency);

  // — Actions —

  /// Loads the saved currency from SharedPreferences.
  Future<void> loadCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    _currency = prefs.getString(_key) ?? 'IDR';
    notifyListeners();
  }

  /// Sets and persists a new global currency.
  Future<void> setCurrency(String code) async {
    if (_currency == code) return;
    _currency = code;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, code);
  }
}
