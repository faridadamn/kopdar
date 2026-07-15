import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../config/constants.dart';
import '../providers/registration_draft_provider.dart';

class PersonalDataPage extends StatefulWidget {
  const PersonalDataPage({super.key});

  @override
  State<PersonalDataPage> createState() => _PersonalDataPageState();
}

class _PersonalDataPageState extends State<PersonalDataPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _nik = TextEditingController();
  final _address = TextEditingController();
  final _postalCode = TextEditingController();
  final _emergencyName = TextEditingController();
  final _emergencyPhone = TextEditingController();
  String? _province;
  String? _city;
  DateTime? _dateOfBirth;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final draft = context.read<RegistrationDraftProvider>();
    if (_name.text.isEmpty) {
      _name.text = draft.fullName;
      _nik.text = draft.nik;
      _address.text = draft.address;
      _postalCode.text = draft.postalCode;
      _emergencyName.text = draft.emergencyContactName;
      _emergencyPhone.text = draft.emergencyContactPhone;
      _province = draft.province.isEmpty ? null : draft.province;
      _city = draft.city.isEmpty ? null : draft.city;
      _dateOfBirth = draft.dateOfBirth;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _nik.dispose();
    _address.dispose();
    _postalCode.dispose();
    _emergencyName.dispose();
    _emergencyPhone.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final value = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(1995, 1, 1),
      firstDate: DateTime(1940),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 17)),
    );
    if (value != null) setState(() => _dateOfBirth = value);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_province == null || _city == null || _dateOfBirth == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tanggal lahir, provinsi, dan kota wajib diisi.')),
      );
      return;
    }

    final draft = context.read<RegistrationDraftProvider>();
    draft.setPersonalData(
      fullName: _name.text.trim(),
      nik: _nik.text.trim(),
      dateOfBirth: _dateOfBirth!,
      address: _address.text.trim(),
      province: _province!,
      city: _city!,
      postalCode: _postalCode.text.trim(),
    );
    draft.setEmergencyContact(
      name: _emergencyName.text.trim(),
      phone: _emergencyPhone.text.trim(),
    );
    context.push('/register/vehicle');
  }

  String _dateLabel() {
    final date = _dateOfBirth;
    if (date == null) return 'Pilih tanggal lahir';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final cities = AppConstants.citiesByProvince[_province] ?? const <String>[];
    return Scaffold(
      appBar: AppBar(title: const Text('Data Diri')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const LinearProgressIndicator(value: 0.2),
            const SizedBox(height: 24),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Nama lengkap'),
              validator: (v) => v == null || v.trim().length < 3 ? 'Nama wajib diisi' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nik,
              keyboardType: TextInputType.number,
              maxLength: 16,
              decoration: const InputDecoration(labelText: 'NIK'),
              validator: (v) => v?.trim().length == 16 ? null : 'NIK harus 16 digit',
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Tanggal lahir'),
              subtitle: Text(_dateLabel()),
              trailing: const Icon(Icons.calendar_month_outlined),
              onTap: _pickDate,
            ),
            TextFormField(
              controller: _address,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Alamat'),
              validator: (v) => v == null || v.trim().isEmpty ? 'Alamat wajib diisi' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _province,
              decoration: const InputDecoration(labelText: 'Provinsi'),
              items: AppConstants.provinces
                  .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                  .toList(),
              onChanged: (v) => setState(() {
                _province = v;
                _city = null;
              }),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: cities.contains(_city) ? _city : null,
              decoration: const InputDecoration(labelText: 'Kota/Kabupaten'),
              items: cities
                  .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                  .toList(),
              onChanged: _province == null ? null : (v) => setState(() => _city = v),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _postalCode,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Kode pos (opsional)'),
            ),
            const SizedBox(height: 20),
            Text('Kontak darurat', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emergencyName,
              decoration: const InputDecoration(labelText: 'Nama kontak darurat'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emergencyPhone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Nomor kontak darurat'),
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: _submit, child: const Text('Lanjut')),
          ],
        ),
      ),
    );
  }
}
