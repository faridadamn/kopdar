import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/theme.dart';
import '../providers/insurance_provider.dart';
import '../widgets/policy_card.dart';
import '../widgets/claim_card.dart';

/// My insurance page with tabs for policies and claims.
class MyInsurancePage extends StatefulWidget {
  const MyInsurancePage({super.key});

  @override
  State<MyInsurancePage> createState() => _MyInsurancePageState();
}

class _MyInsurancePageState extends State<MyInsurancePage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InsuranceProvider>().fetchMyInsurance();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        title: const Text('Polis & Klaim Saya'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.blue,
          unselectedLabelColor: AppColors.gray500,
          indicatorColor: AppColors.blue,
          indicatorWeight: 3,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
          tabs: const [
            Tab(text: 'Polis Aktif'),
            Tab(text: 'Klaim'),
          ],
        ),
      ),
      body: Consumer<InsuranceProvider>(
        builder: (context, provider, _) {
          return TabBarView(
            controller: _tabController,
            children: [
              // ── Polis Aktif tab ──
              _PoliciesTab(provider: provider),

              // ── Klaim tab ──
              _ClaimsTab(provider: provider),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/insurance/claim'),
        backgroundColor: AppColors.blue,
        foregroundColor: AppColors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Ajukan Klaim',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

/// Policies tab content.
class _PoliciesTab extends StatelessWidget {
  final InsuranceProvider provider;

  const _PoliciesTab({required this.provider});

  @override
  Widget build(BuildContext context) {
    if (provider.policiesStatus == InsuranceStatus.loading &&
        provider.policies.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.blue),
            const SizedBox(height: 16),
            Text(
              'Memuat polis...',
              style: TextStyle(color: AppColors.gray500),
            ),
          ],
        ),
      );
    }

    if (provider.policies.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('📋', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 20),
              Text(
                'Belum ada polis',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Yuk beli asuransi untuk perlindunganmu!',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.gray500,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => context.push('/insurance'),
                icon: const Icon(Icons.shield_rounded),
                label: const Text('Lihat Produk'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.blue,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: provider.fetchPolicies,
      color: AppColors.blue,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: provider.policies.length,
        itemBuilder: (context, index) {
          final policy = provider.policies[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: PolicyCard(
              policy: policy,
              onRenew: policy.isExpiringSoon
                  ? () => _renewPolicy(context, policy.id)
                  : null,
            ),
          );
        },
      ),
    );
  }

  Future<void> _renewPolicy(BuildContext context, String policyId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Perpanjang Polis'),
        content: const Text(
          'Polis akan diperpanjang untuk 1 bulan ke depan. Lanjutkan?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.blue,
            ),
            child: const Text('Perpanjang'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final success =
          await context.read<InsuranceProvider>().renewPolicy(policyId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Polis berhasil diperpanjang!'
                  : context.read<InsuranceProvider>().errorMessage ??
                      'Gagal memperpanjang polis',
            ),
            backgroundColor: success ? AppColors.success : AppColors.danger,
          ),
        );
      }
    }
  }
}

/// Claims tab content.
class _ClaimsTab extends StatelessWidget {
  final InsuranceProvider provider;

  const _ClaimsTab({required this.provider});

  @override
  Widget build(BuildContext context) {
    if (provider.claimsStatus == InsuranceStatus.loading &&
        provider.claims.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.blue),
            const SizedBox(height: 16),
            Text(
              'Memuat klaim...',
              style: TextStyle(color: AppColors.gray500),
            ),
          ],
        ),
      );
    }

    if (provider.claims.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('📝', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 20),
              Text(
                'Belum ada klaim',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Ajukan klaim jika terjadi risiko yang dicover.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.gray500,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => context.push('/insurance/claim'),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Ajukan Klaim'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.blue,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: provider.fetchClaims,
      color: AppColors.blue,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: provider.claims.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ClaimCard(claim: provider.claims[index]),
          );
        },
      ),
    );
  }
}
