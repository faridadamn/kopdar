import 'package:flutter/material.dart';
import '../../../../config/theme.dart';

/// Petition card showing petition details with progress and sign button.
class PetitionCard extends StatelessWidget {
  final String title;
  final String description;
  final int targetSignatures;
  final int currentSignatures;
  final bool hasSigned;
  final VoidCallback? onSign;

  const PetitionCard({
    super.key,
    required this.title,
    required this.description,
    required this.targetSignatures,
    required this.currentSignatures,
    this.hasSigned = false,
    this.onSign,
  });

  @override
  Widget build(BuildContext context) {
    final progress = targetSignatures > 0
        ? (currentSignatures / targetSignatures).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.gray200),
        boxShadow: [
          BoxShadow(
            color: AppColors.gray400.withOpacity(0.1),
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
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E5F5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.campaign_outlined,
                  color: Color(0xFF7B1FA2),
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.gray900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.gray600,
              height: 1.4,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 14),
          // Progress bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_formatNumber(currentSignatures)} tanda tangan',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.gray700,
                ),
              ),
              Text(
                'Target: ${_formatNumber(targetSignatures)}',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.gray500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.gray200,
              valueColor: AlwaysStoppedAnimation<Color>(
                progress >= 1.0 ? AppColors.success : const Color(0xFF7B1FA2),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${(progress * 100).round()}% tercapai',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.gray500,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: hasSigned ? null : onSign,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    hasSigned ? AppColors.gray300 : const Color(0xFF7B1FA2),
                foregroundColor: hasSigned ? AppColors.gray600 : Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    hasSigned ? Icons.check_circle : Icons.edit,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    hasSigned ? 'Sudah Tanda Tangan' : 'Tanda Tangan',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1).replaceAll('.0', '')}rb';
    }
    return number.toString();
  }
}
