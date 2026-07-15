import 'package:flutter/material.dart';
import '../../../../config/theme.dart';
import '../../../core/utils/formatters.dart';
import '../../data/models/ride_model.dart';

/// Ride/order card showing platform, route, earnings, etc.
class RideCard extends StatelessWidget {
  final RideModel ride;
  final VoidCallback? onTap;

  const RideCard({super.key, required this.ride, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: ride.status == 'cancelled'
                ? AppColors.danger.withOpacity(0.2)
                : AppColors.gray200,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Platform + time ──
            Row(
              children: [
                Text(ride.platformEmoji,
                    style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text(
                  ride.platformName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.gray900,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    ride.statusLabel,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: _statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // ── Route ──
            Row(
              children: [
                Column(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Container(
                      width: 2,
                      height: 24,
                      color: AppColors.gray300,
                    ),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.danger,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ride.pickupAddress ?? '-',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.gray800,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        ride.dropoffAddress ?? '-',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.gray600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // ── Stats row ──
            Row(
              children: [
                _MiniStat(
                    icon: '🛣️', value: ride.distanceFormatted),
                const SizedBox(width: 14),
                _MiniStat(
                    icon: '⏱️', value: ride.durationFormatted),
                const Spacer(),
                Text(
                  Formatters.currency(ride.earnings),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),

            // ── Rating ──
            if (ride.rating != null) ...[
              const SizedBox(height: 8),
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < ride.rating!.round()
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    size: 16,
                    color: i < ride.rating!.round()
                        ? AppColors.warning
                        : AppColors.gray300,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color get _statusColor {
    switch (ride.status) {
      case 'completed':
        return AppColors.success;
      case 'cancelled':
        return AppColors.danger;
      default:
        return AppColors.info;
    }
  }
}

class _MiniStat extends StatelessWidget {
  final String icon;
  final String value;

  const _MiniStat({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(icon, style: const TextStyle(fontSize: 12)),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.gray600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
