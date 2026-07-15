import 'package:flutter/material.dart';
import '../../../../config/theme.dart';
import '../../data/models/vehicle_model.dart';

/// Vehicle display card with type emoji, info, and primary badge.
class VehicleCard extends StatelessWidget {
  final VehicleModel vehicle;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onSetPrimary;

  const VehicleCard({
    super.key,
    required this.vehicle,
    this.onTap,
    this.onDelete,
    this.onSetPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: vehicle.isPrimary
                ? AppColors.primary.withOpacity(0.4)
                : AppColors.gray200,
            width: vehicle.isPrimary ? 2 : 1,
          ),
          boxShadow: vehicle.isPrimary
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            // Vehicle type emoji
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: vehicle.isPrimary
                    ? AppColors.primaryBg
                    : AppColors.gray100,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  vehicle.typeEmoji,
                  style: const TextStyle(fontSize: 26),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Vehicle info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${vehicle.brand} ${vehicle.model}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: AppColors.gray900,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (vehicle.isPrimary)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Utama',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    vehicle.plateFormatted,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      letterSpacing: 1.5,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${vehicle.type} • ${vehicle.color} • ${vehicle.year}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.gray500,
                    ),
                  ),
                ],
              ),
            ),

            // More menu
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert_rounded,
                color: AppColors.gray400,
                size: 20,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onSelected: (value) {
                switch (value) {
                  case 'primary':
                    onSetPrimary?.call();
                  case 'delete':
                    onDelete?.call();
                }
              },
              itemBuilder: (_) => [
                if (!vehicle.isPrimary)
                  const PopupMenuItem(
                    value: 'primary',
                    child: Row(
                      children: [
                        Icon(Icons.star_outline_rounded, size: 18),
                        SizedBox(width: 8),
                        Text('Jadikan Utama'),
                      ],
                    ),
                  ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline_rounded,
                          size: 18, color: AppColors.danger),
                      SizedBox(width: 8),
                      Text('Hapus',
                          style: TextStyle(color: AppColors.danger)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
