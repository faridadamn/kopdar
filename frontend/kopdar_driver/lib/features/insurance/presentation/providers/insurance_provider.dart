import 'package:flutter/material.dart';
import '../data/models/insurance_model.dart';
import '../data/datasources/insurance_remote_ds.dart';

enum InsuranceStatus { initial, loading, loaded, error }

class InsuranceProvider extends ChangeNotifier {
  final InsuranceRemoteDataSource _dataSource;

  InsuranceProvider({InsuranceRemoteDataSource? dataSource})
      : _dataSource = dataSource ?? InsuranceRemoteDataSource();

  // ── State ──
  InsuranceStatus _status = InsuranceStatus.initial;
  InsuranceStatus _policiesStatus = InsuranceStatus.initial;
  InsuranceStatus _claimsStatus = InsuranceStatus.initial;
  List<InsuranceProduct> _products = [];
  List<InsurancePolicy> _policies = [];
  List<InsuranceClaim> _claims = [];
  InsuranceProduct? _selectedProduct;
  String? _errorMessage;
  bool _isSubmitting = false;

  // ── Getters ──
  InsuranceStatus get status => _status;
  InsuranceStatus get policiesStatus => _policiesStatus;
  InsuranceStatus get claimsStatus => _claimsStatus;
  List<InsuranceProduct> get products => _products;
  List<InsurancePolicy> get policies => _policies;
  List<InsuranceClaim> get claims => _claims;
  InsuranceProduct? get selectedProduct => _selectedProduct;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == InsuranceStatus.loading;
  bool get isSubmitting => _isSubmitting;

  // ── Derived ──
  List<InsurancePolicy> get activePolicies =>
      _policies.where((p) => p.isActive).toList();

  List<InsurancePolicy> get expiringPolicies =>
      _policies.where((p) => p.isExpiringSoon).toList();

  List<InsuranceClaim> get pendingClaims =>
      _claims.where((c) => c.isPending).toList();

  // ── Actions ──

  /// Fetch all insurance products.
  Future<void> fetchProducts() async {
    _status = InsuranceStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _products = await _dataSource.listProducts();
      _status = InsuranceStatus.loaded;
      notifyListeners();
    } catch (e) {
      _status = InsuranceStatus.error;
      _errorMessage = 'Gagal memuat produk asuransi. Coba lagi.';
      notifyListeners();
    }
  }

  /// Fetch detail of a single product.
  Future<void> fetchProductDetail(String id) async {
    _status = InsuranceStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _selectedProduct = await _dataSource.getProduct(id);
      _status = InsuranceStatus.loaded;
      // Update in list if present
      final index = _products.indexWhere((p) => p.id == id);
      if (index != -1) {
        _products[index] = _selectedProduct!;
      }
      notifyListeners();
    } catch (e) {
      _status = InsuranceStatus.error;
      _errorMessage = 'Gagal memuat detail produk.';
      notifyListeners();
    }
  }

  /// Fetch all policies.
  Future<void> fetchPolicies() async {
    _policiesStatus = InsuranceStatus.loading;
    notifyListeners();

    try {
      _policies = await _dataSource.listPolicies();
      _policiesStatus = InsuranceStatus.loaded;
      notifyListeners();
    } catch (e) {
      _policiesStatus = InsuranceStatus.error;
      _errorMessage = 'Gagal memuat polis. Coba lagi.';
      notifyListeners();
    }
  }

  /// Fetch all claims.
  Future<void> fetchClaims() async {
    _claimsStatus = InsuranceStatus.loading;
    notifyListeners();

    try {
      _claims = await _dataSource.listClaims();
      _claimsStatus = InsuranceStatus.loaded;
      notifyListeners();
    } catch (e) {
      _claimsStatus = InsuranceStatus.error;
      _errorMessage = 'Gagal memuat klaim. Coba lagi.';
      notifyListeners();
    }
  }

  /// Fetch both policies and claims (for MyInsurance page).
  Future<void> fetchMyInsurance() async {
    await Future.wait([fetchPolicies(), fetchClaims()]);
  }

  /// Purchase a policy.
  Future<bool> purchasePolicy({
    required String productId,
    required Map<String, dynamic> additionalData,
    required String paymentMethod,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final policy = await _dataSource.purchasePolicy(
        productId: productId,
        additionalData: additionalData,
        paymentMethod: paymentMethod,
      );
      _policies.insert(0, policy);
      // Mark product as having active policy
      final index = _products.indexWhere((p) => p.id == productId);
      if (index != -1) {
        _products[index] = InsuranceProduct(
          id: _products[index].id,
          name: _products[index].name,
          description: _products[index].description,
          productType: _products[index].productType,
          icon: _products[index].icon,
          coverageDetails: _products[index].coverageDetails,
          priceMember: _products[index].priceMember,
          priceNonMember: _products[index].priceNonMember,
          partnerName: _products[index].partnerName,
          hasActivePolicy: true,
        );
      }
      _isSubmitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isSubmitting = false;
      _errorMessage = 'Gagal membeli polis. Coba lagi.';
      notifyListeners();
      return false;
    }
  }

  /// Renew a policy.
  Future<bool> renewPolicy(String policyId) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final renewed = await _dataSource.renewPolicy(policyId);
      final index = _policies.indexWhere((p) => p.id == policyId);
      if (index != -1) {
        _policies[index] = renewed;
      }
      _isSubmitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isSubmitting = false;
      _errorMessage = 'Gagal memperpanjang polis. Coba lagi.';
      notifyListeners();
      return false;
    }
  }

  /// File a claim.
  Future<bool> fileClaim({
    required String policyId,
    required String claimType,
    required String description,
    required List<String> evidenceUrls,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final claim = await _dataSource.fileClaim(
        policyId: policyId,
        claimType: claimType,
        description: description,
        evidenceUrls: evidenceUrls,
      );
      _claims.insert(0, claim);
      _isSubmitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isSubmitting = false;
      _errorMessage = 'Gagal mengajukan klaim. Coba lagi.';
      notifyListeners();
      return false;
    }
  }
}
