import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/theme.dart';
import '../../../core/utils/formatters.dart';
import '../providers/pinjol_provider.dart';

/// Popular pinjol app options.
const _popularApps = [
  'Kredivo',
  'Akulaku',
  'ShopeePinjam',
  'KreditPintar',
  'AdaKami',
  'Danamas',
  'RupiahCepat',
  'Tunaiku',
];

/// Page to add a new loan entry.
class AddPinjolPage extends StatefulWidget {
  const AddPinjolPage({super.key});

  @override
  State<AddPinjolPage> createState() => _AddPinjolPageState();
}

class _AddPinjolPageState extends State<AddPinjolPage> {
  final _formKey = GlobalKey<FormState>();
  final _appNameController = TextEditingController();
  final _principalController = TextEditingController();
  final _installmentController = TextEditingController();

  String? _selectedApp;
  bool _isCustomApp = false;
  double _principal = 0;
  double _interestRate = 3.0; // default 3%
  double _monthlyInstallment = 0;
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _appNameController.dispose();
    _principalController.dispose();
    _installmentController.dispose();
    super.dispose();
  }

  void _selectApp(String app) {
    setState(() {
      _selectedApp = app;
      _isCustomApp = false;
      _appNameController.text = app;
    });
  }

  void _selectCustom() {
    setState(() {
      _selectedApp = null;
      _isCustomApp = true;
      _appNameController.clear();
    });
  }

  String _formatCurrency(int amount) {
    return Formatters.currency(amount).replaceAll('Rp ', '');
  }

  double get _totalInterest {
    if (_monthlyInstallment <= 0 || _principal <= 0) return 0;
    // Estimate months from principal and installment
    final months = (_principal / _monthlyInstallment).ceil();
    return (_monthlyInstallment * months) - _principal;
  }

  int get _estimatedMonths {
    if (_monthlyInstallment <= 0 || _principal <= 0) return 0;
    return (_principal / _monthlyInstallment).ceil();
  }

  String get _riskLevel {
    if (_interestRate <= 2) return 'safe';
    if (_interestRate <= 5) return 'warning';
    return 'danger';
  }

  String get _riskLabel {
    switch (_riskLevel) {
      case 'safe':
        return '🟢 Aman';
      case 'warning':
        return '🟡 Waspada';
      case 'danger':
        return '🔴 Berisiko';
      default:
        return '';
    }
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'Tanggal Mulai',
    );
    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: _startDate,
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      helpText: 'Tanggal Selesai (opsional)',
    );
    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final provider = context.read<PinjolProvider>();
    final success = await provider.createLoan(
      appName: _appNameController.text.trim(),
      principal: _principal,
      interestRate: _interestRate,
      monthlyInstallment: _monthlyInstallment,
      startDate: _startDate,
      endDate: _endDate,
    );

    setState(() => _isSubmitting = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pinjaman berhasil disimpan ✅'),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(provider.errorMessage ?? 'Gagal menyimpan pinjaman'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        title: const Text('Tambah Pinjaman'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── App name selector ──
            Text(
              'Nama Aplikasi',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.gray700,
                  ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ..._popularApps.map((app) {
                  final isSelected =
                      _selectedApp == app && !_isCustomApp;
                  return GestureDetector(
                    onTap: () => _selectApp(app),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.accentLight
                            : AppColors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.accent
                              : AppColors.gray300,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Text(
                        app,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected
                              ? AppColors.accent
                              : AppColors.gray700,
                        ),
                      ),
                    ),
                  );
                }),
                GestureDetector(
                  onTap: _selectCustom,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: _isCustomApp
                          ? AppColors.accentLight
                          : AppColors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _isCustomApp
                            ? AppColors.accent
                            : AppColors.gray300,
                        width: _isCustomApp ? 2 : 1,
                      ),
                    ),
                    child: Text(
                      'Lainnya',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: _isCustomApp
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: _isCustomApp
                            ? AppColors.accent
                            : AppColors.gray700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (_isCustomApp) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _appNameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  hintText: 'Nama aplikasi pinjaman',
                  prefixIcon: Icon(Icons.apps_rounded),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Masukkan nama aplikasi';
                  }
                  return null;
                },
              ),
            ],
            const SizedBox(height: 24),

            // ── Principal ──
            Text(
              'Jumlah Pinjaman (Pokok)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.gray700,
                  ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _principalController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
              decoration: const InputDecoration(
                hintText: '0',
                prefixText: 'Rp ',
                prefixIcon: Icon(Icons.account_balance_wallet_outlined),
              ),
              onChanged: (value) {
                final parsed = double.tryParse(
                    value.replaceAll(RegExp(r'[^\d]'), ''));
                setState(() => _principal = parsed ?? 0);
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Masukkan jumlah pinjaman';
                }
                final amount =
                    double.tryParse(value.replaceAll(RegExp(r'[^\d]'), ''));
                if (amount == null || amount <= 0) {
                  return 'Jumlah harus lebih dari 0';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // ── Interest rate ──
            Text(
              'Bunga Per Bulan',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.gray700,
                  ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.gray300),
              ),
              child: Column(
                children: [
                  Text(
                    '${_interestRate.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: _riskLevel == 'safe'
                          ? AppColors.success
                          : _riskLevel == 'warning'
                              ? AppColors.warning
                              : AppColors.danger,
                    ),
                  ),
                  Slider(
                    value: _interestRate,
                    min: 0.5,
                    max: 10,
                    divisions: 95,
                    activeColor: _riskLevel == 'safe'
                        ? AppColors.success
                        : _riskLevel == 'warning'
                            ? AppColors.warning
                            : AppColors.danger,
                    inactiveColor: AppColors.gray200,
                    onChanged: (value) =>
                        setState(() => _interestRate = value),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('0.5%',
                          style: TextStyle(
                              fontSize: 11, color: AppColors.gray500)),
                      Text('10%',
                          style: TextStyle(
                              fontSize: 11, color: AppColors.gray500)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Monthly installment ──
            Text(
              'Cicilan Per Bulan',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.gray700,
                  ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _installmentController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
              decoration: const InputDecoration(
                hintText: '0',
                prefixText: 'Rp ',
                prefixIcon: Icon(Icons.calendar_month_outlined),
              ),
              onChanged: (value) {
                final parsed = double.tryParse(
                    value.replaceAll(RegExp(r'[^\d]'), ''));
                setState(() => _monthlyInstallment = parsed ?? 0);
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Masukkan cicilan per bulan';
                }
                final amount =
                    double.tryParse(value.replaceAll(RegExp(r'[^\d]'), ''));
                if (amount == null || amount <= 0) {
                  return 'Cicilan harus lebih dari 0';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // ── Dates ──
            Row(
              children: [
                Expanded(
                  child: _DateField(
                    label: 'Tanggal Mulai',
                    date: _startDate,
                    onTap: _pickStartDate,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DateField(
                    label: 'Tanggal Selesai',
                    date: _endDate,
                    onTap: _pickEndDate,
                    isOptional: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Preview ──
            if (_principal > 0 && _monthlyInstallment > 0)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.accentLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    _PreviewRow(
                      label: 'Total Bunga',
                      value: Formatters.currency(_totalInterest.toInt()),
                      valueColor: AppColors.danger,
                    ),
                    const SizedBox(height: 8),
                    _PreviewRow(
                      label: 'Cicilan',
                      value: '$_estimatedMonths bulan',
                    ),
                    const SizedBox(height: 8),
                    _PreviewRow(
                      label: 'Risk Level',
                      value: _riskLabel,
                    ),
                  ],
                ),
              ),
            if (_principal > 0 && _monthlyInstallment > 0)
              const SizedBox(height: 24),

            // ── Submit button ──
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.white,
                      ),
                    )
                  : const Text('Simpan Pinjaman'),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

/// Date picker field.
class _DateField extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;
  final bool isOptional;

  const _DateField({
    required this.label,
    this.date,
    required this.onTap,
    this.isOptional = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
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
                      : isOptional
                          ? 'Opsional'
                          : 'Pilih tanggal',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: date != null
                        ? AppColors.gray900
                        : AppColors.gray400,
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

/// Preview row in the summary container.
class _PreviewRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _PreviewRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 13, color: AppColors.gray600),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: valueColor ?? AppColors.gray900,
          ),
        ),
      ],
    );
  }
}
