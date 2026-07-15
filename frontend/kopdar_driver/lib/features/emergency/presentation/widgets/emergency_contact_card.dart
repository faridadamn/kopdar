import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../config/theme.dart';
import '../../data/models/emergency_model.dart';

/// Card for an emergency contact with a call button.
class EmergencyContactCard extends StatelessWidget {
  final EmergencyContactModel contact;
  final VoidCallback? onDelete;

  const EmergencyContactCard({
    super.key,
    required this.contact,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: contact.isPrimary
                  ? AppColors.primaryBg
                  : AppColors.gray100,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                _relationIcon(contact.relation),
                color: contact.isPrimary
                    ? AppColors.primary
                    : AppColors.gray600,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        contact.name,
                        style: Theme.of(context).textTheme.titleMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (contact.isPrimary) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Utama',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${contact.relationLabel} · ${contact.phoneNumber}',
                  style: Theme.of(context).textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Call button
          IconButton(
            onPressed: () => _callNumber(contact.phoneNumber),
            icon: const Icon(Icons.phone_rounded),
            color: AppColors.success,
            style: IconButton.styleFrom(
              backgroundColor: AppColors.success.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          // Delete button (optional)
          if (onDelete != null)
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline_rounded),
              color: AppColors.danger,
              iconSize: 20,
            ),
        ],
      ),
    );
  }

  IconData _relationIcon(String relation) {
    switch (relation) {
      case 'keluarga':
        return Icons.family_restroom_rounded;
      case 'pasangan':
        return Icons.favorite_rounded;
      case 'teman':
        return Icons.people_rounded;
      default:
        return Icons.person_rounded;
    }
  }

  Future<void> _callNumber(String phone) async {
    // Launch phone dialer via platform channel
    const platform = MethodChannel('com.kopdar/phone');
    try {
      await platform.invokeMethod('call', {'number': phone});
    } catch (_) {
      // Fallback: copy to clipboard
      await Clipboard.setData(ClipboardData(text: phone));
    }
  }
}
