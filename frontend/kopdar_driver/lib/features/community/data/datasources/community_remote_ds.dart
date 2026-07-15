import '../../../../core/network/api_client.dart';
import '../models/post_model.dart';

/// Remote data source for community API calls.
class CommunityRemoteDataSource {
  final ApiClient _api;

  CommunityRemoteDataSource({ApiClient? api}) : _api = api ?? ApiClient();

  /// Create a new post.
  Future<PostModel> createPost({
    required String content,
    required String category,
    String visibility = 'all',
    List<String> imageUrls = const [],
  }) async {
    final response = await _api.post(
      '/api/v1/community/posts',
      data: {
        'content': content,
        'category': category,
        'visibility': visibility,
        'image_urls': imageUrls,
      },
    );
    return PostModel.fromJson(response.data['data'] ?? response.data);
  }

  /// List posts with optional filters and pagination.
  Future<List<PostModel>> listPosts({
    String? category,
    String? tab, // 'all', 'zone', 'advocacy'
    int page = 1,
    int limit = 20,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (category != null) queryParams['category'] = category;
    if (tab != null) queryParams['tab'] = tab;

    final response = await _api.get(
      '/api/v1/community/posts',
      queryParameters: queryParams,
    );

    final data = response.data['data'] ?? response.data;
    if (data is List) {
      return data
          .map((e) => PostModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    final items = data['items'] ?? data['posts'] ?? [];
    return (items as List)
        .map((e) => PostModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Get a single post with details.
  Future<PostModel> getPost(String id) async {
    final response = await _api.get('/api/v1/community/posts/$id');
    return PostModel.fromJson(response.data['data'] ?? response.data);
  }

  /// Update an existing post.
  Future<PostModel> updatePost(
    String id, {
    String? content,
    String? category,
    String? visibility,
    List<String>? imageUrls,
  }) async {
    final data = <String, dynamic>{};
    if (content != null) data['content'] = content;
    if (category != null) data['category'] = category;
    if (visibility != null) data['visibility'] = visibility;
    if (imageUrls != null) data['image_urls'] = imageUrls;

    final response = await _api.put(
      '/api/v1/community/posts/$id',
      data: data,
    );
    return PostModel.fromJson(response.data['data'] ?? response.data);
  }

  /// Delete a post.
  Future<void> deletePost(String id) async {
    await _api.delete('/api/v1/community/posts/$id');
  }

  /// Toggle like on a post. Returns updated like status.
  Future<PostModel> toggleLike(String id) async {
    final response = await _api.post('/api/v1/community/posts/$id/like');
    return PostModel.fromJson(response.data['data'] ?? response.data);
  }

  /// Add a comment to a post.
  Future<CommentModel> addComment(
    String postId, {
    required String content,
    String? parentId,
  }) async {
    final data = <String, dynamic>{'content': content};
    if (parentId != null) data['parent_id'] = parentId;

    final response = await _api.post(
      '/api/v1/community/posts/$postId/comments',
      data: data,
    );
    return CommentModel.fromJson(response.data['data'] ?? response.data);
  }

  /// Update a comment.
  Future<CommentModel> updateComment(
    String postId,
    String commentId, {
    required String content,
  }) async {
    final response = await _api.put(
      '/api/v1/community/posts/$postId/comments/$commentId',
      data: {'content': content},
    );
    return CommentModel.fromJson(response.data['data'] ?? response.data);
  }

  /// Delete a comment.
  Future<void> deleteComment(String postId, String commentId) async {
    await _api.delete('/api/v1/community/posts/$postId/comments/$commentId');
  }

  /// Get comments for a post.
  Future<List<CommentModel>> getComments(
    String postId, {
    int page = 1,
    int limit = 50,
  }) async {
    final response = await _api.get(
      '/api/v1/community/posts/$postId/comments',
      queryParameters: {'page': page, 'limit': limit},
    );

    final data = response.data['data'] ?? response.data;
    if (data is List) {
      return data
          .map((e) => CommentModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    final items = data['items'] ?? data['comments'] ?? [];
    return (items as List)
        .map((e) => CommentModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Report a post.
  Future<void> reportPost(
    String postId, {
    required String reason,
    String? details,
  }) async {
    await _api.post(
      '/api/v1/community/posts/$postId/report',
      data: {
        'reason': reason,
        if (details != null) 'details': details,
      },
    );
  }

  /// Get zone info for the current driver.
  Future<Map<String, dynamic>> getZoneInfo() async {
    final response = await _api.get('/api/v1/community/zone-info');
    return response.data['data'] ?? response.data;
  }

  /// Get advocacy data (stats, petitions, polls, policy updates).
  Future<Map<String, dynamic>> getAdvocacyData() async {
    final response = await _api.get('/api/v1/community/advocacy');
    return response.data['data'] ?? response.data;
  }
}
