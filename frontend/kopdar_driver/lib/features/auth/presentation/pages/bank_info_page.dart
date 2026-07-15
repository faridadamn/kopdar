import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../config/theme.dart';
import '../../../config/constants.dart';
import '../../../core/utils/validators.dart';
import '../../common/widgets/custom_text_field.dart';
import '../../common/widgets/loading_button.dart';

class BankInfoPage extends StatefulWidget {
  const BankInfoPage({super.key});

  @override
  State<BankInfoPage> createState() => _BankInfoPageState();
}

class _BankInfoPageState extends State<BankInfoPage> {
  final _formKey = GlobalKey<FormState>();
  final _accountNumberController = TextEditingController();
  final _accountNameController = TextEditingController();

  String? _selectedBank;
  bool _isLoading = false;

  @override
  void dispose() {
    _accountNumberController.dispose();
    _accountNameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBank == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih bank/e-wallet')),
      );
      return;
    }

    setState(() => _isLoading = true);

    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;
    setState(() => _isLoading = false);

    // Navigate to waiting verification
    context.go('/waiting-verification');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text('Rekening Bank'),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new),
          style: IconButton.styleFrom(
            backgroundColor: AppColors.gray100,
            padding: const EdgeInsets.all(12),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Langkah 4 dari 5',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.gray600,
                            ),
                      ),
                      const Spacer(),
                      Text(
                        '80%',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: 0.8,
                    backgroundColor: AppColors.gray200,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    borderRadius: BorderRadius.circular(4),
                    minHeight: 6,
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),

                      Text(
                        'Info Rekening',
                        style: Theme.of(context).textTheme.titleLarge,
                      )
                          .animate()
                          .fadeIn(duration: 300.ms),

                      const SizedBox(height: 4),

                      Text(
                        'Untuk pencairan penghasilan dari KopDar.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.gray600,
                            ),
                      ),

                      const SizedBox(height: 24),

                      // Bank dropdown
                      Text(
                        'Bank / E-Wallet',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedBank,
                        decoration: InputDecoration(
                          hintText: 'Pilih Bank atau E-Wallet',
                          prefixIcon: const Icon(Icons.account_balance, size: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.gray300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.gray300),
                          ),
                        ),
                        items: AppConstants.banks.map((bank) {
                          return DropdownMenuItem(
                            value: bank['code'],
                            child: Text(bank['name']!),
                          );
                        }).toList(),
                        onChanged: (value) => setState(() => _selectedBank = value),
                        validator: (value) => value == null ? 'Pilih bank' : null,
                      )
                          .animate()
                          .fadeIn(duration: 300.ms, delay: 100.ms),

                      const SizedBox(height: 16),

                      // Account number
                      CustomTextField(
                        controller: _accountNumberController,
                        label: 'Nomor Rekening',
                        hint: 'Masukkan nomor rekening',
                        keyboardType: TextInputType.number,
                        validator: Validators.validateBankAccount,
                        prefixIcon: const Icon(Icons.numbers, size: 20),
                      )
                          .animate()
                          .fadeIn(duration: 300.ms, delay: 200.ms),

                      const SizedBox(height: 16),

                      // Account name
                      CustomTextField(
                        controller: _accountNameController,
                        label: 'Atas Nama',
                        hint: 'Nama pemilik rekening',
                        textCapitalization: TextCapitalization.words,
                        validator: (v) => Validators.validateRequired(v, 'Atas Nama'),
                        prefixIcon: const Icon(Icons.person_outline, size: 20),
                      )
                          .animate()
                          .fadeIn(duration: 300.ms, delay: 300.ms),

                      const SizedBox(height: 24),

                      // Info box
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.shield_outlined,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Data rekening aman & terenkripsi',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primary,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Rekening digunakan untuk pencairan penghasilan. Pastikan data yang kamu masukkan benar.',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.gray600,
                                    height: 1.5,
                                  ),
                            ),
                          ],
                        ),
                      )
                          .animate()
                          .fadeIn(duration: 300.ms, delay: 400.ms),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom button
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.white,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => context.pop(),
                      child: const Text('Kembali'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: LoadingButton(
                      isLoading: _isLoading,
                      onPressed: _submit,
                      text: 'Kirim Pendaftaran',
                      icon: Icons.check_circle_outline,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
