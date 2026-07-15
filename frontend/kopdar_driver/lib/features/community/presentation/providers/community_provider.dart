import 'package:flutter/material.dart';
import '../../data/models/post_model.dart';
import '../../data/datasources/community_remote_ds.dart';

enum CommunityStatus { initial, loading, loaded, error }
enum CommunityTab { all, myZone, advocacy }

class CommunityProvider extends ChangeNotifier {
  final CommunityRemoteDataSource _dataSource;

  CommunityProvider({CommunityRemoteDataSource? dataSource})
      : _dataSource = dataSource ?? CommunityRemoteDataSource();

  // ── State ──
  CommunityStatus _status = CommunityStatus.initial;
  CommunityStatus _detailStatus = CommunityStatus.initial;
  CommunityStatus _commentsStatus = CommunityStatus.initial;
  List<PostModel> _posts = [];
  PostModel? _currentPost;
  List<CommentModel> _comments = [];
  String? _errorMessage;
  int _currentPage = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  // ── Filters ──
  CommunityTab _activeTab = CommunityTab.all;
  String? _categoryFilter;

  // ── Zone info ──
  Map<String, dynamic>? _zoneInfo;

  // ── Advocacy ──
  Map<String, dynamic>? _advocacyData;

  // ── Getters ──
  CommunityStatus get status => _status;
  CommunityStatus get detailStatus => _detailStatus;
  CommunityStatus get commentsStatus => _commentsStatus;
  List<PostModel> get posts => _posts;
  PostModel? get currentPost => _currentPost;
  List<CommentModel> get comments => _comments;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == CommunityStatus.loading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  CommunityTab get activeTab => _activeTab;
  String? get categoryFilter => _categoryFilter;
  Map<String, dynamic>? get zoneInfo => _zoneInfo;
  Map<String, dynamic>? get advocacyData => _advocacyData;

  // ── Actions ──

  void setActiveTab(CommunityTab tab) {
    _activeTab = tab;
    notifyListeners();
    fetchPosts(refresh: true);
  }

  void setCategoryFilter(String? category) {
    _categoryFilter = category;
    notifyListeners();
    fetchPosts(refresh: true);
  }

  /// Fetch posts with current filters.
  Future<void> fetchPosts({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
      _posts = [];
    }

    _status = CommunityStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      String? tabParam;
      switch (_activeTab) {
        case CommunityTab.all:
          tabParam = 'all';
          break;
        case CommunityTab.myZone:
          tabParam = 'zone';
          break;
        case CommunityTab.advocacy:
          tabParam = 'advocacy';
          break;
      }

      final result = await _dataSource.listPosts(
        category: _categoryFilter,
        tab: tabParam,
        page: _currentPage,
        limit: 20,
      );

      if (refresh) {
        _posts = result;
      } else {
        _posts.addAll(result);
      }

      _hasMore = result.length >= 20;
      _status = CommunityStatus.loaded;
      notifyListeners();
    } catch (e) {
      _status = CommunityStatus.error;
      _errorMessage = 'Gagal memuat postingan. Coba lagi.';
      notifyListeners();
    }
  }

  /// Load next page of posts.
  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore) return;

    _isLoadingMore = true;
    _currentPage++;
    notifyListeners();

    try {
      String? tabParam;
      switch (_activeTab) {
        case CommunityTab.all:
          tabParam = 'all';
          break;
        case CommunityTab.myZone:
          tabParam = 'zone';
          break;
        case CommunityTab.advocacy:
          tabParam = 'advocacy';
          break;
      }

      final result = await _dataSource.listPosts(
        category: _categoryFilter,
        tab: tabParam,
        page: _currentPage,
        limit: 20,
      );

      _posts.addAll(result);
      _hasMore = result.length >= 20;
    } catch (e) {
      _currentPage--;
    }

    _isLoadingMore = false;
    notifyListeners();
  }

  /// Fetch a single post detail.
  Future<void> fetchPost(String id) async {
    _detailStatus = CommunityStatus.loading;
    notifyListeners();

    try {
      _currentPost = await _dataSource.getPost(id);
      _detailStatus = CommunityStatus.loaded;
      notifyListeners();
    } catch (e) {
      _detailStatus = CommunityStatus.error;
      _errorMessage = 'Gagal memuat postingan.';
      notifyListeners();
    }
  }

  /// Fetch comments for a post.
  Future<void> fetchComments(String postId) async {
    _commentsStatus = CommunityStatus.loading;
    notifyListeners();

    try {
      _comments = await _dataSource.getComments(postId);
      _commentsStatus = CommunityStatus.loaded;
      notifyListeners();
    } catch (e) {
      _commentsStatus = CommunityStatus.error;
      notifyListeners();
    }
  }

  /// Create a new post.
  Future<bool> createPost({
    required String content,
    required String category,
    String visibility = 'all',
    List<String> imageUrls = const [],
  }) async {
    try {
      final post = await _dataSource.createPost(
        content: content,
        category: category,
        visibility: visibility,
        imageUrls: imageUrls,
      );

      _posts.insert(0, post);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Gagal membuat postingan.';
      notifyListeners();
      return false;
    }
  }

  /// Toggle like on a post (optimistic update).
  Future<void> toggleLike(String postId) async {
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index != -1) {
      final post = _posts[index];
      final newLiked = !post.isLiked;
      final newCount = newLiked ? post.likesCount + 1 : post.likesCount - 1;

      // Optimistic update
      _posts[index] = post.copyWith(
        isLiked: newLiked,
        likesCount: newCount,
      );
      if (_currentPost?.id == postId) {
        _currentPost = _posts[index];
      }
      notifyListeners();

      try {
        await _dataSource.toggleLike(postId);
      } catch (e) {
        // Rollback
        _posts[index] = post;
        if (_currentPost?.id == postId) {
          _currentPost = post;
        }
        notifyListeners();
      }
    }
  }

  /// Add a comment to a post.
  Future<bool> addComment(
    String postId, {
    required String content,
    String? parentId,
  }) async {
    try {
      final comment = await _dataSource.addComment(
        postId,
        content: content,
        parentId: parentId,
      );

      if (parentId != null) {
        // Add as reply to parent
        _addReplyToComment(parentId, comment);
      } else {
        _comments.insert(0, comment);
      }

      // Update comment count
      final postIndex = _posts.indexWhere((p) => p.id == postId);
      if (postIndex != -1) {
        _posts[postIndex] = _posts[postIndex].copyWith(
          commentsCount: _posts[postIndex].commentsCount + 1,
        );
      }
      if (_currentPost?.id == postId) {
        _currentPost = _currentPost!.copyWith(
          commentsCount: _currentPost!.commentsCount + 1,
        );
      }

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Gagal mengirim komentar.';
      notifyListeners();
      return false;
    }
  }

  void _addReplyToComment(String parentId, CommentModel reply) {
    for (int i = 0; i < _comments.length; i++) {
      if (_comments[i].id == parentId) {
        _comments[i] = _comments[i].copyWith(
          replies: [..._comments[i].replies, reply],
        );
        return;
      }
      // Check nested replies
      for (int j = 0; j < _comments[i].replies.length; j++) {
        if (_comments[i].replies[j].id == parentId) {
          final updatedReplies = List<CommentModel>.from(_comments[i].replies);
          updatedReplies.insert(j + 1, reply);
          _comments[i] = _comments[i].copyWith(replies: updatedReplies);
          return;
        }
      }
    }
  }

  /// Delete a comment.
  Future<bool> deleteComment(String postId, String commentId) async {
    try {
      await _dataSource.deleteComment(postId, commentId);
      _comments.removeWhere((c) => c.id == commentId);

      final postIndex = _posts.indexWhere((p) => p.id == postId);
      if (postIndex != -1) {
        _posts[postIndex] = _posts[postIndex].copyWith(
          commentsCount: (_posts[postIndex].commentsCount - 1)
              .clamp(0, 999999),
        );
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Gagal menghapus komentar.';
      notifyListeners();
      return false;
    }
  }

  /// Report a post.
  Future<bool> reportPost(String postId, String reason) async {
    try {
      await _dataSource.reportPost(postId, reason: reason);
      return true;
    } catch (e) {
      _errorMessage = 'Gagal melaporkan postingan.';
      notifyListeners();
      return false;
    }
  }

  /// Fetch zone info.
  Future<void> fetchZoneInfo() async {
    try {
      _zoneInfo = await _dataSource.getZoneInfo();
      notifyListeners();
    } catch (e) {
      // Silently fail, zone info is optional
    }
  }

  /// Fetch advocacy data.
  Future<void> fetchAdvocacyData() async {
    try {
      _advocacyData = await _dataSource.getAdvocacyData();
      notifyListeners();
    } catch (e) {
      // Use mock data as fallback
      _advocacyData = _mockAdvocacyData();
      notifyListeners();
    }
  }

  /// Mock advocacy data for development.
  Map<String, dynamic> _mockAdvocacyData() {
    return {
      'stats': {
        'total_members': 2340,
        'avg_profit': 2100000,
        'pinjol_percentage': 65,
        'avg_hours': 10.5,
      },
      'petitions': [
        {
          'id': '1',
          'title': 'Kenaikan Tarif Minimum Ojol',
          'description':
              'Menuntut kenaikan tarif minimum per km dari Rp 1.800 menjadi Rp 2.500 untuk mengikuti inflasi dan biaya operasional.',
          'target_signatures': 5000,
          'current_signatures': 3247,
        },
        {
          'id': '2',
          'title': 'Perlindungan Asuransi untuk Driver',
          'description':
              'Mendorong platform menyediakan asuransi kesehatan dan kecelakaan kerja untuk semua driver aktif.',
          'target_signatures': 10000,
          'current_signatures': 6891,
        },
      ],
      'policy_updates': [
        {
          'id': '1',
          'title': 'Perubahan Tarif GrabFood per 1 Agustus 2026',
          'date': '2026-07-10',
          'summary':
              'Grab mengumumkan penyesuaian tarif pengantaran makanan dengan peningkatan base fare sebesar 5%.',
        },
        {
          'id': '2',
          'title': 'Regulasi Baru Ojol dari Kemenhub',
          'date': '2026-07-08',
          'summary':
              'Kementerian Perhubungan mewajibkan semua platform ride-hailing memiliki program kesejahteraan driver.',
        },
      ],
      'polls': [
        {
          'id': '1',
          'question': 'Apakah Anda setuju dengan sistem insentif baru?',
          'options': [
            {'id': 'a', 'text': 'Ya, lebih adil', 'votes': 1250},
            {'id': 'b', 'text': 'Tidak, merugikan', 'votes': 890},
            {'id': 'c', 'text': 'Perlu perbaikan', 'votes': 560},
          ],
          'total_votes': 2700,
          'has_voted': false,
        },
      ],
    };
  }
}
