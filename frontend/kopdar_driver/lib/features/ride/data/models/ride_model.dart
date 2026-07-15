/// Ride/Order history data models.

class RideModel {
  final String id;
  final String platform; // 'grab', 'gojek', 'shopee', 'maxim', 'indriver'
  final String status; // 'completed', 'cancelled', 'ongoing'
  final String? pickupAddress;
  final String? dropoffAddress;
  final double? pickupLat;
  final double? pickupLng;
  final double? dropoffLat;
  final double? dropoffLng;
  final int earnings;
  final int distance; // in meters
  final int duration; // in seconds
  final double? rating;
  final String? note;
  final DateTime createdAt;

  const RideModel({
    required this.id,
    required this.platform,
    required this.status,
    this.pickupAddress,
    this.dropoffAddress,
    this.pickupLat,
    this.pickupLng,
    this.dropoffLat,
    this.dropoffLng,
    required this.earnings,
    required this.distance,
    required this.duration,
    this.rating,
    this.note,
    required this.createdAt,
  });

  factory RideModel.fromJson(Map<String, dynamic> json) {
    return RideModel(
      id: json['id'] as String? ?? '',
      platform: json['platform'] as String? ?? 'grab',
      status: json['status'] as String? ?? 'completed',
      pickupAddress: json['pickup_address'] as String?,
      dropoffAddress: json['dropoff_address'] as String?,
      pickupLat: (json['pickup_lat'] as num?)?.toDouble(),
      pickupLng: (json['pickup_lng'] as num?)?.toDouble(),
      dropoffLat: (json['dropoff_lat'] as num?)?.toDouble(),
      dropoffLng: (json['dropoff_lng'] as num?)?.toDouble(),
      earnings: json['earnings'] as int? ?? 0,
      distance: json['distance'] as int? ?? 0,
      duration: json['duration'] as int? ?? 0,
      rating: (json['rating'] as num?)?.toDouble(),
      note: json['note'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  String get platformEmoji {
    switch (platform) {
      case 'grab':
        return '🟢';
      case 'gojek':
        return '🟢';
      case 'shopee':
        return '🟠';
      case 'maxim':
        return '🟡';
      case 'indriver':
        return '🔵';
      default:
        return '🚗';
    }
  }

  String get platformName {
    switch (platform) {
      case 'grab':
        return 'Grab';
      case 'gojek':
        return 'Gojek';
      case 'shopee':
        return 'Shopee Food';
      case 'maxim':
        return 'Maxim';
      case 'indriver':
        return 'InDriver';
      default:
        return platform;
    }
  }

  String get statusLabel {
    switch (status) {
      case 'completed':
        return 'Selesai';
      case 'cancelled':
        return 'Dibatalkan';
      case 'ongoing':
        return 'Berlangsung';
      default:
        return status;
    }
  }

  String get distanceFormatted {
    if (distance < 1000) return '${distance}m';
    return '${(distance / 1000).toStringAsFixed(1)}km';
  }

  String get durationFormatted {
    final mins = (duration / 60).round();
    if (mins < 60) return '$mins menit';
    final hours = mins ~/ 60;
    final remainMins = mins % 60;
    return '$hours jam $remainMins menit';
  }
}
