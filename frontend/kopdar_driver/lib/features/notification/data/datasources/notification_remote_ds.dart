import '../../../../core/network/api_client.dart';
import '../models/notification_model.dart';

/// Remote data source for notification API calls.
class NotificationRemoteDataSource {
  final ApiClient _api;

  NotificationRemoteDataSource({ApiClient? api})
      : _api = api ?? ApiClient();

  /// Get notifications with pagination.
  Future<List<NotificationModel>> getNotifications({
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _api.get(
      '/api/v1/notifications',
      queryParameters: {'page': page, 'limit': limit},
    );
    final data = response.data['data'] ?? response.data;
    if (data is List) {
      return data
          .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    final items = data['items'] ?? data['notifications'] ?? [];
    return (items as List)
        .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Get unread count.
  Future<int> getUnreadCount() async {
    final response = await _api.get('/api/v1/notifications/unread-count');
    return response.data['data']['count'] as int? ?? 0;
  }

  /// Mark a notification as read.
  Future<void> markAsRead(String id) async {
    await _api.put('/api/v1/notifications/$id/read');
  }

  /// Mark all notifications as read.
  Future<void> markAllAsRead() async {
    await _api.put('/api/v1/notifications/read-all');
  }

  /// Delete a notification.
  Future<void> deleteNotification(String id) async {
    await _api.delete('/api/v1/notifications/$id');
  }

  /// Delete all notifications.
  Future<void> deleteAll() async {
    await _api.delete('/api/v1/notifications');
  }

  /// Register FCM device token.
  Future<void> registerDeviceToken(String token) async {
    await _api.post(
      '/api/v1/notifications/register',
      data: {'device_token': token, 'platform': 'android'},
    );
  }
}
