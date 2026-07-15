import 'package:flutter/material.dart';
import '../../../../config/theme.dart';
import '../../../core/utils/formatters.dart';
import '../../data/models/insurance_model.dart';

/// Claim card showing claim type, status, and date.
class ClaimCard extends StatelessWidget {
  final InsuranceClaim claim;

  const ClaimCard({super.key, required this.claim});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: claim type + status badge
          Row(
            children: [
              // Type icon
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.blueLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  _claimTypeEmoji(claim.claimType),
                  style: const TextStyle(fontSize: 18),
                ),
              ),
              const SizedBox(width: 12),

              // Type + policy name
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      claim.claimTypeLabel,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.gray900,
                      ),
                    ),
                    Text(
                      claim.policyName,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.gray500,
                      ),
                    ),
                  ],
                ),
              ),

              _StatusBadge(status: claim.status),
            ],
          ),
          const SizedBox(height: 12),

          // Description preview
          Text(
            claim.description,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.gray700,
              height: 1.4,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),

          // Date + evidence count
          Row(
            children: [
              Icon(Icons.access_time_rounded,
                  size: 13, color: AppColors.gray400),
              const SizedBox(width: 4),
              Text(
                Formatters.relativeTime(claim.createdAt),
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.gray500,
                ),
              ),
              if (claim.evidenceUrls.isNotEmpty) ...[
                const SizedBox(width: 12),
                Icon(Icons.image_rounded,
                    size: 13, color: AppColors.gray400),
                const SizedBox(width: 4),
                Text(
                  '${claim.evidenceUrls.length} foto',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.gray500,
                  ),
                ),
              ],
            ],
          ),

          // Admin notes (if any)
          if (claim.adminNotes != null && claim.adminNotes!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.gray100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Catatan: ${claim.adminNotes}',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.gray600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _claimTypeEmoji(String type) {
    switch (type) {
      case 'accident':
        return '🚑';
      case 'inpatient':
        return '🏥';
      case 'vehicle':
        return '🛵';
      default:
        return '📋';
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    Color bgColor;
    String label;

    switch (status) {
      case 'pending':
        color = AppColors.warning;
        bgColor = AppColors.warning.withOpacity(0.1);
        label = 'Menunggu';
        break;
      case 'approved':
        color = AppColors.success;
        bgColor = AppColors.success.withOpacity(0.1);
        label = 'Disetujui';
        break;
      case 'rejected':
        color = AppColors.danger;
        bgColor = AppColors.dangerLight;
        label = 'Ditolak';
        break;
      case 'reimbursed':
        color = AppColors.blue;
        bgColor = AppColors.blueLight;
        label = 'Dibayar';
        break;
      default:
        color = AppColors.gray500;
        bgColor = AppColors.gray200;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
