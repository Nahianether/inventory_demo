import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/analytics_providers.dart';
import '../models/analytics/chart_data.dart';
import '../models/analytics/transaction_detail.dart';
import '../utils/currency_helper.dart';

/// Complete Reports Screen with Charts and Visualizations
class ApiReportsScreen extends ConsumerStatefulWidget {
  const ApiReportsScreen({super.key});

  @override
  ConsumerState<ApiReportsScreen> createState() => _ApiReportsScreenState();
}

class _ApiReportsScreenState extends ConsumerState<ApiReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedDays = 30;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          _buildHeader(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSalesTab(),
                _buildProductsTab(),
                _buildTransactionsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Reports & Analytics',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Visualize your business performance',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              ),
            ],
          ),
          PopupMenuButton<int>(
            initialValue: _selectedDays,
            onSelected: (days) => setState(() => _selectedDays = days),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.date_range, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Last $_selectedDays days',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_drop_down, color: Colors.white, size: 20),
                ],
              ),
            ),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 7, child: Text('Last 7 days')),
              const PopupMenuItem(value: 30, child: Text('Last 30 days')),
              const PopupMenuItem(value: 90, child: Text('Last 90 days')),
              const PopupMenuItem(value: 365, child: Text('Last year')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: const Color(0xFF6366F1),
        unselectedLabelColor: Colors.grey.shade600,
        indicatorColor: const Color(0xFF6366F1),
        indicatorWeight: 3,
        labelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        tabs: const [
          Tab(text: 'Sales Dashboard'),
          Tab(text: 'Products'),
          Tab(text: 'Transactions'),
        ],
      ),
    );
  }

  Widget _buildSalesTab() {
    final chartDataAsync = ref.watch(
      chartDataProvider(ChartDataFilters(days: _selectedDays, limit: 10)),
    );

    return chartDataAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorView(error),
      data: (chartData) {
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(chartDataProvider);
          },
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // Daily Sales Line Chart
              _DailySalesChart(data: chartData.dailySales),
              const SizedBox(height: 24),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category Pie Chart
                  Expanded(
                    child: _CategoryPieChart(data: chartData.categorySales),
                  ),
                  const SizedBox(width: 24),

                  // Payment Methods Bar Chart
                  Expanded(
                    child: _PaymentMethodChart(
                      data: chartData.paymentMethodBreakdown,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProductsTab() {
    final chartDataAsync = ref.watch(
      chartDataProvider(ChartDataFilters(days: _selectedDays, limit: 10)),
    );
    final categoryRevenueAsync = ref.watch(categoryRevenueProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(chartDataProvider);
        ref.invalidate(categoryRevenueProvider);
      },
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          chartDataAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(48),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, stack) => _buildErrorView(error),
            data: (chartData) => _TopProductsChart(data: chartData.topProducts),
          ),
          const SizedBox(height: 24),

          categoryRevenueAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(48),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, stack) => _buildErrorView(error),
            data: (categoryRevenue) =>
                _CategoryRevenueTable(data: categoryRevenue),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsTab() {
    final transactionsAsync = ref.watch(
      transactionsProvider(const TransactionFilters(limit: 50)),
    );

    return transactionsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorView(error),
      data: (transactions) {
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(transactionsProvider);
          },
          child: transactions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(
                        'No transactions yet',
                        style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: _TransactionsTable(transactions: transactions),
                ),
        );
      },
    );
  }

  Widget _buildErrorView(Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
            const SizedBox(height: 16),
            Text(
              'Failed to load report data',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                ref.invalidate(chartDataProvider);
                ref.invalidate(categoryRevenueProvider);
                ref.invalidate(transactionsProvider);
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Daily Sales Line Chart Widget
class _DailySalesChart extends ConsumerWidget {
  final List<DailySalesData> data;

  const _DailySalesChart({required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (data.isEmpty) {
      return Card(
        child: Container(
          height: 300,
          alignment: Alignment.center,
          child: Text('No sales data available', style: TextStyle(color: Colors.grey.shade600)),
        ),
      );
    }

    final maxSales = data.fold<double>(0.0, (max, d) => d.totalSales > max ? d.totalSales : max);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sales Trend',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey.shade900),
            ),
            const SizedBox(height: 8),
            Text(
              'Daily sales and profit over time',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 300,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxSales / 5,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.grey.withValues(alpha: 0.3),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: data.length > 15 ? (data.length / 7).ceilToDouble() : 1,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= data.length) return const Text('');
                          final date = DateTime.parse(data[index].date);
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              DateFormat('MM/dd').format(date),
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        getTitlesWidget: (value, meta) {
                          final compactValue = value / 1000;
                          return Text(
                            '${CurrencyHelper.getSymbol(ref)}${compactValue.toStringAsFixed(0)}K',
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                  ),
                  minX: 0,
                  maxX: (data.length - 1).toDouble(),
                  minY: 0,
                  maxY: maxSales * 1.2,
                  lineBarsData: [
                    LineChartBarData(
                      spots: data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.totalSales)).toList(),
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(show: true, color: Colors.blue.withValues(alpha: 0.1)),
                    ),
                    LineChartBarData(
                      spots: data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.totalProfit)).toList(),
                      isCurved: true,
                      color: Colors.green,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(show: true, color: Colors.green.withValues(alpha: 0.1)),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (spot) => Colors.blueGrey.withValues(alpha: 0.8),
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final date = DateTime.parse(data[spot.x.toInt()].date);
                          final label = spot.barIndex == 0 ? 'Sales' : 'Profit';
                          return LineTooltipItem(
                            '$label\n${spot.y.toCurrency(ref)}\n${DateFormat('MMM dd').format(date)}',
                            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegend('Sales', Colors.blue),
                const SizedBox(width: 24),
                _buildLegend('Profit', Colors.green),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(String label, Color color) {
    return Row(
      children: [
        Container(width: 16, height: 16, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

// Category Pie Chart Widget
class _CategoryPieChart extends ConsumerWidget {
  final List<CategorySalesData> data;

  const _CategoryPieChart({required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (data.isEmpty) {
      return Card(
        child: Container(
          height: 350,
          alignment: Alignment.center,
          child: Text('No category data', style: TextStyle(color: Colors.grey.shade600)),
        ),
      );
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sales by Category',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade900),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 250,
              child: PieChart(
                PieChartData(
                  sections: data.asMap().entries.map((entry) {
                    final color = _getColorForIndex(entry.key);
                    return PieChartSectionData(
                      value: entry.value.percentage,
                      title: '${entry.value.percentage.toStringAsFixed(1)}%',
                      color: color,
                      radius: 100,
                      titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                    );
                  }).toList(),
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ...data.asMap().entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(width: 12, height: 12, decoration: BoxDecoration(color: _getColorForIndex(entry.key), shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(entry.value.categoryName, style: const TextStyle(fontSize: 12))),
                    Text(entry.value.totalSales.toCurrency(ref), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Color _getColorForIndex(int index) {
    final colors = [Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.red, Colors.teal, Colors.pink, Colors.indigo];
    return colors[index % colors.length];
  }
}

// Payment Method Bar Chart Widget
class _PaymentMethodChart extends ConsumerWidget {
  final List<PaymentMethodData> data;

  const _PaymentMethodChart({required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (data.isEmpty) {
      return Card(
        child: Container(
          height: 350,
          alignment: Alignment.center,
          child: Text('No payment data', style: TextStyle(color: Colors.grey.shade600)),
        ),
      );
    }

    final maxAmount = data.fold<double>(0.0, (max, d) => d.totalAmount > max ? d.totalAmount : max);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment Methods',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade900),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 250,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxAmount * 1.2,
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= data.length) return const Text('');
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(data[index].paymentMethod.displayName, style: const TextStyle(fontSize: 10)),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        getTitlesWidget: (value, meta) {
                          final compactValue = value / 1000;
                          return Text(
                            '${CurrencyHelper.getSymbol(ref)}${compactValue.toStringAsFixed(0)}K',
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: data.asMap().entries.map((entry) {
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value.totalAmount,
                          color: _getColorForPaymentMethod(entry.value.paymentMethod),
                          width: 40,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    );
                  }).toList(),
                  gridData: FlGridData(show: true, drawVerticalLine: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getColorForPaymentMethod(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return Colors.green;
      case PaymentMethod.card:
        return Colors.blue;
      case PaymentMethod.digitalWallet:
        return Colors.purple;
      default:
        return Colors.orange;
    }
  }
}

// Top Products Chart Widget
class _TopProductsChart extends ConsumerWidget {
  final List<TopProductData> data;

  const _TopProductsChart({required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (data.isEmpty) {
      return Card(
        child: Container(
          height: 300,
          alignment: Alignment.center,
          child: Text('No product data', style: TextStyle(color: Colors.grey.shade600)),
        ),
      );
    }

    final maxRevenue = data.first.totalRevenue;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Top Selling Products',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey.shade900),
            ),
            const SizedBox(height: 8),
            Text(
              'Products ranked by revenue',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            ...data.asMap().entries.map((entry) {
              final percentage = (entry.value.totalRevenue / maxRevenue * 100);
              final color = _getColorForIndex(entry.key);

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${entry.key + 1}. ${entry.value.productName}',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          entry.value.totalRevenue.toCurrency(ref),
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: percentage / 100,
                              minHeight: 20,
                              backgroundColor: Colors.grey.withValues(alpha: 0.2),
                              valueColor: AlwaysStoppedAnimation<Color>(color),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${entry.value.quantitySold} sold',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Color _getColorForIndex(int index) {
    final colors = [Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.red, Colors.teal, Colors.pink, Colors.indigo, Colors.cyan, Colors.amber];
    return colors[index % colors.length];
  }
}

// Category Revenue Table Widget
class _CategoryRevenueTable extends ConsumerWidget {
  final List<CategoryRevenue> data;

  const _CategoryRevenueTable({required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Category Performance',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey.shade900),
            ),
            const SizedBox(height: 24),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(Colors.grey.shade50),
                columns: [
                  DataColumn(label: Text('Category', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700))),
                  DataColumn(label: Text('Products', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700)), numeric: true),
                  DataColumn(label: Text('Inventory Value', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700)), numeric: true),
                  DataColumn(label: Text('Potential Revenue', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700)), numeric: true),
                  DataColumn(label: Text('Profit', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700)), numeric: true),
                  DataColumn(label: Text('% of Total', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700)), numeric: true),
                ],
                rows: data.map((cat) {
                  return DataRow(cells: [
                    DataCell(Text(cat.categoryName, style: const TextStyle(fontWeight: FontWeight.w600))),
                    DataCell(Text('${cat.totalProducts}')),
                    DataCell(Text(cat.inventoryValue.toCurrency(ref))),
                    DataCell(Text(cat.potentialRevenue.toCurrency(ref), style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold))),
                    DataCell(Text(cat.potentialProfit.toCurrency(ref), style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold))),
                    DataCell(Text('${cat.percentageOfTotal.toStringAsFixed(1)}%')),
                  ]);
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Transactions Table Widget
class _TransactionsTable extends ConsumerWidget {
  final List<TransactionDetail> transactions;

  const _TransactionsTable({required this.transactions});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Transaction History',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey.shade900),
            ),
            const SizedBox(height: 8),
            Text(
              'Complete list of all transactions',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(Colors.grey.shade50),
                columnSpacing: 30,
                columns: [
                  DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700))),
                  DataColumn(label: Text('Customer', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700))),
                  DataColumn(label: Text('Items', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700)), numeric: true),
                  DataColumn(label: Text('Subtotal', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700)), numeric: true),
                  DataColumn(label: Text('Discount', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700)), numeric: true),
                  DataColumn(label: Text('Tax', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700)), numeric: true),
                  DataColumn(label: Text('Total', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700)), numeric: true),
                  DataColumn(label: Text('Profit', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700)), numeric: true),
                  DataColumn(label: Text('Payment', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700))),
                ],
                rows: transactions.map((t) {
                  return DataRow(cells: [
                    DataCell(Text(DateFormat('MMM dd, yyyy\nh:mm a').format(t.createdAt), style: const TextStyle(fontSize: 12))),
                    DataCell(Text(t.customerName ?? 'Walk-in', style: const TextStyle(fontWeight: FontWeight.w600))),
                    DataCell(Text('${t.itemCount}')),
                    DataCell(Text(t.subtotal.toCurrency(ref))),
                    DataCell(Text(t.discount.toCurrency(ref), style: TextStyle(color: Colors.orange.shade700))),
                    DataCell(Text(t.tax.toCurrency(ref))),
                    DataCell(Text(t.total.toCurrency(ref), style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold))),
                    DataCell(Text(t.profit.toCurrency(ref), style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold))),
                    DataCell(_buildPaymentBadge(t.paymentMethod)),
                  ]);
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentBadge(PaymentMethod method) {
    Color color;
    IconData icon;

    switch (method) {
      case PaymentMethod.cash:
        color = Colors.green;
        icon = Icons.attach_money;
        break;
      case PaymentMethod.card:
        color = Colors.blue;
        icon = Icons.credit_card;
        break;
      case PaymentMethod.digitalWallet:
        color = Colors.purple;
        icon = Icons.phone_android;
        break;
      default:
        color = Colors.orange;
        icon = Icons.payment;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(method.displayName, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}
