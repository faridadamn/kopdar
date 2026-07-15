import 'package:flutter/material.dart';
import '../data/models/pinjol_model.dart';
import '../data/datasources/pinjol_remote_ds.dart';

enum PinjolStatus { initial, loading, loaded, error }

class PinjolProvider extends ChangeNotifier {
  final PinjolRemoteDataSource _dataSource;

  PinjolProvider({PinjolRemoteDataSource? dataSource})
      : _dataSource = dataSource ?? PinjolRemoteDataSource();

  // ── State ──
  PinjolStatus _status = PinjolStatus.initial;
  PinjolStatus _detailStatus = PinjolStatus.initial;
  List<PinjolModel> _loans = [];
  PinjolModel? _selectedLoan;
  PayoffSimulation? _simulation;
  String? _errorMessage;
  bool _isSubmitting = false;
  int _simulationMonths = 3;

  // ── Getters ──
  PinjolStatus get status => _status;
  PinjolStatus get detailStatus => _detailStatus;
  List<PinjolModel> get loans => _loans;
  PinjolModel? get selectedLoan => _selectedLoan;
  PayoffSimulation? get simulation => _simulation;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == PinjolStatus.loading;
  bool get isSubmitting => _isSubmitting;
  int get simulationMonths => _simulationMonths;

  // ── Derived ──
  double get totalOutstanding =>
      _loans.fold(0, (sum, l) => sum + l.outstandingAmount);

  double get totalMonthlyInstallment =>
      _loans.fold(0, (sum, l) => sum + l.monthlyInstallment);

  int get safeCount => _loans.where((l) => l.isSafe).length;
  int get warningCount => _loans.where((l) => l.isWarning).length;
  int get dangerCount => _loans.where((l) => l.isDanger).length;

  /// Debt-to-income ratio (assumes ~Rp 150/day * 30 days = 4.5jt monthly).
  /// In production this should come from actual income data.
  double get debtToIncomeRatio {
    const estimatedMonthlyIncome = 4500000.0;
    if (estimatedMonthlyIncome <= 0) return 0;
    return totalMonthlyInstallment / estimatedMonthlyIncome;
  }

  bool get isDebtRatioWarning => debtToIncomeRatio > 0.3;

  List<String> get recommendations {
    final recs = <String>[];
    if (dangerCount > 0) {
      recs.add(
        '🔴 Ada $dangerCount pinjaman berisiko tinggi! Prioritaskan lunasi segera.',
      );
    }
    if (isDebtRatioWarning) {
      recs.add(
        '⚠️ Rasio cicilan/penghasilan ${(debtToIncomeRatio * 100).round()}%. '
        'Idealnya di bawah 30%.',
      );
    }
    if (warningCount > 0) {
      recs.add(
        '🟡 $warningCount pinjaman perlu perhatian. Pertimbangkan bayar lebih.',
      );
    }
    if (_loans.isEmpty) {
      recs.add('🎉 Tidak ada pinjaman aktif. Pertahankan!');
    }
    return recs;
  }

  // ── Actions ──

  /// Fetch all loans.
  Future<void> fetchLoans() async {
    _status = PinjolStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _loans = await _dataSource.list();
      _status = PinjolStatus.loaded;
      notifyListeners();
    } catch (e) {
      _status = PinjolStatus.error;
      _errorMessage = 'Gagal memuat data pinjaman. Coba lagi.';
      notifyListeners();
    }
  }

  /// Fetch detail of a single loan.
  Future<void> fetchLoanDetail(String id) async {
    _detailStatus = PinjolStatus.loading;
    _simulation = null;
    _errorMessage = null;
    notifyListeners();

    try {
      _selectedLoan = await _dataSource.get(id);
      _detailStatus = PinjolStatus.loaded;
      // Update in list
      final index = _loans.indexWhere((l) => l.id == id);
      if (index != -1) {
        _loans[index] = _selectedLoan!;
      }
      notifyListeners();
    } catch (e) {
      _detailStatus = PinjolStatus.error;
      _errorMessage = 'Gagal memuat detail pinjaman.';
      notifyListeners();
    }
  }

  /// Create a new loan.
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
      _isSubmitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isSubmitting = false;
      _errorMessage = 'Gagal menyimpan pinjaman.';
      notifyListeners();
      return false;
    }
  }

  /// Delete a loan.
  Future<bool> deleteLoan(String id) async {
    final index = _loans.indexWhere((l) => l.id == id);
    PinjolModel? removed;
    if (index != -1) {
      removed = _loans.removeAt(index);
      notifyListeners();
    }

    try {
      await _dataSource.delete(id);
      if (_selectedLoan?.id == id) {
        _selectedLoan = null;
      }
      notifyListeners();
      return true;
    } catch (e) {
      if (removed != null && index != -1) {
        _loans.insert(index, removed);
        notifyListeners();
      }
      _errorMessage = 'Gagal menghapus pinjaman.';
      notifyListeners();
      return false;
    }
  }

  /// Set simulation months and fetch simulation.
  Future<void> setSimulationMonths(int months) async {
    _simulationMonths = months;
    if (_selectedLoan != null) {
      await fetchSimulation(_selectedLoan!.id, months);
    }
    notifyListeners();
  }

  /// Fetch payoff simulation for a loan.
  Future<void> fetchSimulation(String id, int months) async {
    try {
      _simulation = await _dataSource.simulate(id, months: months);
      notifyListeners();
    } catch (e) {
      // Simulation is optional, fail silently
      _simulation = null;
      notifyListeners();
    }
  }
}
