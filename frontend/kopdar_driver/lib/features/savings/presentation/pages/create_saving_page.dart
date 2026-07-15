import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/theme.dart';
import '../../../core/utils/formatters.dart';
import '../providers/saving_provider.dart';

/// Predefined savings goal templates.
class _GoalTemplate {
  final String emoji;
  final String name;
  final double? targetAmount;

  const _GoalTemplate({
    required this.emoji,
    required this.name,
    this.targetAmount,
  });
}

const _templates = [
  _GoalTemplate(emoji: '🏥', name: 'Dana Darurat', targetAmount: null),
  _GoalTemplate(emoji: '🏍️', name: 'Servis Motor', targetAmount: 1500000),
  _GoalTemplate(emoji: '🎓', name: 'Dana Anak', targetAmount: null),
  _GoalTemplate(emoji: '📦', name: 'Custom', targetAmount: null),
];

const _dailyChips = [5000, 10000, 15000, 20000, 50000];

/// Page to create a new savings goal.
class CreateSavingPage extends StatefulWidget {
  const CreateSavingPage({super.key});

  @override
  State<CreateSavingPage> createState() => _CreateSavingPageState();
}

class _CreateSavingPageState extends State<CreateSavingPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _targetController = TextEditingController();
  final _dailyController = TextEditingController();

  _GoalTemplate? _selectedTemplate;
  String _selectedIcon = '🎯';
  double _targetAmount = 0;
  double _dailyAmount = 0;
  bool _autoSave = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _targetController.dispose();
    _dailyController.dispose();
    super.dispose();
  }

  void _selectTemplate(_GoalTemplate template) {
    setState(() {
      _selectedTemplate = template;
      _selectedIcon = template.emoji;
      _nameController.text = template.name;

      if (template.targetAmount != null) {
        _targetAmount = template.targetAmount!;
        _targetController.text = _formatCurrency(_targetAmount.toInt());
      } else {
        _targetController.clear();
        _targetAmount = 0;
      }
    });
  }

  void _selectDailyAmount(double amount) {
    setState(() {
      _dailyAmount = amount;
      _dailyController.text = _formatCurrency(amount.toInt());
    });
  }

  String _formatCurrency(int amount) {
    return Formatters.currency(amount).replaceAll('Rp ', '');
  }

  int get _estimatedDays {
    if (_dailyAmount <= 0 || _targetAmount <= 0) return 0;
    return (_targetAmount / _dailyAmount).ceil();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final provider = context.read<SavingProvider>();
    final success = await provider.createGoal(
      goalName: _nameController.text.trim(),
      goalIcon: _selectedIcon,
      targetAmount: _targetAmount,
      dailyAmount: _dailyAmount,
      autoSave: _autoSave,
    );

    setState(() => _isSubmitting = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tabungan berhasil dibuat ✅'),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(provider.errorMessage ?? 'Gagal membuat tabungan'),
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
        title: const Text('Buat Tabungan Baru'),
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
            // ── Template buttons ──
            Text(
              'Pilih Tujuan',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.gray700,
                  ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _templates.map((t) {
                final isSelected = _selectedTemplate == t;
                return GestureDetector(
                  onTap: () => _selectTemplate(t),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primaryBg : AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.gray300,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Text(
                      '${t.emoji} ${t.name}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.gray700,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // ── Goal name ──
            Text(
              'Nama Tabungan',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.gray700,
                  ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                hintText: 'Contoh: Dana Darurat',
                prefixIcon: Icon(Icons.edit_outlined),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Masukkan nama tabungan';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // ── Target amount ──
            Text(
              'Target Nominal',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.gray700,
                  ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _targetController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
              decoration: const InputDecoration(
                hintText: '0',
                prefixText: 'Rp ',
                prefixIcon: Icon(Icons.flag_outlined),
              ),
              onChanged: (value) {
                final parsed = double.tryParse(
                    value.replaceAll(RegExp(r'[^\d]'), ''));
                setState(() {
                  _targetAmount = parsed ?? 0;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Masukkan target nominal';
                }
                final amount =
                    double.tryParse(value.replaceAll(RegExp(r'[^\d]'), ''));
                if (amount == null || amount <= 0) {
                  return 'Nominal harus lebih dari 0';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // ── Daily amount chips ──
            Text(
              'Setor Per Hari',
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
                ..._dailyChips.map((amount) {
                  final isSelected = _dailyAmount == amount;
                  return GestureDetector(
                    onTap: () => _selectDailyAmount(amount.toDouble()),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isSelected ? AppColors.primaryBg : AppColors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.gray300,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Text(
                        Formatters.currency(amount),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.gray700,
                        ),
                      ),
                    ),
                  );
                }),
                // Custom chip
                GestureDetector(
                  onTap: () {
                    _dailyController.clear();
                    _showCustomDailyDialog();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.gray300),
                    ),
                    child: Text(
                      'Custom',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.gray600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Auto-save toggle ──
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primaryBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: const Text('🔄', style: TextStyle(fontSize: 20)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Auto-Save',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.gray900,
                          ),
                        ),
                        Text(
                          'Setor otomatis setiap hari',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.gray500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _autoSave,
                    onChanged: (value) => setState(() => _autoSave = value),
                    activeColor: AppColors.primary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Preview ──
            if (_dailyAmount > 0 && _targetAmount > 0)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Text('💡', style: TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${Formatters.currency(_dailyAmount.toInt())}/hari → '
                        'target tercapai dalam $_estimatedDays hari',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (_dailyAmount > 0 && _targetAmount > 0)
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
                  : const Text('Buat Tabungan'),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _showCustomDailyDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Setor Per Hari'),
        content: TextField(
          controller: _dailyController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Masukkan nominal',
            prefixText: 'Rp ',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(
                  _dailyController.text.replaceAll(RegExp(r'[^\d]'), ''));
              if (amount != null && amount > 0) {
                setState(() => _dailyAmount = amount);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Pilih'),
          ),
        ],
      ),
    );
  }
}
