import 'package:flutter_test/flutter_test.dart';
import 'package:kopdar_driver/features/profile/data/models/vehicle_model.dart';

void main() {
  group('VehicleModel', () {
    test('fromJson creates valid model', () {
      final json = {
        'id': 'v-1',
        'type': 'Motor',
        'brand': 'Honda',
        'model': 'Vario 125',
        'year': 2023,
        'plate_number': 'B 1234 ABC',
        'color': 'Hitam',
        'photo_url': 'https://example.com/vehicle.jpg',
        'is_primary': true,
        'created_at': '2026-01-15T00:00:00.000',
      };

      final vehicle = VehicleModel.fromJson(json);

      expect(vehicle.id, 'v-1');
      expect(vehicle.type, 'Motor');
      expect(vehicle.brand, 'Honda');
      expect(vehicle.model, 'Vario 125');
      expect(vehicle.year, 2023);
      expect(vehicle.plateNumber, 'B 1234 ABC');
      expect(vehicle.color, 'Hitam');
      expect(vehicle.photoUrl, 'https://example.com/vehicle.jpg');
      expect(vehicle.isPrimary, isTrue);
    });

    test('fromJson handles missing fields with defaults', () {
      final vehicle = VehicleModel.fromJson({});

      expect(vehicle.id, '');
      expect(vehicle.type, 'Motor');
      expect(vehicle.brand, '');
      expect(vehicle.model, '');
      expect(vehicle.year, DateTime.now().year);
      expect(vehicle.plateNumber, '');
      expect(vehicle.color, '');
      expect(vehicle.photoUrl, isNull);
      expect(vehicle.isPrimary, isFalse);
    });

    test('typeEmoji returns correct emoji', () {
      expect(
        VehicleModel.fromJson({'type': 'Motor'}).typeEmoji,
        '🏍️',
      );
      expect(
        VehicleModel.fromJson({'type': 'Mobil'}).typeEmoji,
        '🚗',
      );
    });

    test('displayName formats correctly', () {
      final vehicle = VehicleModel.fromJson({
        'brand': 'Honda',
        'model': 'Vario 125',
        'year': 2023,
      });

      expect(vehicle.displayName, 'Honda Vario 125 (2023)');
    });

    test('plateFormatted uppercases plate number', () {
      final vehicle = VehicleModel.fromJson({
        'plate_number': 'b 1234 abc',
      });

      expect(vehicle.plateFormatted, 'B 1234 ABC');
    });

    test('toJson serializes correctly', () {
      final vehicle = VehicleModel.fromJson({
        'id': 'v-1',
        'type': 'Mobil',
        'brand': 'Toyota',
        'model': 'Avanza',
        'year': 2022,
        'plate_number': 'D 5678 EF',
        'color': 'Putih',
        'is_primary': false,
        'created_at': '2026-01-01T00:00:00.000',
      });

      final json = vehicle.toJson();

      expect(json['type'], 'Mobil');
      expect(json['brand'], 'Toyota');
      expect(json['model'], 'Avanza');
      expect(json['year'], 2022);
      expect(json['plate_number'], 'D 5678 EF');
      expect(json['color'], 'Putih');
      expect(json['is_primary'], isFalse);
    });
  });

  group('DocumentModel', () {
    test('fromJson creates valid model', () {
      final json = {
        'id': 'd-1',
        'type': 'sim',
        'file_url': 'https://example.com/sim.pdf',
        'file_name': 'sim_budi.pdf',
        'expiry_date': '2027-12-31T00:00:00.000',
        'status': 'verified',
        'uploaded_at': '2026-01-15T00:00:00.000',
      };

      final doc = DocumentModel.fromJson(json);

      expect(doc.id, 'd-1');
      expect(doc.type, 'sim');
      expect(doc.fileUrl, 'https://example.com/sim.pdf');
      expect(doc.fileName, 'sim_budi.pdf');
      expect(doc.expiryDate, DateTime(2027, 12, 31));
      expect(doc.status, 'verified');
    });

    test('status helpers work correctly', () {
      expect(DocumentModel.fromJson({'status': 'verified'}).isVerified, isTrue);
      expect(DocumentModel.fromJson({'status': 'expired'}).isExpired, isTrue);
      expect(DocumentModel.fromJson({'status': 'pending'}).isPending, isTrue);
      expect(DocumentModel.fromJson({'status': 'rejected'}).isRejected, isTrue);
    });

    test('typeLabel returns correct label', () {
      expect(DocumentModel.fromJson({'type': 'sim'}).typeLabel, 'SIM');
      expect(DocumentModel.fromJson({'type': 'stnk'}).typeLabel, 'STNK');
      expect(DocumentModel.fromJson({'type': 'skck'}).typeLabel, 'SKCK');
      expect(DocumentModel.fromJson({'type': 'ktp'}).typeLabel, 'KTP');
    });

    test('typeEmoji returns correct emoji', () {
      expect(DocumentModel.fromJson({'type': 'sim'}).typeEmoji, '🪪');
      expect(DocumentModel.fromJson({'type': 'stnk'}).typeEmoji, '📋');
      expect(DocumentModel.fromJson({'type': 'skck'}).typeEmoji, '📜');
      expect(DocumentModel.fromJson({'type': 'ktp'}).typeEmoji, '🆔');
    });

    test('statusLabel returns Bahasa label', () {
      expect(
        DocumentModel.fromJson({'status': 'verified'}).statusLabel,
        'Terverifikasi',
      );
      expect(
        DocumentModel.fromJson({'status': 'expired'}).statusLabel,
        'Kedaluwarsa',
      );
      expect(
        DocumentModel.fromJson({'status': 'rejected'}).statusLabel,
        'Ditolak',
      );
      expect(
        DocumentModel.fromJson({'status': 'pending'}).statusLabel,
        'Menunggu Verifikasi',
      );
    });
  });
}
