import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/theme.dart';
import '../../../../core/utils/formatters.dart';
import '../providers/transaction_provider.dart';
import '../widgets/income_form_field.dart';
import '../widgets/platform_chip.dart';

/// Screen to record income from a ride-hailing platform.
class AddIncomePage extends StatefulWidget {
  const AddIncomePage({super.key});

  @override
  State<AddIncomePage> createState() => _AddIncomePageState();
}

class _AddIncomePageState extends State<AddIncomePage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _commissionController = TextEditingController();
  final _orderCountController = TextEditingController(text: '1');
  final _notesController = TextEditingController();

  String? _selectedPlatform;
  double _grossAmount = 0;
  double _commission = 0;
  int _orderCount = 1;
  String? _receiptPath;
  bool _isSubmitting = false;

  double get _netAmount => _grossAmount - _commission;

  @override
  void dispose() {
    _amountController.dispose();
    _commissionController.dispose();
    _orderCountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onAmountChanged(double value) {
    setState(() {
      _grossAmount = value;
      // Auto-calculate commission (20% default for ride-hailing)
      _commission = value * 0.20;
      _commissionController.text =
          _commission > 0 ? _formatCurrency(_commission.toInt()) : '';
    });
  }

  void _onCommissionChanged(double value) {
    setState(() {
      _commission = value;
    });
  }

  String _formatCurrency(int amount) {
    return Formatters.currency(amount).replaceAll('Rp ', '');
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() => _receiptPath = picked.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengambil gambar: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.gray300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Foto Struk',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded,
                    color: AppColors.primary),
                title: const Text('Kamera'),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded,
                    color: AppColors.primary),
                title: const Text('Galeri'),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPlatform == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih platform terlebih dahulu'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final provider = context.read<TransactionProvider>();
    final success = await provider.createTransaction(
      type: 'income',
      category: 'order',
      platform: _selectedPlatform,
      amount: _grossAmount,
      commission: _commission,
      notes:
          _notesController.text.isNotEmpty ? _notesController.text : null,
      receiptUrl: _receiptPath,
      orderCount: _orderCount,
    );

    setState(() => _isSubmitting = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Penghasilan berhasil disimpan ✅'),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(provider.errorMessage ?? 'Gagal menyimpan penghasilan'),
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
        title: const Text('Tambah Penghasilan'),
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
            // ── Platform selector ──
            Text(
              'Platform',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.gray700,
                  ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: platformOptions.map((opt) {
                return PlatformChip(
                  name: opt.name,
                  emoji: opt.emoji,
                  isSelected: _selectedPlatform == opt.name,
                  onTap: () =>
                      setState(() => _selectedPlatform = opt.name),
                );
              }).toList(),
            ),
            if (_selectedPlatform == null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Pilih platform untuk melanjutkan',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.gray500,
                  ),
                ),
              ),
            const SizedBox(height: 24),

            // ── Order count ──
            Text(
              'Jumlah Order',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.gray700,
                  ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _orderCountController,
              keyboardType: TextInputType.number,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
              decoration: const InputDecoration(
                hintText: '1',
                prefixIcon: Icon(Icons.shopping_bag_outlined),
              ),
              onChanged: (value) {
                setState(() {
                  _orderCount = int.tryParse(value) ?? 1;
                });
              },
            ),
            const SizedBox(height: 24),

            // ── Gross income ──
            IncomeFormField(
              label: 'Total Penghasilan Kotor',
              hint: '0',
              controller: _amountController,
              onChanged: _onAmountChanged,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Masukkan jumlah penghasilan';
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

            // ── Commission ──
            IncomeFormField(
              label: 'Komisi Platform',
              hint: '0',
              controller: _commissionController,
              onChanged: _onCommissionChanged,
            ),
            const SizedBox(height: 24),

            // ── Notes ──
            Text(
              'Catatan (opsional)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.gray700,
                  ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Tambahkan catatan...',
              ),
            ),
            const SizedBox(height: 24),

            // ── Receipt photo ──
            Text(
              'Screenshot Struk (opsional)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.gray700,
                  ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _showImageSourceSheet,
              child: Container(
                width: double.infinity,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _receiptPath != null
                        ? AppColors.primary
                        : AppColors.gray300,
                    width: _receiptPath != null ? 2 : 1,
                  ),
                ),
                child: _receiptPath != null
                    ? Stack(
                        children: [
                          Center(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.asset(
                                _receiptPath!,
                                height: 120,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Center(
                                  child: Icon(Icons.check_circle_rounded,
                                      color: AppColors.success, size: 40),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => _receiptPath = null),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: AppColors.danger,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close,
                                    size: 16, color: AppColors.white),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt_outlined,
                              size: 36, color: AppColors.gray400),
                          const SizedBox(height: 8),
                          Text(
                            'Ketuk untuk foto struk',
                            style: TextStyle(
                              color: AppColors.gray500,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 32),

            // ── Summary preview ──
            if (_grossAmount > 0)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _summaryRow(
                      'Penghasilan Kotor',
                      Formatters.currency(_grossAmount.toInt()),
                    ),
                    const SizedBox(height: 8),
                    _summaryRow(
                      'Komisi',
                      '- ${Formatters.currency(_commission.toInt())}',
                      color: AppColors.danger,
                    ),
                    const Divider(height: 24),
                    _summaryRow(
                      'Penghasilan Bersih',
                      Formatters.currency(_netAmount.toInt()),
                      isBold: true,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),

            // ── Submit button ──
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.white,
                      ),
                    )
                  : const Text('Simpan Penghasilan'),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(
    String label,
    String value, {
    Color? color,
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: color ?? AppColors.gray700,
          ),
        ),
        Text(
          'Rp $value',
          style: TextStyle(
            fontSize: isBold ? 18 : 14,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: color ?? AppColors.gray800,
          ),
        ),
      ],
    );
  }
}
