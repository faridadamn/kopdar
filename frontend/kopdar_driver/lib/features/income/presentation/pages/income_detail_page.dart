import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../data/models/transaction_model.dart';
import '../providers/transaction_provider.dart';

/// Detail view of a single transaction.
class IncomeDetailPage extends StatefulWidget {
  final String id;

  const IncomeDetailPage({super.key, required this.id});

  @override
  State<IncomeDetailPage> createState() => _IncomeDetailPageState();
}

class _IncomeDetailPageState extends State<IncomeDetailPage> {
  TransactionModel? _transaction;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTransaction();
  }

  Future<void> _loadTransaction() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // First check local provider
      final provider = context.read<TransactionProvider>();
      final local = provider.transactions.where((t) => t.id == widget.id);
      if (local.isNotEmpty) {
        setState(() {
          _transaction = local.first;
          _isLoading = false;
        });
        return;
      }

      // Fetch from API
      // In a real app, you'd call the datasource directly or via provider
      setState(() {
        _error = 'Transaksi tidak ditemukan';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Gagal memuat transaksi';
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteTransaction() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Hapus Transaksi'),
        content: const Text(
            'Apakah Anda yakin ingin menghapus transaksi ini? Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final provider = context.read<TransactionProvider>();
      final success = await provider.deleteTransaction(widget.id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transaksi berhasil dihapus'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                provider.errorMessage ?? 'Gagal menghapus transaksi'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        title: const Text('Detail Transaksi'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (_transaction != null && _transaction!.isEditable) ...[
            IconButton(
              icon: const Icon(Icons.edit_rounded),
              onPressed: () {
                // Navigate to edit page (future feature)
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Fitur edit akan segera hadir'),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded,
                  color: AppColors.danger),
              onPressed: _deleteTransaction,
            ),
          ],
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('😵', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _loadTransaction,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    final tx = _transaction!;
    final isIncome = tx.type == 'income';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header card ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Icon
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: isIncome
                        ? AppColors.primaryBg
                        : AppColors.dangerLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    isIncome ? tx.platformEmoji : tx.categoryEmoji,
                    style: const TextStyle(fontSize: 32),
                  ),
                ),
                const SizedBox(height: 16),

                // Type badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: isIncome
                        ? AppColors.primaryBg
                        : AppColors.dangerLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isIncome ? 'Penghasilan' : 'Pengeluaran',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color:
                          isIncome ? AppColors.primary : AppColors.danger,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Net amount
                Text(
                  Formatters.currency(
                      (isIncome ? tx.netAmount : tx.amount).toInt()),
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color:
                        isIncome ? AppColors.primary : AppColors.danger,
                  ),
                ),
                const SizedBox(height: 8),

                // Date/time
                Text(
                  Formatters.dateTime(tx.createdAt),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.gray500,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Breakdown (for income) ──
          if (isIncome) ...[
            _SectionCard(
              title: 'Rincian Penghasilan',
              children: [
                _detailRow(
                  'Penghasilan Kotor',
                  Formatters.currency(tx.amount.toInt()),
                ),
                const SizedBox(height: 12),
                _detailRow(
                  'Komisi Platform',
                  '- ${Formatters.currency(tx.commission.toInt())}',
                  valueColor: AppColors.danger,
                ),
                const Divider(height: 24),
                _detailRow(
                  'Penghasilan Bersih',
                  Formatters.currency(tx.netAmount.toInt()),
                  isBold: true,
                  valueColor: AppColors.primary,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Order count
            _SectionCard(
              title: 'Detail Order',
              children: [
                _detailRow(
                  'Jumlah Order',
                  '${tx.orderCount} order',
                ),
                if (tx.orderCount > 1) ...[
                  const SizedBox(height: 8),
                  _detailRow(
                    'Rata-rata per Order',
                    Formatters.currency(
                        (tx.netAmount / tx.orderCount).toInt()),
                  ),
                ],
              ],
            ),
          ],

          // ── Notes ──
          if (tx.notes != null && tx.notes!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Catatan',
              children: [
                Text(
                  tx.notes!,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ],

          // ── Receipt image ──
          if (tx.receiptUrl != null && tx.receiptUrl!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Foto Struk',
              children: [
                GestureDetector(
                  onTap: () {
                    // Show full-screen image viewer
                    showDialog(
                      context: context,
                      builder: (context) => Dialog(
                        backgroundColor: Colors.black,
                        insetPadding: EdgeInsets.zero,
                        child: Stack(
                          children: [
                            Center(
                              child: InteractiveViewer(
                                child: Image.asset(
                                  tx.receiptUrl!,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) =>
                                      const Center(
                                    child: Text(
                                      'Gambar tidak dapat dimuat',
                                      style:
                                          TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: MediaQuery.of(context).padding.top + 16,
                              right: 16,
                              child: IconButton(
                                icon: const Icon(Icons.close_rounded,
                                    color: Colors.white, size: 28),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      color: AppColors.gray100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        tx.receiptUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.receipt_long_rounded,
                                  size: 40, color: AppColors.gray400),
                              const SizedBox(height: 8),
                              Text(
                                'Ketuk untuk memperbesar',
                                style: TextStyle(
                                  color: AppColors.gray500,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],

          // ── Edit hint ──
          if (tx.isEditable) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.accentLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      size: 18, color: AppColors.accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Transaksi masih bisa diubah dalam 24 jam pertama',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.accent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _SectionCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.gray600,
                  fontSize: 13,
                ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _detailRow(
    String label,
    String value, {
    Color? valueColor,
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
            color: AppColors.gray600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 18 : 14,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: valueColor ?? AppColors.gray800,
          ),
        ),
      ],
    );
  }
}
