import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/api_providers.dart';
import '../models/api/api_product.dart';

class ApiInventoryScreen extends ConsumerStatefulWidget {
  const ApiInventoryScreen({super.key});

  @override
  ConsumerState<ApiInventoryScreen> createState() => _ApiInventoryScreenState();
}

class _ApiInventoryScreenState extends ConsumerState<ApiInventoryScreen> {
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _deleteProduct(ApiProduct product) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await ref.read(apiProductProvider.notifier).deleteProduct(product.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${product.name} deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting product: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(apiProductProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/api-purchase'),
        backgroundColor: const Color(0xFF6366F1),
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
      ),
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text('Error loading products', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(error.toString(), style: TextStyle(color: Colors.grey.shade600)),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => ref.read(apiProductProvider.notifier).loadProducts(),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (products) {
          final filteredProducts = _searchQuery.isEmpty
              ? products
              : products.where((p) =>
                  p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                  p.sku.toLowerCase().contains(_searchQuery.toLowerCase())
                ).toList();

          return SingleChildScrollView(
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
                          'Inventory',
                          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.grey.shade900),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${products.length} products from API',
                          style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () => ref.read(apiProductProvider.notifier).loadProducts(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Search Bar
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _searchQuery = value),
                    decoration: InputDecoration(
                      hintText: 'Search products by name or SKU...',
                      prefixIcon: const Icon(Icons.search, color: Color(0xFF6366F1)),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Products Table
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: filteredProducts.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(48),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade300),
                                const SizedBox(height: 16),
                                Text(
                                  _searchQuery.isEmpty ? 'No products found' : 'No products match your search',
                                  style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ),
                        )
                      : SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
                            columns: const [
                              DataColumn(label: Text('SKU', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Name', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Price', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Cost', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Stock', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Value', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                            ],
                            rows: filteredProducts.map((product) {
                              final totalValue = (product.costPrice ?? 0) * product.stockQuantity;
                              final isLowStock = product.stockQuantity < 5;

                              return DataRow(
                                cells: [
                                  DataCell(Text(product.sku, style: const TextStyle(fontFamily: 'monospace'))),
                                  DataCell(
                                    SizedBox(
                                      width: 200,
                                      child: Text(
                                        product.name,
                                        style: const TextStyle(fontWeight: FontWeight.w600),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  DataCell(Text('\$${product.price.toStringAsFixed(2)}')),
                                  DataCell(Text('\$${(product.costPrice ?? 0).toStringAsFixed(2)}')),
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: isLowStock ? Colors.orange.shade100 : Colors.green.shade100,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        product.stockQuantity.toString(),
                                        style: TextStyle(
                                          color: isLowStock ? Colors.orange.shade900 : Colors.green.shade900,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(Text('\$${totalValue.toStringAsFixed(2)}')),
                                  DataCell(
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          onPressed: () => _deleteProduct(product),
                                          tooltip: 'Delete',
                                        ),
                                      ],
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
          );
        },
      ),
    );
  }
}
