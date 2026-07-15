import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kopdar_driver/features/profile/presentation/providers/profile_provider.dart';
import 'package:kopdar_driver/features/profile/data/datasources/profile_remote_ds.dart';
import 'package:kopdar_driver/features/profile/data/models/profile_model.dart';
import 'package:kopdar_driver/features/profile/data/models/vehicle_model.dart';

class MockProfileRemoteDataSource extends Mock
    implements ProfileRemoteDataSource {}

void main() {
  late ProfileProvider provider;
  late MockProfileRemoteDataSource mockDataSource;

  setUp(() {
    mockDataSource = MockProfileRemoteDataSource();
    provider = ProfileProvider(dataSource: mockDataSource);
  });

  setUpAll(() {
    registerFallbackValue(FakeProfileModel());
    registerFallbackValue(FakeVehicleModel());
  });

  group('ProfileProvider — Profile', () {
    test('initial state is correct', () {
      expect(provider.profileStatus, ProfileStatus.initial);
      expect(provider.profile, isNull);
      expect(provider.errorMessage, isNull);
      expect(provider.isProfileLoading, isFalse);
    });

    test('fetchProfile success updates state', () async {
      final profile = ProfileModel.fromJson({
        'id': 'p-1',
        'name': 'Budi',
        'phone': '081',
        'member_id': 'KPD-001',
        'level': 'silver',
        'points': 500,
        'total_orders': 50,
        'active_days': 20,
        'rating': 4.5,
        'member_since': '2026-01-01T00:00:00.000',
      });

      when(() => mockDataSource.getProfile()).thenAnswer((_) async => profile);

      await provider.fetchProfile();

      expect(provider.profileStatus, ProfileStatus.loaded);
      expect(provider.profile, isNotNull);
      expect(provider.profile!.name, 'Budi');
      expect(provider.profile!.level, 'silver');
      verify(() => mockDataSource.getProfile()).called(1);
    });

    test('fetchProfile failure sets error state', () async {
      when(() => mockDataSource.getProfile()).thenThrow(Exception('network'));

      await provider.fetchProfile();

      expect(provider.profileStatus, ProfileStatus.error);
      expect(provider.errorMessage, contains('Gagal'));
      expect(provider.profile, isNull);
    });

    test('updateProfile success updates profile', () async {
      // First set a profile
      when(() => mockDataSource.getProfile()).thenAnswer(
        (_) async => ProfileModel.fromJson({
          'id': 'p-1',
          'name': 'Old Name',
          'phone': '081',
          'member_id': 'KPD-001',
          'level': 'bronze',
          'member_since': '2026-01-01T00:00:00.000',
        }),
      );
      await provider.fetchProfile();

      // Then update
      when(() => mockDataSource.updateProfile(name: 'New Name')).thenAnswer(
        (_) async => ProfileModel.fromJson({
          'id': 'p-1',
          'name': 'New Name',
          'phone': '081',
          'member_id': 'KPD-001',
          'level': 'bronze',
          'member_since': '2026-01-01T00:00:00.000',
        }),
      );

      final result = await provider.updateProfile(name: 'New Name');

      expect(result, isTrue);
      expect(provider.profile!.name, 'New Name');
    });
  });

  group('ProfileProvider — Vehicles', () {
    test('fetchVehicles success populates list', () async {
      final vehicles = [
        VehicleModel.fromJson({
          'id': 'v-1',
          'type': 'Motor',
          'brand': 'Honda',
          'model': 'Vario',
          'year': 2023,
          'plate_number': 'B 1234',
          'color': 'Hitam',
          'is_primary': true,
          'created_at': '2026-01-01T00:00:00.000',
        }),
      ];

      when(() => mockDataSource.getVehicles()).thenAnswer((_) async => vehicles);

      await provider.fetchVehicles();

      expect(provider.vehicleStatus, VehicleStatus.loaded);
      expect(provider.vehicles, hasLength(1));
      expect(provider.vehicles[0].brand, 'Honda');
      expect(provider.primaryVehicle, isNotNull);
      expect(provider.primaryVehicle!.id, 'v-1');
    });

    test('addVehicle appends to list', () async {
      when(() => mockDataSource.getVehicles()).thenAnswer((_) async => []);
      await provider.fetchVehicles();

      final newVehicle = VehicleModel.fromJson({
        'id': 'v-new',
        'type': 'Motor',
        'brand': 'Yamaha',
        'model': 'NMAX',
        'year': 2024,
        'plate_number': 'D 5678',
        'color': 'Merah',
        'is_primary': false,
        'created_at': '2026-01-15T00:00:00.000',
      });

      when(() => mockDataSource.addVehicle(
            type: any(named: 'type'),
            brand: any(named: 'brand'),
            model: any(named: 'model'),
            year: any(named: 'year'),
            plateNumber: any(named: 'plateNumber'),
            color: any(named: 'color'),
          )).thenAnswer((_) async => newVehicle);

      final result = await provider.addVehicle(
        type: 'Motor',
        brand: 'Yamaha',
        model: 'NMAX',
        year: 2024,
        plateNumber: 'D 5678',
        color: 'Merah',
      );

      expect(result, isTrue);
      expect(provider.vehicles, hasLength(1));
      expect(provider.vehicles[0].brand, 'Yamaha');
    });

    test('deleteVehicle removes from list', () async {
      final vehicles = [
        VehicleModel.fromJson({
          'id': 'v-1',
          'type': 'Motor',
          'brand': 'Honda',
          'model': 'Vario',
          'year': 2023,
          'plate_number': 'B 1234',
          'color': 'Hitam',
          'is_primary': true,
          'created_at': '2026-01-01T00:00:00.000',
        }),
      ];

      when(() => mockDataSource.getVehicles()).thenAnswer((_) async => vehicles);
      await provider.fetchVehicles();

      when(() => mockDataSource.deleteVehicle('v-1'))
          .thenAnswer((_) async => true);

      final result = await provider.deleteVehicle('v-1');

      expect(result, isTrue);
      expect(provider.vehicles, isEmpty);
    });

    test('setPrimaryVehicle updates local state', () async {
      final vehicles = [
        VehicleModel.fromJson({
          'id': 'v-1',
          'type': 'Motor',
          'brand': 'Honda',
          'model': 'Vario',
          'year': 2023,
          'plate_number': 'B 1234',
          'color': 'Hitam',
          'is_primary': true,
          'created_at': '2026-01-01T00:00:00.000',
        }),
        VehicleModel.fromJson({
          'id': 'v-2',
          'type': 'Mobil',
          'brand': 'Toyota',
          'model': 'Avanza',
          'year': 2022,
          'plate_number': 'D 5678',
          'color': 'Putih',
          'is_primary': false,
          'created_at': '2026-01-01T00:00:00.000',
        }),
      ];

      when(() => mockDataSource.getVehicles()).thenAnswer((_) async => vehicles);
      await provider.fetchVehicles();

      when(() => mockDataSource.setPrimaryVehicle('v-2'))
          .thenAnswer((_) async => true);

      final result = await provider.setPrimaryVehicle('v-2');

      expect(result, isTrue);
      expect(provider.vehicles[0].isPrimary, isFalse); // v-1
      expect(provider.vehicles[1].isPrimary, isTrue); // v-2
      expect(provider.primaryVehicle!.id, 'v-2');
    });
  });

  group('ProfileProvider — Logout', () {
    test('logout clears all state', () async {
      when(() => mockDataSource.getProfile()).thenAnswer(
        (_) async => ProfileModel.fromJson({
          'id': 'p-1',
          'name': 'Test',
          'phone': '081',
          'member_id': 'KPD-001',
          'level': 'bronze',
          'member_since': '2026-01-01T00:00:00.000',
        }),
      );
      await provider.fetchProfile();

      provider.logout();

      expect(provider.profile, isNull);
      expect(provider.profileStatus, ProfileStatus.initial);
      expect(provider.vehicles, isEmpty);
      expect(provider.documents, isEmpty);
    });
  });
}

class FakeProfileModel extends Fake implements ProfileModel {}
class FakeVehicleModel extends Fake implements VehicleModel {}
