import 'package:flutter/material.dart';
import '../../../../config/theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../data/models/hourly_rate_model.dart';

/// Simple bar chart showing hourly rate per day.
/// 7 bars (Mon-Sun), green for normal, orange for below average.
class HourlyRateChart extends StatefulWidget {
  final List<DailyRate> dailyBreakdown;
  final double zoneAverage;

  const HourlyRateChart({
    super.key,
    required this.dailyBreakdown,
    required this.zoneAverage,
  });

  @override
  State<HourlyRateChart> createState() => _HourlyRateChartState();
}

class _HourlyRateChartState extends State<HourlyRateChart> {
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    if (widget.dailyBreakdown.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            const Text('📊', style: TextStyle(fontSize: 32)),
            const SizedBox(height: 8),
            Text(
              'Belum ada data harian',
              style: TextStyle(color: AppColors.gray500, fontSize: 13),
            ),
          ],
        ),
      );
    }

    final maxRate = widget.dailyBreakdown
        .map((d) => d.rate)
        .reduce((a, b) => a > b ? a : b);
    final chartHeight = 160.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Legend
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Di atas rata-rata',
                style: TextStyle(fontSize: 11, color: AppColors.gray600),
              ),
              const SizedBox(width: 16),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: AppColors.warning,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Di bawah rata-rata',
                style: TextStyle(fontSize: 11, color: AppColors.gray600),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Value tooltip
          if (_selectedIndex != null &&
              _selectedIndex! < widget.dailyBreakdown.length)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                '${widget.dailyBreakdown[_selectedIndex!].day}: ${Formatters.currency(widget.dailyBreakdown[_selectedIndex!].rate.toInt())}/jam',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.gray800,
                ),
              ),
            ),

          // Bar chart
          SizedBox(
            height: chartHeight + 30, // extra for labels
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(widget.dailyBreakdown.length, (index) {
                final daily = widget.dailyBreakdown[index];
                final ratio = maxRate > 0 ? daily.rate / maxRate : 0.0;
                final barHeight = ratio * chartHeight;
                final isBelow = daily.rate < widget.zoneAverage;
                final barColor =
                    isBelow ? AppColors.warning : AppColors.primary;
                final isSelected = _selectedIndex == index;

                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedIndex = isSelected ? null : index;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Value on top
                          if (daily.rate > 0)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                Formatters.currencyCompact(daily.rate.toInt()),
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? barColor
                                      : AppColors.gray500,
                                ),
                                maxLines: 1,
                              ),
                            ),

                          // Bar
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            height: barHeight > 0 ? barHeight : 4,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? barColor
                                  : barColor.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: barColor.withOpacity(0.3),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 6),

                          // Day label
                          Text(
                            _shortDay(daily.day),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected
                                  ? AppColors.gray800
                                  : AppColors.gray500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),

          // Average line label
          if (widget.zoneAverage > 0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Container(
                    width: 16,
                    height: 1.5,
                    color: AppColors.gray400,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Rata-rata zona: ${Formatters.currency(widget.zoneAverage.toInt())}/jam',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.gray500,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Short day label: 'Senin' → 'Sen', 'Selasa' → 'Sel', etc.
  String _shortDay(String day) {
    switch (day.toLowerCase()) {
      case 'senin':
        return 'Sen';
      case 'selasa':
        return 'Sel';
      case 'rabu':
        return 'Rab';
      case 'kamis':
        return 'Kam';
      case "jum'at":
      case 'jumat':
        return 'Jum';
      case 'sabtu':
        return 'Sab';
      case 'minggu':
        return 'Min';
      default:
        return day.length > 3 ? day.substring(0, 3) : day;
    }
  }
}
