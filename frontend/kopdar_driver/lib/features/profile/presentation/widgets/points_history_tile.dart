import 'package:flutter/material.dart';

import 'package:kopdar_driver/config/theme.dart';
import 'package:kopdar_driver/core/utils/formatters.dart';
import 'package:kopdar_driver/features/profile/data/models/profile_model.dart';

/// Points history tile: action, points (+/-), date.
class PointsHistoryTile extends StatelessWidget {
  final PointsHistory entry;

  const PointsHistoryTile({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final isEarn = entry.type == 'earn';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isEarn ? AppColors.primaryBg : AppColors.accentLight,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                isEarn ? '⬆️' : '⬇️',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.action,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColors.gray900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  Formatters.relativeTime(entry.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.gray500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${isEarn ? '+' : '-'}${entry.points}',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: isEarn ? AppColors.success : AppColors.accent,
            ),
          ),
        ],
      ),
    );
  }
}
