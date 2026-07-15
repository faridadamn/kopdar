import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kopdar_driver/core/cache/cache_helper.dart';

void main() {
  group('CacheHelper', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await CacheHelper.init();
    });

    group('JSON caching', () {
      test('cacheJson and getCachedJson round-trip', () async {
        final data = {'name': 'Budi', 'age': 30};

        await CacheHelper.cacheJson('test_key', data);
        final cached = CacheHelper.getCachedJson('test_key');

        expect(cached, isNotNull);
        expect(cached!['name'], 'Budi');
        expect(cached['age'], 30);
      });

      test('getCachedJson returns null for expired cache', () async {
        final data = {'name': 'Budi'};

        // Cache with zero TTL (expires immediately)
        await CacheHelper.cacheJson(
          'expired_key',
          data,
          ttl: Duration.zero,
        );

        // Wait a tiny bit to ensure expiry
        await Future.delayed(const Duration(milliseconds: 10));

        final cached = CacheHelper.getCachedJson('expired_key');
        expect(cached, isNull);
      });

      test('getCachedJson returns null for non-existent key', () {
        final cached = CacheHelper.getCachedJson('nonexistent');
        expect(cached, isNull);
      });
    });

    group('JSON list caching', () {
      test('cacheJsonList and getCachedJsonList round-trip', () async {
        final data = [
          {'id': '1', 'name': 'Item 1'},
          {'id': '2', 'name': 'Item 2'},
        ];

        await CacheHelper.cacheJsonList('list_key', data);
        final cached = CacheHelper.getCachedJsonList('list_key');

        expect(cached, isNotNull);
        expect(cached, hasLength(2));
        expect(cached![0]['name'], 'Item 1');
        expect(cached[1]['id'], '2');
      });

      test('getCachedJsonList returns null for expired', () async {
        await CacheHelper.cacheJsonList(
          'expired_list',
          [{'id': '1'}],
          ttl: Duration.zero,
        );

        await Future.delayed(const Duration(milliseconds: 10));

        expect(CacheHelper.getCachedJsonList('expired_list'), isNull);
      });
    });

    group('Convenience methods', () {
      test('cacheProfile and getCachedProfile', () async {
        final data = {
          'id': 'p-1',
          'name': 'Budi',
          'level': 'silver',
        };

        await CacheHelper.cacheProfile(data);
        final cached = CacheHelper.getCachedProfile();

        expect(cached, isNotNull);
        expect(cached!['name'], 'Budi');
      });

      test('cacheVehicles and getCachedVehicles', () async {
        final data = [
          {'id': 'v-1', 'brand': 'Honda'},
          {'id': 'v-2', 'brand': 'Toyota'},
        ];

        await CacheHelper.cacheVehicles(data);
        final cached = CacheHelper.getCachedVehicles();

        expect(cached, isNotNull);
        expect(cached, hasLength(2));
      });

      test('cacheDashboard and getCachedDashboard', () async {
        final data = {
          'income': 150000,
          'orders': 12,
        };

        await CacheHelper.cacheDashboard(data);
        final cached = CacheHelper.getCachedDashboard();

        expect(cached, isNotNull);
        expect(cached!['income'], 150000);
      });
    });

    group('Cache management', () {
      test('removeCache removes specific entry', () async {
        await CacheHelper.cacheJson('to_remove', {'data': true});
        expect(CacheHelper.getCachedJson('to_remove'), isNotNull);

        await CacheHelper.removeCache('to_remove');
        expect(CacheHelper.getCachedJson('to_remove'), isNull);
      });

      test('clearAllCache removes all cache entries', () async {
        await CacheHelper.cacheJson('key1', {'a': 1});
        await CacheHelper.cacheJson('key2', {'b': 2});
        await CacheHelper.cacheProfile({'name': 'test'});

        await CacheHelper.clearAllCache();

        expect(CacheHelper.getCachedJson('key1'), isNull);
        expect(CacheHelper.getCachedJson('key2'), isNull);
        expect(CacheHelper.getCachedProfile(), isNull);
      });
    });
  });
}
