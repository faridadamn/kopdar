import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../config/theme.dart';
import '../../data/models/emergency_model.dart';

/// Tile showing a nearby driver who can respond to the emergency.
class NearbyDriverTile extends StatelessWidget {
  final NearbyDriverModel driver;

  const NearbyDriverTile({super.key, required this.driver});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: driver.isResponding
              ? AppColors.warning.withOpacity(0.5)
              : AppColors.gray200,
        ),
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 22,
            backgroundColor: driver.isResponding
                ? AppColors.warning.withOpacity(0.2)
                : AppColors.gray200,
            child: driver.avatarUrl != null
                ? ClipOval(
                    child: Image.network(
                      driver.avatarUrl!,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.person_rounded,
                        color: driver.isResponding
                            ? AppColors.warning
                            : AppColors.gray500,
                      ),
                    ),
                  )
                : Icon(
                    Icons.person_rounded,
                    color: driver.isResponding
                        ? AppColors.warning
                        : AppColors.gray500,
                  ),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  driver.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: 14,
                      ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      size: 14,
                      color: AppColors.gray500,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${driver.distanceKm.toStringAsFixed(1)} km',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(width: 10),
                    Icon(
                      Icons.access_time_rounded,
                      size: 14,
                      color: AppColors.gray500,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '±${driver.etaMinutes} mnt',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Status / Action
          if (driver.isResponding)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Menuju',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.warning,
                ),
              ),
            )
          else if (driver.phoneNumber != null)
            IconButton(
              onPressed: () => _callNumber(driver.phoneNumber!),
              icon: const Icon(Icons.phone_rounded, size: 20),
              color: AppColors.success,
              style: IconButton.styleFrom(
                backgroundColor: AppColors.success.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _callNumber(String phone) async {
    const platform = MethodChannel('com.kopdar/phone');
    try {
      await platform.invokeMethod('call', {'number': phone});
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: phone));
    }
  }
}
