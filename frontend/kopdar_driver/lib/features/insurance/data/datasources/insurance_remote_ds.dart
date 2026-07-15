import '../../../../core/network/api_client.dart';
import '../models/insurance_model.dart';

/// Remote data source for insurance API calls.
class InsuranceRemoteDataSource {
  final ApiClient _api;

  InsuranceRemoteDataSource({ApiClient? api}) : _api = api ?? ApiClient();

  /// List all available insurance products.
  Future<List<InsuranceProduct>> listProducts() async {
    final response = await _api.get('/api/v1/insurance/products');
    final data = response.data['data'] ?? response.data;
    if (data is List) {
      return data
          .map((e) => InsuranceProduct.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    final items = data['items'] ?? data['products'] ?? [];
    return (items as List)
        .map((e) => InsuranceProduct.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Get detail of a single insurance product.
  Future<InsuranceProduct> getProduct(String id) async {
    final response = await _api.get('/api/v1/insurance/products/$id');
    return InsuranceProduct.fromJson(response.data['data'] ?? response.data);
  }

  /// Purchase a policy for a product.
  Future<InsurancePolicy> purchasePolicy({
    required String productId,
    required Map<String, dynamic> additionalData,
    required String paymentMethod,
  }) async {
    final response = await _api.post(
      '/api/v1/insurance/products/$productId/purchase',
      data: {
        'additional_data': additionalData,
        'payment_method': paymentMethod,
      },
    );
    return InsurancePolicy.fromJson(response.data['data'] ?? response.data);
  }

  /// List all policies (active, expired, cancelled).
  Future<List<InsurancePolicy>> listPolicies() async {
    final response = await _api.get('/api/v1/insurance/policies');
    final data = response.data['data'] ?? response.data;
    if (data is List) {
      return data
          .map((e) => InsurancePolicy.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    final items = data['items'] ?? data['policies'] ?? [];
    return (items as List)
        .map((e) => InsurancePolicy.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Get detail of a single policy.
  Future<InsurancePolicy> getPolicy(String id) async {
    final response = await _api.get('/api/v1/insurance/policies/$id');
    return InsurancePolicy.fromJson(response.data['data'] ?? response.data);
  }

  /// Renew an expiring policy.
  Future<InsurancePolicy> renewPolicy(String policyId) async {
    final response =
        await _api.post('/api/v1/insurance/policies/$policyId/renew');
    return InsurancePolicy.fromJson(response.data['data'] ?? response.data);
  }

  /// File a claim against a policy.
  Future<InsuranceClaim> fileClaim({
    required String policyId,
    required String claimType,
    required String description,
    required List<String> evidenceUrls,
  }) async {
    final response = await _api.post(
      '/api/v1/insurance/claims',
      data: {
        'policy_id': policyId,
        'claim_type': claimType,
        'description': description,
        'evidence_urls': evidenceUrls,
      },
    );
    return InsuranceClaim.fromJson(response.data['data'] ?? response.data);
  }

  /// List all claims.
  Future<List<InsuranceClaim>> listClaims() async {
    final response = await _api.get('/api/v1/insurance/claims');
    final data = response.data['data'] ?? response.data;
    if (data is List) {
      return data
          .map((e) => InsuranceClaim.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    final items = data['items'] ?? data['claims'] ?? [];
    return (items as List)
        .map((e) => InsuranceClaim.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Get detail of a single claim.
  Future<InsuranceClaim> getClaim(String id) async {
    final response = await _api.get('/api/v1/insurance/claims/$id');
    return InsuranceClaim.fromJson(response.data['data'] ?? response.data);
  }
}
