# Currency Helper Usage Guide

This guide shows how to use the CurrencyHelper utility throughout the app to display amounts with the user's selected currency.

## Quick Start

### 1. Import the Currency Helper

```dart
import '../utils/currency_helper.dart';
```

### 2. Use in Consumer Widgets

For widgets that use Riverpod (ConsumerWidget or ConsumerStatefulWidget):

```dart
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final amount = 1500.50;

    return Text(
      CurrencyHelper.format(ref, amount), // Output: ৳1500.50
      style: AppTheme.headingMedium,
    );
  }
}
```

### 3. Use with Extension Methods

```dart
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final amount = 1500.50;

    return Text(
      amount.toCurrency(ref), // Output: ৳1500.50
      style: AppTheme.headingMedium,
    );
  }
}
```

## Common Use Cases

### Format with Thousands Separator

For large amounts, use the separator for better readability:

```dart
final revenue = 1234567.89;
Text(CurrencyHelper.formatWithSeparator(ref, revenue)) // ৳1,234,567.89

// Or using extension:
Text(revenue.toCurrencyWithSeparator(ref)) // ৳1,234,567.89
```

### Compact Format (K, M, B)

For dashboard cards and statistics:

```dart
final totalSales = 1500000.0;
Text(CurrencyHelper.formatCompact(ref, totalSales)) // ৳1.5M

// Or using extension:
Text(totalSales.toCurrencyCompact(ref)) // ৳1.5M
```

### Custom Decimal Places

```dart
final price = 99.99;
Text(CurrencyHelper.formatWithDecimals(ref, price, decimals: 0)) // ৳100
Text(CurrencyHelper.formatWithDecimals(ref, price, decimals: 3)) // ৳99.990
```

### Get Currency Info

```dart
final symbol = CurrencyHelper.getSymbol(ref); // ৳
final code = CurrencyHelper.getCode(ref); // BDT
final name = CurrencyHelper.getName(ref); // Bangladeshi Taka
```

### Format Percentages

```dart
final profitMargin = 0.15;
Text(CurrencyHelper.formatPercentage(profitMargin)) // 15.00%

// Or using extension:
Text(profitMargin.toPercentage()) // 15.00%
Text(profitMargin.toPercentage(decimals: 0)) // 15%
```

## Integration Examples

### Dashboard Stats Card

```dart
Widget _buildStatCard(WidgetRef ref, String label, double value) {
  return AppTheme.buildCard(
    child: Column(
      children: [
        Text(label, style: AppTheme.bodyMedium),
        Text(
          value.toCurrencyWithSeparator(ref),
          style: AppTheme.headingLarge,
        ),
      ],
    ),
  );
}
```

### Transaction List Item

```dart
class TransactionItem extends ConsumerWidget {
  final double amount;
  final String description;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      title: Text(description),
      trailing: Text(
        amount.toCurrency(ref),
        style: AppTheme.headingSmall.copyWith(
          color: amount >= 0 ? AppTheme.successColor : AppTheme.errorColor,
        ),
      ),
    );
  }
}
```

### Chart Tooltip

```dart
LineTooltipItem(
  '${spot.y.toCurrency(ref)}\n${DateFormat('MMM dd').format(date)}',
  const TextStyle(color: Colors.white),
)
```

### Product Price Display

```dart
Widget _buildProductCard(WidgetRef ref, ApiProduct product) {
  return AppTheme.buildCard(
    child: Column(
      children: [
        Text(product.name, style: AppTheme.headingSmall),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Buying:', style: AppTheme.bodySmall),
            Text(
              product.buyingPrice.toCurrency(ref),
              style: AppTheme.bodyMedium,
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Selling:', style: AppTheme.bodySmall),
            Text(
              product.sellingPrice.toCurrency(ref),
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.successColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
```

## Migrating Existing Code

Replace hardcoded currency symbols and formats:

### Before:
```dart
Text('৳${amount.toStringAsFixed(2)}')
Text('\$${product.price}')
Text('Price: ${price.toStringAsFixed(2)} BDT')
```

### After:
```dart
Text(amount.toCurrency(ref))
Text(product.price.toCurrency(ref))
Text('Price: ${price.toCurrency(ref)}')
```

## Important Notes

1. **Always use ref parameter**: The helper needs access to Riverpod's ref to watch currency changes
2. **Use ConsumerWidget**: Your widget must extend ConsumerWidget or ConsumerStatefulWidget
3. **Reactive updates**: When currency changes in settings, all displays update automatically
4. **Consistent formatting**: Use these helpers everywhere for consistent appearance
5. **Performance**: The helpers are lightweight and optimized for frequent use

## Where to Apply

Update currency displays in these screens:
- ✅ Settings Screen (already using AppTheme)
- 🔄 Account/Financial Screen (update to use CurrencyHelper)
- 🔄 Reports Screen (update to use CurrencyHelper)
- 🔄 Product Cards (update to use CurrencyHelper)
- 🔄 Transaction Lists (update to use CurrencyHelper)
- 🔄 Dashboard Stats (update to use CurrencyHelper)
- 🔄 Sale/Purchase Screens (update to use CurrencyHelper)

## Testing

To test currency formatting:

1. Run the app
2. Go to Settings screen
3. Change currency from BDT to USD
4. Navigate to other screens
5. Verify all amounts update to show $ symbol and format

Example test cases:
- Amount: 1500.50 → BDT: ৳1500.50 → USD: $1500.50
- Large amount: 1500000 → BDT: ৳1.5M → USD: $1.5M
- With separator: 1500000 → BDT: ৳1,500,000.00 → USD: $1,500,000.00
