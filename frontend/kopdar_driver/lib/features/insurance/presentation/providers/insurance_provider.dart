import 'package:flutter/material.dart';

import 'package:kopdar_driver/features/insurance/data/datasources/insurance_remote_ds.dart';
import 'package:kopdar_driver/features/insurance/data/models/insurance_model.dart';

enum InsuranceStatus { initial, loading, loaded, error }

class InsuranceProvider extends ChangeNotifier {
  final InsuranceRemoteDataSource _dataSource;

  InsuranceProvider({InsuranceRemoteDataSource? dataSource})
      : _dataSource = dataSource ?? InsuranceRemoteDataSource();

  InsuranceStatus _status = InsuranceStatus.initial;
  InsuranceStatus _policiesStatus = InsuranceStatus.initial;
  InsuranceStatus _claimsStatus = InsuranceStatus.initial;
  List<InsuranceProduct> _products = [];
  List<InsurancePolicy> _policies = [];
  List<InsuranceClaim> _claims = [];
  InsuranceProduct? _selectedProduct;
  String? _errorMessage;
  bool _isSubmitting = false;

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

  List<InsurancePolicy> get activePolicies =>
      _policies.where((policy) => policy.isActive).toList();

  List<InsurancePolicy> get expiringPolicies =>
      _policies.where((policy) => policy.isExpiringSoon).toList();

  List<InsuranceClaim> get pendingClaims =>
      _claims.where((claim) => claim.isPending).toList();

  Future<void> fetchProducts() async {
    _status = InsuranceStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _products = await _dataSource.listProducts();
      _status = InsuranceStatus.loaded;
    } catch (_) {
      _status = InsuranceStatus.error;
      _errorMessage = 'Gagal memuat produk asuransi. Coba lagi.';
    }
    notifyListeners();
  }

  Future<void> fetchProductDetail(String id) async {
    _status = InsuranceStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final product = await _dataSource.getProduct(id);
      _selectedProduct = product;
      _status = InsuranceStatus.loaded;
      final index = _products.indexWhere((item) => item.id == id);
      if (index != -1) _products[index] = product;
    } catch (_) {
      _status = InsuranceStatus.error;
      _errorMessage = 'Gagal memuat detail produk.';
    }
    notifyListeners();
  }

  Future<void> fetchPolicies() async {
    _policiesStatus = InsuranceStatus.loading;
    notifyListeners();

    try {
      _policies = await _dataSource.listPolicies();
      _policiesStatus = InsuranceStatus.loaded;
    } catch (_) {
      _policiesStatus = InsuranceStatus.error;
      _errorMessage = 'Gagal memuat polis. Coba lagi.';
    }
    notifyListeners();
  }

  Future<void> fetchClaims() async {
    _claimsStatus = InsuranceStatus.loading;
    notifyListeners();

    try {
      _claims = await _dataSource.listClaims();
      _claimsStatus = InsuranceStatus.loaded;
    } catch (_) {
      _claimsStatus = InsuranceStatus.error;
      _errorMessage = 'Gagal memuat klaim. Coba lagi.';
    }
    notifyListeners();
  }

  Future<void> fetchMyInsurance() async {
    await Future.wait([fetchPolicies(), fetchClaims()]);
  }

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

      final index = _products.indexWhere((item) => item.id == productId);
      if (index != -1) {
        final product = _products[index];
        _products[index] = InsuranceProduct(
          id: product.id,
          name: product.name,
          description: product.description,
          productType: product.productType,
          icon: product.icon,
          coverageDetails: product.coverageDetails,
          priceMember: product.priceMember,
          priceNonMember: product.priceNonMember,
          partnerName: product.partnerName,
          hasActivePolicy: true,
        );
      }
      return true;
    } catch (_) {
      _errorMessage = 'Gagal membeli polis. Coba lagi.';
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> renewPolicy(String policyId) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final renewed = await _dataSource.renewPolicy(policyId);
      final index = _policies.indexWhere((item) => item.id == policyId);
      if (index != -1) _policies[index] = renewed;
      return true;
    } catch (_) {
      _errorMessage = 'Gagal memperpanjang polis. Coba lagi.';
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

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
      return true;
    } catch (_) {
      _errorMessage = 'Gagal mengajukan klaim. Coba lagi.';
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
