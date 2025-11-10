import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/analytics_providers.dart';
import '../models/analytics/transaction_detail.dart';
import '../utils/currency_helper.dart';

/// Enhanced Account Screen with Real Analytics from Backend API
class ApiAccountEnhancedScreen extends ConsumerStatefulWidget {
  const ApiAccountEnhancedScreen({super.key});

  @override
  ConsumerState<ApiAccountEnhancedScreen> createState() => _ApiAccountEnhancedScreenState();
}

class _ApiAccountEnhancedScreenState extends ConsumerState<ApiAccountEnhancedScreen> {
  String _selectedPeriod = 'today'; // today, week, month

  @override
  Widget build(BuildContext context) {
    final financialAsync = ref.watch(financialAnalyticsProvider);
    final dashboardAsync = ref.watch(dashboardStatsProvider);
    final transactionsAsync = ref.watch(
      transactionsProvider(const TransactionFilters(limit: 20)),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: financialAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorView(error),
        data: (financial) {
          return dashboardAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => _buildErrorView(error),
            data: (dashboard) {
              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(financialAnalyticsProvider);
                  ref.invalidate(dashboardStatsProvider);
                  ref.invalidate(transactionsProvider);
                },
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      _buildHeader(),
                      const SizedBox(height: 32),

                      // Period Selector
                      _buildPeriodSelector(),
                      const SizedBox(height: 24),

                      // Sales Stats Cards (Today/Week/Month)
                      _buildSalesStatsCards(dashboard),
                      const SizedBox(height: 24),

                      // Financial Overview Cards
                      _buildFinancialCards(financial),
                      const SizedBox(height: 24),

                      // Stock Status
                      _buildStockStatus(financial),
                      const SizedBox(height: 32),

                      // Recent Transactions
                      _buildRecentTransactions(transactionsAsync),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Financial Overview',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Track your business performance',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
              const Icon(Icons.schedule, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                'Last updated: ${DateFormat('MMM dd, h:mm a').format(DateTime.now())}',
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodSelector() {
    return Row(
      children: [
        _buildPeriodChip('Today', 'today'),
        const SizedBox(width: 12),
        _buildPeriodChip('This Week', 'week'),
        const SizedBox(width: 12),
        _buildPeriodChip('This Month', 'month'),
      ],
    );
  }

  Widget _buildPeriodChip(String label, String value) {
    final isSelected = _selectedPeriod == value;
    return InkWell(
      onTap: () => setState(() => _selectedPeriod = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                )
              : null,
          color: isSelected ? null : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  Widget _buildSalesStatsCards(dashboard) {
    final stats = _selectedPeriod == 'today'
        ? dashboard.today
        : _selectedPeriod == 'week'
            ? dashboard.thisWeek
            : dashboard.thisMonth;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Sales',
            CurrencyHelper.format(ref, stats.totalSales),
            Icons.point_of_sale,
            const Color(0xFF10B981),
            '${CurrencyHelper.format(ref, stats.avgTransactionValue)} avg',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Total Profit',
            CurrencyHelper.format(ref, stats.totalProfit),
            Icons.trending_up,
            const Color(0xFF3B82F6),
            '${((stats.totalProfit / (stats.totalSales > 0 ? stats.totalSales : 1)) * 100).toStringAsFixed(1)}% margin',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Transactions',
            '${stats.transactionCount}',
            Icons.receipt_long,
            const Color(0xFF8B5CF6),
            '${stats.transactionCount} orders',
          ),
        ),
      ],
    );
  }

  Widget _buildFinancialCards(financial) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Inventory Value',
            CurrencyHelper.format(ref, financial.totalInventoryValue),
            Icons.inventory_2,
            const Color(0xFF3B82F6),
            'Cost: ${CurrencyHelper.format(ref, financial.totalCostValue)}',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Potential Revenue',
            CurrencyHelper.format(ref, financial.potentialRevenue),
            Icons.attach_money,
            const Color(0xFF10B981),
            'If all sold',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Potential Profit',
            CurrencyHelper.format(ref, financial.potentialProfit),
            Icons.trending_up,
            financial.potentialProfit >= 0
                ? const Color(0xFF10B981)
                : Colors.red.shade600,
            '${financial.profitMargin.toStringAsFixed(1)}% margin',
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
    String subtitle,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockStatus(financial) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Stock Status',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade900,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStockStat(
                      '${financial.totalProducts}',
                      'Total Products',
                      Icons.inventory,
                      Colors.blue.shade600,
                    ),
                    Container(width: 1, height: 50, color: Colors.grey.shade300),
                    _buildStockStat(
                      '${financial.lowStockCount}',
                      'Low Stock',
                      Icons.warning,
                      Colors.orange.shade600,
                    ),
                    Container(width: 1, height: 50, color: Colors.grey.shade300),
                    _buildStockStat(
                      '${financial.outOfStockCount}',
                      'Out of Stock',
                      Icons.remove_circle,
                      Colors.red.shade600,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStockStat(String count, String label, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 24, color: color),
        ),
        const SizedBox(height: 12),
        Text(
          count,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentTransactions(AsyncValue<List<TransactionDetail>> transactionsAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Transactions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade900,
              ),
            ),
            TextButton.icon(
              onPressed: () {
                // Navigate to full transactions/reports page
                Navigator.pushNamed(context, '/api-reports');
              },
              icon: const Icon(Icons.arrow_forward),
              label: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: transactionsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(48),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, stack) => Padding(
              padding: const EdgeInsets.all(48),
              child: Center(
                child: Text(
                  'Failed to load transactions',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
            ),
            data: (transactions) {
              if (transactions.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(48),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.receipt_long, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(
                          'No transactions yet',
                          style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowHeight: 60,
                  dataRowMinHeight: 70,
                  dataRowMaxHeight: 70,
                  columnSpacing: 40,
                  headingRowColor: WidgetStateProperty.all(Colors.grey.shade50),
                  columns: [
                    _buildTableHeader('Date'),
                    _buildTableHeader('Customer'),
                    _buildTableHeader('Items'),
                    _buildTableHeader('Total'),
                    _buildTableHeader('Profit'),
                    _buildTableHeader('Payment'),
                  ],
                  rows: transactions.take(10).map((transaction) {
                    return DataRow(cells: [
                      DataCell(Text(
                        DateFormat('MMM dd, yyyy\nh:mm a').format(transaction.createdAt),
                        style: const TextStyle(fontSize: 13),
                      )),
                      DataCell(Text(
                        transaction.customerName ?? 'Walk-in',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      )),
                      DataCell(Text(
                        '${transaction.itemCount} items',
                        style: const TextStyle(fontSize: 14),
                      )),
                      DataCell(Text(
                        CurrencyHelper.format(ref, transaction.total),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      )),
                      DataCell(Text(
                        CurrencyHelper.format(ref, transaction.profit),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade700,
                        ),
                      )),
                      DataCell(_buildPaymentMethodBadge(transaction.paymentMethod)),
                    ]);
                  }).toList(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  DataColumn _buildTableHeader(String label) {
    return DataColumn(
      label: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }

  Widget _buildPaymentMethodBadge(PaymentMethod method) {
    Color color;
    IconData icon;

    switch (method) {
      case PaymentMethod.cash:
        color = Colors.green.shade600;
        icon = Icons.attach_money;
        break;
      case PaymentMethod.card:
        color = Colors.blue.shade600;
        icon = Icons.credit_card;
        break;
      case PaymentMethod.digitalWallet:
        color = Colors.purple.shade600;
        icon = Icons.phone_android;
        break;
      default:
        color = Colors.grey.shade600;
        icon = Icons.payment;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            method.displayName,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
          const SizedBox(height: 16),
          Text(
            'Error loading account data',
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
              ref.invalidate(financialAnalyticsProvider);
              ref.invalidate(dashboardStatsProvider);
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
