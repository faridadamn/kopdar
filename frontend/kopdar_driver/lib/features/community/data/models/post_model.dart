/// Post model for community feed.
class PostModel {
  final String id;
  final String driverId;
  final String driverName;
  final String? driverAvatar;
  final String? driverZone;
  final String? driverPlatform;
  final String content;
  final List<String> imageUrls;
  final String category; // tips, question, complaint, info, advocacy
  final String visibility; // zone, all
  final int likesCount;
  final int commentsCount;
  final bool isLiked;
  final bool isPinned;
  final DateTime createdAt;

  const PostModel({
    required this.id,
    required this.driverId,
    required this.driverName,
    this.driverAvatar,
    this.driverZone,
    this.driverPlatform,
    required this.content,
    this.imageUrls = const [],
    required this.category,
    this.visibility = 'all',
    this.likesCount = 0,
    this.commentsCount = 0,
    this.isLiked = false,
    this.isPinned = false,
    required this.createdAt,
  });

  PostModel copyWith({
    String? id,
    String? driverId,
    String? driverName,
    String? driverAvatar,
    String? driverZone,
    String? driverPlatform,
    String? content,
    List<String>? imageUrls,
    String? category,
    String? visibility,
    int? likesCount,
    int? commentsCount,
    bool? isLiked,
    bool? isPinned,
    DateTime? createdAt,
  }) {
    return PostModel(
      id: id ?? this.id,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      driverAvatar: driverAvatar ?? this.driverAvatar,
      driverZone: driverZone ?? this.driverZone,
      driverPlatform: driverPlatform ?? this.driverPlatform,
      content: content ?? this.content,
      imageUrls: imageUrls ?? this.imageUrls,
      category: category ?? this.category,
      visibility: visibility ?? this.visibility,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      isLiked: isLiked ?? this.isLiked,
      isPinned: isPinned ?? this.isPinned,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['id'] as String,
      driverId: json['driver_id'] as String,
      driverName: json['driver_name'] as String? ?? 'Driver',
      driverAvatar: json['driver_avatar'] as String?,
      driverZone: json['driver_zone'] as String?,
      driverPlatform: json['driver_platform'] as String?,
      content: json['content'] as String,
      imageUrls: (json['image_urls'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      category: json['category'] as String? ?? 'info',
      visibility: json['visibility'] as String? ?? 'all',
      likesCount: json['likes_count'] as int? ?? 0,
      commentsCount: json['comments_count'] as int? ?? 0,
      isLiked: json['is_liked'] as bool? ?? false,
      isPinned: json['is_pinned'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'driver_id': driverId,
      'driver_name': driverName,
      'driver_avatar': driverAvatar,
      'driver_zone': driverZone,
      'driver_platform': driverPlatform,
      'content': content,
      'image_urls': imageUrls,
      'category': category,
      'visibility': visibility,
      'likes_count': likesCount,
      'comments_count': commentsCount,
      'is_liked': isLiked,
      'is_pinned': isPinned,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

/// Comment model for post discussions.
class CommentModel {
  final String id;
  final String postId;
  final String driverId;
  final String driverName;
  final String? driverAvatar;
  final String? parentId;
  final String content;
  final DateTime createdAt;
  final List<CommentModel> replies;

  const CommentModel({
    required this.id,
    required this.postId,
    required this.driverId,
    required this.driverName,
    this.driverAvatar,
    this.parentId,
    required this.content,
    required this.createdAt,
    this.replies = const [],
  });

  CommentModel copyWith({
    String? id,
    String? postId,
    String? driverId,
    String? driverName,
    String? driverAvatar,
    String? parentId,
    String? content,
    DateTime? createdAt,
    List<CommentModel>? replies,
  }) {
    return CommentModel(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      driverAvatar: driverAvatar ?? this.driverAvatar,
      parentId: parentId ?? this.parentId,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      replies: replies ?? this.replies,
    );
  }

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id'] as String,
      postId: json['post_id'] as String,
      driverId: json['driver_id'] as String,
      driverName: json['driver_name'] as String? ?? 'Driver',
      driverAvatar: json['driver_avatar'] as String?,
      parentId: json['parent_id'] as String?,
      content: json['content'] as String,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      replies: (json['replies'] as List<dynamic>?)
              ?.map((e) => CommentModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'post_id': postId,
      'driver_id': driverId,
      'driver_name': driverName,
      'driver_avatar': driverAvatar,
      'parent_id': parentId,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'replies': replies.map((e) => e.toJson()).toList(),
    };
  }
}
