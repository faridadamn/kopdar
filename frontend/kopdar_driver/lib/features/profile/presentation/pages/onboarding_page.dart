import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../config/theme.dart';
import '../providers/profile_provider.dart';

/// Onboarding carousel: 5 slides introducing KopDar features.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageCtrl = PageController();
  int _currentPage = 0;

  static const _slides = [
    _SlideData(
      emoji: '👋',
      title: 'Selamat Datang di KopDar!',
      description:
          'Koperasi Digital untuk para gig worker Indonesia. '
          'Kelola penghasilan, nabung, dan saling bantu sesama driver.',
      color: AppColors.primary,
    ),
    _SlideData(
      emoji: '📊',
      title: 'Lacak Penghasilanmu',
      description:
          'Catat pemasukan & pengeluaran harian. '
          'Lihat laporan keuangan otomatis dan tahu persis berapa yang kamu hasilkan.',
      color: AppColors.blue,
    ),
    _SlideData(
      emoji: '🐷',
      title: 'Menjadi Mudah',
      description:
          'Set target tabungan dan auto-potong dari penghasilan harian. '
          'Kecil-kecil lama-lama jadi bukit!',
      color: AppColors.success,
    ),
    _SlideData(
      emoji: '👥',
      title: 'Komunitas Solid',
      description:
          'Terhubung dengan sesama driver. Berbagi tips, info jalan, '
          'dan saling support. Bersama kita kuat!',
      color: AppColors.accent,
    ),
    _SlideData(
      emoji: '🚨',
      title: 'SOS Darurat',
      description:
          'Butuh bantuan darurat? Tekan tombol SOS dan driver terdekat '
          'akan segera merespons. Keselamatan adalah prioritas.',
      color: AppColors.danger,
    ),
  ];

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _slides.length - 1) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _completeOnboarding() {
    context.read<ProfileProvider>().completeOnboarding();
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── Skip button ──
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextButton(
                  onPressed: _completeOnboarding,
                  child: Text(
                    'Lewati',
                    style: TextStyle(
                      color: AppColors.gray500,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),

            // ── Page view ──
            Expanded(
              child: PageView.builder(
                controller: _pageCtrl,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (_, i) => _SlideContent(slide: _slides[i]),
              ),
            ),

            // ── Dots ──
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _slides.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: i == _currentPage ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: i == _currentPage
                        ? AppColors.primary
                        : AppColors.gray300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // ── Action button ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: ElevatedButton(
                onPressed: _nextPage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _slides[_currentPage].color,
                  minimumSize: const Size(double.infinity, 54),
                ),
                child: Text(
                  _currentPage == _slides.length - 1 ? 'Mulai' : 'Selanjutnya',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _SlideData {
  final String emoji;
  final String title;
  final String description;
  final Color color;

  const _SlideData({
    required this.emoji,
    required this.title,
    required this.description,
    required this.color,
  });
}

class _SlideContent extends StatelessWidget {
  final _SlideData slide;

  const _SlideContent({required this.slide});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Big emoji
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: slide.color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                slide.emoji,
                style: const TextStyle(fontSize: 56),
              ),
            ),
          ),
          const SizedBox(height: 36),

          // Title
          Text(
            slide.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.gray900,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Description
          Text(
            slide.description,
            style: TextStyle(
              fontSize: 15,
              color: AppColors.gray600,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
