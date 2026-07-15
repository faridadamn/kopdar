import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../config/theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../common/widgets/date_range_picker.dart';
import '../providers/finance_provider.dart';

/// Export financial data screen with date range, type filter, preview, and share.
class ExportPage extends StatefulWidget {
  const ExportPage({super.key});

  @override
  State<ExportPage> createState() => _ExportPageState();
}

class _ExportPageState extends State<ExportPage> {
  DateTime? _dateFrom;
  DateTime? _dateTo;
  String _selectedType = 'all';

  @override
  void initState() {
    super.initState();
    // Default: last 7 days
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    _dateFrom = today.subtract(const Duration(days: 7));
    _dateTo = today.add(const Duration(days: 1));
  }

  Future<void> _loadPreview() async {
    if (_dateFrom == null || _dateTo == null) return;
    await context.read<FinanceProvider>().exportData(
          dateFrom: _dateFrom!,
          dateTo: _dateTo!,
          type: _selectedType,
        );
  }

  Future<void> _exportAndShare() async {
    final provider = context.read<FinanceProvider>();
    if (provider.exportData.isEmpty) {
      await _loadPreview();
    }

    if (provider.exportData.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tidak ada data untuk di-export'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
      return;
    }

    try {
      final csv = provider.generateCsv();
      final dir = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/kopdar_export_${DateTime.now().millisecondsSinceEpoch}.csv');
      await file.writeAsString(csv);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Data keuangan KopDar',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal export. Coba lagi.'),
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
        title: const Text('Export Data'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Consumer<FinanceProvider>(
        builder: (context, provider, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Date range picker ──
                _SectionTitle(title: 'Rentang Tanggal'),
                const SizedBox(height: 8),
                DateRangePickerWidget(
                  dateFrom: _dateFrom,
                  dateTo: _dateTo,
                  onFromChanged: (date) => setState(() => _dateFrom = date),
                  onToChanged: (date) => setState(() => _dateTo = date),
                ),
                const SizedBox(height: 24),

                // ── Type selector ──
                _SectionTitle(title: 'Tipe Data'),
                const SizedBox(height: 8),
                _TypeSelector(
                  selected: _selectedType,
                  onSelected: (type) =>
                      setState(() => _selectedType = type),
                ),
                const SizedBox(height: 24),

                // ── Load preview button ──
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: provider.isExporting ? null : _loadPreview,
                    icon: provider.isExporting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          )
                        : const Icon(Icons.visibility_rounded),
                    label: const Text('Preview Data'),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Preview table ──
                if (provider.exportData.isNotEmpty) ...[
                  _SectionTitle(
                    title: 'Preview (${provider.exportData.length} data)',
                  ),
                  const SizedBox(height: 8),
                  _PreviewTable(data: provider.exportData),
                  const SizedBox(height: 24),
                ],

                // ── Format info ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.blueLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        size: 20,
                        color: AppColors.blue,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'File akan berformat CSV yang bisa dibuka di Excel',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.blue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Export button ──
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed:
                        provider.isExporting ? null : _exportAndShare,
                    icon: provider.isExporting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.white,
                            ),
                          )
                        : const Icon(Icons.download_rounded),
                    label: const Text('Export ke CSV'),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Share options ──
                if (provider.exportData.isNotEmpty) ...[
                  _SectionTitle(title: 'Bagikan'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _ShareButton(
                          icon: '💬',
                          label: 'WhatsApp',
                          onTap: _exportAndShare,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ShareButton(
                          icon: '📧',
                          label: 'Email',
                          onTap: _exportAndShare,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ShareButton(
                          icon: '📥',
                          label: 'Download',
                          onTap: _exportAndShare,
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 80),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
    );
  }
}

/// Type selector: Semua | Penghasilan | Pengeluaran.
class _TypeSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelected;

  const _TypeSelector({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final options = [
      ('all', 'Semua', '📋'),
      ('income', 'Penghasilan', '💰'),
      ('expense', 'Pengeluaran', '💸'),
    ];

    return Row(
      children: options.map((opt) {
        final isSelected = selected == opt.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () => onSelected(opt.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color:
                      isSelected ? AppColors.primary : AppColors.gray300,
                ),
              ),
              child: Column(
                children: [
                  Text(opt.$3, style: const TextStyle(fontSize: 18)),
                  const SizedBox(height: 4),
                  Text(
                    opt.$2,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isSelected
                          ? AppColors.white
                          : AppColors.gray600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Preview table showing first 5 rows of export data.
class _PreviewTable extends StatelessWidget {
  final List<Map<String, dynamic>> data;

  const _PreviewTable({required this.data});

  @override
  Widget build(BuildContext context) {
    final previewRows = data.take(5).toList();
    if (previewRows.isEmpty) return const SizedBox.shrink();

    final headers = previewRows.first.keys.toList();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(AppColors.gray100),
          dataRowColor: WidgetStateProperty.all(AppColors.white),
          headingTextStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.gray700,
          ),
          dataTextStyle: const TextStyle(
            fontSize: 12,
            color: AppColors.gray800,
          ),
          columnSpacing: 16,
          columns: headers
              .map((h) => DataColumn(label: Text(_formatHeader(h))))
              .toList(),
          rows: previewRows.map((row) {
            return DataRow(
              cells: headers.map((h) {
                final value = row[h]?.toString() ?? '-';
                return DataCell(
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
            );
          }).toList(),
        ),
      ),
    );
  }

  String _formatHeader(String key) {
    return key
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
        .join(' ');
  }
}

/// Share option button.
class _ShareButton extends StatelessWidget {
  final String icon;
  final String label;
  final VoidCallback onTap;

  const _ShareButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.gray200),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.gray700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
