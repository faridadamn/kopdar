/// Model for a pinjol (online loan) entry.
class PinjolModel {
  final String id;
  final String appName;
  final double principal;
  final double interestRate;
  final double monthlyInstallment;
  final double outstandingAmount;
  final double totalPaidInterest;
  final DateTime startDate;
  final DateTime? endDate;
  final String riskLevel; // safe, warning, danger
  final int monthsRemaining;
  final double totalInterestIfFullTerm;
  final PayoffSimulation? earlyPayoff;

  const PinjolModel({
    required this.id,
    required this.appName,
    required this.principal,
    required this.interestRate,
    required this.monthlyInstallment,
    required this.outstandingAmount,
    required this.totalPaidInterest,
    required this.startDate,
    this.endDate,
    required this.riskLevel,
    required this.monthsRemaining,
    required this.totalInterestIfFullTerm,
    this.earlyPayoff,
  });

  factory PinjolModel.fromJson(Map<String, dynamic> json) {
    return PinjolModel(
      id: json['id'] as String,
      appName: json['app_name'] as String,
      principal: (json['principal'] as num).toDouble(),
      interestRate: (json['interest_rate'] as num).toDouble(),
      monthlyInstallment: (json['monthly_installment'] as num).toDouble(),
      outstandingAmount: (json['outstanding_amount'] as num).toDouble(),
      totalPaidInterest: (json['total_paid_interest'] as num?)?.toDouble() ?? 0,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'] as String)
          : null,
      riskLevel: json['risk_level'] as String? ?? 'safe',
      monthsRemaining: (json['months_remaining'] as num?)?.toInt() ?? 0,
      totalInterestIfFullTerm:
          (json['total_interest_if_full_term'] as num?)?.toDouble() ?? 0,
      earlyPayoff: json['early_payoff'] != null
          ? PayoffSimulation.fromJson(
              json['early_payoff'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'app_name': appName,
      'principal': principal,
      'interest_rate': interestRate,
      'monthly_installment': monthlyInstallment,
      'outstanding_amount': outstandingAmount,
      'total_paid_interest': totalPaidInterest,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'risk_level': riskLevel,
      'months_remaining': monthsRemaining,
      'total_interest_if_full_term': totalInterestIfFullTerm,
      'early_payoff': earlyPayoff?.toJson(),
    };
  }

  String get riskLabel {
    switch (riskLevel) {
      case 'safe':
        return 'Aman';
      case 'warning':
        return 'Waspada';
      case 'danger':
        return 'Berisiko';
      default:
        return riskLevel;
    }
  }

  String get riskEmoji {
    switch (riskLevel) {
      case 'safe':
        return '🟢';
      case 'warning':
        return '🟡';
      case 'danger':
        return '🔴';
      default:
        return '⚪';
    }
  }

  bool get isSafe => riskLevel == 'safe';
  bool get isWarning => riskLevel == 'warning';
  bool get isDanger => riskLevel == 'danger';

  PinjolModel copyWith({
    String? id,
    String? appName,
    double? principal,
    double? interestRate,
    double? monthlyInstallment,
    double? outstandingAmount,
    double? totalPaidInterest,
    DateTime? startDate,
    DateTime? endDate,
    String? riskLevel,
    int? monthsRemaining,
    double? totalInterestIfFullTerm,
    PayoffSimulation? earlyPayoff,
  }) {
    return PinjolModel(
      id: id ?? this.id,
      appName: appName ?? this.appName,
      principal: principal ?? this.principal,
      interestRate: interestRate ?? this.interestRate,
      monthlyInstallment: monthlyInstallment ?? this.monthlyInstallment,
      outstandingAmount: outstandingAmount ?? this.outstandingAmount,
      totalPaidInterest: totalPaidInterest ?? this.totalPaidInterest,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      riskLevel: riskLevel ?? this.riskLevel,
      monthsRemaining: monthsRemaining ?? this.monthsRemaining,
      totalInterestIfFullTerm:
          totalInterestIfFullTerm ?? this.totalInterestIfFullTerm,
      earlyPayoff: earlyPayoff ?? this.earlyPayoff,
    );
  }
}

/// Simulation result for early payoff.
class PayoffSimulation {
  final int months;
  final double totalPayments;
  final double totalInterest;
  final double interestSaved;
  final bool canAffordFromSavings;
  final String recommendation;

  const PayoffSimulation({
    required this.months,
    required this.totalPayments,
    required this.totalInterest,
    required this.interestSaved,
    required this.canAffordFromSavings,
    required this.recommendation,
  });

  factory PayoffSimulation.fromJson(Map<String, dynamic> json) {
    return PayoffSimulation(
      months: (json['months'] as num).toInt(),
      totalPayments: (json['total_payments'] as num).toDouble(),
      totalInterest: (json['total_interest'] as num).toDouble(),
      interestSaved: (json['interest_saved'] as num).toDouble(),
      canAffordFromSavings: json['can_afford_from_savings'] as bool? ?? false,
      recommendation: json['recommendation'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'months': months,
      'total_payments': totalPayments,
      'total_interest': totalInterest,
      'interest_saved': interestSaved,
      'can_afford_from_savings': canAffordFromSavings,
      'recommendation': recommendation,
    };
  }
}
