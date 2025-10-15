/// API Product Model - matches backend schema
class ApiProduct {
  final String id;
  final String name;
  final String? description;
  final String sku;
  final double price;
  final double? costPrice;
  final String? categoryId;
  final String? imageUrl;
  final bool isActive;
  final int stockQuantity;
  final DateTime createdAt;
  final DateTime updatedAt;

  ApiProduct({
    required this.id,
    required this.name,
    this.description,
    required this.sku,
    required this.price,
    this.costPrice,
    this.categoryId,
    this.imageUrl,
    required this.isActive,
    required this.stockQuantity,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ApiProduct.fromJson(Map<String, dynamic> json) {
    return ApiProduct(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      sku: json['sku'],
      price: (json['price'] as num).toDouble(),
      costPrice: json['cost_price'] != null
          ? (json['cost_price'] as num).toDouble()
          : null,
      categoryId: json['category_id'],
      imageUrl: json['image_url'],
      isActive: json['is_active'],
      stockQuantity: json['stock_quantity'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    if (description != null) 'description': description,
    'sku': sku,
    'price': price,
    if (costPrice != null) 'cost_price': costPrice,
    if (categoryId != null) 'category_id': categoryId,
    if (imageUrl != null) 'image_url': imageUrl,
    'is_active': isActive,
    'stock_quantity': stockQuantity,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  // Helper getters for compatibility with existing Product model
  double get buyingPrice => costPrice ?? 0.0;
  double get sellingPrice => price;
  int get quantity => stockQuantity;
  bool get isInStock => stockQuantity > 0;
  bool get isLowStock => stockQuantity < 5 && stockQuantity > 0;
  double get profitMargin => price - (costPrice ?? 0.0);
  double get totalBuyingValue => (costPrice ?? 0.0) * stockQuantity;
  double get potentialRevenue => price * stockQuantity;
  double get potentialProfit => potentialRevenue - totalBuyingValue;
}

/// Request model for creating a product
class CreateProductRequest {
  final String name;
  final String? description;
  final String sku;
  final double price;
  final double? costPrice;
  final String? categoryId;
  final String? imageUrl;
  final int? initialStock;

  CreateProductRequest({
    required this.name,
    this.description,
    required this.sku,
    required this.price,
    this.costPrice,
    this.categoryId,
    this.imageUrl,
    this.initialStock,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    if (description != null) 'description': description,
    'sku': sku,
    'price': price,
    if (costPrice != null) 'cost_price': costPrice,
    if (categoryId != null) 'category_id': categoryId,
    if (imageUrl != null) 'image_url': imageUrl,
    if (initialStock != null) 'initial_stock': initialStock,
  };
}

/// Request model for updating a product
class UpdateProductRequest {
  final String? name;
  final String? description;
  final String? sku;
  final double? price;
  final double? costPrice;
  final String? categoryId;
  final String? imageUrl;
  final bool? isActive;

  UpdateProductRequest({
    this.name,
    this.description,
    this.sku,
    this.price,
    this.costPrice,
    this.categoryId,
    this.imageUrl,
    this.isActive,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (name != null) map['name'] = name;
    if (description != null) map['description'] = description;
    if (sku != null) map['sku'] = sku;
    if (price != null) map['price'] = price;
    if (costPrice != null) map['cost_price'] = costPrice;
    if (categoryId != null) map['category_id'] = categoryId;
    if (imageUrl != null) map['image_url'] = imageUrl;
    if (isActive != null) map['is_active'] = isActive;
    return map;
  }
}
