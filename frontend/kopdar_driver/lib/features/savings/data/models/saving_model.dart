/// Model for a savings goal.
class SavingModel {
  final String id;
  final String goalName;
  final String goalIcon;
  final double targetAmount;
  final double currentAmount;
  final double dailyAmount;
  final bool autoSave;
  final String status; // active, paused, completed
  final int progressPercent;
  final int estimatedDays;
  final List<SavingTransaction> recentTransactions;
  final DateTime createdAt;

  const SavingModel({
    required this.id,
    required this.goalName,
    required this.goalIcon,
    required this.targetAmount,
    required this.currentAmount,
    required this.dailyAmount,
    required this.autoSave,
    required this.status,
    required this.progressPercent,
    required this.estimatedDays,
    required this.recentTransactions,
    required this.createdAt,
  });

  factory SavingModel.fromJson(Map<String, dynamic> json) {
    return SavingModel(
      id: json['id'] as String,
      goalName: json['goal_name'] as String,
      goalIcon: json['goal_icon'] as String? ?? '🎯',
      targetAmount: (json['target_amount'] as num).toDouble(),
      currentAmount: (json['current_amount'] as num).toDouble(),
      dailyAmount: (json['daily_amount'] as num).toDouble(),
      autoSave: json['auto_save'] as bool? ?? false,
      status: json['status'] as String? ?? 'active',
      progressPercent: (json['progress_percent'] as num?)?.toInt() ?? 0,
      estimatedDays: (json['estimated_days'] as num?)?.toInt() ?? 0,
      recentTransactions: (json['recent_transactions'] as List<dynamic>?)
              ?.map((e) =>
                  SavingTransaction.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'goal_name': goalName,
      'goal_icon': goalIcon,
      'target_amount': targetAmount,
      'current_amount': currentAmount,
      'daily_amount': dailyAmount,
      'auto_save': autoSave,
      'status': status,
      'progress_percent': progressPercent,
      'estimated_days': estimatedDays,
      'recent_transactions':
          recentTransactions.map((e) => e.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  double get progress =>
      targetAmount > 0 ? currentAmount / targetAmount : 0;

  bool get isActive => status == 'active';
  bool get isPaused => status == 'paused';
  bool get isCompleted => status == 'completed';

  String get statusLabel {
    switch (status) {
      case 'active':
        return 'Aktif';
      case 'paused':
        return 'Dijeda';
      case 'completed':
        return 'Selesai';
      default:
        return status;
    }
  }

  SavingModel copyWith({
    String? id,
    String? goalName,
    String? goalIcon,
    double? targetAmount,
    double? currentAmount,
    double? dailyAmount,
    bool? autoSave,
    String? status,
    int? progressPercent,
    int? estimatedDays,
    List<SavingTransaction>? recentTransactions,
    DateTime? createdAt,
  }) {
    return SavingModel(
      id: id ?? this.id,
      goalName: goalName ?? this.goalName,
      goalIcon: goalIcon ?? this.goalIcon,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      dailyAmount: dailyAmount ?? this.dailyAmount,
      autoSave: autoSave ?? this.autoSave,
      status: status ?? this.status,
      progressPercent: progressPercent ?? this.progressPercent,
      estimatedDays: estimatedDays ?? this.estimatedDays,
      recentTransactions: recentTransactions ?? this.recentTransactions,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// A single deposit or withdrawal transaction within a savings goal.
class SavingTransaction {
  final String id;
  final String type; // deposit, withdrawal
  final double amount;
  final String method; // auto, manual
  final String? notes;
  final DateTime createdAt;

  const SavingTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.method,
    this.notes,
    required this.createdAt,
  });

  factory SavingTransaction.fromJson(Map<String, dynamic> json) {
    return SavingTransaction(
      id: json['id'] as String,
      type: json['type'] as String,
      amount: (json['amount'] as num).toDouble(),
      method: json['method'] as String? ?? 'manual',
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'amount': amount,
      'method': method,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isDeposit => type == 'deposit';
  bool get isWithdrawal => type == 'withdrawal';
}
