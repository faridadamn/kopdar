import 'package:flutter/material.dart';

import 'package:kopdar_driver/features/pinjol/data/datasources/pinjol_remote_ds.dart';
import 'package:kopdar_driver/features/pinjol/data/models/pinjol_model.dart';

enum PinjolStatus { initial, loading, loaded, error }

class PinjolProvider extends ChangeNotifier {
  final PinjolRemoteDataSource _dataSource;

  PinjolProvider({PinjolRemoteDataSource? dataSource})
      : _dataSource = dataSource ?? PinjolRemoteDataSource();

  PinjolStatus _status = PinjolStatus.initial;
  PinjolStatus _detailStatus = PinjolStatus.initial;
  List<PinjolModel> _loans = [];
  PinjolModel? _selectedLoan;
  PayoffSimulation? _simulation;
  String? _errorMessage;
  bool _isSubmitting = false;
  int _simulationMonths = 3;

  PinjolStatus get status => _status;
  PinjolStatus get detailStatus => _detailStatus;
  List<PinjolModel> get loans => List.unmodifiable(_loans);
  PinjolModel? get selectedLoan => _selectedLoan;
  PayoffSimulation? get simulation => _simulation;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == PinjolStatus.loading;
  bool get isSubmitting => _isSubmitting;
  int get simulationMonths => _simulationMonths;

  double get totalOutstanding =>
      _loans.fold(0, (sum, loan) => sum + loan.outstandingAmount);
  double get totalMonthlyInstallment =>
      _loans.fold(0, (sum, loan) => sum + loan.monthlyInstallment);
  int get safeCount => _loans.where((loan) => loan.isSafe).length;
  int get warningCount => _loans.where((loan) => loan.isWarning).length;
  int get dangerCount => _loans.where((loan) => loan.isDanger).length;

  double get debtToIncomeRatio {
    const estimatedMonthlyIncome = 4500000.0;
    return totalMonthlyInstallment / estimatedMonthlyIncome;
  }

  bool get isDebtRatioWarning => debtToIncomeRatio > 0.3;

  List<String> get recommendations {
    final recommendations = <String>[];
    if (dangerCount > 0) {
      recommendations.add(
        '🔴 Ada $dangerCount pinjaman berisiko tinggi! Prioritaskan lunasi segera.',
      );
    }
    if (isDebtRatioWarning) {
      recommendations.add(
        '⚠️ Rasio cicilan/penghasilan ${(debtToIncomeRatio * 100).round()}%. Idealnya di bawah 30%.',
      );
    }
    if (warningCount > 0) {
      recommendations.add(
        '🟡 $warningCount pinjaman perlu perhatian. Pertimbangkan bayar lebih.',
      );
    }
    if (_loans.isEmpty) {
      recommendations.add('🎉 Tidak ada pinjaman aktif. Pertahankan!');
    }
    return recommendations;
  }

  Future<void> fetchLoans() async {
    _status = PinjolStatus.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      _loans = await _dataSource.list();
      _status = PinjolStatus.loaded;
    } catch (_) {
      _status = PinjolStatus.error;
      _errorMessage = 'Gagal memuat data pinjaman. Coba lagi.';
    }
    notifyListeners();
  }

  Future<void> fetchLoanDetail(String id) async {
    _detailStatus = PinjolStatus.loading;
    _simulation = null;
    _errorMessage = null;
    notifyListeners();
    try {
      final loan = await _dataSource.get(id);
      _selectedLoan = loan;
      _detailStatus = PinjolStatus.loaded;
      final index = _loans.indexWhere((item) => item.id == id);
      if (index >= 0) _loans[index] = loan;
    } catch (_) {
      _detailStatus = PinjolStatus.error;
      _errorMessage = 'Gagal memuat detail pinjaman.';
    }
    notifyListeners();
  }

  Future<bool> createLoan({
    required String appName,
    required double principal,
    required double interestRate,
    required double monthlyInstallment,
    required DateTime startDate,
    DateTime? endDate,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final loan = await _dataSource.create(
        appName: appName,
        principal: principal,
        interestRate: interestRate,
        monthlyInstallment: monthlyInstallment,
        startDate: startDate,
        endDate: endDate,
      );
      _loans.insert(0, loan);
      return true;
    } catch (_) {
      _errorMessage = 'Gagal menyimpan pinjaman.';
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> deleteLoan(String id) async {
    final index = _loans.indexWhere((loan) => loan.id == id);
    final removed = index >= 0 ? _loans.removeAt(index) : null;
    notifyListeners();
    try {
      await _dataSource.delete(id);
      if (_selectedLoan?.id == id) _selectedLoan = null;
      notifyListeners();
      return true;
    } catch (_) {
      if (removed != null && index >= 0) _loans.insert(index, removed);
      _errorMessage = 'Gagal menghapus pinjaman.';
      notifyListeners();
      return false;
    }
  }

  Future<void> setSimulationMonths(int months) async {
    _simulationMonths = months;
    final loan = _selectedLoan;
    if (loan != null) await fetchSimulation(loan.id, months);
    notifyListeners();
  }

  Future<void> fetchSimulation(String id, int months) async {
    try {
      _simulation = await _dataSource.simulate(id, months: months);
    } catch (_) {
      _simulation = null;
    }
    notifyListeners();
  }
}
