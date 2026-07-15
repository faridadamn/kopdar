import 'package:flutter/material.dart';
import '../../../config/theme.dart';

/// Data class for a single quick-action button.
class QuickAction {
  final String emoji;
  final String label;
  final Color bgColor;
  final VoidCallback? onTap;

  const QuickAction({
    required this.emoji,
    required this.label,
    required this.bgColor,
    this.onTap,
  });
}

/// 4-button grid of quick actions on the dashboard.
class QuickActionsGrid extends StatelessWidget {
  final VoidCallback? onTabungan;
  final VoidCallback? onAsuransi;
  final VoidCallback? onKomunitas;
  final VoidCallback? onKeuangan;
  final VoidCallback? onRiwayat;
  final VoidCallback? onRewards;

  const QuickActionsGrid({
    super.key,
    this.onTabungan,
    this.onAsuransi,
    this.onKomunitas,
    this.onKeuangan,
    this.onRiwayat,
    this.onRewards,
  });

  @override
  Widget build(BuildContext context) {
    final actions = [
      QuickAction(
        emoji: '🐷',
        label: 'Tabungan',
        bgColor: const Color(0xFFFFF0F5),
        onTap: onTabungan,
      ),
      QuickAction(
        emoji: '🛡️',
        label: 'Asuransi',
        bgColor: AppColors.blueLight,
        onTap: onAsuransi,
      ),
      QuickAction(
        emoji: '📦',
        label: 'Riwayat',
        bgColor: const Color(0xFFE8F5E9),
        onTap: onRiwayat,
      ),
      QuickAction(
        emoji: '🏆',
        label: 'Rewards',
        bgColor: const Color(0xFFFFF8E1),
        onTap: onRewards,
      ),
      QuickAction(
        emoji: '👥',
        label: 'Komunitas',
        bgColor: const Color(0xFFF3E5F5),
        onTap: onKomunitas,
      ),
      QuickAction(
        emoji: '📊',
        label: 'Keuangan',
        bgColor: AppColors.accentLight,
        onTap: onKeuangan,
      ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: actions
            .map((a) => SizedBox(
                  width: 72,
                  child: _QuickActionButton(action: a),
                ))
            .toList(),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final QuickAction action;

  const _QuickActionButton({required this.action});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: action.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: action.bgColor,
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: Text(
                action.emoji,
                style: const TextStyle(fontSize: 26),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              action.label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.gray700,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
