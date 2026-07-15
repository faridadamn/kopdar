import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/theme.dart';
import '../../../core/utils/formatters.dart';
import '../providers/insurance_provider.dart';
import '../widgets/product_card.dart';

/// Insurance product catalog page.
class InsuranceCatalogPage extends StatefulWidget {
  const InsuranceCatalogPage({super.key});

  @override
  State<InsuranceCatalogPage> createState() => _InsuranceCatalogPageState();
}

class _InsuranceCatalogPageState extends State<InsuranceCatalogPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InsuranceProvider>().fetchProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        title: const Text('🛡️ Asuransi'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.description_outlined),
            tooltip: 'Polis Saya',
            onPressed: () => context.push('/insurance/my'),
          ),
        ],
      ),
      body: Consumer<InsuranceProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.products.isEmpty) {
            return const _LoadingState();
          }

          if (provider.status == InsuranceStatus.error &&
              provider.products.isEmpty) {
            return _ErrorState(
              message: provider.errorMessage ?? 'Terjadi kesalahan',
              onRetry: provider.fetchProducts,
            );
          }

          return RefreshIndicator(
            onRefresh: provider.fetchProducts,
            color: AppColors.blue,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── Info banner ──
                _InfoBanner(),
                const SizedBox(height: 20),

                // ── Section title ──
                Text(
                  'Produk Asuransi',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  'Pilih perlindungan yang tepat untukmu',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.gray500,
                      ),
                ),
                const SizedBox(height: 16),

                // ── Product list ──
                ...provider.products.map(
                  (product) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ProductCard(
                      product: product,
                      onTap: () =>
                          context.push('/insurance/${product.id}'),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ── My Insurance button ──
                if (provider.policies.isNotEmpty ||
                    provider.claims.isNotEmpty)
                  OutlinedButton.icon(
                    onPressed: () => context.push('/insurance/my'),
                    icon: const Icon(Icons.folder_open_rounded),
                    label: const Text('Lihat Polis & Klaim Saya'),
                  ),
                const SizedBox(height: 80),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Blue gradient info banner with member pricing highlight.
class _InfoBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.blue, Color(0xFF42A5F5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.blue.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Harga Khusus Anggota KopDar',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Lebih murah 30%! Nikmati perlindungan terjangkau untukmu dan keluarga.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.85),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '💰 Hemat hingga Rp 50.000/bulan',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const Text('🛡️', style: TextStyle(fontSize: 48)),
        ],
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppColors.blue),
          const SizedBox(height: 16),
          Text(
            'Memuat produk asuransi...',
            style: TextStyle(color: AppColors.gray500),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('😵', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
