import 'package:flutter_test/flutter_test.dart';
import 'package:kopdar_driver/features/profile/data/models/profile_model.dart';

void main() {
  group('ProfileModel', () {
    test('fromJson creates valid model', () {
      final json = {
        'id': 'p-1',
        'name': 'Budi Santoso',
        'phone': '081234567890',
        'email': 'budi@test.com',
        'photo_url': 'https://example.com/photo.jpg',
        'member_id': 'KPD-2026-00001',
        'level': 'gold',
        'points': 2500,
        'total_orders': 300,
        'active_days': 90,
        'rating': 4.9,
        'member_since': '2025-06-15T00:00:00.000',
      };

      final profile = ProfileModel.fromJson(json);

      expect(profile.id, 'p-1');
      expect(profile.name, 'Budi Santoso');
      expect(profile.phone, '081234567890');
      expect(profile.email, 'budi@test.com');
      expect(profile.photoUrl, 'https://example.com/photo.jpg');
      expect(profile.memberId, 'KPD-2026-00001');
      expect(profile.level, 'gold');
      expect(profile.points, 2500);
      expect(profile.totalOrders, 300);
      expect(profile.activeDays, 90);
      expect(profile.rating, 4.9);
      expect(profile.memberSince, DateTime(2025, 6, 15));
    });

    test('fromJson handles missing fields with defaults', () {
      final profile = ProfileModel.fromJson({});

      expect(profile.id, '');
      expect(profile.name, '');
      expect(profile.phone, '');
      expect(profile.email, isNull);
      expect(profile.photoUrl, isNull);
      expect(profile.level, 'bronze');
      expect(profile.points, 0);
      expect(profile.totalOrders, 0);
      expect(profile.activeDays, 0);
      expect(profile.rating, 0.0);
    });

    test('toJson serializes correctly', () {
      final profile = ProfileModel.fromJson({
        'id': 'p-1',
        'name': 'Test',
        'phone': '081',
        'member_id': 'KPD-001',
        'level': 'silver',
        'points': 500,
        'total_orders': 50,
        'active_days': 20,
        'rating': 4.5,
        'member_since': '2026-01-01T00:00:00.000',
      });

      final json = profile.toJson();

      expect(json['id'], 'p-1');
      expect(json['name'], 'Test');
      expect(json['level'], 'silver');
      expect(json['points'], 500);
    });

    test('levelLabel returns correct Bahasa labels', () {
      expect(
        ProfileModel.fromJson({'level': 'bronze'}).levelLabel,
        'Perunggu',
      );
      expect(
        ProfileModel.fromJson({'level': 'silver'}).levelLabel,
        'Perak',
      );
      expect(
        ProfileModel.fromJson({'level': 'gold'}).levelLabel,
        'Emas',
      );
      expect(
        ProfileModel.fromJson({'level': 'platinum'}).levelLabel,
        'Platinum',
      );
    });

    test('levelEmoji returns correct emoji', () {
      expect(ProfileModel.fromJson({'level': 'bronze'}).levelEmoji, '🥉');
      expect(ProfileModel.fromJson({'level': 'silver'}).levelEmoji, '🥈');
      expect(ProfileModel.fromJson({'level': 'gold'}).levelEmoji, '🥇');
      expect(ProfileModel.fromJson({'level': 'platinum'}).levelEmoji, '💎');
    });
  });

  group('LevelInfo', () {
    test('fromJson creates valid model', () {
      final json = {
        'current_level': 'silver',
        'current_points': 750,
        'next_level_points': 2000,
        'next_level': 'gold',
        'progress': 0.375,
        'benefits': [
          {
            'icon': '🎁',
            'title': 'Cashback 5%',
            'description': 'Cashback setiap order',
            'unlocked': true,
          }
        ],
        'points_history': [
          {
            'id': 'ph-1',
            'action': 'Order selesai',
            'points': 10,
            'type': 'earn',
            'created_at': '2026-01-15T10:30:00.000',
          }
        ],
      };

      final info = LevelInfo.fromJson(json);

      expect(info.currentLevel, 'silver');
      expect(info.currentPoints, 750);
      expect(info.nextLevelPoints, 2000);
      expect(info.nextLevel, 'gold');
      expect(info.progress, 0.375);
      expect(info.benefits, hasLength(1));
      expect(info.benefits[0].title, 'Cashback 5%');
      expect(info.benefits[0].unlocked, isTrue);
      expect(info.pointsHistory, hasLength(1));
      expect(info.pointsHistory[0].points, 10);
      expect(info.pointsHistory[0].type, 'earn');
    });
  });

  group('ReferralInfo', () {
    test('fromJson creates valid model', () {
      final json = {
        'code': 'KOPDAR123',
        'total_referrals': 5,
        'total_bonus': 250,
        'referrals': [
          {
            'id': 'r-1',
            'name': 'Andi',
            'status': 'completed',
            'bonus': 50,
            'created_at': '2026-01-10T00:00:00.000',
          }
        ],
      };

      final info = ReferralInfo.fromJson(json);

      expect(info.code, 'KOPDAR123');
      expect(info.totalReferrals, 5);
      expect(info.totalBonus, 250);
      expect(info.referrals, hasLength(1));
      expect(info.referrals[0].name, 'Andi');
      expect(info.referrals[0].isCompleted, isTrue);
    });
  });

  group('SettingsModel', () {
    test('fromJson creates valid model', () {
      final json = {
        'language': 'id',
        'timezone': 'Asia/Jakarta',
        'auto_save': true,
        'notif_order': true,
        'notif_promo': false,
        'notif_community': true,
        'notif_sos': true,
        'biometric_enabled': false,
        'app_version': '1.0.0',
      };

      final settings = SettingsModel.fromJson(json);

      expect(settings.language, 'id');
      expect(settings.timezone, 'Asia/Jakarta');
      expect(settings.autoSave, isTrue);
      expect(settings.notifPromo, isFalse);
      expect(settings.appVersion, '1.0.0');
    });

    test('copyWith creates new instance with overrides', () {
      final original = SettingsModel.fromJson({
        'language': 'id',
        'auto_save': false,
        'notif_order': true,
      });

      final updated = original.copyWith(
        language: 'en',
        autoSave: true,
      );

      expect(updated.language, 'en');
      expect(updated.autoSave, isTrue);
      expect(updated.notifOrder, isTrue); // unchanged
    });
  });

  group('PointsHistory', () {
    test('fromJson creates valid model', () {
      final json = {
        'id': 'ph-1',
        'action': 'Login harian',
        'points': 5,
        'type': 'earn',
        'created_at': '2026-01-15T08:00:00.000',
      };

      final ph = PointsHistory.fromJson(json);

      expect(ph.id, 'ph-1');
      expect(ph.action, 'Login harian');
      expect(ph.points, 5);
      expect(ph.type, 'earn');
    });
  });

  group('ReferralEntry', () {
    test('isPending and isCompleted work correctly', () {
      final pending = ReferralEntry.fromJson({
        'status': 'pending',
      });
      final completed = ReferralEntry.fromJson({
        'status': 'completed',
      });

      expect(pending.isPending, isTrue);
      expect(pending.isCompleted, isFalse);
      expect(completed.isPending, isFalse);
      expect(completed.isCompleted, isTrue);
    });
  });
}
