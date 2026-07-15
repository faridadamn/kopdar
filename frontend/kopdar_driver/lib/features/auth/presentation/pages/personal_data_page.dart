import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../config/theme.dart';
import '../../../config/constants.dart';
import '../../../core/utils/validators.dart';
import '../../common/widgets/custom_text_field.dart';
import '../../common/widgets/loading_button.dart';

class PersonalDataPage extends StatefulWidget {
  const PersonalDataPage({super.key});

  @override
  State<PersonalDataPage> createState() => _PersonalDataPageState();
}

class _PersonalDataPageState extends State<PersonalDataPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _nikController = TextEditingController();
  final _addressController = TextEditingController();

  String? _selectedProvince;
  String? _selectedCity;
  bool _isLoading = false;

  List<String> _availableCities = [];

  @override
  void dispose() {
    _nameController.dispose();
    _nikController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _onProvinceChanged(String? province) {
    setState(() {
      _selectedProvince = province;
      _selectedCity = null;
      _availableCities = AppConstants.citiesByProvince[province] ?? [];
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProvince == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih provinsi terlebih dahulu')),
      );
      return;
    }
    if (_selectedCity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih kota terlebih dahulu')),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;
    setState(() => _isLoading = false);

    // Navigate to vehicle data
    context.push('/register/vehicle');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text('Data Diri'),
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
                        'Langkah 1 dari 5',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.gray600,
                            ),
                      ),
                      const Spacer(),
                      Text(
                        '20%',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: 0.2,
                    backgroundColor: AppColors.gray200,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    borderRadius: BorderRadius.circular(4),
                    minHeight: 6,
                  ),
                ],
              ),
            ),

            // Form
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
                        'Isi data diri kamu',
                        style: Theme.of(context).textTheme.titleLarge,
                      )
                          .animate()
                          .fadeIn(duration: 300.ms),

                      const SizedBox(height: 4),

                      Text(
                        'Sesuai dengan data KTP kamu ya!',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.gray600,
                            ),
                      ),

                      const SizedBox(height: 24),

                      // Name
                      CustomTextField(
                        controller: _nameController,
                        label: 'Nama Lengkap',
                        hint: 'Sesuai KTP',
                        validator: Validators.validateName,
                        textCapitalization: TextCapitalization.words,
                      )
                          .animate()
                          .fadeIn(duration: 300.ms, delay: 100.ms),

                      const SizedBox(height: 16),

                      // NIK
                      CustomTextField(
                        controller: _nikController,
                        label: 'NIK',
                        hint: '16 digit nomor KTP',
                        keyboardType: TextInputType.number,
                        validator: Validators.validateNik,
                        maxLength: 16,
                      )
                          .animate()
                          .fadeIn(duration: 300.ms, delay: 150.ms),

                      const SizedBox(height: 16),

                      // Address
                      CustomTextField(
                        controller: _addressController,
                        label: 'Alamat Domisili',
                        hint: 'Jalan, RT/RW, Kelurahan, Kecamatan',
                        maxLines: 3,
                        validator: Validators.validateAddress,
                      )
                          .animate()
                          .fadeIn(duration: 300.ms, delay: 200.ms),

                      const SizedBox(height: 16),

                      // Province dropdown
                      Text(
                        'Provinsi',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedProvince,
                        decoration: InputDecoration(
                          hintText: 'Pilih Provinsi',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.gray300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.gray300),
                          ),
                        ),
                        items: AppConstants.provinces.map((province) {
                          return DropdownMenuItem(
                            value: province,
                            child: Text(province),
                          );
                        }).toList(),
                        onChanged: _onProvinceChanged,
                        validator: (value) => Validators.validateDropdown(value, 'Provinsi'),
                      )
                          .animate()
                          .fadeIn(duration: 300.ms, delay: 250.ms),

                      const SizedBox(height: 16),

                      // City dropdown
                      Text(
                        'Kota / Kabupaten',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedCity,
                        decoration: InputDecoration(
                          hintText: _selectedProvince == null
                              ? 'Pilih provinsi dulu'
                              : 'Pilih Kota',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.gray300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.gray300),
                          ),
                        ),
                        items: _availableCities.map((city) {
                          return DropdownMenuItem(
                            value: city,
                            child: Text(city),
                          );
                        }).toList(),
                        onChanged: _selectedProvince == null
                            ? null
                            : (value) => setState(() => _selectedCity = value),
                        validator: (value) => Validators.validateDropdown(value, 'Kota'),
                      )
                          .animate()
                          .fadeIn(duration: 300.ms, delay: 300.ms),

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
    );
  }
}
