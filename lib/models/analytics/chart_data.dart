import 'transaction_detail.dart';

/// Sales Chart Data Models - matches backend /api/analytics/charts

class DailySalesData {
  final String date;
  final double totalSales;
  final double totalProfit;
  final int transactionCount;

  DailySalesData({
    required this.date,
    required this.totalSales,
    required this.totalProfit,
    required this.transactionCount,
  });

  factory DailySalesData.fromJson(Map<String, dynamic> json) {
    return DailySalesData(
      date: json['date'] as String,
      totalSales: (json['total_sales'] as num).toDouble(),
      totalProfit: (json['total_profit'] as num).toDouble(),
      transactionCount: json['transaction_count'] as int,
    );
  }
}

class CategorySalesData {
  final String categoryName;
  final double totalSales;
  final double percentage;

  CategorySalesData({
    required this.categoryName,
    required this.totalSales,
    required this.percentage,
  });

  factory CategorySalesData.fromJson(Map<String, dynamic> json) {
    return CategorySalesData(
      categoryName: json['category_name'] as String,
      totalSales: (json['total_sales'] as num).toDouble(),
      percentage: (json['percentage'] as num).toDouble(),
    );
  }
}

class PaymentMethodData {
  final PaymentMethod paymentMethod;
  final double totalAmount;
  final int transactionCount;
  final double percentage;

  PaymentMethodData({
    required this.paymentMethod,
    required this.totalAmount,
    required this.transactionCount,
    required this.percentage,
  });

  factory PaymentMethodData.fromJson(Map<String, dynamic> json) {
    return PaymentMethodData(
      paymentMethod: PaymentMethod.fromString(json['payment_method'] as String),
      totalAmount: (json['total_amount'] as num).toDouble(),
      transactionCount: json['transaction_count'] as int,
      percentage: (json['percentage'] as num).toDouble(),
    );
  }
}

class TopProductData {
  final String productId;
  final String productName;
  final int quantitySold;
  final double totalRevenue;
  final double totalProfit;

  TopProductData({
    required this.productId,
    required this.productName,
    required this.quantitySold,
    required this.totalRevenue,
    required this.totalProfit,
  });

  factory TopProductData.fromJson(Map<String, dynamic> json) {
    return TopProductData(
      productId: json['product_id'] as String,
      productName: json['product_name'] as String,
      quantitySold: json['quantity_sold'] as int,
      totalRevenue: (json['total_revenue'] as num).toDouble(),
      totalProfit: (json['total_profit'] as num).toDouble(),
    );
  }
}

class SalesChartData {
  final List<DailySalesData> dailySales;
  final List<CategorySalesData> categorySales;
  final List<PaymentMethodData> paymentMethodBreakdown;
  final List<TopProductData> topProducts;

  SalesChartData({
    required this.dailySales,
    required this.categorySales,
    required this.paymentMethodBreakdown,
    required this.topProducts,
  });

  factory SalesChartData.fromJson(Map<String, dynamic> json) {
    return SalesChartData(
      dailySales: (json['daily_sales'] as List)
          .map((e) => DailySalesData.fromJson(e as Map<String, dynamic>))
          .toList(),
      categorySales: (json['category_sales'] as List)
          .map((e) => CategorySalesData.fromJson(e as Map<String, dynamic>))
          .toList(),
      paymentMethodBreakdown: (json['payment_method_breakdown'] as List)
          .map((e) => PaymentMethodData.fromJson(e as Map<String, dynamic>))
          .toList(),
      topProducts: (json['top_products'] as List)
          .map((e) => TopProductData.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class CategoryRevenue {
  final String? categoryId;
  final String categoryName;
  final int totalProducts;
  final double inventoryValue;
  final double costValue;
  final double potentialRevenue;
  final double potentialProfit;
  final double percentageOfTotal;

  CategoryRevenue({
    this.categoryId,
    required this.categoryName,
    required this.totalProducts,
    required this.inventoryValue,
    required this.costValue,
    required this.potentialRevenue,
    required this.potentialProfit,
    required this.percentageOfTotal,
  });

  factory CategoryRevenue.fromJson(Map<String, dynamic> json) {
    return CategoryRevenue(
      categoryId: json['category_id'],
      categoryName: json['category_name'] as String,
      totalProducts: json['total_products'] as int,
      inventoryValue: (json['inventory_value'] as num).toDouble(),
      costValue: (json['cost_value'] as num).toDouble(),
      potentialRevenue: (json['potential_revenue'] as num).toDouble(),
      potentialProfit: (json['potential_profit'] as num).toDouble(),
      percentageOfTotal: (json['percentage_of_total'] as num).toDouble(),
    );
  }
}
