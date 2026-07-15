import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../config/theme.dart';
import '../../../config/constants.dart';
import '../../../core/utils/validators.dart';
import '../../../core/utils/formatters.dart';
import '../../common/widgets/custom_text_field.dart';
import '../../common/widgets/loading_button.dart';

class PhoneInputPage extends StatefulWidget {
  const PhoneInputPage({super.key});

  @override
  State<PhoneInputPage> createState() => _PhoneInputPageState();
}

class _PhoneInputPageState extends State<PhoneInputPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  String? _validatePhone(String? value) {
    return Validators.validatePhone(value);
  }

  void _formatPhoneInput(String value) {
    // Auto-format as user types: 0812-3456-7890
    final cleaned = value.replaceAll(RegExp(r'[\s\-]'), '');
    if (cleaned.length <= 4) {
      _phoneController.value = TextEditingValue(
        text: cleaned,
        selection: TextSelection.collapsed(offset: cleaned.length),
      );
    } else if (cleaned.length <= 8) {
      final formatted = '${cleaned.substring(0, 4)}-${cleaned.substring(4)}';
      _phoneController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    } else if (cleaned.length <= 13) {
      final formatted =
          '${cleaned.substring(0, 4)}-${cleaned.substring(4, 8)}-${cleaned.substring(8)}';
      _phoneController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    setState(() => _isLoading = false);

    final phone = Validators.normalizePhone(_phoneController.text);
    context.push('/otp', extra: phone);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 60),

                // Back button
                IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back_ios_new),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.gray100,
                    padding: const EdgeInsets.all(12),
                  ),
                )
                    .animate()
                    .fadeIn(duration: 300.ms)
                    .slideX(begin: -0.2, end: 0, duration: 300.ms),

                const SizedBox(height: 32),

                // Illustration
                Center(
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.primaryBg,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Center(
                      child: Text(
                        '📱',
                        style: TextStyle(fontSize: 48),
                      ),
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(duration: 400.ms, delay: 100.ms)
                    .scale(begin: const Offset(0.8, 0.8), duration: 400.ms, delay: 100.ms),

                const SizedBox(height: 32),

                // Title
                Text(
                  'Masuk ke KopDar',
                  style: Theme.of(context).textTheme.headlineMedium,
                )
                    .animate()
                    .fadeIn(duration: 400.ms, delay: 200.ms)
                    .slideY(begin: 0.2, end: 0, duration: 400.ms, delay: 200.ms),

                const SizedBox(height: 8),

                Text(
                  'Masukkan nomor HP kamu untuk mulai.\nKami akan kirim kode OTP untuk verifikasi.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.gray600,
                        height: 1.5,
                      ),
                )
                    .animate()
                    .fadeIn(duration: 400.ms, delay: 300.ms),

                const SizedBox(height: 32),

                // Phone input
                CustomTextField(
                  controller: _phoneController,
                  label: 'Nomor HP',
                  hint: '0812-3456-7890',
                  keyboardType: TextInputType.phone,
                  prefixIcon: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          '🇮🇩',
                          style: TextStyle(fontSize: 20),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '+62',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: AppColors.gray700,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 1,
                          height: 24,
                          color: AppColors.gray300,
                        ),
                        const SizedBox(width: 4),
                      ],
                    ),
                  ),
                  validator: _validatePhone,
                  onChanged: _formatPhoneInput,
                )
                    .animate()
                    .fadeIn(duration: 400.ms, delay: 400.ms)
                    .slideY(begin: 0.2, end: 0, duration: 400.ms, delay: 400.ms),

                const SizedBox(height: 32),

                // Submit button
                LoadingButton(
                  isLoading: _isLoading,
                  onPressed: _submit,
                  text: 'Kirim OTP',
                  icon: Icons.send_rounded,
                )
                    .animate()
                    .fadeIn(duration: 400.ms, delay: 500.ms)
                    .slideY(begin: 0.2, end: 0, duration: 400.ms, delay: 500.ms),

                const SizedBox(height: 24),

                // Terms
                Center(
                  child: Text(
                    'Dengan masuk, kamu setuju dengan\nSyarat & Ketentuan dan Kebijakan Privasi KopDar',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.gray500,
                          height: 1.5,
                        ),
                  ),
                )
                    .animate()
                    .fadeIn(duration: 400.ms, delay: 600.ms),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
