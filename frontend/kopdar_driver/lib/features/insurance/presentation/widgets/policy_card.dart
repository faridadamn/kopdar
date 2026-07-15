import 'package:flutter/material.dart';

import 'package:kopdar_driver/config/theme.dart';
import 'package:kopdar_driver/core/utils/formatters.dart';
import 'package:kopdar_driver/features/insurance/data/models/insurance_model.dart';

/// Policy card showing active/expiring policy details.
class PolicyCard extends StatelessWidget {
  final InsurancePolicy policy;
  final VoidCallback? onRenew;

  const PolicyCard({
    super.key,
    required this.policy,
    this.onRenew,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: policy.isExpiringSoon
            ? Border.all(
                color: AppColors.warning.withValues(alpha: 0.4),
                width: 1.5,
              )
            : null,
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
              Expanded(
                child: Text(
                  policy.productName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.gray900,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _StatusBadge(status: policy.status),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'No. ${policy.policyNumber}',
            style: const TextStyle(fontSize: 12, color: AppColors.gray500),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_rounded,
                size: 14,
                color: AppColors.gray500,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${Formatters.date(policy.startDate)} — ${Formatters.date(policy.endDate)}',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AppColors.gray600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Premi',
                      style: TextStyle(fontSize: 11, color: AppColors.gray500),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${Formatters.currency(policy.premium.toInt())}/bulan',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.gray900,
                      ),
                    ),
                  ],
                ),
              ),
              if (policy.isActive)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Sisa',
                      style: TextStyle(fontSize: 11, color: AppColors.gray500),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${policy.daysUntilExpiry} hari',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: policy.isExpiringSoon
                            ? AppColors.warning
                            : AppColors.success,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          if (policy.isExpiringSoon && onRenew != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onRenew,
                icon: const Icon(Icons.autorenew_rounded, size: 18),
                label: const Text('Perpanjang'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.warning,
                  side: const BorderSide(color: AppColors.warning),
                  minimumSize: const Size(double.infinity, 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, backgroundColor, label) = switch (status) {
      'active' => (
          AppColors.success,
          AppColors.success.withValues(alpha: 0.1),
          'Aktif',
        ),
      'expired' => (AppColors.danger, AppColors.dangerLight, 'Kedaluwarsa'),
      'cancelled' => (AppColors.gray500, AppColors.gray200, 'Dibatalkan'),
      _ => (AppColors.gray500, AppColors.gray200, status),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
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
