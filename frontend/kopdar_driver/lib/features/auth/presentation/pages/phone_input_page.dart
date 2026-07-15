import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kopdar_driver/config/theme.dart';
import 'package:kopdar_driver/features/auth/presentation/providers/auth_provider.dart';
import 'package:provider/provider.dart';

class PhoneInputPage extends StatefulWidget {
  const PhoneInputPage({super.key});

  @override
  State<PhoneInputPage> createState() => _PhoneInputPageState();
}

class _PhoneInputPageState extends State<PhoneInputPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  String _normalizePhone(String value) {
    var digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('0')) {
      digits = '62${digits.substring(1)}';
    } else if (!digits.startsWith('62')) {
      digits = '62$digits';
    }
    return '+$digits';
  }

  String? _validatePhone(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return 'Nomor HP wajib diisi';
    if (!digits.startsWith('08') && !digits.startsWith('62')) {
      return 'Gunakan nomor Indonesia yang valid';
    }
    if (digits.length < 10 || digits.length > 15) {
      return 'Panjang nomor HP tidak valid';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final phone = _normalizePhone(_phoneController.text);
    final auth = context.read<AuthProvider>();
    final success = await auth.sendOtp(phone);
    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _errorMessage = success ? null : auth.errorMessage;
    });

    if (success) {
      context.push('/otp', extra: phone);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        leading: IconButton(
          onPressed: _isLoading ? null : () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const CircleAvatar(
                  radius: 42,
                  backgroundColor: AppColors.primaryBg,
                  child: Icon(Icons.phone_android, size: 42, color: AppColors.primary),
                ),
                const SizedBox(height: 28),
                Text(
                  'Masuk ke KopDar',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Masukkan nomor HP. Kami akan mengirim kode OTP untuk verifikasi.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.gray600,
                        height: 1.5,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  enabled: !_isLoading,
                  validator: _validatePhone,
                  onFieldSubmitted: (_) => _submit(),
                  decoration: const InputDecoration(
                    labelText: 'Nomor HP',
                    hintText: '0812 3456 7890',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.dangerLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: AppColors.danger),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
                const SizedBox(height: 28),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _submit,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded),
                  label: Text(_isLoading ? 'Mengirim...' : 'Kirim OTP'),
                ),
                const SizedBox(height: 20),
                Text(
                  'Dengan masuk, kamu menyetujui Syarat & Ketentuan serta Kebijakan Privasi KopDar.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.gray500,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
