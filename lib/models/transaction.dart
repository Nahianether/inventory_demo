import 'package:hive/hive.dart';

part 'transaction.g.dart';

enum TransactionType {
  purchase,
  sale,
}

@HiveType(typeId: 1)
class Transaction extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String productId;

  @HiveField(2)
  late String productName;

  @HiveField(3)
  late int quantity;

  @HiveField(4)
  late double pricePerUnit;

  @HiveField(5)
  late double totalAmount;

  @HiveField(6)
  late String type; // 'purchase' or 'sale'

  @HiveField(7)
  late DateTime createdAt;

  @HiveField(8)
  late String? notes;

  Transaction({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.pricePerUnit,
    required this.totalAmount,
    required this.type,
    required this.createdAt,
    this.notes,
  });

  bool get isPurchase => type == 'purchase';
  bool get isSale => type == 'sale';

  @override
  String toString() {
    return 'Transaction(id: $id, product: $productName, quantity: $quantity, type: $type, amount: $totalAmount)';
  }
}
