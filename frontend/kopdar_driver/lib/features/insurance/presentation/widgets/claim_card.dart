import 'package:flutter/material.dart';

import 'package:kopdar_driver/config/theme.dart';
import 'package:kopdar_driver/core/utils/formatters.dart';
import 'package:kopdar_driver/features/insurance/data/models/insurance_model.dart';

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
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
          Row(
            children: [
              Icon(
                Icons.access_time_rounded,
                size: 13,
                color: AppColors.gray400,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  Formatters.relativeTime(claim.createdAt),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.gray500,
                  ),
                ),
              ),
              if (claim.evidenceUrls.isNotEmpty) ...[
                const SizedBox(width: 12),
                Icon(
                  Icons.image_rounded,
                  size: 13,
                  color: AppColors.gray400,
                ),
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
    late final Color color;
    late final Color bgColor;
    late final String label;

    switch (status) {
      case 'pending':
        color = AppColors.warning;
        bgColor = AppColors.warning.withValues(alpha: 0.1);
        label = 'Menunggu';
      case 'approved':
        color = AppColors.success;
        bgColor = AppColors.success.withValues(alpha: 0.1);
        label = 'Disetujui';
      case 'rejected':
        color = AppColors.danger;
        bgColor = AppColors.dangerLight;
        label = 'Ditolak';
      case 'reimbursed':
        color = AppColors.blue;
        bgColor = AppColors.blueLight;
        label = 'Dibayar';
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
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
