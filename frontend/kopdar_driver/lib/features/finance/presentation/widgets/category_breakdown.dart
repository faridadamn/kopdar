import 'package:flutter/material.dart';
import '../../../../config/theme.dart';
import '../../../../core/utils/formatters.dart';

/// Horizontal bar chart showing expense breakdown by category.
/// Each bar: category icon + name + amount + percentage.
class CategoryBreakdown extends StatelessWidget {
  final Map<String, double> categoryTotals;
  final Map<String, String> categoryEmojis;

  const CategoryBreakdown({
    super.key,
    required this.categoryTotals,
    required this.categoryEmojis,
  });

  @override
  Widget build(BuildContext context) {
    if (categoryTotals.isEmpty) {
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
              'Belum ada data pengeluaran',
              style: TextStyle(color: AppColors.gray500, fontSize: 13),
            ),
          ],
        ),
      );
    }

    final total = categoryTotals.values.fold(0.0, (sum, v) => sum + v);
    final entries = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxAmount = entries.first.value;

    // Color palette for categories
    final colors = [
      AppColors.danger,
      AppColors.warning,
      AppColors.accent,
      AppColors.primary,
      AppColors.blue,
      AppColors.info,
      AppColors.gray600,
      AppColors.gray500,
    ];

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
        children: List.generate(entries.length, (index) {
          final entry = entries[index];
          final ratio = maxAmount > 0 ? entry.value / maxAmount : 0.0;
          final percent = total > 0 ? (entry.value / total * 100) : 0.0;
          final emoji =
              categoryEmojis[entry.key] ?? _defaultEmoji(entry.key);
          final barColor = colors[index % colors.length];

          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              children: [
                Row(
                  children: [
                    // Icon
                    Text(emoji, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 10),

                    // Name + percentage
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.key,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${percent.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.gray500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Amount
                    Text(
                      Formatters.currency(entry.value.toInt()),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: barColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Bar
                Container(
                  width: double.infinity,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.gray100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: ratio,
                    child: Container(
                      decoration: BoxDecoration(
                        color: barColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  String _defaultEmoji(String category) {
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
}
