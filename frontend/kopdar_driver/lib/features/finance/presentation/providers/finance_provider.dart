import 'package:flutter/material.dart';
import '../../data/datasources/finance_remote_ds.dart';
import '../../data/models/hourly_rate_model.dart';
import '../../data/models/insight_model.dart';

enum FinanceStatus { initial, loading, loaded, error }

class FinanceProvider extends ChangeNotifier {
  final FinanceRemoteDataSource _dataSource;

  FinanceProvider({FinanceRemoteDataSource? dataSource})
      : _dataSource = dataSource ?? FinanceRemoteDataSource();

  // ── State ──
  FinanceStatus _hourlyRateStatus = FinanceStatus.initial;
  FinanceStatus _insightsStatus = FinanceStatus.initial;
  FinanceStatus _exportStatus = FinanceStatus.initial;

  HourlyRateModel? _hourlyRate;
  List<InsightModel> _insights = [];
  List<Map<String, dynamic>> _exportData = [];

  String? _errorMessage;
  String _hourlyRatePeriod = 'today';

  // ── Getters ──
  FinanceStatus get hourlyRateStatus => _hourlyRateStatus;
  FinanceStatus get insightsStatus => _insightsStatus;
  FinanceStatus get exportStatus => _exportStatus;

  HourlyRateModel? get hourlyRate => _hourlyRate;
  List<InsightModel> get insights => _insights;
  List<Map<String, dynamic>> get exportData => _exportData;

  String? get errorMessage => _errorMessage;
  String get hourlyRatePeriod => _hourlyRatePeriod;

  bool get isLoadingHourlyRate => _hourlyRateStatus == FinanceStatus.loading;
  bool get isLoadingInsights => _insightsStatus == FinanceStatus.loading;
  bool get isExporting => _exportStatus == FinanceStatus.loading;

  // ── Actions ──

  /// Fetch hourly rate data for the given period.
  Future<void> fetchHourlyRate(String period) async {
    _hourlyRatePeriod = period;
    _hourlyRateStatus = FinanceStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _hourlyRate = await _dataSource.getHourlyRate(period);
      _hourlyRateStatus = FinanceStatus.loaded;
      notifyListeners();
    } catch (e) {
      _hourlyRateStatus = FinanceStatus.error;
      _errorMessage = 'Gagal memuat data tarif per jam.';
      notifyListeners();
    }
  }

  /// Fetch financial insights.
  Future<void> fetchInsights() async {
    _insightsStatus = FinanceStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _insights = await _dataSource.getInsights();
      _insightsStatus = FinanceStatus.loaded;
      notifyListeners();
    } catch (e) {
      _insightsStatus = FinanceStatus.error;
      _errorMessage = 'Gagal memuat insight.';
      notifyListeners();
    }
  }

  /// Export financial data for the given date range and type.
  Future<bool> exportData({
    required DateTime dateFrom,
    required DateTime dateTo,
    required String type,
  }) async {
    _exportStatus = FinanceStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _exportData = await _dataSource.exportData(
        dateFrom: dateFrom,
        dateTo: dateTo,
        type: type,
      );
      _exportStatus = FinanceStatus.loaded;
      notifyListeners();
      return true;
    } catch (e) {
      _exportStatus = FinanceStatus.error;
      _errorMessage = 'Gagal export data.';
      notifyListeners();
      return false;
    }
  }

  /// Generate CSV string from export data.
  String generateCsv() {
    if (_exportData.isEmpty) return '';

    final headers = _exportData.first.keys.toList();
    final buffer = StringBuffer();

    // Header row
    buffer.writeln(headers.join(','));

    // Data rows
    for (final row in _exportData) {
      final values = headers.map((h) {
        final value = row[h]?.toString() ?? '';
        // Escape commas and quotes in CSV
        if (value.contains(',') || value.contains('"')) {
          return '"${value.replaceAll('"', '""')}"';
        }
        return value;
      }).toList();
      buffer.writeln(values.join(','));
    }

    return buffer.toString();
  }
}
