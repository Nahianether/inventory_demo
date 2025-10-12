import 'package:hive/hive.dart';

part 'account.g.dart';

@HiveType(typeId: 2)
class Account extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late double totalBalance;

  @HiveField(2)
  late double totalRevenue;

  @HiveField(3)
  late double totalExpenses;

  @HiveField(4)
  late double totalProfit;

  @HiveField(5)
  late DateTime lastUpdated;

  Account({
    required this.id,
    required this.totalBalance,
    required this.totalRevenue,
    required this.totalExpenses,
    required this.totalProfit,
    required this.lastUpdated,
  });

  // Calculate net profit
  double get netProfit => totalRevenue - totalExpenses;

  // Update account after sale
  void recordSale(double saleAmount, double costAmount) {
    totalBalance += saleAmount;
    totalRevenue += saleAmount;
    totalExpenses += costAmount;
    totalProfit = netProfit;
    lastUpdated = DateTime.now();
  }

  // Update account after purchase
  void recordPurchase(double purchaseAmount) {
    totalBalance -= purchaseAmount;
    totalExpenses += purchaseAmount;
    totalProfit = netProfit;
    lastUpdated = DateTime.now();
  }

  Account copyWith({
    String? id,
    double? totalBalance,
    double? totalRevenue,
    double? totalExpenses,
    double? totalProfit,
    DateTime? lastUpdated,
  }) {
    return Account(
      id: id ?? this.id,
      totalBalance: totalBalance ?? this.totalBalance,
      totalRevenue: totalRevenue ?? this.totalRevenue,
      totalExpenses: totalExpenses ?? this.totalExpenses,
      totalProfit: totalProfit ?? this.totalProfit,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  String toString() {
    return 'Account(balance: $totalBalance, revenue: $totalRevenue, expenses: $totalExpenses, profit: $totalProfit)';
  }
}
