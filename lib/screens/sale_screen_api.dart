import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction.dart';
import '../providers/api_inventory_provider.dart';
import '../providers/inventory_provider.dart';
import '../widgets/qr_scanner_dialog.dart';
import '../services/inventory_api_service.dart';

/// Sale Screen with API Integration
/// Records sales and adjusts stock via backend API
class SaleScreenApi extends ConsumerStatefulWidget {
  const SaleScreenApi({super.key});

  @override
  ConsumerState<SaleScreenApi> createState() => _SaleScreenApiState();
}

class _SaleScreenApiState extends ConsumerState<SaleScreenApi> {
  String? selectedProductId;
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

  Future<void> _scanQRCode() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => const QRScannerDialog(),
    );

    if (result != null && mounted) {
      // Get products from API
      final productsAsync = ref.read(apiProductProvider);
      productsAsync.whenData((products) {
        final product = products.where((p) => p.id == result).firstOrNull;
        if (product != null && product.isInStock) {
          setState(() {
            selectedProductId = result;
            _searchController.text = product.name;
            _showProductSuggestions = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Product "${product.name}" selected'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Product not found or out of stock'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      });
    }
  }

  Future<void> _recordSale() async {
    if (selectedProductId == null) {
      _showError('Please select a product');
      return;
    }

    if (_quantityController.text.isEmpty) {
      _showError('Please enter quantity');
      return;
    }

    final quantity = int.tryParse(_quantityController.text);
    if (quantity == null || quantity <= 0) {
      _showError('Please enter a valid quantity');
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // Get the product details
      final productsAsync = ref.read(apiProductProvider);
      final products = productsAsync.value;
      if (products == null) {
        throw Exception('Products not loaded');
      }

      final product = products.firstWhere((p) => p.id == selectedProductId);

      // Check stock availability
      if (product.stockQuantity < quantity) {
        throw InsufficientStockException(
          'Insufficient stock! Available: ${product.stockQuantity}',
        );
      }

      // Adjust stock via API
      final inventoryService = ref.read(apiInventoryProvider);
      await inventoryService.adjustStock(
        productId: selectedProductId!,
        quantityChange: -quantity,
        reason: 'Sale: ${_notesController.text.isEmpty ? "POS transaction" : _notesController.text}',
      );

      // Calculate amounts
      final saleAmount = product.price * quantity;
      final costAmount = (product.costPrice ?? 0) * quantity;

      // Record transaction locally (for now)
      final transaction = Transaction(
        id: const Uuid().v4(),
        productId: product.id,
        productName: product.name,
        quantity: quantity,
        pricePerUnit: product.price,
        totalAmount: saleAmount,
        type: 'sale',
        createdAt: DateTime.now(),
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );

      await ref.read(transactionProvider.notifier).addTransaction(transaction);
      await ref.read(accountProvider.notifier).recordSale(saleAmount, costAmount);

      // Refresh product list
      await ref.read(apiProductProvider.notifier).loadProducts();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Sale recorded: $quantity x ${product.name}\nProfit: \$${(saleAmount - costAmount).toStringAsFixed(2)}',
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 3),
          ),
        );

        setState(() {
          selectedProductId = null;
          _searchController.clear();
          _quantityController.clear();
          _notesController.clear();
          _showProductSuggestions = false;
        });
      }
    } on InsufficientStockException catch (e) {
      _showError(e.toString());
    } catch (e) {
      _showError('Failed to record sale: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(apiProductProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: productsAsync.when(
        data: (products) {
          final inStockProducts = products.where((p) => p.isInStock).toList();
          return _buildSaleForm(inStockProducts);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text(
                'Failed to load products',
                style: TextStyle(fontSize: 18, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => ref.read(apiProductProvider.notifier).loadProducts(),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSaleForm(List<dynamic> products) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Record Sale (API)',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.grey.shade900),
              ),
              const SizedBox(height: 8),
              Text(
                'Process sales and update inventory via backend API',
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
                          BoxShadow(
                            color: Colors.black.withValues(alpha: .05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (products.isEmpty)
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
                                  Expanded(
                                    child: Text(
                                      'No products available in stock',
                                      style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else ...[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      TextFormField(
                                        controller: _searchController,
                                        onChanged: (value) {
                                          setState(() {
                                            _searchQuery = value;
                                            _showProductSuggestions = value.isNotEmpty;
                                            if (selectedProductId != null) {
                                              try {
                                                final product = products.firstWhere(
                                                  (p) => p.id == selectedProductId,
                                                );
                                                if (product.name != value) {
                                                  selectedProductId = null;
                                                }
                                              } catch (e) {
                                                selectedProductId = null;
                                              }
                                            }
                                          });
                                        },
                                        decoration: InputDecoration(
                                          labelText: 'Search Product',
                                          labelStyle: TextStyle(color: Colors.grey.shade700),
                                          hintText: 'Type product name...',
                                          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                                          prefixIcon: const Icon(Icons.search, color: Color(0xFF10B981)),
                                          suffixIcon: selectedProductId != null
                                              ? Container(
                                                  margin: const EdgeInsets.all(8),
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFF10B981).withValues(alpha: 0.1),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(Icons.check_circle,
                                                        color: const Color(0xFF10B981),
                                                        size: 16
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        'Selected',
                                                        style: TextStyle(
                                                          color: const Color(0xFF10B981),
                                                          fontSize: 12,
                                                          fontWeight: FontWeight.w600,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
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
                                            borderSide: const BorderSide(color: Color(0xFF10B981), width: 2),
                                          ),
                                          filled: true,
                                          fillColor: Colors.grey.shade50,
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                        ),
                                      ),
                                      if (_showProductSuggestions)
                                        _buildProductSuggestions(products),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  height: 56,
                                  width: 56,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: IconButton(
                                    onPressed: _scanQRCode,
                                    icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
                                    tooltip: 'Scan QR Code',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            TextFormField(
                              controller: _quantityController,
                              keyboardType: TextInputType.number,
                              onChanged: (_) => setState(() {}),
                              decoration: InputDecoration(
                                labelText: 'Quantity',
                                labelStyle: TextStyle(color: Colors.grey.shade700),
                                prefixIcon: const Icon(Icons.production_quantity_limits, color: Color(0xFF10B981)),
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
                                  borderSide: const BorderSide(color: Color(0xFF10B981), width: 2),
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              ),
                            ),
                            const SizedBox(height: 24),

                            TextFormField(
                              controller: _notesController,
                              maxLines: 3,
                              decoration: InputDecoration(
                                labelText: 'Notes (Optional)',
                                labelStyle: TextStyle(color: Colors.grey.shade700),
                                prefixIcon: const Icon(Icons.notes, color: Color(0xFF10B981)),
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
                                  borderSide: const BorderSide(color: Color(0xFF10B981), width: 2),
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),

                  Container(
                    width: 300,
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
                          'Sale Summary',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade900),
                        ),
                        const SizedBox(height: 20),

                        if (selectedProductId != null) ...[
                          Builder(
                            builder: (context) {
                              final product = products.firstWhere((p) => p.id == selectedProductId);
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
                                      Text(
                                        'Profit',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey.shade900,
                                        ),
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
                            onPressed: _isProcessing || products.isEmpty ? null : _recordSale,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: _isProcessing
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Text(
                                    'Record Sale',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                  ),
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
  }

  Widget _buildProductSuggestions(List<dynamic> products) {
    final filteredProducts = products.where((product) {
      return product.name.toLowerCase().contains(_searchQuery.toLowerCase());
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
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
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
            title: Text(
              product.name,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              '\$${product.price.toStringAsFixed(2)} • Stock: ${product.stockQuantity}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            onTap: () {
              setState(() {
                selectedProductId = product.id;
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
