import 'package:flutter/material.dart';
import '../../../../config/theme.dart';
import '../../../core/utils/formatters.dart';
import '../../data/models/insurance_model.dart';

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
            ? Border.all(color: AppColors.warning.withOpacity(0.4), width: 1.5)
            : null,
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
          // Header: product name + status badge
          Row(
            children: [
              Expanded(
                child: Text(
                  policy.productName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.gray900,
                  ),
                ),
              ),
              _StatusBadge(status: policy.status),
            ],
          ),
          const SizedBox(height: 4),

          // Policy number
          Text(
            'No. ${policy.policyNumber}',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.gray500,
            ),
          ),
          const SizedBox(height: 12),

          // Date range
          Row(
            children: [
              Icon(Icons.calendar_today_rounded,
                  size: 14, color: AppColors.gray500),
              const SizedBox(width: 6),
              Text(
                '${Formatters.date(policy.startDate)} — ${Formatters.date(policy.endDate)}',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.gray600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Premium + expiry
          Row(
            children: [
              // Premium
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Premi',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.gray500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${Formatters.currency(policy.premium.toInt())}/bulan',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.gray900,
                      ),
                    ),
                  ],
                ),
              ),

              // Days until expiry
              if (policy.isActive)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Sisa',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.gray500,
                      ),
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

          // Renew button for expiring policies
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
    Color color;
    Color bgColor;
    String label;

    switch (status) {
      case 'active':
        color = AppColors.success;
        bgColor = AppColors.success.withOpacity(0.1);
        label = 'Aktif';
        break;
      case 'expired':
        color = AppColors.danger;
        bgColor = AppColors.dangerLight;
        label = 'Kedaluwarsa';
        break;
      case 'cancelled':
        color = AppColors.gray500;
        bgColor = AppColors.gray200;
        label = 'Dibatalkan';
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
