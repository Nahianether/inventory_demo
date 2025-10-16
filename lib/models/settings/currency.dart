/// Currency Model
class Currency {
  final String code;
  final String symbol;
  final String name;
  final double rate; // Exchange rate to USD (for future conversion)

  const Currency({
    required this.code,
    required this.symbol,
    required this.name,
    this.rate = 1.0,
  });

  String format(double amount) {
    return '$symbol${amount.toStringAsFixed(2)}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Currency && runtimeType == other.runtimeType && code == other.code;

  @override
  int get hashCode => code.hashCode;
}

/// Available Currencies
class Currencies {
  static const Currency bdt = Currency(
    code: 'BDT',
    symbol: '৳',
    name: 'Bangladeshi Taka',
    rate: 110.0, // Example rate to USD
  );

  static const Currency usd = Currency(
    code: 'USD',
    symbol: '\$',
    name: 'US Dollar',
    rate: 1.0,
  );

  static const Currency eur = Currency(
    code: 'EUR',
    symbol: '€',
    name: 'Euro',
    rate: 0.92,
  );

  static const Currency gbp = Currency(
    code: 'GBP',
    symbol: '£',
    name: 'British Pound',
    rate: 0.79,
  );

  static const Currency inr = Currency(
    code: 'INR',
    symbol: '₹',
    name: 'Indian Rupee',
    rate: 83.0,
  );

  static const Currency jpy = Currency(
    code: 'JPY',
    symbol: '¥',
    name: 'Japanese Yen',
    rate: 148.0,
  );

  static const Currency cny = Currency(
    code: 'CNY',
    symbol: '¥',
    name: 'Chinese Yuan',
    rate: 7.2,
  );

  static const Currency aud = Currency(
    code: 'AUD',
    symbol: 'A\$',
    name: 'Australian Dollar',
    rate: 1.52,
  );

  static const Currency cad = Currency(
    code: 'CAD',
    symbol: 'C\$',
    name: 'Canadian Dollar',
    rate: 1.36,
  );

  static const Currency pkr = Currency(
    code: 'PKR',
    symbol: '₨',
    name: 'Pakistani Rupee',
    rate: 278.0,
  );

  static const List<Currency> all = [
    bdt, // Default first
    usd,
    eur,
    gbp,
    inr,
    jpy,
    cny,
    aud,
    cad,
    pkr,
  ];

  static Currency fromCode(String code) {
    return all.firstWhere(
      (c) => c.code == code,
      orElse: () => bdt,
    );
  }
}
