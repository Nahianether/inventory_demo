/// API Inventory Model - matches backend schema
class ApiInventory {
  final String id;
  final String productId;
  final int quantity;
  final int? minStockLevel;
  final int? maxStockLevel;
  final String? location;
  final DateTime? lastRestockedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  ApiInventory({
    required this.id,
    required this.productId,
    required this.quantity,
    this.minStockLevel,
    this.maxStockLevel,
    this.location,
    this.lastRestockedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ApiInventory.fromJson(Map<String, dynamic> json) {
    return ApiInventory(
      id: json['id'],
      productId: json['product_id'],
      quantity: json['quantity'],
      minStockLevel: json['min_stock_level'],
      maxStockLevel: json['max_stock_level'],
      location: json['location'],
      lastRestockedAt: json['last_restocked_at'] != null
          ? DateTime.parse(json['last_restocked_at'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'product_id': productId,
    'quantity': quantity,
    if (minStockLevel != null) 'min_stock_level': minStockLevel,
    if (maxStockLevel != null) 'max_stock_level': maxStockLevel,
    if (location != null) 'location': location,
    if (lastRestockedAt != null) 'last_restocked_at': lastRestockedAt!.toIso8601String(),
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };
}

/// Request model for updating inventory settings
class UpdateInventoryRequest {
  final int? quantity;
  final int? minStockLevel;
  final int? maxStockLevel;
  final String? location;

  UpdateInventoryRequest({
    this.quantity,
    this.minStockLevel,
    this.maxStockLevel,
    this.location,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (quantity != null) map['quantity'] = quantity;
    if (minStockLevel != null) map['min_stock_level'] = minStockLevel;
    if (maxStockLevel != null) map['max_stock_level'] = maxStockLevel;
    if (location != null) map['location'] = location;
    return map;
  }
}

/// Request model for adjusting stock
class AdjustStockRequest {
  final String productId;
  final int quantityChange;
  final String? reason;

  AdjustStockRequest({
    required this.productId,
    required this.quantityChange,
    this.reason,
  });

  Map<String, dynamic> toJson() => {
    'product_id': productId,
    'quantity_change': quantityChange,
    if (reason != null) 'reason': reason,
  };
}

/// Low stock product info
class LowStockProduct {
  final String productId;
  final String productName;
  final int currentQuantity;
  final int minStockLevel;

  LowStockProduct({
    required this.productId,
    required this.productName,
    required this.currentQuantity,
    required this.minStockLevel,
  });

  factory LowStockProduct.fromJson(Map<String, dynamic> json) {
    return LowStockProduct(
      productId: json['product_id'],
      productName: json['product_name'],
      currentQuantity: json['current_quantity'],
      minStockLevel: json['min_stock_level'],
    );
  }

  int get stockDeficit => minStockLevel - currentQuantity;
}

/// Stock movement record
class StockMovement {
  final String id;
  final String productId;
  final int quantityChange;
  final String? reason;
  final String? performedBy;
  final DateTime createdAt;

  StockMovement({
    required this.id,
    required this.productId,
    required this.quantityChange,
    this.reason,
    this.performedBy,
    required this.createdAt,
  });

  factory StockMovement.fromJson(Map<String, dynamic> json) {
    return StockMovement(
      id: json['id'],
      productId: json['product_id'],
      quantityChange: json['quantity_change'],
      reason: json['reason'],
      performedBy: json['performed_by'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  bool get isAddition => quantityChange > 0;
  bool get isRemoval => quantityChange < 0;
}
