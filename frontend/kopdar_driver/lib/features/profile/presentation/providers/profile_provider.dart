import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/profile_model.dart';
import '../data/models/vehicle_model.dart';
import '../data/datasources/profile_remote_ds.dart';

enum ProfileStatus { initial, loading, loaded, error }
enum LevelStatus { initial, loading, loaded, error }
enum ReferralStatus { initial, loading, loaded, applying, error }
enum SettingsStatus { initial, loading, loaded, updating, error }
enum VehicleStatus { initial, loading, loaded, error }
enum DocumentStatus { initial, loading, loaded, error }

/// Provider for the entire Profile feature area.
class ProfileProvider extends ChangeNotifier {
  final ProfileRemoteDataSource _dataSource;

  ProfileProvider({ProfileRemoteDataSource? dataSource})
      : _dataSource = dataSource ?? ProfileRemoteDataSource();

  // ── Profile state ──
  ProfileStatus _profileStatus = ProfileStatus.initial;
  ProfileModel? _profile;
  String? _errorMessage;

  ProfileStatus get profileStatus => _profileStatus;
  ProfileModel? get profile => _profile;
  String? get errorMessage => _errorMessage;
  bool get isProfileLoading => _profileStatus == ProfileStatus.loading;

  // ── Level state ──
  LevelStatus _levelStatus = LevelStatus.initial;
  LevelInfo? _levelInfo;

  LevelStatus get levelStatus => _levelStatus;
  LevelInfo? get levelInfo => _levelInfo;
  bool get isLevelLoading => _levelStatus == LevelStatus.loading;

  // ── Referral state ──
  ReferralStatus _referralStatus = ReferralStatus.initial;
  ReferralInfo? _referralInfo;
  String? _referralError;

  ReferralStatus get referralStatus => _referralStatus;
  ReferralInfo? get referralInfo => _referralInfo;
  String? get referralError => _referralError;
  bool get isReferralLoading => _referralStatus == ReferralStatus.loading;

  // ── Settings state ──
  SettingsStatus _settingsStatus = SettingsStatus.initial;
  SettingsModel? _settings;

  SettingsStatus get settingsStatus => _settingsStatus;
  SettingsModel? get settings => _settings;
  bool get isSettingsLoading => _settingsStatus == SettingsStatus.loading;

  // ── Vehicle state ──
  VehicleStatus _vehicleStatus = VehicleStatus.initial;
  List<VehicleModel> _vehicles = [];
  bool _isSubmittingVehicle = false;

  VehicleStatus get vehicleStatus => _vehicleStatus;
  List<VehicleModel> get vehicles => _vehicles;
  bool get isVehicleLoading => _vehicleStatus == VehicleStatus.loading;
  bool get isSubmittingVehicle => _isSubmittingVehicle;
  VehicleModel? get primaryVehicle =>
      _vehicles.where((v) => v.isPrimary).firstOrNull;

  // ── Document state ──
  DocumentStatus _documentStatus = DocumentStatus.initial;
  List<DocumentModel> _documents = [];

  DocumentStatus get documentStatus => _documentStatus;
  List<DocumentModel> get documents => _documents;
  bool get isDocumentLoading => _documentStatus == DocumentStatus.loading;

  // ── Onboarding state ──
  bool _showOnboarding = false;
  bool _onboardingChecked = false;

  bool get showOnboarding => _showOnboarding;

  // ═══════════════════════════════════════
  //  PROFILE ACTIONS
  // ═══════════════════════════════════════

  Future<void> fetchProfile() async {
    _profileStatus = ProfileStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _profile = await _dataSource.getProfile();
      _profileStatus = ProfileStatus.loaded;
      notifyListeners();
    } catch (e) {
      _profileStatus = ProfileStatus.error;
      _errorMessage = 'Gagal memuat profil. Coba lagi.';
      notifyListeners();
    }
  }

  Future<bool> updateProfile({String? name, String? email}) async {
    try {
      _profile = await _dataSource.updateProfile(
        name: name,
        email: email,
      );
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Gagal memperbarui profil.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updatePhoto(String filePath) async {
    try {
      final url = await _dataSource.updatePhoto(filePath);
      if (_profile != null) {
        _profile = ProfileModel(
          id: _profile!.id,
          name: _profile!.name,
          phone: _profile!.phone,
          email: _profile!.email,
          photoUrl: url,
          memberId: _profile!.memberId,
          level: _profile!.level,
          points: _profile!.points,
          totalOrders: _profile!.totalOrders,
          activeDays: _profile!.activeDays,
          rating: _profile!.rating,
          memberSince: _profile!.memberSince,
          levelInfo: _profile!.levelInfo,
          referralInfo: _profile!.referralInfo,
        );
        notifyListeners();
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  // ═══════════════════════════════════════
  //  LEVEL ACTIONS
  // ═══════════════════════════════════════

  Future<void> fetchLevel() async {
    _levelStatus = LevelStatus.loading;
    notifyListeners();

    try {
      _levelInfo = await _dataSource.getLevel();
      _levelStatus = LevelStatus.loaded;
      notifyListeners();
    } catch (e) {
      _levelStatus = LevelStatus.error;
      notifyListeners();
    }
  }

  // ═══════════════════════════════════════
  //  REFERRAL ACTIONS
  // ═══════════════════════════════════════

  Future<void> fetchReferral() async {
    _referralStatus = ReferralStatus.loading;
    _referralError = null;
    notifyListeners();

    try {
      _referralInfo = await _dataSource.getReferral();
      _referralStatus = ReferralStatus.loaded;
      notifyListeners();
    } catch (e) {
      _referralStatus = ReferralStatus.error;
      _referralError = 'Gagal memuat data referral.';
      notifyListeners();
    }
  }

  Future<bool> applyReferralCode(String code) async {
    _referralStatus = ReferralStatus.applying;
    _referralError = null;
    notifyListeners();

    try {
      await _dataSource.applyReferralCode(code);
      await fetchReferral();
      return true;
    } catch (e) {
      _referralStatus = ReferralStatus.error;
      _referralError = 'Kode referral tidak valid atau sudah digunakan.';
      notifyListeners();
      return false;
    }
  }

  // ═══════════════════════════════════════
  //  VEHICLE ACTIONS
  // ═══════════════════════════════════════

  Future<void> fetchVehicles() async {
    _vehicleStatus = VehicleStatus.loading;
    notifyListeners();

    try {
      _vehicles = await _dataSource.getVehicles();
      _vehicleStatus = VehicleStatus.loaded;
      notifyListeners();
    } catch (e) {
      _vehicleStatus = VehicleStatus.error;
      notifyListeners();
    }
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
      _isSubmittingVehicle = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isSubmittingVehicle = false;
      notifyListeners();
      return false;
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
      final index = _vehicles.indexWhere((v) => v.id == id);
      if (index != -1) _vehicles[index] = vehicle;
      _isSubmittingVehicle = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isSubmittingVehicle = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteVehicle(String id) async {
    try {
      await _dataSource.deleteVehicle(id);
      _vehicles.removeWhere((v) => v.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> setPrimaryVehicle(String id) async {
    try {
      await _dataSource.setPrimaryVehicle(id);
      // Update local state
      _vehicles = _vehicles.map((v) {
        return VehicleModel(
          id: v.id,
          type: v.type,
          brand: v.brand,
          model: v.model,
          year: v.year,
          plateNumber: v.plateNumber,
          color: v.color,
          photoUrl: v.photoUrl,
          isPrimary: v.id == id,
          createdAt: v.createdAt,
        );
      }).toList();
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  // ═══════════════════════════════════════
  //  DOCUMENT ACTIONS
  // ═══════════════════════════════════════

  Future<void> fetchDocuments() async {
    _documentStatus = DocumentStatus.loading;
    notifyListeners();

    try {
      _documents = await _dataSource.getDocuments();
      _documentStatus = DocumentStatus.loaded;
      notifyListeners();
    } catch (e) {
      _documentStatus = DocumentStatus.error;
      notifyListeners();
    }
  }

  Future<bool> uploadDocument({
    required String type,
    required String filePath,
    String? fileName,
    DateTime? expiryDate,
  }) async {
    try {
      final doc = await _dataSource.uploadDocument(
        type: type,
        filePath: filePath,
        fileName: fileName,
        expiryDate: expiryDate,
      );
      // Replace if same type exists, otherwise add
      final index = _documents.indexWhere((d) => d.type == type);
      if (index != -1) {
        _documents[index] = doc;
      } else {
        _documents.add(doc);
      }
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteDocument(String id) async {
    try {
      await _dataSource.deleteDocument(id);
      _documents.removeWhere((d) => d.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  // ═══════════════════════════════════════
  //  SETTINGS ACTIONS
  // ═══════════════════════════════════════

  Future<void> fetchSettings() async {
    _settingsStatus = SettingsStatus.loading;
    notifyListeners();

    try {
      _settings = await _dataSource.getSettings();
      _settingsStatus = SettingsStatus.loaded;
      notifyListeners();
    } catch (e) {
      _settingsStatus = SettingsStatus.error;
      notifyListeners();
    }
  }

  Future<void> updateSetting(String key, dynamic value) async {
    if (_settings == null) return;

    // Optimistic update
    final updates = <String, dynamic>{key: value};
    _settings = _applySettingUpdate(_settings!, key, value);
    _settingsStatus = SettingsStatus.updating;
    notifyListeners();

    try {
      _settings = await _dataSource.updateSettings(updates);
      _settingsStatus = SettingsStatus.loaded;
      notifyListeners();
    } catch (e) {
      // Revert on error
      await fetchSettings();
    }
  }

  SettingsModel _applySettingUpdate(
      SettingsModel s, String key, dynamic value) {
    switch (key) {
      case 'language':
        return s.copyWith(language: value as String);
      case 'timezone':
        return s.copyWith(timezone: value as String);
      case 'auto_save':
        return s.copyWith(autoSave: value as bool);
      case 'notif_order':
        return s.copyWith(notifOrder: value as bool);
      case 'notif_promo':
        return s.copyWith(notifPromo: value as bool);
      case 'notif_community':
        return s.copyWith(notifCommunity: value as bool);
      case 'notif_sos':
        return s.copyWith(notifSOS: value as bool);
      case 'biometric_enabled':
        return s.copyWith(biometricEnabled: value as bool);
      default:
        return s;
    }
  }

  Future<bool> deleteAccount() async {
    try {
      return await _dataSource.deleteAccount();
    } catch (e) {
      return false;
    }
  }

  // ═══════════════════════════════════════
  //  ONBOARDING
  // ═══════════════════════════════════════

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

  /// Logout — clears all state.
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
    notifyListeners();
  }
}
