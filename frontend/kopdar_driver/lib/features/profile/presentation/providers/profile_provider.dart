import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kopdar_driver/features/profile/data/datasources/profile_remote_ds.dart';
import 'package:kopdar_driver/features/profile/data/models/profile_model.dart';
import 'package:kopdar_driver/features/profile/data/models/vehicle_model.dart';

enum ProfileStatus { initial, loading, loaded, error }
enum LevelStatus { initial, loading, loaded, error }
enum ReferralStatus { initial, loading, loaded, applying, error }
enum SettingsStatus { initial, loading, loaded, updating, error }
enum VehicleStatus { initial, loading, loaded, error }
enum DocumentStatus { initial, loading, loaded, error }

class ProfileProvider extends ChangeNotifier {
  final ProfileRemoteDataSource _dataSource;

  ProfileProvider({ProfileRemoteDataSource? dataSource})
      : _dataSource = dataSource ?? ProfileRemoteDataSource();

  ProfileStatus _profileStatus = ProfileStatus.initial;
  LevelStatus _levelStatus = LevelStatus.initial;
  ReferralStatus _referralStatus = ReferralStatus.initial;
  SettingsStatus _settingsStatus = SettingsStatus.initial;
  VehicleStatus _vehicleStatus = VehicleStatus.initial;
  DocumentStatus _documentStatus = DocumentStatus.initial;

  ProfileModel? _profile;
  LevelInfo? _levelInfo;
  ReferralInfo? _referralInfo;
  SettingsModel? _settings;
  List<VehicleModel> _vehicles = [];
  List<DocumentModel> _documents = [];
  String? _errorMessage;
  String? _referralError;
  bool _isSubmittingVehicle = false;
  bool _showOnboarding = false;
  bool _onboardingChecked = false;

  ProfileStatus get profileStatus => _profileStatus;
  LevelStatus get levelStatus => _levelStatus;
  ReferralStatus get referralStatus => _referralStatus;
  SettingsStatus get settingsStatus => _settingsStatus;
  VehicleStatus get vehicleStatus => _vehicleStatus;
  DocumentStatus get documentStatus => _documentStatus;
  ProfileModel? get profile => _profile;
  LevelInfo? get levelInfo => _levelInfo;
  ReferralInfo? get referralInfo => _referralInfo;
  SettingsModel? get settings => _settings;
  List<VehicleModel> get vehicles => List.unmodifiable(_vehicles);
  List<DocumentModel> get documents => List.unmodifiable(_documents);
  String? get errorMessage => _errorMessage;
  String? get referralError => _referralError;
  bool get isProfileLoading => _profileStatus == ProfileStatus.loading;
  bool get isLevelLoading => _levelStatus == LevelStatus.loading;
  bool get isReferralLoading => _referralStatus == ReferralStatus.loading;
  bool get isSettingsLoading => _settingsStatus == SettingsStatus.loading;
  bool get isVehicleLoading => _vehicleStatus == VehicleStatus.loading;
  bool get isDocumentLoading => _documentStatus == DocumentStatus.loading;
  bool get isSubmittingVehicle => _isSubmittingVehicle;
  bool get showOnboarding => _showOnboarding;

  VehicleModel? get primaryVehicle {
    for (final vehicle in _vehicles) {
      if (vehicle.isPrimary) return vehicle;
    }
    return null;
  }

  Future<void> fetchProfile() async {
    _profileStatus = ProfileStatus.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      _profile = await _dataSource.getProfile();
      _profileStatus = ProfileStatus.loaded;
    } catch (_) {
      _profileStatus = ProfileStatus.error;
      _errorMessage = 'Gagal memuat profil. Coba lagi.';
    }
    notifyListeners();
  }

  Future<bool> updateProfile({String? name, String? email}) async {
    try {
      _profile = await _dataSource.updateProfile(name: name, email: email);
      notifyListeners();
      return true;
    } catch (_) {
      _errorMessage = 'Gagal memperbarui profil.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updatePhoto(String filePath) async {
    try {
      await _dataSource.updatePhoto(filePath);
      await fetchProfile();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> fetchLevel() async {
    _levelStatus = LevelStatus.loading;
    notifyListeners();
    try {
      _levelInfo = await _dataSource.getLevel();
      _levelStatus = LevelStatus.loaded;
    } catch (_) {
      _levelStatus = LevelStatus.error;
    }
    notifyListeners();
  }

  Future<void> fetchReferral() async {
    _referralStatus = ReferralStatus.loading;
    _referralError = null;
    notifyListeners();
    try {
      _referralInfo = await _dataSource.getReferral();
      _referralStatus = ReferralStatus.loaded;
    } catch (_) {
      _referralStatus = ReferralStatus.error;
      _referralError = 'Gagal memuat data referral.';
    }
    notifyListeners();
  }

  Future<bool> applyReferralCode(String code) async {
    _referralStatus = ReferralStatus.applying;
    _referralError = null;
    notifyListeners();
    try {
      await _dataSource.applyReferralCode(code);
      await fetchReferral();
      return true;
    } catch (_) {
      _referralStatus = ReferralStatus.error;
      _referralError = 'Kode referral tidak valid atau sudah digunakan.';
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchVehicles() async {
    _vehicleStatus = VehicleStatus.loading;
    notifyListeners();
    try {
      _vehicles = await _dataSource.getVehicles();
      _vehicleStatus = VehicleStatus.loaded;
    } catch (_) {
      _vehicleStatus = VehicleStatus.error;
    }
    notifyListeners();
  }

  Future<bool> addVehicle({
    required String type,
    required String brand,
    required String model,
    required int year,
    required String plateNumber,
    required String color,
    String? photoPath,
  }) async {
    _isSubmittingVehicle = true;
    notifyListeners();
    try {
      final vehicle = await _dataSource.addVehicle(
        type: type,
        brand: brand,
        model: model,
        year: year,
        plateNumber: plateNumber,
        color: color,
        photoPath: photoPath,
      );
      _vehicles.add(vehicle);
      return true;
    } catch (_) {
      return false;
    } finally {
      _isSubmittingVehicle = false;
      notifyListeners();
    }
  }

  Future<bool> updateVehicle(
    String id, {
    String? type,
    String? brand,
    String? model,
    int? year,
    String? plateNumber,
    String? color,
    String? photoPath,
  }) async {
    _isSubmittingVehicle = true;
    notifyListeners();
    try {
      final vehicle = await _dataSource.updateVehicle(
        id,
        type: type,
        brand: brand,
        model: model,
        year: year,
        plateNumber: plateNumber,
        color: color,
        photoPath: photoPath,
      );
      final index = _vehicles.indexWhere((item) => item.id == id);
      if (index >= 0) _vehicles[index] = vehicle;
      return true;
    } catch (_) {
      return false;
    } finally {
      _isSubmittingVehicle = false;
      notifyListeners();
    }
  }

  Future<bool> deleteVehicle(String id) async {
    try {
      await _dataSource.deleteVehicle(id);
      _vehicles.removeWhere((item) => item.id == id);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> setPrimaryVehicle(String id) async {
    try {
      await _dataSource.setPrimaryVehicle(id);
      await fetchVehicles();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> fetchDocuments() async {
    _documentStatus = DocumentStatus.loading;
    notifyListeners();
    try {
      _documents = await _dataSource.getDocuments();
      _documentStatus = DocumentStatus.loaded;
    } catch (_) {
      _documentStatus = DocumentStatus.error;
    }
    notifyListeners();
  }

  Future<bool> uploadDocument({
    required String type,
    required String filePath,
    String? fileName,
    DateTime? expiryDate,
  }) async {
    try {
      final document = await _dataSource.uploadDocument(
        type: type,
        filePath: filePath,
        fileName: fileName,
        expiryDate: expiryDate,
      );
      final index = _documents.indexWhere((item) => item.type == type);
      if (index >= 0) {
        _documents[index] = document;
      } else {
        _documents.add(document);
      }
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteDocument(String id) async {
    try {
      await _dataSource.deleteDocument(id);
      _documents.removeWhere((item) => item.id == id);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> fetchSettings() async {
    _settingsStatus = SettingsStatus.loading;
    notifyListeners();
    try {
      _settings = await _dataSource.getSettings();
      _settingsStatus = SettingsStatus.loaded;
    } catch (_) {
      _settingsStatus = SettingsStatus.error;
    }
    notifyListeners();
  }

  Future<void> updateSetting(String key, dynamic value) async {
    if (_settings == null) return;
    final updates = <String, dynamic>{key: value};
    _settings = _applySettingUpdate(_settings!, key, value);
    _settingsStatus = SettingsStatus.updating;
    notifyListeners();
    try {
      _settings = await _dataSource.updateSettings(updates);
      _settingsStatus = SettingsStatus.loaded;
      notifyListeners();
    } catch (_) {
      await fetchSettings();
    }
  }

  SettingsModel _applySettingUpdate(
    SettingsModel settings,
    String key,
    dynamic value,
  ) {
    switch (key) {
      case 'language':
        return settings.copyWith(language: value as String);
      case 'timezone':
        return settings.copyWith(timezone: value as String);
      case 'auto_save':
        return settings.copyWith(autoSave: value as bool);
      case 'notif_order':
        return settings.copyWith(notifOrder: value as bool);
      case 'notif_promo':
        return settings.copyWith(notifPromo: value as bool);
      case 'notif_community':
        return settings.copyWith(notifCommunity: value as bool);
      case 'notif_sos':
        return settings.copyWith(notifSOS: value as bool);
      case 'biometric_enabled':
        return settings.copyWith(biometricEnabled: value as bool);
      default:
        return settings;
    }
  }

  Future<bool> deleteAccount() async {
    try {
      return await _dataSource.deleteAccount();
    } catch (_) {
      return false;
    }
  }

  Future<void> checkOnboarding() async {
    if (_onboardingChecked) return;
    _onboardingChecked = true;
    final prefs = await SharedPreferences.getInstance();
    _showOnboarding = prefs.getBool('seen_onboarding') != true;
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    _showOnboarding = false;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seen_onboarding', true);
  }

  void logout() {
    _profile = null;
    _levelInfo = null;
    _referralInfo = null;
    _settings = null;
    _vehicles = [];
    _documents = [];
    _profileStatus = ProfileStatus.initial;
    _levelStatus = LevelStatus.initial;
    _referralStatus = ReferralStatus.initial;
    _settingsStatus = SettingsStatus.initial;
    _vehicleStatus = VehicleStatus.initial;
    _documentStatus = DocumentStatus.initial;
    _errorMessage = null;
    _referralError = null;
    notifyListeners();
  }
}
