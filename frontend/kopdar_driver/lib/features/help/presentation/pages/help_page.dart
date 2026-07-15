import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../config/theme.dart';

/// Help center / Bantuan page with FAQ, contact, and feedback.
class HelpPage extends StatefulWidget {
  const HelpPage({super.key});

  @override
  State<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage> {
  final _feedbackCtrl = TextEditingController();
  bool _isSendingFeedback = false;

  static const _faqs = [
    _Faq(
      question: 'Bagaimana cara menambah poin?',
      answer:
          'Kamu bisa mendapatkan poin dengan:\n'
          '• Menyelesaikan order (+10 poin)\n'
          '• Login harian (+5 poin)\n'
          '• Mengundang teman via referral (+50 poin)\n'
          '• Menabung secara rutin (+5 poin/hari)\n'
          '• Berpartisipasi di komunitas (+2 poin/posting)',
    ),
    _Faq(
      question: 'Bagaimana cara naik level?',
      answer:
          'Level ditentukan oleh total poin:\n'
          '• Perunggu: 0 poin\n'
          '• Perak: 500 poin\n'
          '• Emas: 2.000 poin\n'
          '• Platinum: 10.000 poin\n\n'
          'Semakin tinggi level, semakin banyak keuntungan yang kamu dapat!',
    ),
    _Faq(
      question: 'Bagaimana cara menggunakan fitur SOS?',
      answer:
          'Tekan tombol SOS di halaman Beranda atau tab Darurat. '
          'Pilih jenis darurat, tulis deskripsi (opsional), lalu kirim. '
          'Driver terdekat akan melihat sinyalarmu dan bisa membantu.',
    ),
    _Faq(
      question: 'Apakah data saya aman?',
      answer:
          'Ya! KopDar menggunakan enkripsi end-to-end untuk melindungi data kamu. '
          'Kami tidak akan membagikan data pribadi ke pihak ketiga tanpa izinmu.',
    ),
    _Faq(
      question: 'Bagaimana cara menghapus akun?',
      answer:
          'Buka Profil → Pengaturan → Hapus Akun. '
          'Perlu diingat, penghapusan akun bersifat permanen dan tidak dapat dibatalkan.',
    ),
    _Faq(
      question: 'Bagaimana cara klaim asuransi?',
      answer:
          'Buka menu Asuransi → polis aktif kamu → Ajukan Klaim. '
          'Isi formulir klaim, lampirkan foto bukti, dan tunggu verifikasi dari tim kami.',
    ),
  ];

  @override
  void dispose() {
    _feedbackCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        title: const Text('❓ Bantuan'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Header ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.blue, Color(0xFF42A5F5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Text('🆘', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 12),
                const Text(
                  'Ada yang bisa kami bantu?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Cari jawaban atau hubungi kami langsung.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Quick contact ──
          Row(
            children: [
              Expanded(
                child: _ContactCard(
                  icon: '💬',
                  label: 'WhatsApp',
                  subtitle: 'Chat langsung',
                  color: const Color(0xFF25D366),
                  onTap: () => _launchUrl('https://wa.me/6281234567890'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ContactCard(
                  icon: '📞',
                  label: 'Telepon',
                  subtitle: '0800-1234-5678',
                  color: AppColors.primary,
                  onTap: () => _launchUrl('tel:080012345678'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ContactCard(
                  icon: '✉️',
                  label: 'Email',
                  subtitle: 'support@kopdar.id',
                  color: AppColors.info,
                  onTap: () => _launchUrl('mailto:support@kopdar.id'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── FAQ ──
          Text(
            'Pertanyaan Umum (FAQ)',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: _faqs
                  .map((faq) => _FaqTile(faq: faq))
                  .toList(),
            ),
          ),
          const SizedBox(height: 24),

          // ── Feedback ──
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kirim Masukan',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Bantu kami menjadi lebih baik!',
                  style: TextStyle(fontSize: 13, color: AppColors.gray500),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _feedbackCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Tulis masukan, saran, atau laporan bug...',
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _isSendingFeedback ? null : _sendFeedback,
                  icon: _isSendingFeedback
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_rounded, size: 18),
                  label: Text(_isSendingFeedback
                      ? 'Mengirim...'
                      : 'Kirim Masukan'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.blue,
                    minimumSize: const Size(double.infinity, 44),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── App info ──
          Center(
            child: Column(
              children: [
                Text(
                  'KopDar v1.0.0',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.gray400,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Koperasi Digital untuk Gig Worker Indonesia',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.gray400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Future<void> _sendFeedback() async {
    if (_feedbackCtrl.text.trim().isEmpty) return;

    setState(() => _isSendingFeedback = true);
    await Future.delayed(const Duration(seconds: 1)); // simulate API
    setState(() => _isSendingFeedback = false);

    _feedbackCtrl.clear();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Terima kasih! Masukan kamu sangat berharga. 🙏'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tidak bisa membuka: $url')),
      );
    }
  }
}

class _ContactCard extends StatelessWidget {
  final String icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ContactCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: color,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: AppColors.gray500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _FaqTile extends StatefulWidget {
  final _Faq faq;

  const _FaqTile({required this.faq});

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.faq.question,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color:
                          _expanded ? AppColors.primary : AppColors.gray800,
                    ),
                  ),
                ),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.expand_more_rounded,
                    color: _expanded ? AppColors.primary : AppColors.gray400,
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Text(
              widget.faq.answer,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.gray600,
                height: 1.6,
              ),
            ),
          ),
          crossFadeState:
              _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
        if (!_expanded)
          Divider(height: 1, indent: 16, color: AppColors.gray200),
      ],
    );
  }
}

class _Faq {
  final String question;
  final String answer;

  const _Faq({required this.question, required this.answer});
}
