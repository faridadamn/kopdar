import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../../config/theme.dart';

/// Reusable currency input field with "Rp" prefix and thousand separator.
class IncomeFormField extends StatefulWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final ValueChanged<double>? onChanged;
  final bool enabled;

  const IncomeFormField({
    super.key,
    required this.label,
    this.hint,
    required this.controller,
    this.validator,
    this.onChanged,
    this.enabled = true,
  });

  @override
  State<IncomeFormField> createState() => _IncomeFormFieldState();
}

class _IncomeFormFieldState extends State<IncomeFormField> {
  final _numberFormat = NumberFormat('#,###', 'id_ID');
  String _rawValue = '';

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    // No-op, formatting handled in onChanged
  }

  String _formatWithSeparator(String digits) {
    if (digits.isEmpty) return '';
    final num = int.tryParse(digits);
    if (num == null) return _rawValue;
    return _numberFormat.format(num).replaceAll(',', '.');
  }

  double _parseAmount(String formatted) {
    final cleaned = formatted.replaceAll(RegExp(r'[^\d]'), '');
    return double.tryParse(cleaned) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.gray700,
              ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: widget.controller,
          enabled: widget.enabled,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
          decoration: InputDecoration(
            hintText: widget.hint ?? '0',
            prefixText: 'Rp ',
            prefixStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.gray600,
                ),
            filled: true,
            fillColor: widget.enabled ? AppColors.white : AppColors.gray100,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          onChanged: (value) {
            final formatted = _formatWithSeparator(value);
            if (formatted != widget.controller.text) {
              widget.controller.value = TextEditingValue(
                text: formatted,
                selection:
                    TextSelection.collapsed(offset: formatted.length),
              );
            }
            _rawValue = formatted;
            if (widget.onChanged != null) {
              widget.onChanged!(_parseAmount(formatted));
            }
          },
          validator: widget.validator,
        ),
      ],
    );
  }
}
