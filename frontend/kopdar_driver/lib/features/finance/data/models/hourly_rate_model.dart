/// Model for hourly rate data from the API.
class HourlyRateModel {
  final String period;
  final double totalHours;
  final double totalProfit;
  final double hourlyRate;
  final double zoneAverage;
  final String trend; // 'up', 'down', 'stable'
  final String insight;
  final List<DailyRate> dailyBreakdown;

  const HourlyRateModel({
    required this.period,
    required this.totalHours,
    required this.totalProfit,
    required this.hourlyRate,
    required this.zoneAverage,
    required this.trend,
    required this.insight,
    required this.dailyBreakdown,
  });

  factory HourlyRateModel.fromJson(Map<String, dynamic> json) {
    return HourlyRateModel(
      period: json['period'] as String? ?? '',
      totalHours: (json['total_hours'] as num?)?.toDouble() ?? 0,
      totalProfit: (json['total_profit'] as num?)?.toDouble() ?? 0,
      hourlyRate: (json['hourly_rate'] as num?)?.toDouble() ?? 0,
      zoneAverage: (json['zone_average'] as num?)?.toDouble() ?? 0,
      trend: json['trend'] as String? ?? 'stable',
      insight: json['insight'] as String? ?? '',
      dailyBreakdown: (json['daily_breakdown'] as List<dynamic>?)
              ?.map((e) => DailyRate.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// Percentage difference from zone average.
  double get percentDiff {
    if (zoneAverage == 0) return 0;
    return ((hourlyRate - zoneAverage) / zoneAverage);
  }

  /// Whether the rate is above zone average.
  bool get isAboveAverage => hourlyRate >= zoneAverage;

  /// Formatted trend emoji.
  String get trendEmoji {
    switch (trend) {
      case 'up':
        return '↑';
      case 'down':
        return '↓';
      default:
        return '→';
    }
  }
}

/// Single day rate entry in the breakdown.
class DailyRate {
  final String day; // e.g. 'Senin'
  final double rate;
  final double hours;
  final double profit;

  const DailyRate({
    required this.day,
    required this.rate,
    required this.hours,
    required this.profit,
  });

  factory DailyRate.fromJson(Map<String, dynamic> json) {
    return DailyRate(
      day: json['day'] as String? ?? '',
      rate: (json['rate'] as num?)?.toDouble() ?? 0,
      hours: (json['hours'] as num?)?.toDouble() ?? 0,
      profit: (json['profit'] as num?)?.toDouble() ?? 0,
    );
  }
}
