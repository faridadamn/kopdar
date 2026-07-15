class TransactionModel {
  final String id;
  final String type; // 'income', 'expense'
  final String? platform; // Gojek, Grab, etc. (for income)
  final String? category; // Bensin, Makan, etc. (for expense)
  final int amount;
  final int? grossAmount; // for income
  final int? commission; // for income
  final int? orderCount; // for income
  final String? notes;
  final String? photoUrl;
  final DateTime createdAt;

  const TransactionModel({
    required this.id,
    required this.type,
    this.platform,
    this.category,
    required this.amount,
    this.grossAmount,
    this.commission,
    this.orderCount,
    this.notes,
    this.photoUrl,
    required this.createdAt,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as String,
      type: json['type'] as String,
      platform: json['platform'] as String?,
      category: json['category'] as String?,
      amount: json['amount'] as int,
      grossAmount: json['gross_amount'] as int?,
      commission: json['commission'] as int?,
      orderCount: json['order_count'] as int?,
      notes: json['notes'] as String?,
      photoUrl: json['photo_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'platform': platform,
      'category': category,
      'amount': amount,
      'gross_amount': grossAmount,
      'commission': commission,
      'order_count': orderCount,
      'notes': notes,
      'photo_url': photoUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isIncome => type == 'income';
  bool get isExpense => type == 'expense';

  String get displayTitle {
    if (isIncome) return platform ?? 'Penghasilan';
    return category ?? 'Pengeluaran';
  }

  String get displayIcon {
    if (isIncome) {
      switch (platform) {
        case 'Gojek':
          return '🟢';
        case 'Grab':
          return '🟩';
        case 'ShopeeFood':
          return '🟠';
        case 'Maxim':
          return '🟡';
        case 'InDrive':
          return '🔵';
        default:
          return '💰';
      }
    }

    switch (category) {
      case 'Bensin':
        return '⛽';
      case 'Makan':
        return '🍚';
      case 'Angsuran':
        return '🏍️';
      case 'Servis':
        return '🔧';
      case 'Pulsa':
        return '📱';
      case 'Parkir':
        return '🅿️';
      case 'Kesehatan':
        return '💊';
      default:
        return '📦';
    }
  }
}
