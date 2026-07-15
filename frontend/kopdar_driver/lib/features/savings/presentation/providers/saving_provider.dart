import 'package:flutter/material.dart';
import '../data/models/saving_model.dart';
import '../data/datasources/saving_remote_ds.dart';

enum SavingStatus { initial, loading, loaded, error }

class SavingProvider extends ChangeNotifier {
  final SavingRemoteDataSource _dataSource;

  SavingProvider({SavingRemoteDataSource? dataSource})
      : _dataSource = dataSource ?? SavingRemoteDataSource();

  // ── State ──
  SavingStatus _status = SavingStatus.initial;
  SavingStatus _detailStatus = SavingStatus.initial;
  List<SavingModel> _goals = [];
  SavingModel? _selectedGoal;
  String? _errorMessage;
  bool _isSubmitting = false;

  // ── Getters ──
  SavingStatus get status => _status;
  SavingStatus get detailStatus => _detailStatus;
  List<SavingModel> get goals => _goals;
  SavingModel? get selectedGoal => _selectedGoal;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == SavingStatus.loading;
  bool get isSubmitting => _isSubmitting;

  // ── Derived ──
  double get totalSaved =>
      _goals.fold(0, (sum, g) => sum + g.currentAmount);

  double get totalTarget =>
      _goals.fold(0, (sum, g) => sum + g.targetAmount);

  double get overallProgress =>
      totalTarget > 0 ? totalSaved / totalTarget : 0;

  List<SavingModel> get activeGoals =>
      _goals.where((g) => g.isActive).toList();

  // ── Actions ──

  /// Fetch all savings goals.
  Future<void> fetchGoals() async {
    _status = SavingStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _goals = await _dataSource.listGoals();
      _status = SavingStatus.loaded;
      notifyListeners();
    } catch (e) {
      _status = SavingStatus.error;
      _errorMessage = 'Gagal memuat tabungan. Coba lagi.';
      notifyListeners();
    }
  }

  /// Fetch detail of a single goal.
  Future<void> fetchGoalDetail(String id) async {
    _detailStatus = SavingStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _selectedGoal = await _dataSource.getGoal(id);
      _detailStatus = SavingStatus.loaded;
      // Also update in list if present
      final index = _goals.indexWhere((g) => g.id == id);
      if (index != -1) {
        _goals[index] = _selectedGoal!;
      }
      notifyListeners();
    } catch (e) {
      _detailStatus = SavingStatus.error;
      _errorMessage = 'Gagal memuat detail tabungan.';
      notifyListeners();
    }
  }

  /// Create a new savings goal.
  Future<bool> createGoal({
    required String goalName,
    required String goalIcon,
    required double targetAmount,
    required double dailyAmount,
    required bool autoSave,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final goal = await _dataSource.createGoal(
        goalName: goalName,
        goalIcon: goalIcon,
        targetAmount: targetAmount,
        dailyAmount: dailyAmount,
        autoSave: autoSave,
      );
      _goals.insert(0, goal);
      _isSubmitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isSubmitting = false;
      _errorMessage = 'Gagal membuat tabungan.';
      notifyListeners();
      return false;
    }
  }

  /// Make a manual deposit.
  Future<bool> deposit(String id, double amount, {String? notes}) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = await _dataSource.deposit(id, amount: amount, notes: notes);
      _updateGoalInState(updated);
      _isSubmitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isSubmitting = false;
      _errorMessage = 'Gagal melakukan setor.';
      notifyListeners();
      return false;
    }
  }

  /// Make a withdrawal.
  Future<bool> withdraw(String id, double amount, {String? notes}) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = await _dataSource.withdraw(id, amount: amount, notes: notes);
      _updateGoalInState(updated);
      _isSubmitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isSubmitting = false;
      _errorMessage = 'Gagal melakukan penarikan.';
      notifyListeners();
      return false;
    }
  }

  /// Pause auto-save.
  Future<bool> pauseGoal(String id) async {
    try {
      final updated = await _dataSource.pause(id);
      _updateGoalInState(updated);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Gagal menjeda tabungan.';
      notifyListeners();
      return false;
    }
  }

  /// Resume auto-save.
  Future<bool> resumeGoal(String id) async {
    try {
      final updated = await _dataSource.resume(id);
      _updateGoalInState(updated);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Gagal melanjutkan tabungan.';
      notifyListeners();
      return false;
    }
  }

  void _updateGoalInState(SavingModel updated) {
    _selectedGoal = updated;
    final index = _goals.indexWhere((g) => g.id == updated.id);
    if (index != -1) {
      _goals[index] = updated;
    }
  }
}
