import 'package:flutter/material.dart';
import '../../../../config/theme.dart';
import '../../../core/utils/formatters.dart';
import '../../data/models/vehicle_model.dart';

/// Document tile: icon, type, status badge, expiry, actions.
class DocumentTile extends StatelessWidget {
  final DocumentModel document;
  final VoidCallback? onUpload;
  final VoidCallback? onDelete;
  final VoidCallback? onView;

  const DocumentTile({
    super.key,
    required this.document,
    this.onUpload,
    this.onDelete,
    this.onView,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _borderColor,
          width: document.isExpiringSoon ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          // Document icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _iconBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                document.typeEmoji,
                style: const TextStyle(fontSize: 22),
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
                    Text(
                      document.typeLabel,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.gray900,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _StatusBadge(status: document.status),
                  ],
                ),
                const SizedBox(height: 4),
                if (document.fileName != null)
                  Text(
                    document.fileName!,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.gray500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (document.expiryDate != null)
                  Text(
                    'Berlaku s/d ${Formatters.date(document.expiryDate!)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: document.isExpiringSoon
                          ? AppColors.warning
                          : AppColors.gray500,
                      fontWeight: document.isExpiringSoon
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
              ],
            ),
          ),

          // Action
          if (document.fileUrl != null)
            IconButton(
              icon: Icon(
                Icons.visibility_outlined,
                size: 20,
                color: AppColors.gray500,
              ),
              onPressed: onView,
            )
          else
            IconButton(
              icon: const Icon(
                Icons.cloud_upload_outlined,
                size: 20,
                color: AppColors.primary,
              ),
              onPressed: onUpload,
            ),
        ],
      ),
    );
  }

  Color get _borderColor {
    if (document.isExpiringSoon) return AppColors.warning;
    if (document.isRejected) return AppColors.danger;
    if (document.isVerified) return AppColors.success.withOpacity(0.3);
    return AppColors.gray200;
  }

  Color get _iconBgColor {
    if (document.isVerified) return AppColors.success.withOpacity(0.1);
    if (document.isRejected) return AppColors.dangerLight;
    if (document.isExpiringSoon) return AppColors.warning.withOpacity(0.1);
    return AppColors.gray100;
  }
}

/// Status badge chip.
class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        _label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: _color,
        ),
      ),
    );
  }

  String get _label {
    switch (status) {
      case 'verified':
        return '✓ Valid';
      case 'expired':
        return '⚠ Kadaluarsa';
      case 'rejected':
        return '✗ Ditolak';
      default:
        return '⏳ Review';
    }
  }

  Color get _color {
    switch (status) {
      case 'verified':
        return AppColors.success;
      case 'expired':
        return AppColors.warning;
      case 'rejected':
        return AppColors.danger;
      default:
        return AppColors.info;
    }
  }
}
