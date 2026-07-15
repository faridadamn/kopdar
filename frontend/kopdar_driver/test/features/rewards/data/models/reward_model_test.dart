import 'package:flutter_test/flutter_test.dart';
import 'package:kopdar_driver/features/rewards/data/models/reward_model.dart';

void main() {
  group('RewardModel', () {
    test('fromJson creates valid model', () {
      final json = {
        'id': 'rw-1',
        'title': 'Saldo Rp 25.000',
        'description': 'Tukar poin dengan saldo',
        'icon': '💰',
        'points_cost': 500,
        'category': 'saldo',
        'stock': 100,
        'is_available': true,
        'image_url': 'https://example.com/reward.jpg',
      };

      final reward = RewardModel.fromJson(json);

      expect(reward.id, 'rw-1');
      expect(reward.title, 'Saldo Rp 25.000');
      expect(reward.icon, '💰');
      expect(reward.pointsCost, 500);
      expect(reward.category, 'saldo');
      expect(reward.stock, 100);
      expect(reward.isAvailable, isTrue);
    });

    test('fromJson handles missing fields', () {
      final reward = RewardModel.fromJson({});

      expect(reward.id, '');
      expect(reward.title, '');
      expect(reward.icon, '🎁');
      expect(reward.pointsCost, 0);
      expect(reward.stock, 0);
      expect(reward.isAvailable, isTrue);
    });
  });

  group('AchievementModel', () {
    test('fromJson creates valid model', () {
      final json = {
        'id': 'ach-1',
        'title': 'Order Pertama',
        'desc': 'Selesaikan order pertama',
        'icon': '🎯',
        'unlocked': true,
        'progress': 1.0,
        'reward_points': 50,
      };

      final ach = AchievementModel.fromJson(json);

      expect(ach.id, 'ach-1');
      expect(ach.title, 'Order Pertama');
      expect(ach.unlocked, isTrue);
      expect(ach.progress, 1.0);
      expect(ach.rewardPoints, 50);
    });

    test('fromJson handles defaults', () {
      final ach = AchievementModel.fromJson({});

      expect(ach.unlocked, isFalse);
      expect(ach.progress, 0.0);
      expect(ach.rewardPoints, isNull);
    });
  });

  group('LeaderboardEntry', () {
    test('fromJson creates valid model', () {
      final json = {
        'rank': 1,
        'name': 'Budi',
        'photo_url': 'https://example.com/photo.jpg',
        'points': 15000,
        'level': 'platinum',
        'is_current_user': false,
      };

      final entry = LeaderboardEntry.fromJson(json);

      expect(entry.rank, 1);
      expect(entry.name, 'Budi');
      expect(entry.points, 15000);
      expect(entry.level, 'platinum');
      expect(entry.isCurrentUser, isFalse);
    });

    test('levelEmoji returns correct emoji', () {
      expect(
        LeaderboardEntry.fromJson({'level': 'platinum'}).levelEmoji,
        '💎',
      );
      expect(
        LeaderboardEntry.fromJson({'level': 'gold'}).levelEmoji,
        '🥇',
      );
      expect(
        LeaderboardEntry.fromJson({'level': 'silver'}).levelEmoji,
        '🥈',
      );
      expect(
        LeaderboardEntry.fromJson({'level': 'bronze'}).levelEmoji,
        '🥉',
      );
    });
  });
}
