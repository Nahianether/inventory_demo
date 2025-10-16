import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/analytics_api_service.dart';
import '../models/analytics/financial_analytics.dart';
import '../models/analytics/dashboard_stats.dart';
import '../models/analytics/transaction_detail.dart';
import '../models/analytics/chart_data.dart';

/// Analytics API service provider
final analyticsApiServiceProvider = Provider<AnalyticsApiService>((ref) {
  return AnalyticsApiService();
});

/// Financial Analytics Provider - for Account Screen
final financialAnalyticsProvider = FutureProvider<FinancialAnalytics>((ref) async {
  final service = ref.watch(analyticsApiServiceProvider);
  return await service.getFinancialAnalytics();
});

/// Dashboard Stats Provider - for Today, Week, Month stats
final dashboardStatsProvider = FutureProvider<DashboardStats>((ref) async {
  final service = ref.watch(analyticsApiServiceProvider);
  return await service.getDashboardStats();
});

/// Category Revenue Provider - for Reports Screen
final categoryRevenueProvider = FutureProvider<List<CategoryRevenue>>((ref) async {
  final service = ref.watch(analyticsApiServiceProvider);
  return await service.getCategoryRevenue();
});

/// Transactions Provider - with filtering
final transactionsProvider = FutureProvider.family<List<TransactionDetail>, TransactionFilters>(
  (ref, filters) async {
    final service = ref.watch(analyticsApiServiceProvider);
    return await service.getTransactions(
      type: filters.type,
      startDate: filters.startDate,
      endDate: filters.endDate,
      limit: filters.limit,
      offset: filters.offset,
    );
  },
);

/// Chart Data Provider - for Reports Screen
final chartDataProvider = FutureProvider.family<SalesChartData, ChartDataFilters>(
  (ref, filters) async {
    final service = ref.watch(analyticsApiServiceProvider);
    return await service.getChartData(
      days: filters.days,
      limit: filters.limit,
    );
  },
);

/// Filter classes for providers
class TransactionFilters {
  final String? type;
  final DateTime? startDate;
  final DateTime? endDate;
  final int limit;
  final int offset;

  const TransactionFilters({
    this.type,
    this.startDate,
    this.endDate,
    this.limit = 20,
    this.offset = 0,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionFilters &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          startDate == other.startDate &&
          endDate == other.endDate &&
          limit == other.limit &&
          offset == other.offset;

  @override
  int get hashCode =>
      type.hashCode ^
      startDate.hashCode ^
      endDate.hashCode ^
      limit.hashCode ^
      offset.hashCode;
}

class ChartDataFilters {
  final int days;
  final int limit;

  const ChartDataFilters({
    this.days = 30,
    this.limit = 10,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChartDataFilters &&
          runtimeType == other.runtimeType &&
          days == other.days &&
          limit == other.limit;

  @override
  int get hashCode => days.hashCode ^ limit.hashCode;
}
