import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/api_providers.dart';
import '../models/api/api_product.dart';

class ApiPurchaseScreen extends ConsumerStatefulWidget {
  const ApiPurchaseScreen({super.key});

  @override
  ConsumerState<ApiPurchaseScreen> createState() => _ApiPurchaseScreenState();
}

class _ApiPurchaseScreenState extends ConsumerState<ApiPurchaseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _skuController = TextEditingController();
  final _priceController = TextEditingController();
  final _costPriceController = TextEditingController();
  final _initialStockController = TextEditingController();

  String? _selectedCategoryId;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _skuController.dispose();
    _priceController.dispose();
    _costPriceController.dispose();
    _initialStockController.dispose();
    super.dispose();
  }

  Future<void> _submitProduct() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a category'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await ref.read(apiProductProvider.notifier).createProduct(
        CreateProductRequest(
          name: _nameController.text,
          description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
          sku: _skuController.text,
          price: double.parse(_priceController.text),
          costPrice: double.tryParse(_costPriceController.text),
          categoryId: _selectedCategoryId!,
          initialStock: int.tryParse(_initialStockController.text) ?? 0,
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_nameController.text} added successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Reset form
        _formKey.currentState!.reset();
        _nameController.clear();
        _descriptionController.clear();
        _skuController.clear();
        _priceController.clear();
        _costPriceController.clear();
        _initialStockController.clear();
        setState(() => _selectedCategoryId = null);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding product: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(apiCategoryProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
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
                          'Add Product',
                          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.grey.shade900),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Add new products to backend inventory',
                          style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pushNamed(context, '/api-categories'),
                      icon: const Icon(Icons.category),
                      label: const Text('Manage Categories'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B5CF6),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Form
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Product Name
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Product Name *',
                            prefixIcon: const Icon(Icons.inventory_2, color: Color(0xFF6366F1)),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
                          validator: (value) => value?.isEmpty ?? true ? 'Please enter product name' : null,
                        ),
                        const SizedBox(height: 20),

                        // Description
                        TextFormField(
                          controller: _descriptionController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: 'Description (Optional)',
                            prefixIcon: const Icon(Icons.description, color: Color(0xFF6366F1)),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
                        const SizedBox(height: 20),

                        // SKU
                        TextFormField(
                          controller: _skuController,
                          decoration: InputDecoration(
                            labelText: 'SKU *',
                            hintText: 'e.g., BIKE-001',
                            prefixIcon: const Icon(Icons.qr_code, color: Color(0xFF6366F1)),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
                          validator: (value) => value?.isEmpty ?? true ? 'Please enter SKU' : null,
                        ),
                        const SizedBox(height: 20),

                        // Category Dropdown
                        categoriesAsync.when(
                          loading: () => const LinearProgressIndicator(),
                          error: (error, stack) => Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.shade300),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error, color: Colors.red.shade700),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Error loading categories: $error',
                                    style: TextStyle(color: Colors.red.shade700),
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () => ref.read(apiCategoryProvider.notifier).loadCategories(),
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                          data: (categories) {
                            if (categories.isEmpty) {
                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.orange.shade300),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.warning, color: Colors.orange.shade700),
                                    const SizedBox(width: 12),
                                    const Expanded(child: Text('No categories found. Please create a category first.')),
                                    ElevatedButton(
                                      onPressed: () => Navigator.pushNamed(context, '/api-categories'),
                                      child: const Text('Add Category'),
                                    ),
                                  ],
                                ),
                              );
                            }

                            return DropdownButtonFormField<String>(
                              value: _selectedCategoryId,
                              decoration: InputDecoration(
                                labelText: 'Category *',
                                prefixIcon: const Icon(Icons.category, color: Color(0xFF6366F1)),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
                              items: categories.map((category) {
                                return DropdownMenuItem<String>(
                                  value: category.id,
                                  child: Text(category.name),
                                );
                              }).toList(),
                              onChanged: (value) => setState(() => _selectedCategoryId = value),
                              validator: (value) => value == null ? 'Please select a category' : null,
                            );
                          },
                        ),
                        const SizedBox(height: 20),

                        // Price and Cost Price Row
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _priceController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Selling Price *',
                                  prefixIcon: const Icon(Icons.attach_money, color: Color(0xFF10B981)),
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
                                validator: (value) {
                                  if (value?.isEmpty ?? true) return 'Required';
                                  if (double.tryParse(value!) == null) return 'Invalid price';
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _costPriceController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Cost Price',
                                  prefixIcon: const Icon(Icons.money_off, color: Color(0xFFF59E0B)),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: Colors.grey.shade300),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: Color(0xFFF59E0B), width: 2),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                ),
                                validator: (value) {
                                  if (value?.isNotEmpty ?? false) {
                                    if (double.tryParse(value!) == null) return 'Invalid price';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Initial Stock
                        TextFormField(
                          controller: _initialStockController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Initial Stock Quantity *',
                            hintText: 'e.g., 10',
                            prefixIcon: const Icon(Icons.inventory, color: Color(0xFF6366F1)),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
                          validator: (value) {
                            if (value?.isEmpty ?? true) return 'Required';
                            if (int.tryParse(value!) == null) return 'Invalid quantity';
                            return null;
                          },
                        ),
                        const SizedBox(height: 32),

                        // Submit Button
                        ElevatedButton(
                          onPressed: _isSubmitting ? null : _submitProduct,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6366F1),
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
                                )
                              : const Text('Add Product to Backend', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
