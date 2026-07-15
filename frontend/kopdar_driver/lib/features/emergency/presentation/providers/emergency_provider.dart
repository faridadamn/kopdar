import 'package:flutter/material.dart';
import '../../data/models/emergency_model.dart';
import '../../data/datasources/emergency_remote_ds.dart';

enum EmergencyStatus { initial, loading, loaded, error }

class EmergencyProvider extends ChangeNotifier {
  final EmergencyRemoteDataSource _dataSource;

  EmergencyProvider({EmergencyRemoteDataSource? dataSource})
      : _dataSource = dataSource ?? EmergencyRemoteDataSource();

  // ── State ──
  EmergencyStatus _status = EmergencyStatus.initial;
  EmergencyStatus _contactsStatus = EmergencyStatus.initial;
  EmergencyStatus _medicalStatus = EmergencyStatus.initial;
  EmergencyStatus _nearbyStatus = EmergencyStatus.initial;
  EmergencyStatus _historyStatus = EmergencyStatus.initial;

  EmergencyModel? _activeSOS;
  List<EmergencyContactModel> _contacts = [];
  DriverMedicalModel? _medicalInfo;
  List<NearbyDriverModel> _nearbyDrivers = [];
  List<EmergencyModel> _history = [];
  String? _errorMessage;

  // ── Getters ──
  EmergencyStatus get status => _status;
  EmergencyStatus get contactsStatus => _contactsStatus;
  EmergencyStatus get medicalStatus => _medicalStatus;
  EmergencyStatus get nearbyStatus => _nearbyStatus;
  EmergencyStatus get historyStatus => _historyStatus;

  EmergencyModel? get activeSOS => _activeSOS;
  bool get hasActiveSOS => _activeSOS != null;
  List<EmergencyContactModel> get contacts => _contacts;
  DriverMedicalModel? get medicalInfo => _medicalInfo;
  List<NearbyDriverModel> get nearbyDrivers => _nearbyDrivers;
  List<EmergencyModel> get history => _history;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == EmergencyStatus.loading;

  // ───────────────────── SOS ─────────────────────

  /// Check for an active SOS on startup.
  Future<void> checkActiveSOS() async {
    try {
      _activeSOS = await _dataSource.getActiveSOS();
      notifyListeners();
    } catch (_) {
      // No active SOS
    }
  }

  /// Trigger a new SOS.
  Future<bool> triggerSOS({
    required String type,
    String? description,
    double? latitude,
    double? longitude,
    String? address,
  }) async {
    _status = EmergencyStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _activeSOS = await _dataSource.triggerSOS(
        type: type,
        description: description,
        latitude: latitude,
        longitude: longitude,
        address: address,
      );
      _status = EmergencyStatus.loaded;
      notifyListeners();

      // Fetch nearby drivers after triggering SOS
      if (latitude != null && longitude != null) {
        fetchNearbyDrivers(latitude: latitude, longitude: longitude);
      }

      return true;
    } catch (e) {
      _status = EmergencyStatus.error;
      _errorMessage = 'Gagal mengirim sinyal darurat. Coba lagi.';
      notifyListeners();
      return false;
    }
  }

  /// Resolve the active SOS.
  Future<bool> resolveSOS() async {
    if (_activeSOS == null) return false;

    try {
      _activeSOS = await _dataSource.resolveSOS(_activeSOS!.id);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Gagal menyelesaikan darurat.';
      notifyListeners();
      return false;
    }
  }

  // ───────────────────── Contacts ─────────────────────

  /// Fetch emergency contacts.
  Future<void> fetchContacts() async {
    _contactsStatus = EmergencyStatus.loading;
    notifyListeners();

    try {
      _contacts = await _dataSource.listContacts();
      _contactsStatus = EmergencyStatus.loaded;
      notifyListeners();
    } catch (e) {
      _contactsStatus = EmergencyStatus.error;
      _errorMessage = 'Gagal memuat kontak darurat.';
      notifyListeners();
    }
  }

  /// Add a new emergency contact.
  Future<bool> addContact({
    required String name,
    required String phoneNumber,
    required String relation,
    bool isPrimary = false,
  }) async {
    try {
      final contact = await _dataSource.addContact(
        name: name,
        phoneNumber: phoneNumber,
        relation: relation,
        isPrimary: isPrimary,
      );
      _contacts.add(contact);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Gagal menambah kontak.';
      notifyListeners();
      return false;
    }
  }

  /// Delete an emergency contact.
  Future<bool> deleteContact(String id) async {
    try {
      await _dataSource.deleteContact(id);
      _contacts.removeWhere((c) => c.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Gagal menghapus kontak.';
      notifyListeners();
      return false;
    }
  }

  // ───────────────────── Medical ─────────────────────

  /// Fetch medical info.
  Future<void> fetchMedicalInfo() async {
    _medicalStatus = EmergencyStatus.loading;
    notifyListeners();

    try {
      _medicalInfo = await _dataSource.getMedicalInfo();
      _medicalStatus = EmergencyStatus.loaded;
      notifyListeners();
    } catch (e) {
      _medicalStatus = EmergencyStatus.error;
      _errorMessage = 'Gagal memuat info medis.';
      notifyListeners();
    }
  }

  /// Save medical info.
  Future<bool> saveMedicalInfo({
    String? bloodType,
    List<String>? allergies,
    List<String>? conditions,
    List<String>? medications,
    String? emergencyNotes,
    String? hospitalPreference,
  }) async {
    try {
      _medicalInfo = await _dataSource.saveMedicalInfo(
        bloodType: bloodType,
        allergies: allergies,
        conditions: conditions,
        medications: medications,
        emergencyNotes: emergencyNotes,
        hospitalPreference: hospitalPreference,
      );
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Gagal menyimpan info medis.';
      notifyListeners();
      return false;
    }
  }

  // ───────────────────── Nearby ─────────────────────

  /// Fetch nearby drivers.
  Future<void> fetchNearbyDrivers({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
  }) async {
    _nearbyStatus = EmergencyStatus.loading;
    notifyListeners();

    try {
      _nearbyDrivers = await _dataSource.getNearbyDrivers(
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
      );
      _nearbyStatus = EmergencyStatus.loaded;
      notifyListeners();
    } catch (e) {
      _nearbyStatus = EmergencyStatus.error;
      notifyListeners();
    }
  }

  // ───────────────────── History ─────────────────────

  /// Fetch emergency history.
  Future<void> fetchHistory({bool refresh = false}) async {
    if (refresh) _history = [];

    _historyStatus = EmergencyStatus.loading;
    notifyListeners();

    try {
      _history = await _dataSource.listEmergencies();
      _historyStatus = EmergencyStatus.loaded;
      notifyListeners();
    } catch (e) {
      _historyStatus = EmergencyStatus.error;
      _errorMessage = 'Gagal memuat riwayat darurat.';
      notifyListeners();
    }
  }
}
