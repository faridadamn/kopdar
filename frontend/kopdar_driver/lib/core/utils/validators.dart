import '../../config/constants.dart';

class Validators {
  Validators._();

  /// Validate Indonesian phone number format
  /// Accepts: 08xx, +628xx, 628xx
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Nomor HP wajib diisi';
    }

    // Remove spaces, dashes, and + prefix
    final cleaned = value.replaceAll(RegExp(r'[\s\-+]'), '');

    // Check format
    if (!RegExp(r'^(08|628)\d{8,12}$').hasMatch(cleaned)) {
      return 'Format nomor HP tidak valid';
    }

    // Check length (08xx = 10-13 digits, 628xx = 11-14 digits)
    if (cleaned.startsWith('08') && (cleaned.length < 10 || cleaned.length > 13)) {
      return 'Nomor HP harus 10-13 digit';
    }

    if (cleaned.startsWith('628') && (cleaned.length < 11 || cleaned.length > 14)) {
      return 'Nomor HP tidak valid';
    }

    return null;
  }

  /// Validate NIK (16 digits)
  static String? validateNik(String? value) {
    if (value == null || value.isEmpty) {
      return 'NIK wajib diisi';
    }

    final cleaned = value.replaceAll(RegExp(r'\D'), '');

    if (cleaned.length != AppConstants.nikLength) {
      return 'NIK harus ${AppConstants.nikLength} digit';
    }

    if (!RegExp(r'^\d{16}$').hasMatch(cleaned)) {
      return 'NIK hanya boleh angka';
    }

    return null;
  }

  /// Validate name (not empty, min 2 chars)
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Nama wajib diisi';
    }

    if (value.trim().length < 2) {
      return 'Nama minimal 2 karakter';
    }

    if (value.trim().length > 100) {
      return 'Nama maksimal 100 karakter';
    }

    return null;
  }

  /// Validate address
  static String? validateAddress(String? value) {
    if (value == null || value.isEmpty) {
      return 'Alamat wajib diisi';
    }

    if (value.trim().length < 10) {
      return 'Alamat minimal 10 karakter';
    }

    return null;
  }

  /// Validate required field
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName wajib diisi';
    }
    return null;
  }

  /// Validate dropdown selection
  static String? validateDropdown(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return 'Pilih $fieldName';
    }
    return null;
  }

  /// Validate plate number (Indonesian format)
  static String? validatePlat(String? value) {
    if (value == null || value.isEmpty) {
      return 'Plat nomor wajib diisi';
    }

    final cleaned = value.toUpperCase().trim();

    // Basic Indonesian plate format: XX XXXX XXX or XX XXX XXX
    if (!RegExp(r'^[A-Z]{1,2}\s?\d{1,4}\s?[A-Z]{0,3}\s?\d{1,4}$').hasMatch(cleaned)) {
      return 'Format plat nomor tidak valid';
    }

    return null;
  }

  /// Validate bank account number
  static String? validateBankAccount(String? value) {
    if (value == null || value.isEmpty) {
      return 'Nomor rekening wajib diisi';
    }

    final cleaned = value.replaceAll(RegExp(r'\s\-'), '');

    if (!RegExp(r'^\d{5,20}$').hasMatch(cleaned)) {
      return 'Nomor rekening tidak valid';
    }

    return null;
  }

  /// Validate OTP code
  static String? validateOtp(String? value) {
    if (value == null || value.isEmpty) {
      return 'Kode OTP wajib diisi';
    }

    if (value.length != AppConstants.otpLength) {
      return 'Kode OTP harus ${AppConstants.otpLength} digit';
    }

    if (!RegExp(r'^\d{6}$').hasMatch(value)) {
      return 'Kode OTP hanya boleh angka';
    }

    return null;
  }

  /// Normalize phone number to 08xx format
  static String normalizePhone(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[\s\-+]'), '');
    if (cleaned.startsWith('628')) {
      return '0${cleaned.substring(2)}';
    }
    return cleaned;
  }
}
