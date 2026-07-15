import 'dart:io';
import 'package:flutter/foundation.dart';

class RegistrationDraftProvider extends ChangeNotifier {
  String fullName = '';
  String nik = '';
  DateTime? dateOfBirth;
  String address = '';
  String province = '';
  String city = '';
  String postalCode = '';

  String vehicleType = '';
  String vehicleBrand = '';
  String vehicleModel = '';
  int? vehicleYear;
  String vehiclePlate = '';
  String vehicleColor = '';

  List<String> platforms = [];
  String bankName = '';
  String bankAccountNumber = '';
  String bankAccountName = '';

  String emergencyContactName = '';
  String emergencyContactPhone = '';

  File? ktpPhoto;
  File? selfiePhoto;
  File? stnkPhoto;

  void setPersonalData({
    required String fullName,
    required String nik,
    required DateTime dateOfBirth,
    required String address,
    required String province,
    required String city,
    String postalCode = '',
  }) {
    this.fullName = fullName;
    this.nik = nik;
    this.dateOfBirth = dateOfBirth;
    this.address = address;
    this.province = province;
    this.city = city;
    this.postalCode = postalCode;
    notifyListeners();
  }

  void setVehicleData({
    required String type,
    required String brand,
    required String model,
    required int year,
    required String plate,
    required String color,
  }) {
    vehicleType = type;
    vehicleBrand = brand;
    vehicleModel = model;
    vehicleYear = year;
    vehiclePlate = plate;
    vehicleColor = color;
    notifyListeners();
  }

  void setPlatforms(List<String> values) {
    platforms = List.unmodifiable(values);
    notifyListeners();
  }

  void setBankData({
    required String bankName,
    required String accountNumber,
    required String accountName,
  }) {
    this.bankName = bankName;
    bankAccountNumber = accountNumber;
    bankAccountName = accountName;
    notifyListeners();
  }

  void setEmergencyContact({
    required String name,
    required String phone,
  }) {
    emergencyContactName = name;
    emergencyContactPhone = phone;
    notifyListeners();
  }

  void setDocuments({
    File? ktp,
    File? selfie,
    File? stnk,
  }) {
    if (ktp != null) ktpPhoto = ktp;
    if (selfie != null) selfiePhoto = selfie;
    if (stnk != null) stnkPhoto = stnk;
    notifyListeners();
  }

  bool get hasRequiredPersonalData =>
      fullName.isNotEmpty &&
      nik.length == 16 &&
      dateOfBirth != null &&
      address.isNotEmpty &&
      province.isNotEmpty &&
      city.isNotEmpty;

  bool get hasRequiredVehicleData =>
      vehicleType.isNotEmpty &&
      vehicleModel.isNotEmpty &&
      vehicleYear != null &&
      vehiclePlate.isNotEmpty;

  bool get hasRequiredDocuments =>
      ktpPhoto != null && selfiePhoto != null && stnkPhoto != null;

  bool get isComplete =>
      hasRequiredPersonalData &&
      hasRequiredVehicleData &&
      platforms.isNotEmpty &&
      hasRequiredDocuments;

  void clear() {
    fullName = '';
    nik = '';
    dateOfBirth = null;
    address = '';
    province = '';
    city = '';
    postalCode = '';
    vehicleType = '';
    vehicleBrand = '';
    vehicleModel = '';
    vehicleYear = null;
    vehiclePlate = '';
    vehicleColor = '';
    platforms = [];
    bankName = '';
    bankAccountNumber = '';
    bankAccountName = '';
    emergencyContactName = '';
    emergencyContactPhone = '';
    ktpPhoto = null;
    selfiePhoto = null;
    stnkPhoto = null;
    notifyListeners();
  }
}
