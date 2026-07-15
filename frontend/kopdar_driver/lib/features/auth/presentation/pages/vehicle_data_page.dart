import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../config/theme.dart';
import '../../../config/constants.dart';
import '../../../core/utils/validators.dart';
import '../../common/widgets/custom_text_field.dart';
import '../../common/widgets/loading_button.dart';

class VehicleDataPage extends StatefulWidget {
  const VehicleDataPage({super.key});

  @override
  State<VehicleDataPage> createState() => _VehicleDataPageState();
}

class _VehicleDataPageState extends State<VehicleDataPage> {
  final _formKey = GlobalKey<FormState>();
  final _modelController = TextEditingController();
  final _platController = TextEditingController();
  final _colorController = TextEditingController();

  String? _vehicleType;
  String? _selectedBrand;
  int? _selectedYear;
  bool _isLoading = false;

  List<String> _availableBrands = [];

  @override
  void dispose() {
    _modelController.dispose();
    _platController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  void _onVehicleTypeChanged(String? type) {
    setState(() {
      _vehicleType = type;
      _selectedBrand = null;
      _availableBrands = AppConstants.vehicleBrands[type] ?? [];
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_vehicleType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih tipe kendaraan')),
      );
      return;
    }
    if (_selectedBrand == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih merek kendaraan')),
      );
      return;
    }
    if (_selectedYear == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih tahun kendaraan')),
      );
      return;
    }

    setState(() => _isLoading = true);

    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;
    setState(() => _isLoading = false);

    context.push('/register/platforms');
  }

  @override
  Widget build(BuildContext context) {
    final years = List<int>.generate(
      AppConstants.vehicleYearMax - AppConstants.vehicleYearMin + 1,
      (i) => AppConstants.vehicleYearMax - i,
    );

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text('Data Kendaraan'),
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
                        'Langkah 2 dari 5',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.gray600,
                            ),
                      ),
                      const Spacer(),
                      Text(
                        '40%',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: 0.4,
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
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),

                      Text(
                        'Data Kendaraan Kamu',
                        style: Theme.of(context).textTheme.titleLarge,
                      )
                          .animate()
                          .fadeIn(duration: 300.ms),

                      const SizedBox(height: 4),

                      Text(
                        'Masukkan informasi kendaraan yang kamu pakai narik.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.gray600,
                            ),
                      ),

                      const SizedBox(height: 24),

                      // Vehicle type
                      Text(
                        'Tipe Kendaraan',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _VehicleTypeCard(
                              icon: '🏍️',
                              label: 'Motor',
                              isSelected: _vehicleType == 'Motor',
                              onTap: () => _onVehicleTypeChanged('Motor'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _VehicleTypeCard(
                              icon: '🚗',
                              label: 'Mobil',
                              isSelected: _vehicleType == 'Mobil',
                              onTap: () => _onVehicleTypeChanged('Mobil'),
                            ),
                          ),
                        ],
                      )
                          .animate()
                          .fadeIn(duration: 300.ms, delay: 100.ms),

                      const SizedBox(height: 16),

                      // Brand dropdown
                      Text(
                        'Merek',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedBrand,
                        decoration: InputDecoration(
                          hintText: _vehicleType == null
                              ? 'Pilih tipe kendaraan dulu'
                              : 'Pilih Merek',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.gray300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.gray300),
                          ),
                        ),
                        items: _availableBrands.map((brand) {
                          return DropdownMenuItem(
                            value: brand,
                            child: Text(brand),
                          );
                        }).toList(),
                        onChanged: _vehicleType == null
                            ? null
                            : (value) => setState(() => _selectedBrand = value),
                        validator: (value) => Validators.validateDropdown(value, 'Merek'),
                      )
                          .animate()
                          .fadeIn(duration: 300.ms, delay: 150.ms),

                      const SizedBox(height: 16),

                      // Model
                      CustomTextField(
                        controller: _modelController,
                        label: 'Model',
                        hint: 'Contoh: Vario 125, Avanza',
                        validator: (v) => Validators.validateRequired(v, 'Model'),
                      )
                          .animate()
                          .fadeIn(duration: 300.ms, delay: 200.ms),

                      const SizedBox(height: 16),

                      // Year dropdown
                      Text(
                        'Tahun',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        value: _selectedYear,
                        decoration: InputDecoration(
                          hintText: 'Pilih Tahun',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.gray300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.gray300),
                          ),
                        ),
                        items: years.map((year) {
                          return DropdownMenuItem(
                            value: year,
                            child: Text(year.toString()),
                          );
                        }).toList(),
                        onChanged: (value) => setState(() => _selectedYear = value),
                        validator: (value) => value == null ? 'Pilih tahun' : null,
                      )
                          .animate()
                          .fadeIn(duration: 300.ms, delay: 250.ms),

                      const SizedBox(height: 16),

                      // Plat nomor
                      CustomTextField(
                        controller: _platController,
                        label: 'Plat Nomor',
                        hint: 'B 1234 ABC',
                        textCapitalization: TextCapitalization.characters,
                        validator: Validators.validatePlat,
                      )
                          .animate()
                          .fadeIn(duration: 300.ms, delay: 300.ms),

                      const SizedBox(height: 16),

                      // Warna
                      CustomTextField(
                        controller: _colorController,
                        label: 'Warna Kendaraan',
                        hint: 'Contoh: Hitam, Merah',
                        validator: (v) => Validators.validateRequired(v, 'Warna'),
                      )
                          .animate()
                          .fadeIn(duration: 300.ms, delay: 350.ms),

                      const SizedBox(height: 24),

                      // Photo section
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.gray50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.gray200),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.camera_alt_outlined,
                              size: 40,
                              color: AppColors.gray400,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Foto Kendaraan',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Ambil foto kendaraan kamu (opsional)',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.gray500,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: () {
                                // TODO: Implement image picker
                              },
                              icon: const Icon(Icons.camera_alt, size: 18),
                              label: const Text('Pilih Foto'),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(0, 40),
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                              ),
                            ),
                          ],
                        ),
                      )
                          .animate()
                          .fadeIn(duration: 300.ms, delay: 400.ms),

                      const SizedBox(height: 32),
                    ],
                  ),
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
}

class _VehicleTypeCard extends StatelessWidget {
  final String icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _VehicleTypeCard({
    required this.icon,
    required this.label,
    required this.isSelected,
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
          color: isSelected ? AppColors.primaryBg : AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.gray300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isSelected ? AppColors.primary : AppColors.gray700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
