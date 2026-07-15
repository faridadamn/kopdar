import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../config/theme.dart';
import '../../../config/constants.dart';
import '../../common/widgets/loading_button.dart';

class PlatformSelectionPage extends StatefulWidget {
  const PlatformSelectionPage({super.key});

  @override
  State<PlatformSelectionPage> createState() => _PlatformSelectionPageState();
}

class _PlatformSelectionPageState extends State<PlatformSelectionPage> {
  final Set<String> _selectedPlatforms = {};
  final _otherController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _otherController.dispose();
    super.dispose();
  }

  void _togglePlatform(String platform) {
    setState(() {
      if (_selectedPlatforms.contains(platform)) {
        _selectedPlatforms.remove(platform);
      } else {
        _selectedPlatforms.add(platform);
      }
    });
  }

  Future<void> _submit() async {
    if (_selectedPlatforms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih minimal 1 platform')),
      );
      return;
    }

    setState(() => _isLoading = true);

    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;
    setState(() => _isLoading = false);

    context.push('/register/bank');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text('Platform Aktif'),
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
                        'Langkah 3 dari 5',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.gray600,
                            ),
                      ),
                      const Spacer(),
                      Text(
                        '60%',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: 0.6,
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    Text(
                      'Platform yang Kamu Pakai',
                      style: Theme.of(context).textTheme.titleLarge,
                    )
                        .animate()
                        .fadeIn(duration: 300.ms),

                    const SizedBox(height: 4),

                    Text(
                      'Pilih semua platform ojol yang aktif kamu gunakan untuk narik.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.gray600,
                          ),
                    ),

                    const SizedBox(height: 24),

                    // Platform cards
                    ...AppConstants.platforms.asMap().entries.map((entry) {
                      final platform = entry.key;
                      final name = entry.value;
                      final isSelected = _selectedPlatforms.contains(name);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _PlatformCard(
                          name: name,
                          icon: _platformIcon(name),
                          color: _platformColor(name),
                          isSelected: isSelected,
                          onTap: () => _togglePlatform(name),
                        )
                            .animate()
                            .fadeIn(
                              duration: 300.ms,
                              delay: Duration(milliseconds: 100 + (platform * 50)),
                            )
                            .slideX(
                              begin: 0.1,
                              end: 0,
                              duration: 300.ms,
                              delay: Duration(milliseconds: 100 + (platform * 50)),
                            ),
                      );
                    }),

                    const SizedBox(height: 16),

                    // Other platform
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.gray50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.gray200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.add_circle_outline,
                                color: AppColors.gray500,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Platform Lainnya',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _otherController,
                            decoration: InputDecoration(
                              hintText: 'Tulis nama platform (opsional)',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: AppColors.gray300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: AppColors.gray300),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              isDense: true,
                            ),
                          ),
                        ],
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 300.ms, delay: 400.ms),

                    const SizedBox(height: 24),

                    // Info
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.blueLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: AppColors.blue,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Data platform digunakan untuk tracking penghasilan multi-platform. Tidak ada yang di-share ke platform lain.',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.blue,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
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
                      text: 'Lanjut',
                      icon: Icons.arrow_forward_rounded,
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

  String _platformIcon(String name) {
    switch (name) {
      case 'Gojek':
        return '🟢';
      case 'Grab':
        return '🟩';
      case 'ShopeeFood':
        return '🟠';
      case 'Maxim':
        return '🟡';
      case 'InDrive':
        return '🔵';
      default:
        return '🚗';
    }
  }

  Color _platformColor(String name) {
    switch (name) {
      case 'Gojek':
        return const Color(0xFF00AA13);
      case 'Grab':
        return const Color(0xFF00B14F);
      case 'ShopeeFood':
        return const Color(0xFFEE4D2D);
      case 'Maxim':
        return const Color(0xFFFFD700);
      case 'InDrive':
        return const Color(0xFF1DA1F2);
      default:
        return AppColors.gray500;
    }
  }
}

class _PlatformCard extends StatelessWidget {
  final String name;
  final String icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _PlatformCard({
    required this.name,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.05) : AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : AppColors.gray300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(icon, style: const TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                name,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isSelected ? color : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isSelected ? color : AppColors.gray400,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      size: 16,
                      color: AppColors.white,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
