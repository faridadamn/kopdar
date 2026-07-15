import 'package:flutter_test/flutter_test.dart';
import 'package:kopdar_driver/features/ride/data/models/ride_model.dart';

void main() {
  group('RideModel', () {
    test('fromJson creates valid model', () {
      final json = {
        'id': 'ride-1',
        'platform': 'grab',
        'status': 'completed',
        'pickup_address': 'Jl. Sudirman No. 1',
        'dropoff_address': 'Jl. Thamrin No. 10',
        'pickup_lat': -6.2088,
        'pickup_lng': 106.8456,
        'dropoff_lat': -6.1944,
        'dropoff_lng': 106.8230,
        'earnings': 25000,
        'distance': 5200,
        'duration': 1200,
        'rating': 4.8,
        'note': 'Customer ramah',
        'created_at': '2026-01-15T10:30:00.000',
      };

      final ride = RideModel.fromJson(json);

      expect(ride.id, 'ride-1');
      expect(ride.platform, 'grab');
      expect(ride.status, 'completed');
      expect(ride.pickupAddress, 'Jl. Sudirman No. 1');
      expect(ride.dropoffAddress, 'Jl. Thamrin No. 10');
      expect(ride.earnings, 25000);
      expect(ride.distance, 5200);
      expect(ride.duration, 1200);
      expect(ride.rating, 4.8);
      expect(ride.note, 'Customer ramah');
    });

    test('fromJson handles missing fields with defaults', () {
      final ride = RideModel.fromJson({});

      expect(ride.id, '');
      expect(ride.platform, 'grab');
      expect(ride.status, 'completed');
      expect(ride.pickupAddress, isNull);
      expect(ride.dropoffAddress, isNull);
      expect(ride.earnings, 0);
      expect(ride.distance, 0);
      expect(ride.duration, 0);
      expect(ride.rating, isNull);
    });

    test('platformEmoji returns correct emoji', () {
      expect(RideModel.fromJson({'platform': 'grab'}).platformEmoji, '🟢');
      expect(RideModel.fromJson({'platform': 'gojek'}).platformEmoji, '🟢');
      expect(RideModel.fromJson({'platform': 'shopee'}).platformEmoji, '🟠');
      expect(RideModel.fromJson({'platform': 'maxim'}).platformEmoji, '🟡');
      expect(RideModel.fromJson({'platform': 'indriver'}).platformEmoji, '🔵');
    });

    test('platformName returns correct name', () {
      expect(RideModel.fromJson({'platform': 'grab'}).platformName, 'Grab');
      expect(RideModel.fromJson({'platform': 'gojek'}).platformName, 'Gojek');
      expect(
          RideModel.fromJson({'platform': 'shopee'}).platformName, 'Shopee Food');
    });

    test('statusLabel returns Bahasa label', () {
      expect(
          RideModel.fromJson({'status': 'completed'}).statusLabel, 'Selesai');
      expect(
          RideModel.fromJson({'status': 'cancelled'}).statusLabel, 'Dibatalkan');
      expect(
          RideModel.fromJson({'status': 'ongoing'}).statusLabel, 'Berlangsung');
    });

    test('distanceFormatted formats correctly', () {
      expect(
        RideModel.fromJson({'distance': 500}).distanceFormatted,
        '500m',
      );
      expect(
        RideModel.fromJson({'distance': 5200}).distanceFormatted,
        '5.2km',
      );
      expect(
        RideModel.fromJson({'distance': 15000}).distanceFormatted,
        '15.0km',
      );
    });

    test('durationFormatted formats correctly', () {
      expect(
        RideModel.fromJson({'duration': 600}).durationFormatted,
        '10 menit',
      );
      expect(
        RideModel.fromJson({'duration': 3600}).durationFormatted,
        '1 jam 0 menit',
      );
      expect(
        RideModel.fromJson({'duration': 5400}).durationFormatted,
        '1 jam 30 menit',
      );
    });
  });
}
