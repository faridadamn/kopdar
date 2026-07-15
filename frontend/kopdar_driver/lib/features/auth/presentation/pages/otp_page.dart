import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kopdar_driver/config/constants.dart';
import 'package:kopdar_driver/config/theme.dart';
import 'package:kopdar_driver/features/auth/presentation/providers/auth_provider.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:provider/provider.dart';

class OtpPage extends StatefulWidget {
  final String phoneNumber;

  const OtpPage({super.key, required this.phoneNumber});

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  final _otpController = TextEditingController();
  Timer? _timer;
  int _resendSeconds = AppConstants.otpResendSeconds;
  bool _isSubmitting = false;
  bool _isResending = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _resendSeconds = AppConstants.otpResendSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendSeconds <= 1) {
        timer.cancel();
        setState(() => _resendSeconds = 0);
      } else {
        setState(() => _resendSeconds--);
      }
    });
  }

  Future<void> _verifyOtp(String otp) async {
    if (_isSubmitting || otp.length != AppConstants.otpLength) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final auth = context.read<AuthProvider>();
    final success = await auth.verifyOtp(widget.phoneNumber, otp);
    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
      _errorMessage = success ? null : auth.errorMessage;
    });

    if (success) {
      context.go('/register/personal');
    } else {
      _otpController.clear();
    }
  }

  Future<void> _resendOtp() async {
    if (_resendSeconds > 0 || _isResending) return;

    setState(() {
      _isResending = true;
      _errorMessage = null;
    });

    final auth = context.read<AuthProvider>();
    final success = await auth.sendOtp(widget.phoneNumber);
    if (!mounted) return;

    setState(() {
      _isResending = false;
      _errorMessage = success ? null : auth.errorMessage;
    });

    if (success) {
      _startTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kode OTP baru sudah dikirim.'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  String get _formattedPhone {
    final digits = widget.phoneNumber.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 8) return widget.phoneNumber;
    return '${digits.substring(0, 4)}-${digits.substring(4, 8)}-${digits.substring(8)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        leading: IconButton(
          onPressed: _isSubmitting ? null : () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const CircleAvatar(
                radius: 38,
                backgroundColor: AppColors.primaryBg,
                child: Icon(Icons.lock_outline, size: 38, color: AppColors.primary),
              ),
              const SizedBox(height: 24),
              Text(
                'Masukkan kode OTP',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Kode dikirim ke $_formattedPhone',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.gray600,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              PinCodeTextField(
                appContext: context,
                length: AppConstants.otpLength,
                controller: _otpController,
                keyboardType: TextInputType.number,
                enabled: !_isSubmitting,
                animationType: AnimationType.fade,
                animationDuration: const Duration(milliseconds: 200),
                enableActiveFill: true,
                backgroundColor: Colors.transparent,
                pinTheme: PinTheme(
                  shape: PinCodeFieldShape.box,
                  borderRadius: BorderRadius.circular(12),
                  fieldHeight: 56,
                  fieldWidth: 48,
                  activeFillColor: AppColors.white,
                  inactiveFillColor: AppColors.gray50,
                  selectedFillColor: AppColors.primaryBg,
                  activeColor: AppColors.primary,
                  inactiveColor: AppColors.gray300,
                  selectedColor: AppColors.primary,
                  errorBorderColor: AppColors.danger,
                ),
                onCompleted: _verifyOtp,
                onChanged: (_) {
                  if (_errorMessage != null) {
                    setState(() => _errorMessage = null);
                  }
                },
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 8),
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
              const SizedBox(height: 20),
              if (_isSubmitting)
                const Center(child: CircularProgressIndicator())
              else
                ElevatedButton(
                  onPressed: () => _verifyOtp(_otpController.text),
                  child: const Text('Verifikasi'),
                ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _resendSeconds == 0 && !_isResending ? _resendOtp : null,
                child: Text(
                  _isResending
                      ? 'Mengirim ulang...'
                      : _resendSeconds > 0
                          ? 'Kirim ulang dalam ${_resendSeconds}s'
                          : 'Kirim ulang kode',
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _isSubmitting ? null : () => context.pop(),
                child: const Text('Ubah nomor telepon'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
