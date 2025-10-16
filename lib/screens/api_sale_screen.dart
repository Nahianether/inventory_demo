import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/api_providers.dart';
import '../models/api/api_inventory.dart';

class ApiSaleScreen extends ConsumerStatefulWidget {
  const ApiSaleScreen({super.key});

  @override
  ConsumerState<ApiSaleScreen> createState() => _ApiSaleScreenState();
}

class _ApiSaleScreenState extends ConsumerState<ApiSaleScreen> {
  String? _selectedProductId;
  final _quantityController = TextEditingController();
  final _notesController = TextEditingController();
  final _searchController = TextEditingController();
  bool _showProductSuggestions = false;
  String _searchQuery = '';
  bool _isProcessing = false;

  @override
  void dispose() {
    _quantityController.dispose();
    _notesController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _recordSale() async {
    if (_selectedProductId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a product'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_quantityController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter quantity'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final quantity = int.tryParse(_quantityController.text);
    if (quantity == null || quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid quantity'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final productsAsync = ref.read(apiProductProvider);
    final product = productsAsync.whenOrNull(
      data: (products) => products.firstWhere((p) => p.id == _selectedProductId),
    );

    if (product == null) return;

    if (product.stockQuantity < quantity) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Insufficient stock! Available: ${product.stockQuantity}'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // Adjust stock on server (negative for sale)
      await ref.read(apiProductProvider.notifier).adjustStock(
        AdjustStockRequest(
          productId: _selectedProductId!,
          quantityChange: -quantity,
          reason: _notesController.text.isEmpty
              ? 'Sale from inventory app'
              : 'Sale: ${_notesController.text}',
        ),
      );

      if (mounted) {
        final saleAmount = product.price * quantity;
        final costAmount = (product.costPrice ?? 0) * quantity;
        final profit = saleAmount - costAmount;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Sale recorded: $quantity x ${product.name}\nProfit: \$${profit.toStringAsFixed(2)}',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        // Reset form
        setState(() {
          _selectedProductId = null;
          _searchController.clear();
          _quantityController.clear();
          _notesController.clear();
          _showProductSuggestions = false;
          _searchQuery = '';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error recording sale: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(apiProductProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
              const SizedBox(height: 16),
              const Text('Error loading products', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
          final inStockProducts = products.where((p) => p.stockQuantity > 0).toList();

          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Record Sale',
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.grey.shade900),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Process product sales - updates backend directly',
                      style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 32),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2)),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (inStockProducts.isEmpty)
                                  Container(
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.red.shade300),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.warning, color: Colors.red.shade700),
                                        const SizedBox(width: 12),
                                        const Expanded(
                                          child: Text(
                                            'No products available in stock',
                                            style: TextStyle(fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                else ...[
                                  // Product Search
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      TextField(
                                        controller: _searchController,
                                        onChanged: (value) {
                                          setState(() {
                                            _searchQuery = value;
                                            _showProductSuggestions = value.isNotEmpty;
                                            if (_selectedProductId != null) {
                                              final product = inStockProducts.firstWhere(
                                                (p) => p.id == _selectedProductId,
                                                orElse: () => inStockProducts.first,
                                              );
                                              if (product.name != value) {
                                                _selectedProductId = null;
                                              }
                                            }
                                          });
                                        },
                                        decoration: InputDecoration(
                                          labelText: 'Search Product',
                                          hintText: 'Type product name or SKU...',
                                          prefixIcon: const Icon(Icons.search, color: Color(0xFF10B981)),
                                          suffixIcon: _selectedProductId != null
                                              ? Container(
                                                  margin: const EdgeInsets.all(8),
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFF10B981).withValues(alpha: 0.1),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: const Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(Icons.check_circle, color: Color(0xFF10B981), size: 16),
                                                      SizedBox(width: 4),
                                                      Text(
                                                        'Selected',
                                                        style: TextStyle(
                                                          color: Color(0xFF10B981),
                                                          fontSize: 12,
                                                          fontWeight: FontWeight.w600,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                )
                                              : null,
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: BorderSide(color: Colors.grey.shade300),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: const BorderSide(color: Color(0xFF10B981), width: 2),
                                          ),
                                          filled: true,
                                          fillColor: Colors.grey.shade50,
                                        ),
                                      ),
                                      if (_showProductSuggestions) _buildProductSuggestions(inStockProducts),
                                    ],
                                  ),
                                  const SizedBox(height: 24),

                                  // Quantity
                                  TextField(
                                    controller: _quantityController,
                                    keyboardType: TextInputType.number,
                                    onChanged: (_) => setState(() {}),
                                    decoration: InputDecoration(
                                      labelText: 'Quantity',
                                      prefixIcon: const Icon(Icons.production_quantity_limits, color: Color(0xFF10B981)),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(color: Colors.grey.shade300),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(color: Color(0xFF10B981), width: 2),
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey.shade50,
                                    ),
                                  ),
                                  const SizedBox(height: 24),

                                  // Notes
                                  TextField(
                                    controller: _notesController,
                                    maxLines: 3,
                                    decoration: InputDecoration(
                                      labelText: 'Notes (Optional)',
                                      prefixIcon: const Icon(Icons.notes, color: Color(0xFF10B981)),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(color: Colors.grey.shade300),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(color: Color(0xFF10B981), width: 2),
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey.shade50,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 24),

                        // Sale Summary
                        Container(
                          width: 300,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2)),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Sale Summary',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 20),

                              if (_selectedProductId != null) ...[
                                Builder(
                                  builder: (context) {
                                    final product = inStockProducts.firstWhere((p) => p.id == _selectedProductId);
                                    final quantity = int.tryParse(_quantityController.text) ?? 0;
                                    final saleAmount = product.price * quantity;
                                    final costAmount = (product.costPrice ?? 0) * quantity;
                                    final profit = saleAmount - costAmount;
                                    final isValidQuantity = quantity > 0 && quantity <= product.stockQuantity;

                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _buildDetailRow('Product', product.name),
                                        const SizedBox(height: 12),
                                        _buildDetailRow('Available Stock', '${product.stockQuantity}'),
                                        const SizedBox(height: 12),
                                        _buildDetailRow('Selling Price', '\$${product.price.toStringAsFixed(2)}'),
                                        const SizedBox(height: 12),
                                        _buildDetailRow('Quantity', quantity > 0 ? '$quantity' : '-'),

                                        if (!isValidQuantity && quantity > product.stockQuantity) ...[
                                          const SizedBox(height: 12),
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Colors.red.shade50,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              'Exceeds available stock!',
                                              style: TextStyle(
                                                color: Colors.red.shade700,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],

                                        const Divider(height: 32),
                                        _buildDetailRow('Sale Amount', '\$${saleAmount.toStringAsFixed(2)}'),
                                        const SizedBox(height: 8),
                                        _buildDetailRow('Cost', '\$${costAmount.toStringAsFixed(2)}'),
                                        const Divider(height: 24),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text(
                                              'Profit',
                                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                            ),
                                            Text(
                                              '\$${profit.toStringAsFixed(2)}',
                                              style: TextStyle(
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold,
                                                color: profit >= 0 ? const Color(0xFF10B981) : Colors.red.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ] else ...[
                                Center(
                                  child: Column(
                                    children: [
                                      Icon(Icons.point_of_sale, size: 48, color: Colors.grey.shade300),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Select a product\nto see details',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(color: Colors.grey.shade500),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _isProcessing || inStockProducts.isEmpty ? null : _recordSale,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF10B981),
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  child: _isProcessing
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
                                        )
                                      : const Text('Record Sale', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductSuggestions(List<dynamic> products) {
    final filteredProducts = products.where((product) {
      return product.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          product.sku.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    if (filteredProducts.isEmpty || _searchQuery.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      constraints: const BoxConstraints(maxHeight: 200),
      child: ListView.builder(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        itemCount: filteredProducts.length,
        itemBuilder: (context, index) {
          final product = filteredProducts[index];
          return ListTile(
            dense: true,
            title: Text(product.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            subtitle: Text(
              '${product.sku} • \$${product.price.toStringAsFixed(2)} • Stock: ${product.stockQuantity}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            onTap: () {
              setState(() {
                _selectedProductId = product.id;
                _searchController.text = product.name;
                _showProductSuggestions = false;
                _searchQuery = '';
              });
            },
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
        Text(
          value,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade800),
        ),
      ],
    );
  }
}
