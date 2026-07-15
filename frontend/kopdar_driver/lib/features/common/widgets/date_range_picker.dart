import 'package:flutter/material.dart';
import '../../../../config/theme.dart';
import '../../../../core/utils/formatters.dart';

/// Date range picker widget with two date fields and quick select buttons.
class DateRangePickerWidget extends StatelessWidget {
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final ValueChanged<DateTime> onFromChanged;
  final ValueChanged<DateTime> onToChanged;

  const DateRangePickerWidget({
    super.key,
    required this.dateFrom,
    required this.dateTo,
    required this.onFromChanged,
    required this.onToChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Quick select buttons
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _QuickChip(
                label: '7 hari terakhir',
                onTap: () {
                  final now = DateTime.now();
                  final today = DateTime(now.year, now.month, now.day);
                  onFromChanged(today.subtract(const Duration(days: 7)));
                  onToChanged(today.add(const Duration(days: 1)));
                },
              ),
              const SizedBox(width: 8),
              _QuickChip(
                label: '30 hari terakhir',
                onTap: () {
                  final now = DateTime.now();
                  final today = DateTime(now.year, now.month, now.day);
                  onFromChanged(today.subtract(const Duration(days: 30)));
                  onToChanged(today.add(const Duration(days: 1)));
                },
              ),
              const SizedBox(width: 8),
              _QuickChip(
                label: 'Bulan ini',
                onTap: () {
                  final now = DateTime.now();
                  final monthStart = DateTime(now.year, now.month, 1);
                  final monthEnd = DateTime(now.year, now.month + 1, 1);
                  onFromChanged(monthStart);
                  onToChanged(monthEnd);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Date fields
        Row(
          children: [
            Expanded(
              child: _DateField(
                label: 'Dari',
                date: dateFrom,
                onTap: () => _pickDate(context, isFrom: true),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Icon(
                Icons.arrow_forward_rounded,
                size: 20,
                color: AppColors.gray400,
              ),
            ),
            Expanded(
              child: _DateField(
                label: 'Sampai',
                date: dateTo,
                onTap: () => _pickDate(context, isFrom: false),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _pickDate(BuildContext context, {required bool isFrom}) async {
    final now = DateTime.now();
    final initial = isFrom ? dateFrom : dateTo;
    final firstDate = DateTime(2020);
    final lastDate = DateTime(now.year + 1);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? now,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: AppColors.white,
              surface: AppColors.white,
              onSurface: AppColors.gray900,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      if (isFrom) {
        onFromChanged(picked);
      } else {
        onToChanged(picked);
      }
    }
  }
}

class _QuickChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.primaryBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;

  const _DateField({
    required this.label,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.gray300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: AppColors.gray500,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 16,
                  color: AppColors.gray500,
                ),
                const SizedBox(width: 8),
                Text(
                  date != null
                      ? Formatters.date(date!)
                      : 'Pilih tanggal',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color:
                        date != null ? AppColors.gray800 : AppColors.gray400,
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
