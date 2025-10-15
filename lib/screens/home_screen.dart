import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/inventory_provider.dart';
import '../widgets/sync_button.dart';
import '../widgets/full_sync_button.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(productProvider);
    final account = ref.watch(accountProvider);
    final totalInventoryValue = ref.watch(totalInventoryValueProvider);
    final potentialRevenue = ref.watch(potentialRevenueProvider);
    final lowStockProducts = ref.watch(lowStockProductsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      floatingActionButton: const SyncButton(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dashboard',
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.grey.shade900),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Welcome to Bike Accessory Inventory Manager',
                      style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                    ),
                  ],
                ),
                const FullSyncButton(),
              ],
            ),
            const SizedBox(height: 32),

            // Stats Cards - 4 Column Grid
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Balance',
                    '\$${account?.totalBalance.toStringAsFixed(2) ?? '0.00'}',
                    Icons.account_balance_wallet,
                    const Color(0xFF6366F1),
                    (account?.totalBalance ?? 0) >= 0 ? 'Profit' : 'Loss',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Products',
                    products.length.toString(),
                    Icons.inventory_2,
                    const Color(0xFF3B82F6),
                    '${lowStockProducts.length} low stock',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Inventory Value',
                    '\$${totalInventoryValue.toStringAsFixed(0)}',
                    Icons.store,
                    const Color(0xFFF59E0B),
                    'Total cost',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Potential Revenue',
                    '\$${potentialRevenue.toStringAsFixed(0)}',
                    Icons.trending_up,
                    const Color(0xFF10B981),
                    'Selling all stock',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Financial Overview Cards
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _buildFinancialCard(
                    'Revenue & Expenses',
                    account?.totalRevenue ?? 0,
                    account?.totalExpenses ?? 0,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(child: _buildProfitCard('Total Profit', account?.totalProfit ?? 0)),
              ],
            ),
            const SizedBox(height: 24),

            // Low Stock Alert
            if (lowStockProducts.isNotEmpty)
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Navigator.pushReplacementNamed(context, '/inventory'),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.shade300, width: 2),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(10)),
                          child: Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Low Stock Alert',
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange.shade900, fontSize: 18),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${lowStockProducts.length} product(s) need restocking',
                                style: TextStyle(color: Colors.orange.shade700, fontSize: 14),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                lowStockProducts.map((p) => '${p.name} (${p.quantity})').join(', '),
                                style: TextStyle(color: Colors.orange.shade800, fontSize: 13, fontWeight: FontWeight.w500),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios, color: Colors.orange.shade700, size: 20),
                      ],
                    ),
                  ),
                ),
              ),

            if (lowStockProducts.isNotEmpty) const SizedBox(height: 24),

            // Quick Actions
            Text(
              'Quick Actions',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey.shade900),
            ),
            const SizedBox(height: 16),

            // Quick Actions Grid
            Row(
              children: [
                Expanded(
                  child: _buildActionCard(
                    context,
                    icon: Icons.inventory_rounded,
                    title: 'View Inventory',
                    description: 'Manage all products',
                    color: const Color(0xFF3B82F6),
                    onTap: () => Navigator.pushReplacementNamed(context, '/inventory'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildActionCard(
                    context,
                    icon: Icons.add_shopping_cart_rounded,
                    title: 'Add Purchase',
                    description: 'Record new purchases',
                    color: const Color(0xFFF59E0B),
                    onTap: () => Navigator.pushReplacementNamed(context, '/purchase'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildActionCard(
                    context,
                    icon: Icons.point_of_sale_rounded,
                    title: 'Make Sale',
                    description: 'Process sales',
                    color: const Color(0xFF10B981),
                    onTap: () => Navigator.pushReplacementNamed(context, '/sale'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildActionCard(
                    context,
                    icon: Icons.add_circle_rounded,
                    title: 'Add Product',
                    description: 'Purchase new products',
                    color: const Color(0xFF6366F1),
                    onTap: () => Navigator.pushReplacementNamed(context, '/purchase'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, String subtitle) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: color, size: 24),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            label,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.grey.shade900),
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  Widget _buildFinancialCard(String title, double revenue, double expenses) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade900),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.arrow_upward, color: Colors.green.shade600, size: 20),
                        const SizedBox(width: 8),
                        Text('Revenue', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '\$${revenue.toStringAsFixed(2)}',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green.shade600),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.arrow_downward, color: Colors.red.shade600, size: 20),
                        const SizedBox(width: 8),
                        Text('Expenses', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '\$${expenses.toStringAsFixed(2)}',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red.shade600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfitCard(String title, double profit) {
    final isPositive = profit >= 0;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isPositive
              ? [const Color(0xFF10B981), const Color(0xFF059669)]
              : [Colors.red.shade400, Colors.red.shade600],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: (isPositive ? const Color(0xFF10B981) : Colors.red.shade400).withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(isPositive ? Icons.trending_up : Icons.trending_down, color: Colors.white, size: 32),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(fontSize: 16, color: Colors.white70, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            '\$${profit.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, size: 32, color: color),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade900),
              ),
              const SizedBox(height: 4),
              Text(description, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
            ],
          ),
        ),
      ),
    );
  }
}
