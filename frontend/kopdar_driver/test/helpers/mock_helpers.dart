import 'package:mocktail/mocktail.dart';
import 'package:kopdar_driver/features/profile/data/datasources/profile_remote_ds.dart';
import 'package:kopdar_driver/features/profile/data/models/profile_model.dart';
import 'package:kopdar_driver/features/profile/data/models/vehicle_model.dart';

class MockProfileRemoteDataSource extends Mock
    implements ProfileRemoteDataSource {}

class FakeProfileModel extends Fake implements ProfileModel {}
class FakeLevelInfo extends Fake implements LevelInfo {}
class FakeReferralInfo extends Fake implements ReferralInfo {}
class FakeSettingsModel extends Fake implements SettingsModel {}
class FakeVehicleModel extends Fake implements VehicleModel {}
class FakeDocumentModel extends Fake implements DocumentModel {}

class TestData {
  static ProfileModel profile() => ProfileModel(
        id: 'test-id-1',
        name: 'Budi Santoso',
        phone: '081234567890',
        email: 'budi@test.com',
        photoUrl: null,
        memberId: 'KPD-2026-00001',
        level: 'silver',
        points: 750,
        totalOrders: 120,
        activeDays: 45,
        rating: 4.8,
        memberSince: _fixedDate,
      );

  static LevelInfo levelInfo() => const LevelInfo(
        currentLevel: 'silver',
        currentPoints: 750,
        nextLevelPoints: 2000,
        nextLevel: 'gold',
        progress: 0.375,
        benefits: [],
        pointsHistory: [],
      );

  static ReferralInfo referralInfo() => const ReferralInfo(
        code: 'KOPDAR123',
        totalReferrals: 5,
        totalBonus: 250,
        referrals: [],
      );

  static SettingsModel settings() => const SettingsModel(
        language: 'id',
        timezone: 'Asia/Jakarta',
        autoSave: false,
        notifOrder: true,
        notifPromo: true,
        notifCommunity: true,
        notifSOS: true,
        biometricEnabled: false,
        appVersion: '1.0.0',
      );

  static VehicleModel vehicle() => VehicleModel(
        id: 'v-1',
        type: 'Motor',
        brand: 'Honda',
        model: 'Vario 125',
        year: 2023,
        plateNumber: 'B 1234 ABC',
        color: 'Hitam',
        isPrimary: true,
        createdAt: _fixedDate,
      );

  static DocumentModel document() => DocumentModel(
        id: 'd-1',
        type: 'sim',
        status: 'verified',
        uploadedAt: _fixedDate,
        expiryDate: DateTime(2027, 12, 31),
        fileName: 'sim_budi.jpg',
      );

  static PointsHistory pointsHistory() => PointsHistory(
        id: 'ph-1',
        action: 'Order selesai',
        points: 10,
        type: 'earn',
        createdAt: _fixedDate,
      );

  static ReferralEntry referralEntry() => ReferralEntry(
        id: 'r-1',
        name: 'Andi Wijaya',
        status: 'completed',
        bonus: 50,
        createdAt: _fixedDate,
      );

  static final DateTime _fixedDate = DateTime(2026, 1, 15, 10, 30);
}
