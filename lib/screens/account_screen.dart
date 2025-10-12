import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/inventory_provider.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final account = ref.watch(accountProvider);
    final transactions = ref.watch(transactionProvider);
    final totalInventoryValue = ref.watch(totalInventoryValueProvider);
    final potentialRevenue = ref.watch(potentialRevenueProvider);

    if (account == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final purchaseTransactions = transactions.where((t) => t.type == 'purchase').toList();
    final saleTransactions = transactions.where((t) => t.type == 'sale').toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Financial Overview',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.grey.shade900),
            ),
            const SizedBox(height: 8),
            Text('Track your business performance', style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
            const SizedBox(height: 32),

            // Stats Grid (3 columns)
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Balance',
                    '\$${account.totalBalance.toStringAsFixed(2)}',
                    Icons.account_balance_wallet,
                    account.totalBalance >= 0 ? const Color(0xFF10B981) : Colors.red.shade600,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Total Revenue',
                    '\$${account.totalRevenue.toStringAsFixed(2)}',
                    Icons.trending_up,
                    const Color(0xFF10B981),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Total Expenses',
                    '\$${account.totalExpenses.toStringAsFixed(2)}',
                    Icons.trending_down,
                    Colors.red.shade600,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Total Profit',
                    '\$${account.totalProfit.toStringAsFixed(2)}',
                    Icons.attach_money,
                    account.totalProfit >= 0 ? const Color(0xFF3B82F6) : Colors.red.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Inventory Analysis
            Row(
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
                          'Inventory Analysis',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade900),
                        ),
                        const SizedBox(height: 20),
                        _buildAnalysisRow('Current Inventory Value', totalInventoryValue, Colors.blue.shade600),
                        const SizedBox(height: 12),
                        _buildAnalysisRow('Potential Revenue', potentialRevenue, Colors.orange.shade600),
                        const SizedBox(height: 12),
                        _buildAnalysisRow(
                          'Potential Profit',
                          potentialRevenue - totalInventoryValue,
                          Colors.green.shade600,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
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
                          'Transaction Summary',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade900),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildTransactionStat(
                              '${purchaseTransactions.length}',
                              'Purchases',
                              Icons.shopping_bag,
                              Colors.orange.shade600,
                            ),
                            Container(width: 1, height: 50, color: Colors.grey.shade300),
                            _buildTransactionStat(
                              '${saleTransactions.length}',
                              'Sales',
                              Icons.point_of_sale,
                              Colors.green.shade600,
                            ),
                            Container(width: 1, height: 50, color: Colors.grey.shade300),
                            _buildTransactionStat(
                              '${transactions.length}',
                              'Total',
                              Icons.list_alt,
                              Colors.blue.shade600,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Transactions Table
            Text(
              'Recent Transactions',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey.shade900),
            ),
            const SizedBox(height: 16),

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2)),
                ],
              ),
              child: transactions.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(48),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.receipt_long, size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            Text('No transactions yet', style: TextStyle(fontSize: 18, color: Colors.grey.shade600)),
                          ],
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowHeight: 60,
                        dataRowMinHeight: 70,
                        dataRowMaxHeight: 70,
                        columnSpacing: 40,
                        headingRowColor: WidgetStateProperty.all(Colors.grey.shade50),
                        columns: [
                          DataColumn(
                            label: Text(
                              'Date',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey.shade700),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Type',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey.shade700),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Product',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey.shade700),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Quantity',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey.shade700),
                            ),
                            numeric: true,
                          ),
                          DataColumn(
                            label: Text(
                              'Unit Price',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey.shade700),
                            ),
                            numeric: true,
                          ),
                          DataColumn(
                            label: Text(
                              'Total Amount',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey.shade700),
                            ),
                            numeric: true,
                          ),
                          DataColumn(
                            label: Text(
                              'Notes',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey.shade700),
                            ),
                          ),
                        ],
                        rows: transactions.reversed.take(20).map((transaction) {
                          final isPurchase = transaction.type == 'purchase';
                          return DataRow(
                            cells: [
                              DataCell(
                                Text(
                                  DateFormat('MMM dd, yyyy').format(transaction.createdAt),
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isPurchase ? Colors.orange.shade100 : Colors.green.shade100,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isPurchase ? Icons.shopping_bag : Icons.point_of_sale,
                                        size: 16,
                                        color: isPurchase ? Colors.orange.shade700 : Colors.green.shade700,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        isPurchase ? 'Purchase' : 'Sale',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: isPurchase ? Colors.orange.shade700 : Colors.green.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  transaction.productName,
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                ),
                              ),
                              DataCell(Text('${transaction.quantity}', style: const TextStyle(fontSize: 14))),
                              DataCell(
                                Text(
                                  '\$${transaction.pricePerUnit.toStringAsFixed(2)}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                              DataCell(
                                Text(
                                  '\$${transaction.totalAmount.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: isPurchase ? Colors.red.shade600 : Colors.green.shade600,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  transaction.notes ?? '-',
                                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            label,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey.shade900),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisRow(String label, double value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
          ),
          Text(
            '\$${value.toStringAsFixed(2)}',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionStat(String count, String label, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 24, color: color),
        ),
        const SizedBox(height: 12),
        Text(
          count,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
