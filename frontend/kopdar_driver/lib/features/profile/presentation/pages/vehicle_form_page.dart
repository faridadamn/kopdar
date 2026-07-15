import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/theme.dart';
import '../../data/models/vehicle_model.dart';
import '../providers/profile_provider.dart';

/// Vehicle form page for adding or editing a vehicle.
class VehicleFormPage extends StatefulWidget {
  final String? vehicleId; // null = add, non-null = edit

  const VehicleFormPage({super.key, this.vehicleId});

  @override
  State<VehicleFormPage> createState() => _VehicleFormPageState();
}

class _VehicleFormPageState extends State<VehicleFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _brandCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  final _plateCtrl = TextEditingController();
  final _colorCtrl = TextEditingController();

  String _vehicleType = 'Motor';
  int _selectedYear = DateTime.now().year;
  bool _isLoading = false;
  bool _isEdit = false;

  static const _motorBrands = [
    'Honda', 'Yamaha', 'Suzuki', 'Kawasaki', 'Vespa',
    'Ducati', 'BMW', 'KTM', 'TVS', 'Lainnya',
  ];
  static const _mobilBrands = [
    'Toyota', 'Honda', 'Daihatsu', 'Suzuki', 'Mitsubishi',
    'Hyundai', 'Kia', 'Nissan', 'Wuling', 'Lainnya',
  ];

  List<String> get _brands =>
      _vehicleType == 'Motor' ? _motorBrands : _mobilBrands;

  @override
  void initState() {
    super.initState();
    _isEdit = widget.vehicleId != null;

    if (_isEdit) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final provider = context.read<ProfileProvider>();
        final vehicle = provider.vehicles
            .where((v) => v.id == widget.vehicleId)
            .firstOrNull;
        if (vehicle != null) {
          _populateFromVehicle(vehicle);
        }
      });
    }
  }

  void _populateFromVehicle(VehicleModel v) {
    setState(() {
      _vehicleType = v.type;
      _brandCtrl.text = v.brand;
      _modelCtrl.text = v.model;
      _selectedYear = v.year;
      _plateCtrl.text = v.plateNumber;
      _colorCtrl.text = v.color;
    });
  }

  @override
  void dispose() {
    _brandCtrl.dispose();
    _modelCtrl.dispose();
    _plateCtrl.dispose();
    _colorCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final provider = context.read<ProfileProvider>();
    bool success;

    if (_isEdit) {
      success = await provider.updateVehicle(
        widget.vehicleId!,
        type: _vehicleType,
        brand: _brandCtrl.text.trim(),
        model: _modelCtrl.text.trim(),
        year: _selectedYear,
        plateNumber: _plateCtrl.text.trim().toUpperCase(),
        color: _colorCtrl.text.trim(),
      );
    } else {
      success = await provider.addVehicle(
        type: _vehicleType,
        brand: _brandCtrl.text.trim(),
        model: _modelCtrl.text.trim(),
        year: _selectedYear,
        plateNumber: _plateCtrl.text.trim().toUpperCase(),
        color: _colorCtrl.text.trim(),
      );
    }

    setState(() => _isLoading = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEdit
              ? 'Kendaraan diperbarui!'
              : 'Kendaraan ditambahkan!'),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal menyimpan. Coba lagi.'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final years = List<int>.generate(
      30,
      (i) => DateTime.now().year - i,
    );

    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        title: Text(_isEdit ? '✏️ Edit Kendaraan' : '🚗 Tambah Kendaraan'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Vehicle type ──
              Text(
                'Tipe Kendaraan',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _TypeCard(
                      emoji: '🏍️',
                      label: 'Motor',
                      selected: _vehicleType == 'Motor',
                      onTap: () => setState(() {
                        _vehicleType = 'Motor';
                        _brandCtrl.clear();
                      }),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TypeCard(
                      emoji: '🚗',
                      label: 'Mobil',
                      selected: _vehicleType == 'Mobil',
                      onTap: () => setState(() {
                        _vehicleType = 'Mobil';
                        _brandCtrl.clear();
                      }),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Brand ──
              _sectionLabel('Merek'),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _brandCtrl.text.isNotEmpty &&
                        _brands.contains(_brandCtrl.text)
                    ? _brandCtrl.text
                    : null,
                decoration: const InputDecoration(
                  hintText: 'Pilih merek kendaraan',
                ),
                items: _brands
                    .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) _brandCtrl.text = v;
                },
                validator: (v) =>
                    v == null ? 'Pilih merek kendaraan' : null,
              ),
              const SizedBox(height: 16),

              // ── Model ──
              _sectionLabel('Model'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _modelCtrl,
                decoration: const InputDecoration(
                  hintText: 'Contoh: Vario 125, Avanza',
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Masukkan model' : null,
              ),
              const SizedBox(height: 16),

              // ── Year ──
              _sectionLabel('Tahun'),
              const SizedBox(height: 6),
              DropdownButtonFormField<int>(
                value: _selectedYear,
                decoration: const InputDecoration(
                  hintText: 'Pilih tahun',
                ),
                items: years
                    .map((y) => DropdownMenuItem(
                          value: y,
                          child: Text('$y'),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _selectedYear = v);
                },
              ),
              const SizedBox(height: 16),

              // ── Plate number ──
              _sectionLabel('Plat Nomor'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _plateCtrl,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  hintText: 'B 1234 ABC',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Masukkan plat nomor';
                  }
                  if (v.trim().length < 4) {
                    return 'Plat nomor tidak valid';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // ── Color ──
              _sectionLabel('Warna'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _colorCtrl,
                decoration: const InputDecoration(
                  hintText: 'Contoh: Hitam, Merah, Putih',
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Masukkan warna' : null,
              ),
              const SizedBox(height: 32),

              // ── Submit ──
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _isEdit ? 'Simpan Perubahan' : 'Tambah Kendaraan',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.gray700,
      ),
    );
  }
}

/// Vehicle type selection card.
class _TypeCard extends StatelessWidget {
  final String emoji;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TypeCard({
    required this.emoji,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryBg : AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.gray300,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.primary : AppColors.gray700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
