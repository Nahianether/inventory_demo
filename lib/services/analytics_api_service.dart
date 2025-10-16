import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../models/analytics/financial_analytics.dart';
import '../models/analytics/dashboard_stats.dart';
import '../models/analytics/transaction_detail.dart';
import '../models/analytics/chart_data.dart';

/// Analytics API Service for account and reports screens
class AnalyticsApiService {
  // Base URL - same as inventory API
  static const String baseUrl = 'http://localhost:3000/api';

  /// Get comprehensive financial analytics
  /// Used in Account Screen
  Future<FinancialAnalytics> getFinancialAnalytics() async {
    final response = await http.get(
      Uri.parse('$baseUrl/analytics/financial'),
    );

    if (response.statusCode == 200) {
      return FinancialAnalytics.fromJson(json.decode(response.body));
    }
    throw Exception('Failed to load financial analytics: ${response.body}');
  }

  /// Get dashboard statistics (today, week, month)
  /// Used in Account Screen and Dashboard
  Future<DashboardStats> getDashboardStats() async {
    final response = await http.get(
      Uri.parse('$baseUrl/analytics/dashboard'),
    );

    if (response.statusCode == 200) {
      return DashboardStats.fromJson(json.decode(response.body));
    }
    throw Exception('Failed to load dashboard stats: ${response.body}');
  }

  /// Get category-wise revenue breakdown
  /// Used in Reports Screen
  Future<List<CategoryRevenue>> getCategoryRevenue() async {
    final response = await http.get(
      Uri.parse('$baseUrl/analytics/by-category'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((item) => CategoryRevenue.fromJson(item)).toList();
    }
    throw Exception('Failed to load category revenue: ${response.body}');
  }

  /// Get transaction history with filtering
  ///
  /// Parameters:
  /// - [type]: Filter by 'sale' or 'purchase'
  /// - [startDate]: Filter from date
  /// - [endDate]: Filter to date
  /// - [limit]: Number of records (default 20, max 100)
  /// - [offset]: Pagination offset
  Future<List<TransactionDetail>> getTransactions({
    String? type,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 20,
    int offset = 0,
  }) async {
    final queryParams = <String, String>{
      if (type != null) 'type': type,
      if (startDate != null) 'start_date': startDate.toIso8601String(),
      if (endDate != null) 'end_date': endDate.toIso8601String(),
      'limit': limit.toString(),
      'offset': offset.toString(),
    };

    final uri = Uri.parse('$baseUrl/transactions')
        .replace(queryParameters: queryParams.isEmpty ? null : queryParams);

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((item) => TransactionDetail.fromJson(item)).toList();
    }
    throw Exception('Failed to load transactions: ${response.body}');
  }

  /// Get comprehensive chart data for visualizations
  ///
  /// Parameters:
  /// - [days]: Number of days to look back (default 30, max 365)
  /// - [limit]: Number of top products (default 10, max 50)
  Future<SalesChartData> getChartData({
    int days = 30,
    int limit = 10,
  }) async {
    final queryParams = {
      'days': days.toString(),
      'limit': limit.toString(),
    };

    final uri = Uri.parse('$baseUrl/analytics/charts')
        .replace(queryParameters: queryParams);

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      return SalesChartData.fromJson(json.decode(response.body));
    }
    throw Exception('Failed to load chart data: ${response.body}');
  }

  /// Check if analytics API is reachable
  Future<bool> healthCheck() async {
    try {
      final response = await http.get(
        Uri.parse(baseUrl.replaceAll('/api', '/health')),
      ).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Analytics API health check failed: $e');
      return false;
    }
  }
}

/// Custom exception for analytics API errors
class AnalyticsApiException implements Exception {
  final String message;
  final int? statusCode;

  AnalyticsApiException(this.message, [this.statusCode]);

  @override
  String toString() => 'AnalyticsApiException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}';
}
