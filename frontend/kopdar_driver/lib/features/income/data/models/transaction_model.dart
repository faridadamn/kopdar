/// Full transaction model for the Income Tracker feature.
/// Used for API serialization and persistence.
class TransactionModel {
  final String id;
  final String type;
  final String category;
  final String? platform;
  final double amount;
  final double commission;
  final double netAmount;
  final String? notes;
  final String? receiptUrl;
  final int orderCount;
  final DateTime createdAt;

  const TransactionModel({
    required this.id,
    required this.type,
    required this.category,
    this.platform,
    required this.amount,
    required this.commission,
    required this.netAmount,
    this.notes,
    this.receiptUrl,
    required this.orderCount,
    required this.createdAt,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    final amount = (json['amount'] as num).toDouble();
    final commission = (json['commission'] as num?)?.toDouble() ?? 0.0;
    final netAmount =
        (json['net_amount'] as num?)?.toDouble() ?? (amount - commission);

    return TransactionModel(
      id: json['id'] as String,
      type: json['type'] as String,
      category: json['category'] as String,
      platform: json['platform'] as String?,
      amount: amount,
      commission: commission,
      netAmount: netAmount,
      notes: json['notes'] as String?,
      receiptUrl: json['receipt_url'] as String?,
      orderCount: (json['order_count'] as num?)?.toInt() ?? 1,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'category': category,
      'platform': platform,
      'amount': amount,
      'commission': commission,
      'net_amount': netAmount,
      'notes': notes,
      'receipt_url': receiptUrl,
      'order_count': orderCount,
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isEditable => DateTime.now().difference(createdAt).inHours < 24;

  String get platformEmoji {
    switch (platform?.toLowerCase()) {
      case 'gojek':
        return '🛵';
      case 'grab':
        return '🚗';
      case 'shopeefood':
        return '🍔';
      case 'maxim':
        return '🚕';
      case 'indrive':
        return '🚙';
      case 'cash':
        return '💵';
      default:
        return '📋';
    }
  }

  String get categoryEmoji {
    switch (category.toLowerCase()) {
      case 'bensin':
        return '⛽';
      case 'makan':
        return '🍚';
      case 'angsuran':
        return '🏍️';
      case 'servis':
        return '🔧';
      case 'pulsa':
        return '📱';
      case 'parkir':
        return '🅿️';
      case 'kesehatan':
        return '💊';
      default:
        return '📦';
    }
  }

  String get displayTitle {
    if (type == 'income') {
      return '${platform ?? 'Pendapatan'} — $orderCount order';
    }
    return category;
  }

  TransactionModel copyWith({
    String? id,
    String? type,
    String? category,
    String? platform,
    double? amount,
    double? commission,
    double? netAmount,
    String? notes,
    String? receiptUrl,
    int? orderCount,
    DateTime? createdAt,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      type: type ?? this.type,
      category: category ?? this.category,
      platform: platform ?? this.platform,
      amount: amount ?? this.amount,
      commission: commission ?? this.commission,
      netAmount: netAmount ?? this.netAmount,
      notes: notes ?? this.notes,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      orderCount: orderCount ?? this.orderCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
