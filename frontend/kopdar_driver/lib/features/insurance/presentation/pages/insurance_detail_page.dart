import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/theme.dart';
import '../../../core/utils/formatters.dart';
import '../../data/models/insurance_model.dart';
import '../providers/insurance_provider.dart';
import '../widgets/coverage_list.dart';

/// Insurance product detail page with purchase flow.
class InsuranceDetailPage extends StatefulWidget {
  final String id;

  const InsuranceDetailPage({super.key, required this.id});

  @override
  State<InsuranceDetailPage> createState() => _InsuranceDetailPageState();
}

class _InsuranceDetailPageState extends State<InsuranceDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InsuranceProvider>().fetchProductDetail(widget.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        title: const Text('Detail Produk'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Consumer<InsuranceProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.blue),
            );
          }

          if (provider.status == InsuranceStatus.error ||
              provider.selectedProduct == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('😵', style: TextStyle(fontSize: 48)),
                    const SizedBox(height: 16),
                    Text(
                      provider.errorMessage ?? 'Produk tidak ditemukan',
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Kembali'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.blue,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final product = provider.selectedProduct!;

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Header: icon + name ──
                      _ProductHeader(product: product),
                      const SizedBox(height: 20),

                      // ── Full description ──
                      Text(
                        product.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.gray700,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Coverage list ──
                      CoverageList(
                        items: product.coverageItems,
                        title: 'Cakupan Perlindungan',
                      ),
                      const SizedBox(height: 20),

                      // ── Exclusions ──
                      CoverageList(
                        items: product.exclusionItems,
                        title: 'Pengecualian',
                        isExclusion: true,
                      ),
                      const SizedBox(height: 20),

                      // ── Price comparison ──
                      _PriceComparison(product: product),
                      const SizedBox(height: 20),

                      // ── Partner info ──
                      if (product.partnerName.isNotEmpty)
                        _PartnerInfo(partnerName: product.partnerName),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),

              // ── Bottom action button ──
              _BottomActionBar(
                product: product,
                isSubmitting: provider.isSubmitting,
                onPurchase: () => _showPurchaseFlow(context, product),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showPurchaseFlow(
      BuildContext context, InsuranceProduct product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PurchaseFlowSheet(product: product),
    );
  }
}

/// Header with icon and product name.
class _ProductHeader extends StatelessWidget {
  final InsuranceProduct product;

  const _ProductHeader({required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.blue, Color(0xFF42A5F5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
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
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: Text(product.icon, style: const TextStyle(fontSize: 32)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  product.typeLabel,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Price comparison: member vs non-member.
class _PriceComparison extends StatelessWidget {
  final InsuranceProduct product;

  const _PriceComparison({required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Harga Premi',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.gray900,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Member price
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.success.withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        '🏷️ Anggota',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        Formatters.currency(product.priceMember.toInt()),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.success,
                        ),
                      ),
                      Text(
                        '/bulan',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.gray500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Non-member price
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.gray100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Non-anggota',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.gray500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        Formatters.currency(product.priceNonMember.toInt()),
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.gray400,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      Text(
                        '/bulan',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.gray400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Hemat ${product.discountPercent}% sebagai anggota!',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.success,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Partner info with logo placeholder.
class _PartnerInfo extends StatelessWidget {
  final String partnerName;

  const _PartnerInfo({required this.partnerName});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.blueLight,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: const Text('🏢', style: TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Partner Asuransi',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.gray500,
                  ),
                ),
                Text(
                  partnerName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.gray900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom bar with purchase button.
class _BottomActionBar extends StatelessWidget {
  final InsuranceProduct product;
  final bool isSubmitting;
  final VoidCallback onPurchase;

  const _BottomActionBar({
    required this.product,
    required this.isSubmitting,
    required this.onPurchase,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: product.hasActivePolicy
          ? Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_rounded,
                      color: AppColors.success, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Sudah Aktif',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            )
          : ElevatedButton(
              onPressed: isSubmitting ? null : onPurchase,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.blue,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: isSubmitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Beli Sekarang — ${Formatters.currency(product.priceMember.toInt())}/bulan',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
    );
  }
}

/// Multi-step purchase flow bottom sheet.
class _PurchaseFlowSheet extends StatefulWidget {
  final InsuranceProduct product;

  const _PurchaseFlowSheet({required this.product});

  @override
  State<_PurchaseFlowSheet> createState() => _PurchaseFlowSheetState();
}

class _PurchaseFlowSheetState extends State<_PurchaseFlowSheet> {
  int _currentStep = 0;
  final _formKey = GlobalKey<FormState>();
  String _paymentMethod = 'saldo';
  bool _isSubmitting = false;

  // Additional data controllers
  final _nikController = TextEditingController();
  final _addressController = TextEditingController();

  @override
  void dispose() {
    _nikController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.gray300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              _stepTitle,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.gray900,
              ),
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: bottomPadding + 16,
              ),
              child: _buildStep(),
            ),
          ),

          // Navigation buttons
          Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: MediaQuery.of(context).padding.bottom + 16,
            ),
            child: Row(
              children: [
                if (_currentStep > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _currentStep--),
                      child: const Text('Kembali'),
                    ),
                  ),
                if (_currentStep > 0) const SizedBox(width: 12),
                Expanded(
                  flex: _currentStep == 0 ? 1 : 1,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _handleNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.blue,
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(_currentStep == 2 ? 'Konfirmasi' : 'Lanjut'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String get _stepTitle {
    switch (_currentStep) {
      case 0:
        return 'Data Tambahan';
      case 1:
        return 'Metode Pembayaran';
      case 2:
        return 'Konfirmasi Pembelian';
      default:
        return '';
    }
  }

  Widget _buildStep() {
    switch (_currentStep) {
      case 0:
        return _buildAdditionalDataStep();
      case 1:
        return _buildPaymentMethodStep();
      case 2:
        return _buildConfirmationStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildAdditionalDataStep() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lengkapi data berikut untuk melanjutkan pembelian ${widget.product.name}.',
            style: TextStyle(fontSize: 13, color: AppColors.gray600),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _nikController,
            decoration: const InputDecoration(
              labelText: 'NIK',
              hintText: 'Masukkan NIK kamu',
              prefixIcon: Icon(Icons.credit_card_rounded),
            ),
            keyboardType: TextInputType.number,
            maxLength: 16,
            validator: (v) {
              if (v == null || v.isEmpty) return 'NIK wajib diisi';
              if (v.length != 16) return 'NIK harus 16 digit';
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _addressController,
            decoration: const InputDecoration(
              labelText: 'Alamat Lengkap',
              hintText: 'Masukkan alamat sesuai KTP',
              prefixIcon: Icon(Icons.home_rounded),
            ),
            maxLines: 2,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Alamat wajib diisi';
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pilih metode pembayaran premi bulanan.',
          style: TextStyle(fontSize: 13, color: AppColors.gray600),
        ),
        const SizedBox(height: 16),
        _PaymentOption(
          icon: '💰',
          title: 'Saldo KopDar',
          subtitle: 'Potong dari saldo aktif',
          value: 'saldo',
          groupValue: _paymentMethod,
          onChanged: (v) => setState(() => _paymentMethod = v!),
        ),
        const SizedBox(height: 8),
        _PaymentOption(
          icon: '🏦',
          title: 'Transfer Bank',
          subtitle: 'BCA, Mandiri, BNI, BRI',
          value: 'bank_transfer',
          groupValue: _paymentMethod,
          onChanged: (v) => setState(() => _paymentMethod = v!),
        ),
        const SizedBox(height: 8),
        _PaymentOption(
          icon: '📱',
          title: 'E-Wallet',
          subtitle: 'GoPay, OVO, DANA, ShopeePay',
          value: 'ewallet',
          groupValue: _paymentMethod,
          onChanged: (v) => setState(() => _paymentMethod = v!),
        ),
      ],
    );
  }

  Widget _buildConfirmationStep() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.blueLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(widget.product.icon, style: const TextStyle(fontSize: 40)),
          const SizedBox(height: 12),
          Text(
            widget.product.name,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.gray900,
            ),
          ),
          const SizedBox(height: 16),
          _SummaryRow(
            label: 'Premi/bulan',
            value: Formatters.currency(widget.product.priceMember.toInt()),
          ),
          _SummaryRow(
            label: 'Metode Bayar',
            value: _paymentMethodLabel,
          ),
          _SummaryRow(
            label: 'NIK',
            value: Formatters.nik(_nikController.text),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: AppColors.success, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Perlindungan aktif segera setelah pembayaran berhasil.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.gray700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String get _paymentMethodLabel {
    switch (_paymentMethod) {
      case 'saldo':
        return 'Saldo KopDar';
      case 'bank_transfer':
        return 'Transfer Bank';
      case 'ewallet':
        return 'E-Wallet';
      default:
        return _paymentMethod;
    }
  }

  void _handleNext() {
    if (_currentStep == 0) {
      if (_formKey.currentState?.validate() ?? false) {
        setState(() => _currentStep++);
      }
    } else if (_currentStep == 1) {
      setState(() => _currentStep++);
    } else {
      _submitPurchase();
    }
  }

  Future<void> _submitPurchase() async {
    setState(() => _isSubmitting = true);

    final success = await context.read<InsuranceProvider>().purchasePolicy(
          productId: widget.product.id,
          additionalData: {
            'nik': _nikController.text,
            'address': _addressController.text,
          },
          paymentMethod: _paymentMethod,
        );

    setState(() => _isSubmitting = false);

    if (mounted) {
      Navigator.of(context).pop(); // Close bottom sheet
      if (success) {
        _showSuccessDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.read<InsuranceProvider>().errorMessage ??
                  'Gagal membeli polis',
            ),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            const Text(
              'Pembelian Berhasil!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.gray900,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Polis ${widget.product.name} kamu sudah aktif. Cek di menu Polis Saya.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.gray600,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.push('/insurance/my');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.blue,
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text('Lihat Polis Saya'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Kembali'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentOption extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  final String value;
  final String groupValue;
  final ValueChanged<String?> onChanged;

  const _PaymentOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == groupValue;

    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.blueLight : AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.blue : AppColors.gray300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color:
                          isSelected ? AppColors.blue : AppColors.gray800,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.gray500,
                    ),
                  ),
                ],
              ),
            ),
            Radio<String>(
              value: value,
              groupValue: groupValue,
              onChanged: onChanged,
              activeColor: AppColors.blue,
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.gray600,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.gray900,
            ),
          ),
        ],
      ),
    );
  }
}
