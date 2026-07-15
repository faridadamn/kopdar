import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../config/constants.dart';
import '../providers/registration_draft_provider.dart';
import 'registration_documents_page.dart';

class VehicleDataPage extends StatefulWidget {
  const VehicleDataPage({super.key});

  @override
  State<VehicleDataPage> createState() => _VehicleDataPageState();
}

class _VehicleDataPageState extends State<VehicleDataPage> {
  final _formKey = GlobalKey<FormState>();
  final _model = TextEditingController();
  final _plate = TextEditingController();
  final _color = TextEditingController();
  String? _type;
  String? _brand;
  int? _year;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final draft = context.read<RegistrationDraftProvider>();
    if (_model.text.isEmpty) {
      _model.text = draft.vehicleModel;
      _plate.text = draft.vehiclePlate;
      _color.text = draft.vehicleColor;
      _type = draft.vehicleType.isEmpty ? null : draft.vehicleType;
      _brand = draft.vehicleBrand.isEmpty ? null : draft.vehicleBrand;
      _year = draft.vehicleYear;
    }
  }

  @override
  void dispose() {
    _model.dispose();
    _plate.dispose();
    _color.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_type == null || _brand == null || _year == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tipe, merek, dan tahun kendaraan wajib diisi.')),
      );
      return;
    }

    context.read<RegistrationDraftProvider>().setVehicleData(
          type: _type!,
          brand: _brand!,
          model: _model.text.trim(),
          year: _year!,
          plate: _plate.text.trim().toUpperCase(),
          color: _color.text.trim(),
        );

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const RegistrationDocumentsPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final brands = AppConstants.vehicleBrands[_type] ?? const <String>[];
    final years = List<int>.generate(
      AppConstants.vehicleYearMax - AppConstants.vehicleYearMin + 1,
      (index) => AppConstants.vehicleYearMax - index,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Data Kendaraan')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const LinearProgressIndicator(value: 0.4),
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(
              value: _type,
              decoration: const InputDecoration(labelText: 'Tipe kendaraan'),
              items: const [
                DropdownMenuItem(value: 'Motor', child: Text('Motor')),
                DropdownMenuItem(value: 'Mobil', child: Text('Mobil')),
              ],
              onChanged: (value) => setState(() {
                _type = value;
                _brand = null;
              }),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: brands.contains(_brand) ? _brand : null,
              decoration: const InputDecoration(labelText: 'Merek'),
              items: brands
                  .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                  .toList(),
              onChanged: _type == null ? null : (value) => setState(() => _brand = value),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _model,
              decoration: const InputDecoration(labelText: 'Model kendaraan'),
              validator: (v) => v == null || v.trim().isEmpty ? 'Model wajib diisi' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              value: _year,
              decoration: const InputDecoration(labelText: 'Tahun kendaraan'),
              items: years
                  .map((v) => DropdownMenuItem(value: v, child: Text(v.toString())))
                  .toList(),
              onChanged: (value) => setState(() => _year = value),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _plate,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(labelText: 'Plat nomor'),
              validator: (v) => v == null || v.trim().isEmpty ? 'Plat nomor wajib diisi' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _color,
              decoration: const InputDecoration(labelText: 'Warna kendaraan'),
              validator: (v) => v == null || v.trim().isEmpty ? 'Warna wajib diisi' : null,
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: _submit, child: const Text('Lanjut ke Dokumen')),
          ],
        ),
      ),
    );
  }
}
