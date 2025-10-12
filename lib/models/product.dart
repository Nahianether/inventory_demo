import 'package:hive/hive.dart';

part 'product.g.dart';

@HiveType(typeId: 0)
class Product extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String name;

  @HiveField(2)
  late String category;

  @HiveField(3)
  late double buyingPrice;

  @HiveField(4)
  late double sellingPrice;

  @HiveField(5)
  late int quantity;

  @HiveField(6)
  late String? description;

  @HiveField(7)
  late DateTime createdAt;

  @HiveField(8)
  late DateTime updatedAt;

  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.buyingPrice,
    required this.sellingPrice,
    required this.quantity,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  // Calculate profit margin
  double get profitMargin => sellingPrice - buyingPrice;

  // Calculate total inventory value at buying price
  double get totalBuyingValue => buyingPrice * quantity;

  // Calculate potential revenue at selling price
  double get potentialRevenue => sellingPrice * quantity;

  // Calculate potential profit
  double get potentialProfit => potentialRevenue - totalBuyingValue;

  // Check if product is in stock
  bool get isInStock => quantity > 0;

  // Check if product is low stock (less than 5 items)
  bool get isLowStock => quantity < 5 && quantity > 0;

  // Copy with method for updates
  Product copyWith({
    String? id,
    String? name,
    String? category,
    double? buyingPrice,
    double? sellingPrice,
    int? quantity,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      buyingPrice: buyingPrice ?? this.buyingPrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      quantity: quantity ?? this.quantity,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Product(id: $id, name: $name, category: $category, quantity: $quantity)';
  }
}
