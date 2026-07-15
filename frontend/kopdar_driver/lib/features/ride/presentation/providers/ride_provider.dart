import 'package:flutter/material.dart';

import 'package:kopdar_driver/core/network/api_client.dart';
import 'package:kopdar_driver/features/ride/data/models/ride_model.dart';

enum RideStatus { initial, loading, loaded, error }

class RideProvider extends ChangeNotifier {
  final ApiClient _api;

  RideProvider({ApiClient? api}) : _api = api ?? ApiClient();

  RideStatus _status = RideStatus.initial;
  List<RideModel> _rides = [];
  String? _errorMessage;

  RideStatus get status => _status;
  List<RideModel> get rides => List<RideModel>.unmodifiable(_rides);
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == RideStatus.loading;

  Iterable<RideModel> get _todayRides {
    final now = DateTime.now();
    return _rides.where(
      (ride) =>
          ride.createdAt.year == now.year &&
          ride.createdAt.month == now.month &&
          ride.createdAt.day == now.day,
    );
  }

  int get todayEarnings =>
      _todayRides.fold<int>(0, (sum, ride) => sum + ride.earnings);

  int get todayCount => _todayRides.length;

  Future<void> fetchRides() async {
    _status = RideStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _api.get('/api/v1/rides');
      final dynamic payload = response.data['data'] ?? response.data;
      final List<dynamic> items;

      if (payload is List<dynamic>) {
        items = payload;
      } else if (payload is Map<String, dynamic>) {
        final dynamic nestedItems = payload['items'] ?? payload['rides'];
        items = nestedItems is List<dynamic> ? nestedItems : <dynamic>[];
      } else {
        items = <dynamic>[];
      }

      _rides = items
          .whereType<Map<String, dynamic>>()
          .map(RideModel.fromJson)
          .toList(growable: false);
      _status = RideStatus.loaded;
    } catch (_) {
      _status = RideStatus.error;
      _errorMessage = 'Gagal memuat riwayat order.';
    } finally {
      notifyListeners();
    }
  }

  Future<RideModel?> getRideDetail(String id) async {
    try {
      final response = await _api.get('/api/v1/rides/$id');
      final dynamic payload = response.data['data'] ?? response.data;
      if (payload is! Map<String, dynamic>) return null;
      return RideModel.fromJson(payload);
    } catch (_) {
      return null;
    }
  }
}
