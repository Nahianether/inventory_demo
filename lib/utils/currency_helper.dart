import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';

/// Currency Helper Utility
///
/// Provides easy-to-use functions for formatting amounts with the selected currency.
/// Use these helpers throughout the app to ensure consistent currency display.
class CurrencyHelper {
  /// Format an amount with the selected currency
  ///
  /// Example:
  /// ```dart
  /// final formatted = CurrencyHelper.format(ref, 1500.50);
  /// // Returns: "৳1500.50" (if BDT is selected)
  /// ```
  static String format(WidgetRef ref, double amount) {
    final currency = ref.watch(currencyProvider);
    return currency.format(amount);
  }

  /// Format an amount with the selected currency (async version for non-widget contexts)
  ///
  /// Example:
  /// ```dart
  /// final formatted = await CurrencyHelper.formatAsync(ref, 1500.50);
  /// ```
  static String formatAsync(Ref ref, double amount) {
    final currency = ref.read(currencyProvider);
    return currency.format(amount);
  }

  /// Format an amount with custom decimal places
  ///
  /// Example:
  /// ```dart
  /// final formatted = CurrencyHelper.formatWithDecimals(ref, 1500.5, decimals: 0);
  /// // Returns: "৳1501" (rounded)
  /// ```
  static String formatWithDecimals(WidgetRef ref, double amount, {required int decimals}) {
    final currency = ref.watch(currencyProvider);
    return '${currency.symbol}${amount.toStringAsFixed(decimals)}';
  }

  /// Format an amount with thousands separator
  ///
  /// Example:
  /// ```dart
  /// final formatted = CurrencyHelper.formatWithSeparator(ref, 1500000.50);
  /// // Returns: "৳1,500,000.50"
  /// ```
  static String formatWithSeparator(WidgetRef ref, double amount) {
    final currency = ref.watch(currencyProvider);
    final parts = amount.toStringAsFixed(2).split('.');
    final integerPart = parts[0];
    final decimalPart = parts.length > 1 ? parts[1] : '00';

    // Add thousands separator
    final buffer = StringBuffer();
    var count = 0;
    for (var i = integerPart.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(integerPart[i]);
      count++;
    }

    final formattedInteger = buffer.toString().split('').reversed.join('');
    return '${currency.symbol}$formattedInteger.$decimalPart';
  }

  /// Get the currency symbol only
  ///
  /// Example:
  /// ```dart
  /// final symbol = CurrencyHelper.getSymbol(ref);
  /// // Returns: "৳"
  /// ```
  static String getSymbol(WidgetRef ref) {
    final currency = ref.watch(currencyProvider);
    return currency.symbol;
  }

  /// Get the currency code
  ///
  /// Example:
  /// ```dart
  /// final code = CurrencyHelper.getCode(ref);
  /// // Returns: "BDT"
  /// ```
  static String getCode(WidgetRef ref) {
    final currency = ref.watch(currencyProvider);
    return currency.code;
  }

  /// Get the currency name
  ///
  /// Example:
  /// ```dart
  /// final name = CurrencyHelper.getName(ref);
  /// // Returns: "Bangladeshi Taka"
  /// ```
  static String getName(WidgetRef ref) {
    final currency = ref.watch(currencyProvider);
    return currency.name;
  }

  /// Format a percentage value
  ///
  /// Example:
  /// ```dart
  /// final formatted = CurrencyHelper.formatPercentage(0.15);
  /// // Returns: "15.00%"
  /// ```
  static String formatPercentage(double value, {int decimals = 2}) {
    return '${(value * 100).toStringAsFixed(decimals)}%';
  }

  /// Format large numbers with K, M, B suffixes
  ///
  /// Example:
  /// ```dart
  /// final formatted = CurrencyHelper.formatCompact(ref, 1500000);
  /// // Returns: "৳1.5M"
  /// ```
  static String formatCompact(WidgetRef ref, double amount) {
    final currency = ref.watch(currencyProvider);

    if (amount >= 1000000000) {
      return '${currency.symbol}${(amount / 1000000000).toStringAsFixed(1)}B';
    } else if (amount >= 1000000) {
      return '${currency.symbol}${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${currency.symbol}${(amount / 1000).toStringAsFixed(1)}K';
    } else {
      return currency.format(amount);
    }
  }

  /// Parse a currency string back to double
  /// Removes currency symbol and thousands separators
  ///
  /// Example:
  /// ```dart
  /// final amount = CurrencyHelper.parse('৳1,500.50');
  /// // Returns: 1500.50
  /// ```
  static double parse(String formattedAmount) {
    // Remove all non-numeric characters except decimal point and minus sign
    final cleaned = formattedAmount.replaceAll(RegExp(r'[^\d.-]'), '');
    return double.tryParse(cleaned) ?? 0.0;
  }
}

/// Extension method on double for easier currency formatting
extension CurrencyFormatting on double {
  /// Format this amount with the selected currency
  ///
  /// Example:
  /// ```dart
  /// Text(1500.50.toCurrency(ref))
  /// ```
  String toCurrency(WidgetRef ref) {
    return CurrencyHelper.format(ref, this);
  }

  /// Format this amount with thousands separator
  String toCurrencyWithSeparator(WidgetRef ref) {
    return CurrencyHelper.formatWithSeparator(ref, this);
  }

  /// Format this amount in compact form (K, M, B)
  String toCurrencyCompact(WidgetRef ref) {
    return CurrencyHelper.formatCompact(ref, this);
  }

  /// Format this value as a percentage
  String toPercentage({int decimals = 2}) {
    return CurrencyHelper.formatPercentage(this, decimals: decimals);
  }
}
