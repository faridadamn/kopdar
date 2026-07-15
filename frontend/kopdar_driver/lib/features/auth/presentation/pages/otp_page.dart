import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../config/theme.dart';
import '../../../config/constants.dart';
import '../../../core/utils/formatters.dart';
import '../../common/widgets/loading_button.dart';

class OtpPage extends StatefulWidget {
  final String phoneNumber;

  const OtpPage({super.key, required this.phoneNumber});

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  final _otpController = TextEditingController();
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';
  int _resendSeconds = AppConstants.otpResendSeconds;
  bool _canResend = false;
  int _attempts = 0;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    setState(() {
      _resendSeconds = AppConstants.otpResendSeconds;
      _canResend = false;
    });

    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;

      setState(() {
        _resendSeconds--;
      });

      if (_resendSeconds <= 0) {
        setState(() {
          _canResend = true;
        });
        return false;
      }
      return true;
    });
  }

  Future<void> _verifyOtp(String otp) async {
    if (otp.length != AppConstants.otpLength) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    setState(() => _isLoading = false);

    // Simulate success (in real app, check API response)
    _attempts++;

    if (_attempts <= AppConstants.maxOtpAttempts) {
      // Success - navigate to personal data
      context.go('/register/personal');
    } else {
      setState(() {
        _hasError = true;
        _errorMessage = 'Terlalu banyak percobaan. Coba lagi dalam ${AppConstants.lockoutMinutes} menit.';
      });
    }
  }

  Future<void> _resendOtp() async {
    if (!_canResend) return;

    setState(() {
      _canResend = false;
      _resendSeconds = AppConstants.otpResendSeconds;
    });

    // Simulate resend
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    _startResendTimer();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Kode OTP baru sudah dikirim!'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  String get _formattedPhone {
    return Formatters.phone(widget.phoneNumber);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),

              // Lock icon
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Center(
                    child: Text(
                      '🔒',
                      style: TextStyle(fontSize: 40),
                    ),
                  ),
                ),
              )
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .scale(begin: const Offset(0.8, 0.8), duration: 400.ms),

              const SizedBox(height: 24),

              // Title
              Center(
                child: Text(
                  'Kode OTP',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              )
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 100.ms),

              const SizedBox(height: 8),

              Center(
                child: Text(
                  'Kami mengirim kode ke $_formattedPhone',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.gray600,
                      ),
                ),
              )
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 200.ms),

              const SizedBox(height: 8),

              Center(
                child: GestureDetector(
                  onTap: () => context.pop(),
                  child: Text(
                    'Ubah nomor',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // OTP input
              PinCodeTextField(
                appContext: context,
                length: AppConstants.otpLength,
                controller: _otpController,
                keyboardType: TextInputType.number,
                animationType: AnimationType.fade,
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
                animationDuration: const Duration(milliseconds: 300),
                backgroundColor: Colors.transparent,
                enableActiveFill: true,
                errorAnimationController: null,
                onCompleted: _verifyOtp,
                onChanged: (value) {
                  if (_hasError) {
                    setState(() {
                      _hasError = false;
                      _errorMessage = '';
                    });
                  }
                },
              )
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 300.ms)
                  .slideY(begin: 0.2, end: 0, duration: 400.ms, delay: 300.ms),

              // Error message
              if (_hasError) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.dangerLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: AppColors.danger,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.danger,
                              ),
                        ),
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(duration: 300.ms)
                    .shake(duration: 300.ms),
              ],

              const SizedBox(height: 24),

              // Loading indicator
              if (_isLoading) ...[
                const Center(
                  child: Column(
                    children: [
                      SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: AppColors.primary,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text('Memverifikasi...'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Resend button
              Center(
                child: _canResend
                    ? TextButton(
                        onPressed: _resendOtp,
                        child: Text(
                          'Kirim Ulang Kode',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      )
                    : Text(
                        'Kirim ulang dalam ${_resendSeconds}s',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppColors.gray500,
                            ),
                      ),
              )
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 400.ms),

              const SizedBox(height: 16),

              // Info text
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.blueLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: AppColors.blue,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Kode OTP berlaku selama ${AppConstants.otpExpiryMinutes} menit. Periksa SMS masuk kamu.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.blue,
                            ),
                      ),
                    ),
                  ],
                ),
              )
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 500.ms),
            ],
          ),
        ),
      ),
    );
  }
}
