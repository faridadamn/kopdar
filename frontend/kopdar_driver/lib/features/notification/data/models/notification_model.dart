/// Notification data models.

class NotificationModel {
  final String id;
  final String type; // 'order', 'promo', 'community', 'sos', 'system', 'referral', 'savings', 'insurance'
  final String title;
  final String body;
  final String? imageUrl;
  final Map<String, dynamic>? data; // deep link data
  final bool isRead;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.imageUrl,
    this.data,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? 'system',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      imageUrl: json['image_url'] as String?,
      data: json['data'] as Map<String, dynamic>?,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      type: type,
      title: title,
      body: body,
      imageUrl: imageUrl,
      data: data,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }

  String get typeEmoji {
    switch (type) {
      case 'order':
        return '📦';
      case 'promo':
        return '🎉';
      case 'community':
        return '👥';
      case 'sos':
        return '🚨';
      case 'referral':
        return '🤝';
      case 'savings':
        return '🐷';
      case 'insurance':
        return '🛡️';
      case 'payment':
        return '💰';
      case 'level':
        return '🏆';
      default:
        return '🔔';
    }
  }

  String get typeLabel {
    switch (type) {
      case 'order':
        return 'Order';
      case 'promo':
        return 'Promo';
      case 'community':
        return 'Komunitas';
      case 'sos':
        return 'Darurat';
      case 'referral':
        return 'Referral';
      case 'savings':
        return 'Tabungan';
      case 'insurance':
        return 'Asuransi';
      case 'payment':
        return 'Pembayaran';
      case 'level':
        return 'Level';
      default:
        return 'Sistem';
    }
  }

  /// Route path if notification has deep link data.
  String? get route {
    if (data == null) return null;
    final type = data!['type'] as String?;
    final id = data!['id'] as String?;
    if (type == null) return null;

    switch (type) {
      case 'income':
        return id != null ? '/income/$id' : '/keuangan';
      case 'saving':
        return id != null ? '/savings/$id' : '/savings';
      case 'community':
        return id != null ? '/community/$id' : '/community';
      case 'insurance':
        return id != null ? '/insurance/$id' : '/insurance/my';
      case 'pinjol':
        return id != null ? '/pinjol/$id' : '/pinjol';
      case 'emergency':
        return '/emergency/sos';
      case 'profile':
        return '/profile';
      case 'referral':
        return '/profile/referral';
      default:
        return null;
    }
  }
}
