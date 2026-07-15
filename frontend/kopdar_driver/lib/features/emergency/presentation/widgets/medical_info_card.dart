import 'package:flutter/material.dart';
import '../../../../config/theme.dart';
import '../../data/models/emergency_model.dart';

/// Card displaying medical information for emergencies.
class MedicalInfoCard extends StatelessWidget {
  final DriverMedicalModel medical;

  const MedicalInfoCard({super.key, required this.medical});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.blue.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.blue.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.blueLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.medical_information_rounded,
                  color: AppColors.blue,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Info Medis',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.blue,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Blood type
          if (medical.bloodType != null) ...[
            _InfoRow(
              icon: Icons.bloodtype_rounded,
              label: 'Golongan Darah',
              value: medical.bloodType!,
              valueColor: AppColors.danger,
            ),
            const SizedBox(height: 10),
          ],

          // Allergies
          if (medical.allergies.isNotEmpty) ...[
            _InfoRow(
              icon: Icons.warning_amber_rounded,
              label: 'Alergi',
              value: medical.allergies.join(', '),
              valueColor: AppColors.warning,
            ),
            const SizedBox(height: 10),
          ],

          // Conditions
          if (medical.conditions.isNotEmpty) ...[
            _InfoRow(
              icon: Icons.healing_rounded,
              label: 'Kondisi Kesehatan',
              value: medical.conditions.join(', '),
            ),
            const SizedBox(height: 10),
          ],

          // Medications
          if (medical.medications.isNotEmpty) ...[
            _InfoRow(
              icon: Icons.medication_rounded,
              label: 'Obat Rutin',
              value: medical.medications.join(', '),
            ),
            const SizedBox(height: 10),
          ],

          // Notes
          if (medical.emergencyNotes != null &&
              medical.emergencyNotes!.isNotEmpty) ...[
            _InfoRow(
              icon: Icons.note_alt_rounded,
              label: 'Catatan',
              value: medical.emergencyNotes!,
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.gray500),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: Theme.of(context).textTheme.bodyMedium,
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(color: AppColors.gray600),
                ),
                TextSpan(
                  text: value,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? AppColors.gray900,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
