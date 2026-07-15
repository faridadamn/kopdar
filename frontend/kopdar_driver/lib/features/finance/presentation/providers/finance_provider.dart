import 'package:flutter/material.dart';

import 'package:kopdar_driver/features/finance/data/datasources/finance_remote_ds.dart';
import 'package:kopdar_driver/features/finance/data/models/hourly_rate_model.dart';
import 'package:kopdar_driver/features/finance/data/models/insight_model.dart';

enum FinanceStatus { initial, loading, loaded, error }

class FinanceProvider extends ChangeNotifier {
  final FinanceRemoteDataSource _dataSource;

  FinanceProvider({FinanceRemoteDataSource? dataSource})
      : _dataSource = dataSource ?? FinanceRemoteDataSource();

  FinanceStatus _hourlyRateStatus = FinanceStatus.initial;
  FinanceStatus _insightsStatus = FinanceStatus.initial;
  FinanceStatus _exportStatus = FinanceStatus.initial;

  HourlyRateModel? _hourlyRate;
  List<InsightModel> _insights = [];
  List<Map<String, dynamic>> _exportRows = [];

  String? _errorMessage;
  String _hourlyRatePeriod = 'today';

  FinanceStatus get hourlyRateStatus => _hourlyRateStatus;
  FinanceStatus get insightsStatus => _insightsStatus;
  FinanceStatus get exportStatus => _exportStatus;

  HourlyRateModel? get hourlyRate => _hourlyRate;
  List<InsightModel> get insights => List.unmodifiable(_insights);
  List<Map<String, dynamic>> get exportRows => List.unmodifiable(_exportRows);

  String? get errorMessage => _errorMessage;
  String get hourlyRatePeriod => _hourlyRatePeriod;

  bool get isLoadingHourlyRate => _hourlyRateStatus == FinanceStatus.loading;
  bool get isLoadingInsights => _insightsStatus == FinanceStatus.loading;
  bool get isExporting => _exportStatus == FinanceStatus.loading;

  Future<void> fetchHourlyRate(String period) async {
    _hourlyRatePeriod = period;
    _hourlyRateStatus = FinanceStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _hourlyRate = await _dataSource.getHourlyRate(period);
      _hourlyRateStatus = FinanceStatus.loaded;
    } catch (_) {
      _hourlyRateStatus = FinanceStatus.error;
      _errorMessage = 'Gagal memuat data tarif per jam.';
    } finally {
      notifyListeners();
    }
  }

  Future<void> fetchInsights() async {
    _insightsStatus = FinanceStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _insights = await _dataSource.getInsights();
      _insightsStatus = FinanceStatus.loaded;
    } catch (_) {
      _insightsStatus = FinanceStatus.error;
      _errorMessage = 'Gagal memuat insight.';
    } finally {
      notifyListeners();
    }
  }

  Future<bool> exportData({
    required DateTime dateFrom,
    required DateTime dateTo,
    required String type,
  }) async {
    if (isExporting) return false;

    _exportStatus = FinanceStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _exportRows = await _dataSource.exportData(
        dateFrom: dateFrom,
        dateTo: dateTo,
        type: type,
      );
      _exportStatus = FinanceStatus.loaded;
      return true;
    } catch (_) {
      _exportStatus = FinanceStatus.error;
      _errorMessage = 'Gagal export data.';
      return false;
    } finally {
      notifyListeners();
    }
  }

  String generateCsv() {
    if (_exportRows.isEmpty) return '';

    final headers = _exportRows.first.keys.toList();
    final buffer = StringBuffer()..writeln(headers.join(','));

    for (final row in _exportRows) {
      final values = headers.map((header) {
        final value = row[header]?.toString() ?? '';
        if (value.contains(',') || value.contains('"')) {
          return '"${value.replaceAll('"', '""')}"';
        }
        return value;
      });
      buffer.writeln(values.join(','));
    }

    return buffer.toString();
  }
}
