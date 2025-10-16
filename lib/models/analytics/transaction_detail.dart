/// Transaction Detail Model - matches backend /api/transactions
enum PaymentMethod {
  cash,
  card,
  digitalWallet,
  other;

  factory PaymentMethod.fromString(String value) {
    switch (value.toLowerCase()) {
      case 'cash':
        return PaymentMethod.cash;
      case 'card':
        return PaymentMethod.card;
      case 'digital_wallet':
        return PaymentMethod.digitalWallet;
      default:
        return PaymentMethod.other;
    }
  }

  String get displayName {
    switch (this) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.card:
        return 'Card';
      case PaymentMethod.digitalWallet:
        return 'Digital Wallet';
      case PaymentMethod.other:
        return 'Other';
    }
  }
}

class TransactionDetail {
  final String id;
  final String transactionType;
  final String? customerName;
  final double subtotal;
  final double discount;
  final double tax;
  final double total;
  final double profit;
  final PaymentMethod paymentMethod;
  final double paymentReceived;
  final double changeGiven;
  final String? notes;
  final int itemCount;
  final DateTime createdAt;

  TransactionDetail({
    required this.id,
    required this.transactionType,
    this.customerName,
    required this.subtotal,
    required this.discount,
    required this.tax,
    required this.total,
    required this.profit,
    required this.paymentMethod,
    required this.paymentReceived,
    required this.changeGiven,
    this.notes,
    required this.itemCount,
    required this.createdAt,
  });

  factory TransactionDetail.fromJson(Map<String, dynamic> json) {
    return TransactionDetail(
      id: json['id'] as String,
      transactionType: json['transaction_type'] as String,
      customerName: json['customer_name'],
      subtotal: (json['subtotal'] as num).toDouble(),
      discount: (json['discount'] as num).toDouble(),
      tax: (json['tax'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
      profit: (json['profit'] as num).toDouble(),
      paymentMethod: PaymentMethod.fromString(json['payment_method'] as String),
      paymentReceived: (json['payment_received'] as num).toDouble(),
      changeGiven: (json['change_given'] as num).toDouble(),
      notes: json['notes'],
      itemCount: json['item_count'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'transaction_type': transactionType,
        if (customerName != null) 'customer_name': customerName,
        'subtotal': subtotal,
        'discount': discount,
        'tax': tax,
        'total': total,
        'profit': profit,
        'payment_method': paymentMethod.name,
        'payment_received': paymentReceived,
        'change_given': changeGiven,
        if (notes != null) 'notes': notes,
        'item_count': itemCount,
        'created_at': createdAt.toIso8601String(),
      };
}
