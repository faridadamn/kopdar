import 'package:flutter/material.dart';

import 'package:kopdar_driver/features/savings/data/datasources/saving_remote_ds.dart';
import 'package:kopdar_driver/features/savings/data/models/saving_model.dart';

enum SavingStatus { initial, loading, loaded, error }

class SavingProvider extends ChangeNotifier {
  final SavingRemoteDataSource _dataSource;

  SavingProvider({SavingRemoteDataSource? dataSource})
      : _dataSource = dataSource ?? SavingRemoteDataSource();

  SavingStatus _status = SavingStatus.initial;
  SavingStatus _detailStatus = SavingStatus.initial;
  List<SavingModel> _goals = [];
  SavingModel? _selectedGoal;
  String? _errorMessage;
  bool _isSubmitting = false;

  SavingStatus get status => _status;
  SavingStatus get detailStatus => _detailStatus;
  List<SavingModel> get goals => List<SavingModel>.unmodifiable(_goals);
  SavingModel? get selectedGoal => _selectedGoal;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == SavingStatus.loading;
  bool get isSubmitting => _isSubmitting;

  double get totalSaved =>
      _goals.fold<double>(0, (sum, goal) => sum + goal.currentAmount);

  double get totalTarget =>
      _goals.fold<double>(0, (sum, goal) => sum + goal.targetAmount);

  double get overallProgress => totalTarget > 0 ? totalSaved / totalTarget : 0;

  List<SavingModel> get activeGoals =>
      _goals.where((goal) => goal.isActive).toList(growable: false);

  Future<void> fetchGoals() async {
    _status = SavingStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _goals = await _dataSource.listGoals();
      _status = SavingStatus.loaded;
    } catch (_) {
      _status = SavingStatus.error;
      _errorMessage = 'Gagal memuat tabungan. Coba lagi.';
    } finally {
      notifyListeners();
    }
  }

  Future<void> fetchGoalDetail(String id) async {
    _detailStatus = SavingStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final goal = await _dataSource.getGoal(id);
      _selectedGoal = goal;
      _detailStatus = SavingStatus.loaded;
      _updateGoalInList(goal);
    } catch (_) {
      _detailStatus = SavingStatus.error;
      _errorMessage = 'Gagal memuat detail tabungan.';
    } finally {
      notifyListeners();
    }
  }

  Future<bool> createGoal({
    required String goalName,
    required String goalIcon,
    required double targetAmount,
    required double dailyAmount,
    required bool autoSave,
  }) async {
    return _runSubmission(
      action: () async {
        final goal = await _dataSource.createGoal(
          goalName: goalName,
          goalIcon: goalIcon,
          targetAmount: targetAmount,
          dailyAmount: dailyAmount,
          autoSave: autoSave,
        );
        _goals.insert(0, goal);
      },
      errorMessage: 'Gagal membuat tabungan.',
    );
  }

  Future<bool> deposit(String id, double amount, {String? notes}) async {
    return _runSubmission(
      action: () async {
        final updated = await _dataSource.deposit(
          id,
          amount: amount,
          notes: notes,
        );
        _updateGoalInState(updated);
      },
      errorMessage: 'Gagal melakukan setor.',
    );
  }

  Future<bool> withdraw(String id, double amount, {String? notes}) async {
    return _runSubmission(
      action: () async {
        final updated = await _dataSource.withdraw(
          id,
          amount: amount,
          notes: notes,
        );
        _updateGoalInState(updated);
      },
      errorMessage: 'Gagal melakukan penarikan.',
    );
  }

  Future<bool> pauseGoal(String id) async {
    return _runMutation(
      action: () => _dataSource.pause(id),
      errorMessage: 'Gagal menjeda tabungan.',
    );
  }

  Future<bool> resumeGoal(String id) async {
    return _runMutation(
      action: () => _dataSource.resume(id),
      errorMessage: 'Gagal melanjutkan tabungan.',
    );
  }

  Future<bool> _runSubmission({
    required Future<void> Function() action,
    required String errorMessage,
  }) async {
    if (_isSubmitting) return false;

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await action();
      return true;
    } catch (_) {
      _errorMessage = errorMessage;
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> _runMutation({
    required Future<SavingModel> Function() action,
    required String errorMessage,
  }) async {
    _errorMessage = null;
    try {
      final updated = await action();
      _updateGoalInState(updated);
      notifyListeners();
      return true;
    } catch (_) {
      _errorMessage = errorMessage;
      notifyListeners();
      return false;
    }
  }

  void _updateGoalInState(SavingModel updated) {
    _selectedGoal = updated;
    _updateGoalInList(updated);
  }

  void _updateGoalInList(SavingModel updated) {
    final index = _goals.indexWhere((goal) => goal.id == updated.id);
    if (index != -1) {
      _goals[index] = updated;
    }
  }
}
