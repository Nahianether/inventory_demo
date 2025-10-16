/// Financial Analytics Model - matches backend /api/analytics/financial
class FinancialAnalytics {
  final double totalInventoryValue;
  final double totalCostValue;
  final double potentialRevenue;
  final double potentialProfit;
  final double profitMargin;
  final int totalProducts;
  final int lowStockCount;
  final int outOfStockCount;
  final double avgProductValue;

  FinancialAnalytics({
    required this.totalInventoryValue,
    required this.totalCostValue,
    required this.potentialRevenue,
    required this.potentialProfit,
    required this.profitMargin,
    required this.totalProducts,
    required this.lowStockCount,
    required this.outOfStockCount,
    required this.avgProductValue,
  });

  factory FinancialAnalytics.fromJson(Map<String, dynamic> json) {
    return FinancialAnalytics(
      totalInventoryValue: (json['total_inventory_value'] as num).toDouble(),
      totalCostValue: (json['total_cost_value'] as num).toDouble(),
      potentialRevenue: (json['potential_revenue'] as num).toDouble(),
      potentialProfit: (json['potential_profit'] as num).toDouble(),
      profitMargin: (json['profit_margin'] as num).toDouble(),
      totalProducts: json['total_products'] as int,
      lowStockCount: json['low_stock_count'] as int,
      outOfStockCount: json['out_of_stock_count'] as int,
      avgProductValue: (json['avg_product_value'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'total_inventory_value': totalInventoryValue,
        'total_cost_value': totalCostValue,
        'potential_revenue': potentialRevenue,
        'potential_profit': potentialProfit,
        'profit_margin': profitMargin,
        'total_products': totalProducts,
        'low_stock_count': lowStockCount,
        'out_of_stock_count': outOfStockCount,
        'avg_product_value': avgProductValue,
      };
}
