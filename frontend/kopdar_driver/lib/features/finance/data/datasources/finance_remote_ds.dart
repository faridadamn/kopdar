import '../../../../core/network/api_client.dart';
import '../models/hourly_rate_model.dart';
import '../models/insight_model.dart';

/// Remote data source for finance-related API calls.
class FinanceRemoteDataSource {
  final ApiClient _api;

  FinanceRemoteDataSource({ApiClient? api}) : _api = api ?? ApiClient();

  /// Get hourly rate data for the given period.
  /// [period] can be: 'today', 'week', 'month'
  Future<HourlyRateModel> getHourlyRate(String period) async {
    final response = await _api.get(
      '/api/v1/driver/hourly-rate',
      queryParameters: {'period': period},
    );
    return HourlyRateModel.fromJson(response.data['data'] ?? response.data);
  }

  /// Get financial insights for the driver.
  Future<List<InsightModel>> getInsights() async {
    final response = await _api.get('/api/v1/driver/insights');
    final data = response.data['data'] ?? response.data;
    if (data is List) {
      return data
          .map((e) => InsightModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    final items = data['insights'] ?? data['items'] ?? [];
    return (items as List)
        .map((e) => InsightModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Export financial data as a list of maps (for CSV generation).
  /// [type] can be: 'all', 'income', 'expense'
  Future<List<Map<String, dynamic>>> exportData({
    required DateTime dateFrom,
    required DateTime dateTo,
    required String type,
  }) async {
    final response = await _api.get(
      '/api/v1/driver/export',
      queryParameters: {
        'date_from': dateFrom.toIso8601String(),
        'date_to': dateTo.toIso8601String(),
        'type': type,
      },
    );
    final data = response.data['data'] ?? response.data;
    if (data is List) {
      return data.cast<Map<String, dynamic>>();
    }
    final items = data['items'] ?? data['transactions'] ?? [];
    return (items as List).cast<Map<String, dynamic>>();
  }
}
