import '../../../../core/network/api_client.dart';
import '../models/pinjol_model.dart';

/// Remote data source for pinjol (online loan) API calls.
class PinjolRemoteDataSource {
  final ApiClient _api;

  PinjolRemoteDataSource({ApiClient? api}) : _api = api ?? ApiClient();

  /// Create a new loan entry.
  Future<PinjolModel> create({
    required String appName,
    required double principal,
    required double interestRate,
    required double monthlyInstallment,
    required DateTime startDate,
    DateTime? endDate,
  }) async {
    final response = await _api.post(
      '/api/v1/pinjol',
      data: {
        'app_name': appName,
        'principal': principal,
        'interest_rate': interestRate,
        'monthly_installment': monthlyInstallment,
        'start_date': startDate.toIso8601String(),
        'end_date': endDate?.toIso8601String(),
      },
    );
    return PinjolModel.fromJson(response.data['data'] ?? response.data);
  }

  /// Get all loans.
  Future<List<PinjolModel>> list() async {
    final response = await _api.get('/api/v1/pinjol');
    final data = response.data['data'] ?? response.data;
    if (data is List) {
      return data
          .map((e) => PinjolModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    final items = data['items'] ?? data['loans'] ?? [];
    return (items as List)
        .map((e) => PinjolModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Get detail of a single loan.
  Future<PinjolModel> get(String id) async {
    final response = await _api.get('/api/v1/pinjol/$id');
    return PinjolModel.fromJson(response.data['data'] ?? response.data);
  }

  /// Update a loan entry.
  Future<PinjolModel> update(
    String id, {
    String? appName,
    double? principal,
    double? interestRate,
    double? monthlyInstallment,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final data = <String, dynamic>{};
    if (appName != null) data['app_name'] = appName;
    if (principal != null) data['principal'] = principal;
    if (interestRate != null) data['interest_rate'] = interestRate;
    if (monthlyInstallment != null) {
      data['monthly_installment'] = monthlyInstallment;
    }
    if (startDate != null) data['start_date'] = startDate.toIso8601String();
    if (endDate != null) data['end_date'] = endDate.toIso8601String();

    final response = await _api.put('/api/v1/pinjol/$id', data: data);
    return PinjolModel.fromJson(response.data['data'] ?? response.data);
  }

  /// Delete a loan entry.
  Future<void> delete(String id) async {
    await _api.delete('/api/v1/pinjol/$id');
  }

  /// Simulate early payoff for a loan.
  Future<PayoffSimulation> simulate(
    String id, {
    required int months,
  }) async {
    final response = await _api.post(
      '/api/v1/pinjol/$id/simulate',
      data: {'months': months},
    );
    return PayoffSimulation.fromJson(
        response.data['data'] ?? response.data);
  }
}
