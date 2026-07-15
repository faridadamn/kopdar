import '../../../../core/network/api_client.dart';
import '../models/transaction_model.dart';

/// Remote data source for transaction API calls.
class TransactionRemoteDataSource {
  final ApiClient _api;

  TransactionRemoteDataSource({ApiClient? api}) : _api = api ?? ApiClient();

  /// Create a new transaction.
  Future<TransactionModel> createTransaction({
    required String type,
    required String category,
    String? platform,
    required double amount,
    double commission = 0,
    String? notes,
    String? receiptUrl,
    int orderCount = 1,
  }) async {
    final response = await _api.post(
      '/api/v1/transactions',
      data: {
        'type': type,
        'category': category,
        'platform': platform,
        'amount': amount,
        'commission': commission,
        'notes': notes,
        'receipt_url': receiptUrl,
        'order_count': orderCount,
      },
    );
    return TransactionModel.fromJson(response.data['data'] ?? response.data);
  }

  /// Get transactions with optional filters and pagination.
  Future<List<TransactionModel>> getTransactions({
    String? type,
    String? platform,
    DateTime? dateFrom,
    DateTime? dateTo,
    int page = 1,
    int limit = 20,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (type != null) queryParams['type'] = type;
    if (platform != null) queryParams['platform'] = platform;
    if (dateFrom != null) {
      queryParams['date_from'] = dateFrom.toIso8601String();
    }
    if (dateTo != null) {
      queryParams['date_to'] = dateTo.toIso8601String();
    }

    final response = await _api.get(
      '/api/v1/transactions',
      queryParameters: queryParams,
    );

    final data = response.data['data'] ?? response.data;
    if (data is List) {
      return data
          .map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    // If paginated response with items key
    final items = data['items'] ?? data['transactions'] ?? [];
    return (items as List)
        .map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Get detail of a single transaction.
  Future<TransactionModel> getTransactionDetail(String id) async {
    final response = await _api.get('/api/v1/transactions/$id');
    return TransactionModel.fromJson(response.data['data'] ?? response.data);
  }

  /// Update an existing transaction.
  Future<TransactionModel> updateTransaction(
    String id, {
    String? category,
    String? platform,
    double? amount,
    double? commission,
    String? notes,
    String? receiptUrl,
    int? orderCount,
  }) async {
    final data = <String, dynamic>{};
    if (category != null) data['category'] = category;
    if (platform != null) data['platform'] = platform;
    if (amount != null) data['amount'] = amount;
    if (commission != null) data['commission'] = commission;
    if (notes != null) data['notes'] = notes;
    if (receiptUrl != null) data['receipt_url'] = receiptUrl;
    if (orderCount != null) data['order_count'] = orderCount;

    final response = await _api.put('/api/v1/transactions/$id', data: data);
    return TransactionModel.fromJson(response.data['data'] ?? response.data);
  }

  /// Delete a transaction.
  Future<void> deleteTransaction(String id) async {
    await _api.delete('/api/v1/transactions/$id');
  }

  /// Get financial summary for a period.
  Future<Map<String, dynamic>> getSummary(String period) async {
    final response = await _api.get(
      '/api/v1/transactions/summary',
      queryParameters: {'period': period},
    );
    return response.data['data'] ?? response.data;
  }
}
