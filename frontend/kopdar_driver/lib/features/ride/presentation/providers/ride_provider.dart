import 'package:flutter/material.dart';
import '../data/models/ride_model.dart';
import '../../../../core/network/api_client.dart';

enum RideStatus { initial, loading, loaded, error }

class RideProvider extends ChangeNotifier {
  final ApiClient _api;

  RideProvider({ApiClient? api}) : _api = api ?? ApiClient();

  RideStatus _status = RideStatus.initial;
  List<RideModel> _rides = [];
  String? _errorMessage;

  RideStatus get status => _status;
  List<RideModel> get rides => _rides;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == RideStatus.loading;

  // Derived stats
  int get todayEarnings {
    final now = DateTime.now();
    return _rides
        .where((r) =>
            r.createdAt.year == now.year &&
            r.createdAt.month == now.month &&
            r.createdAt.day == now.day)
        .fold(0, (sum, r) => sum + r.earnings);
  }

  int get todayCount {
    final now = DateTime.now();
    return _rides
        .where((r) =>
            r.createdAt.year == now.year &&
            r.createdAt.month == now.month &&
            r.createdAt.day == now.day)
        .length;
  }

  Future<void> fetchRides() async {
    _status = RideStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _api.get('/api/v1/rides');
      final data = response.data['data'] ?? response.data;
      final items = data is List
          ? data
          : (data['items'] ?? data['rides'] ?? []) as List;
      _rides = items
          .map((e) => RideModel.fromJson(e as Map<String, dynamic>))
          .toList();
      _status = RideStatus.loaded;
      notifyListeners();
    } catch (e) {
      _status = RideStatus.error;
      _errorMessage = 'Gagal memuat riwayat order.';
      notifyListeners();
    }
  }

  Future<RideModel?> getRideDetail(String id) async {
    try {
      final response = await _api.get('/api/v1/rides/$id');
      return RideModel.fromJson(response.data['data'] ?? response.data);
    } catch (_) {
      return null;
    }
  }
}
