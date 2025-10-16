/// Dashboard Statistics Model - matches backend /api/analytics/dashboard
class PeriodStats {
  final double totalSales;
  final double totalProfit;
  final int transactionCount;
  final double avgTransactionValue;

  PeriodStats({
    required this.totalSales,
    required this.totalProfit,
    required this.transactionCount,
    required this.avgTransactionValue,
  });

  factory PeriodStats.fromJson(Map<String, dynamic> json) {
    return PeriodStats(
      totalSales: (json['total_sales'] as num).toDouble(),
      totalProfit: (json['total_profit'] as num).toDouble(),
      transactionCount: json['transaction_count'] as int,
      avgTransactionValue: (json['avg_transaction_value'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'total_sales': totalSales,
        'total_profit': totalProfit,
        'transaction_count': transactionCount,
        'avg_transaction_value': avgTransactionValue,
      };
}

class DashboardStats {
  final PeriodStats today;
  final PeriodStats thisWeek;
  final PeriodStats thisMonth;

  DashboardStats({
    required this.today,
    required this.thisWeek,
    required this.thisMonth,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      today: PeriodStats.fromJson(json['today']),
      thisWeek: PeriodStats.fromJson(json['this_week']),
      thisMonth: PeriodStats.fromJson(json['this_month']),
    );
  }

  Map<String, dynamic> toJson() => {
        'today': today.toJson(),
        'this_week': thisWeek.toJson(),
        'this_month': thisMonth.toJson(),
      };
}
