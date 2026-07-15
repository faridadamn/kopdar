import '../../../../core/network/api_client.dart';
import '../models/saving_model.dart';

/// Remote data source for savings API calls.
class SavingRemoteDataSource {
  final ApiClient _api;

  SavingRemoteDataSource({ApiClient? api}) : _api = api ?? ApiClient();

  /// Create a new savings goal.
  Future<SavingModel> createGoal({
    required String goalName,
    required String goalIcon,
    required double targetAmount,
    required double dailyAmount,
    required bool autoSave,
  }) async {
    final response = await _api.post(
      '/api/v1/savings',
      data: {
        'goal_name': goalName,
        'goal_icon': goalIcon,
        'target_amount': targetAmount,
        'daily_amount': dailyAmount,
        'auto_save': autoSave,
      },
    );
    return SavingModel.fromJson(response.data['data'] ?? response.data);
  }

  /// Get all savings goals.
  Future<List<SavingModel>> listGoals() async {
    final response = await _api.get('/api/v1/savings');
    final data = response.data['data'] ?? response.data;
    if (data is List) {
      return data
          .map((e) => SavingModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    final items = data['items'] ?? data['goals'] ?? [];
    return (items as List)
        .map((e) => SavingModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Get detail of a single savings goal.
  Future<SavingModel> getGoal(String id) async {
    final response = await _api.get('/api/v1/savings/$id');
    return SavingModel.fromJson(response.data['data'] ?? response.data);
  }

  /// Update a savings goal.
  Future<SavingModel> updateGoal(
    String id, {
    String? goalName,
    String? goalIcon,
    double? targetAmount,
    double? dailyAmount,
    bool? autoSave,
  }) async {
    final data = <String, dynamic>{};
    if (goalName != null) data['goal_name'] = goalName;
    if (goalIcon != null) data['goal_icon'] = goalIcon;
    if (targetAmount != null) data['target_amount'] = targetAmount;
    if (dailyAmount != null) data['daily_amount'] = dailyAmount;
    if (autoSave != null) data['auto_save'] = autoSave;

    final response = await _api.put('/api/v1/savings/$id', data: data);
    return SavingModel.fromJson(response.data['data'] ?? response.data);
  }

  /// Make a manual deposit to a savings goal.
  Future<SavingModel> deposit(
    String id, {
    required double amount,
    String? notes,
  }) async {
    final response = await _api.post(
      '/api/v1/savings/$id/deposit',
      data: {
        'amount': amount,
        if (notes != null) 'notes': notes,
      },
    );
    return SavingModel.fromJson(response.data['data'] ?? response.data);
  }

  /// Make a withdrawal from a savings goal.
  Future<SavingModel> withdraw(
    String id, {
    required double amount,
    String? notes,
  }) async {
    final response = await _api.post(
      '/api/v1/savings/$id/withdraw',
      data: {
        'amount': amount,
        if (notes != null) 'notes': notes,
      },
    );
    return SavingModel.fromJson(response.data['data'] ?? response.data);
  }

  /// Pause auto-save for a goal.
  Future<SavingModel> pause(String id) async {
    final response = await _api.post('/api/v1/savings/$id/pause');
    return SavingModel.fromJson(response.data['data'] ?? response.data);
  }

  /// Resume auto-save for a goal.
  Future<SavingModel> resume(String id) async {
    final response = await _api.post('/api/v1/savings/$id/resume');
    return SavingModel.fromJson(response.data['data'] ?? response.data);
  }
}
