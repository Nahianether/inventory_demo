import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/api_providers.dart';
import '../utils/currency_helper.dart';

class ApiHomeScreen extends ConsumerWidget {
  const ApiHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(apiProductProvider);
    final categoriesAsync = ref.watch(apiCategoryProvider);
    final totalInventoryValue = ref.watch(apiTotalInventoryValueProvider);
    final potentialRevenue = ref.watch(apiPotentialRevenueProvider);
    final lowStockProducts = ref.watch(apiLowStockProductsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ref.read(apiProductProvider.notifier).loadProducts();
          ref.read(apiCategoryProvider.notifier).loadCategories();
        },
        backgroundColor: const Color(0xFF6366F1),
        child: const Icon(Icons.refresh),
      ),
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text(
                'Error loading data',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey.shade900),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: TextStyle(color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  ref.read(apiProductProvider.notifier).loadProducts();
                  ref.read(apiCategoryProvider.notifier).loadCategories();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                ),
              ),
            ],
          ),
        ),
        data: (products) => SingleChildScrollView(
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
                        'Dashboard (API Mode)',
                        style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.grey.shade900),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Direct Backend Communication',
                        style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.cloud_done, color: Colors.green.shade700, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'API Connected',
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Stats Cards - 4 Column Grid
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      ref,
                      'Products',
                      products.length.toString(),
                      Icons.inventory_2,
                      const Color(0xFF3B82F6),
                      '${lowStockProducts.length} low stock',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: categoriesAsync.when(
                      data: (categories) => _buildStatCard(
                        ref,
                        'Categories',
                        categories.length.toString(),
                        Icons.category,
                        const Color(0xFF8B5CF6),
                        'Active categories',
                      ),
                      loading: () => _buildStatCard(
                        ref,
                        'Categories',
                        '...',
                        Icons.category,
                        const Color(0xFF8B5CF6),
                        'Loading...',
                      ),
                      error: (_, __) => _buildStatCard(
                        ref,
                        'Categories',
                        'Error',
                        Icons.category,
                        const Color(0xFF8B5CF6),
                        'Failed to load',
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      ref,
                      'Inventory Value',
                      totalInventoryValue.toCurrencyCompact(ref),
                      Icons.store,
                      const Color(0xFFF59E0B),
                      'Total cost',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      ref,
                      'Potential Revenue',
                      potentialRevenue.toCurrencyCompact(ref),
                      Icons.trending_up,
                      const Color(0xFF10B981),
                      'Selling all stock',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Low Stock Alert
              if (lowStockProducts.isNotEmpty)
                Container(
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
                              lowStockProducts.map((p) => '${p.name} (${p.stockQuantity})').join(', '),
                              style: TextStyle(color: Colors.orange.shade800, fontSize: 13, fontWeight: FontWeight.w500),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
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
                      onTap: () => Navigator.pushNamed(context, '/api-inventory'),
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
                      onTap: () => Navigator.pushNamed(context, '/api-purchase'),
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
                      onTap: () => Navigator.pushNamed(context, '/api-sale'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildActionCard(
                      context,
                      icon: Icons.category_rounded,
                      title: 'Categories',
                      description: 'Manage categories',
                      color: const Color(0xFF8B5CF6),
                      onTap: () => Navigator.pushNamed(context, '/api-categories'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(WidgetRef ref, String label, String value, IconData icon, Color color, String subtitle) {
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
