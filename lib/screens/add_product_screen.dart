import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/inventory_provider.dart';
import '../models/product.dart';
import '../widgets/qr_scanner_dialog.dart';

class AddProductScreen extends ConsumerStatefulWidget {
  const AddProductScreen({super.key});

  @override
  ConsumerState<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends ConsumerState<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _buyingPriceController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  final _quantityController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isTypingCategory = false;
  Product? _selectedExistingProduct;
  bool _showProductSuggestions = false;

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _buyingPriceController.dispose();
    _sellingPriceController.dispose();
    _quantityController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _onProductNameChanged(String value) {
    setState(() {
      _showProductSuggestions = value.isNotEmpty;

      // Check if the entered name exactly matches an existing product
      final products = ref.read(productProvider);
      final exactMatch = products.where((p) => p.name.toLowerCase() == value.toLowerCase()).firstOrNull;

      if (exactMatch != null && _selectedExistingProduct?.id != exactMatch.id) {
        _selectedExistingProduct = exactMatch;
        // Populate fields with existing product data
        _categoryController.text = exactMatch.category;
        _buyingPriceController.text = exactMatch.buyingPrice.toStringAsFixed(2);
        _sellingPriceController.text = exactMatch.sellingPrice.toStringAsFixed(2);
        _descriptionController.text = exactMatch.description ?? '';
      } else if (exactMatch == null) {
        _selectedExistingProduct = null;
      }
    });
  }

  void _selectProduct(Product product) {
    setState(() {
      _selectedExistingProduct = product;
      _nameController.text = product.name;
      _categoryController.text = product.category;
      _buyingPriceController.text = product.buyingPrice.toStringAsFixed(2);
      _sellingPriceController.text = product.sellingPrice.toStringAsFixed(2);
      _descriptionController.text = product.description ?? '';
      _showProductSuggestions = false;
      _quantityController.clear(); // Clear quantity as user needs to enter new stock
    });
  }

  Future<void> _scanQRCode() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => const QRScannerDialog(),
    );

    if (result != null && mounted) {
      // The QR code contains the product ID
      final product = ref.read(productProvider.notifier).getProductById(result);
      if (product != null) {
        _selectProduct(product);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Product "${product.name}" selected for restocking'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Product not found'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  void _saveProduct() async {
    if (_formKey.currentState!.validate()) {
      // Unfocus to dismiss keyboard and trigger any pending updates
      FocusScope.of(context).unfocus();

      final quantity = int.parse(_quantityController.text);

      if (_selectedExistingProduct != null) {
        // Update existing product
        final updatedProduct = Product(
          id: _selectedExistingProduct!.id,
          name: _nameController.text.trim(),
          category: _categoryController.text.trim(),
          buyingPrice: double.parse(_buyingPriceController.text),
          sellingPrice: double.parse(_sellingPriceController.text),
          quantity: _selectedExistingProduct!.quantity + quantity, // Add to existing quantity
          description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
          createdAt: _selectedExistingProduct!.createdAt,
          updatedAt: DateTime.now(),
        );

        await ref.read(productProvider.notifier).updateProduct(updatedProduct);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Product "${updatedProduct.name}" updated!\nQuantity: ${_selectedExistingProduct!.quantity} → ${updatedProduct.quantity} (+$quantity)',
              ),
              backgroundColor: Colors.blue,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        // Add new product
        await ref.read(productProvider.notifier).addProduct(
          name: _nameController.text.trim(),
          category: _categoryController.text.trim(),
          buyingPrice: double.parse(_buyingPriceController.text),
          sellingPrice: double.parse(_sellingPriceController.text),
          quantity: quantity,
          description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('New product added successfully! You can add another one.'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }

      // Clear form after save
      if (mounted) {
        // Clear all controllers first
        _nameController.clear();
        _categoryController.clear();
        _buyingPriceController.clear();
        _sellingPriceController.clear();
        _quantityController.clear();
        _descriptionController.clear();

        // Reset form state
        _formKey.currentState?.reset();

        // Update UI state
        setState(() {
          _isTypingCategory = false;
          _selectedExistingProduct = null;
          _showProductSuggestions = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final allProducts = ref.watch(productProvider);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                _selectedExistingProduct == null ? 'Add New Product' : 'Update Product',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.grey.shade900),
              ),
              const SizedBox(height: 8),
              Text(
                _selectedExistingProduct == null
                    ? 'Fill in the product details to add to inventory'
                    : 'Update quantity and prices for existing product',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 32),

              // Form Card
              Container(
                padding: const EdgeInsets.all(32),
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
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Row 1: Product Name with QR Scanner & Category
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          _buildProductNameField(allProducts),
                                          if (_showProductSuggestions) _buildProductSuggestions(allProducts),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Container(
                                      height: 56,
                                      width: 56,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF6366F1),
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
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(child: _buildCategoryField()),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Row 2: Buying Price & Selling Price
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _buyingPriceController,
                              label: 'Buying Price',
                              icon: Icons.attach_money,
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter buying price';
                                }
                                if (double.tryParse(value) == null) {
                                  return 'Please enter a valid number';
                                }
                                if (double.parse(value) < 0) {
                                  return 'Price cannot be negative';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              controller: _sellingPriceController,
                              label: 'Selling Price',
                              icon: Icons.sell,
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter selling price';
                                }
                                if (double.tryParse(value) == null) {
                                  return 'Please enter a valid number';
                                }
                                if (double.parse(value) < 0) {
                                  return 'Price cannot be negative';
                                }
                                final buyingPrice = double.tryParse(_buyingPriceController.text);
                                final sellingPrice = double.parse(value);
                                if (buyingPrice != null && sellingPrice < buyingPrice) {
                                  return 'Warning: Selling price is lower than buying price';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Row 3: Quantity
                      _buildTextField(
                        controller: _quantityController,
                        label: _selectedExistingProduct == null ? 'Initial Quantity' : 'Add Quantity',
                        hint: _selectedExistingProduct != null ? 'Current: ${_selectedExistingProduct!.quantity}' : null,
                        icon: Icons.production_quantity_limits,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter quantity';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          if (int.parse(value) < 0) {
                            return 'Quantity cannot be negative';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Row 4: Description
                      _buildTextField(
                        controller: _descriptionController,
                        label: 'Description (Optional)',
                        icon: Icons.description,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 32),

                      // Submit Button
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                setState(() {
                                  _nameController.clear();
                                  _categoryController.clear();
                                  _buyingPriceController.clear();
                                  _sellingPriceController.clear();
                                  _quantityController.clear();
                                  _descriptionController.clear();
                                  _isTypingCategory = false;
                                  _selectedExistingProduct = null;
                                  _showProductSuggestions = false;
                                });
                                _formKey.currentState?.reset();
                              },
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                side: BorderSide(color: Colors.grey.shade300),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: Text('Clear Form', style: TextStyle(fontSize: 16, color: Colors.grey.shade700)),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: _saveProduct,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _selectedExistingProduct == null ? const Color(0xFF6366F1) : Colors.blue,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: Text(
                                _selectedExistingProduct == null ? 'Add Product' : 'Update Product',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductNameField(List<Product> allProducts) {
    return TextFormField(
      controller: _nameController,
      onChanged: _onProductNameChanged,
      onTap: () {
        setState(() {
          _showProductSuggestions = _nameController.text.isNotEmpty;
        });
      },
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        labelText: 'Product Name',
        hintText: 'Start typing to see suggestions...',
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        labelStyle: TextStyle(color: Colors.grey.shade700),
        prefixIcon: const Icon(Icons.inventory_2, color: Color(0xFF6366F1), size: 20),
        suffixIcon: _selectedExistingProduct != null
            ? Container(
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'EXISTING',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
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
          borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter product name';
        }
        return null;
      },
    );
  }

  Widget _buildProductSuggestions(List<Product> allProducts) {
    final searchQuery = _nameController.text.toLowerCase();
    final matchingProducts = allProducts
        .where((p) => p.name.toLowerCase().contains(searchQuery))
        .take(5)
        .toList();

    if (matchingProducts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListView.builder(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: matchingProducts.length,
        itemBuilder: (context, index) {
          final product = matchingProducts[index];
          return ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.inventory_2, color: Colors.blue.shade700, size: 20),
            ),
            title: Text(
              product.name,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            subtitle: Text(
              '${product.category} • Stock: ${product.quantity} • \$${product.sellingPrice.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            onTap: () => _selectProduct(product),
          );
        },
      ),
    );
  }

  Widget _buildCategoryField() {
    final categories = ref.watch(categoryProvider);
    final categoryNames = categories.map((c) => c.name).toList()..sort();

    final dropdownValue = _categoryController.text.isEmpty || !categoryNames.contains(_categoryController.text)
        ? null
        : _categoryController.text;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!_isTypingCategory && categoryNames.isNotEmpty)
          DropdownButtonFormField<String>(
            value: dropdownValue,
            decoration: InputDecoration(
              labelText: 'Category',
              labelStyle: TextStyle(color: Colors.grey.shade700),
              prefixIcon: const Icon(Icons.category, color: Color(0xFF6366F1), size: 20),
              suffixIcon: IconButton(
                icon: const Icon(Icons.edit, size: 18),
                tooltip: 'Type new category',
                onPressed: () {
                  setState(() {
                    _isTypingCategory = true;
                  });
                },
              ),
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
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.red, width: 1),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.red, width: 2),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            hint: const Text('Select or type category'),
            items: categoryNames.map((categoryName) {
              return DropdownMenuItem(value: categoryName, child: Text(categoryName));
            }).toList(),
            onChanged: (value) {
              setState(() {
                _categoryController.text = value ?? '';
              });
            },
            validator: (value) {
              if (_categoryController.text.isEmpty) {
                return 'Please select or enter category';
              }
              return null;
            },
          )
        else
          TextFormField(
            controller: _categoryController,
            style: const TextStyle(fontSize: 15),
            decoration: InputDecoration(
              labelText: 'Category',
              hintText: 'Type category name or go to Categories to add',
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              labelStyle: TextStyle(color: Colors.grey.shade700),
              prefixIcon: const Icon(Icons.category, color: Color(0xFF6366F1), size: 20),
              suffixIcon: categoryNames.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.arrow_drop_down, size: 24),
                      tooltip: 'Select from existing',
                      onPressed: () {
                        setState(() {
                          _isTypingCategory = false;
                        });
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
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.red, width: 1),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.red, width: 2),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter category';
              }
              return null;
            },
          ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        labelStyle: TextStyle(color: Colors.grey.shade700),
        prefixIcon: Icon(icon, color: const Color(0xFF6366F1), size: 20),
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
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}
