import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../data/models/post_model.dart';
import '../providers/community_provider.dart';
import '../widgets/post_card.dart';
import '../widgets/comment_tile.dart';
import '../widgets/category_tag.dart';

/// Post detail page showing full post with comments.
class PostDetailPage extends StatefulWidget {
  final String id;

  const PostDetailPage({super.key, required this.id});

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  final _commentController = TextEditingController();
  String? _replyingToId;
  String? _replyingToName;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<CommunityProvider>();
      provider.fetchPost(widget.id);
      provider.fetchComments(widget.id);
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _submitComment() {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    final provider = context.read<CommunityProvider>();
    provider.addComment(
      widget.id,
      content: content,
      parentId: _replyingToId,
    );

    _commentController.clear();
    setState(() {
      _replyingToId = null;
      _replyingToName = null;
    });

    FocusScope.of(context).unfocus();
  }

  void _startReply(String commentId, String driverName) {
    setState(() {
      _replyingToId = commentId;
      _replyingToName = driverName;
    });
    FocusScope.of(context).requestFocus(FocusNode());
  }

  void _cancelReply() {
    setState(() {
      _replyingToId = null;
      _replyingToName = null;
    });
  }

  void _showReportDialog() {
    String selectedReason = 'spam';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Laporkan Post'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Pilih alasan laporan:'),
            const SizedBox(height: 12),
            ...['spam', 'konten tidak pantas', 'hoax', 'ujaran kebencian', 'lainnya']
                .map(
              (reason) => RadioListTile<String>(
                title: Text(reason[0].toUpperCase() + reason.substring(1)),
                value: reason,
                groupValue: selectedReason,
                onChanged: (v) {
                  selectedReason = v!;
                  (context as Element).markNeedsBuild();
                },
                activeColor: AppColors.primary,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<CommunityProvider>().reportPost(
                    widget.id,
                    selectedReason,
                  );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Laporan berhasil dikirim'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
            ),
            child: const Text('Laporkan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        title: const Text('Detail Post'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.flag_outlined),
            onPressed: _showReportDialog,
            tooltip: 'Laporkan',
          ),
        ],
      ),
      body: Consumer<CommunityProvider>(
        builder: (context, provider, _) {
          if (provider.detailStatus == CommunityStatus.loading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (provider.detailStatus == CommunityStatus.error) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('😵', style: TextStyle(fontSize: 48)),
                    const SizedBox(height: 16),
                    Text(
                      provider.errorMessage ?? 'Gagal memuat postingan',
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () => provider.fetchPost(widget.id),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            );
          }

          final post = provider.currentPost;
          if (post == null) {
            return const Center(child: Text('Post tidak ditemukan'));
          }

          return Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    await provider.fetchPost(widget.id);
                    await provider.fetchComments(widget.id);
                  },
                  color: AppColors.primary,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // ── Post content ──
                      _PostDetailCard(post: post, provider: provider),
                      const SizedBox(height: 16),

                      // ── Comments section ──
                      Text(
                        'Komentar (${provider.comments.length})',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.gray900,
                        ),
                      ),
                      const SizedBox(height: 8),

                      if (provider.commentsStatus == CommunityStatus.loading)
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                              strokeWidth: 2,
                            ),
                          ),
                        )
                      else if (provider.comments.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Center(
                            child: Column(
                              children: [
                                const Text('💬', style: TextStyle(fontSize: 32)),
                                const SizedBox(height: 8),
                                Text(
                                  'Belum ada komentar. Jadilah yang pertama!',
                                  style: TextStyle(
                                    color: AppColors.gray500,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ...provider.comments.map(
                          (comment) => CommentTile(
                            comment: comment,
                            onReply: () =>
                                _startReply(comment.id, comment.driverName),
                            onDelete: () =>
                                provider.deleteComment(widget.id, comment.id),
                          ),
                        ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),

              // ── Comment input bar ──
              _CommentInputBar(
                controller: _commentController,
                replyingToName: _replyingToName,
                onSubmit: _submitComment,
                onCancelReply: _cancelReply,
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Full post detail card with actions.
class _PostDetailCard extends StatelessWidget {
  final PostModel post;
  final CommunityProvider provider;

  const _PostDetailCard({required this.post, required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.gray200),
        boxShadow: [
          BoxShadow(
            color: AppColors.gray400.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primaryBg,
                child: post.driverAvatar != null && post.driverAvatar!.isNotEmpty
                    ? ClipOval(
                        child: Image.network(
                          post.driverAvatar!,
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Text(
                        post.driverName.isNotEmpty
                            ? post.driverName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.driverName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.gray900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      children: [
                        if (post.driverZone != null)
                          _Badge(
                            label: post.driverZone!,
                            color: AppColors.blue,
                            bgColor: AppColors.blueLight,
                          ),
                        if (post.driverPlatform != null)
                          _Badge(
                            label: post.driverPlatform!,
                            color: AppColors.primary,
                            bgColor: AppColors.primaryBg,
                          ),
                        Text(
                          Formatters.relativeTime(post.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.gray500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── Content ──
          Text(
            post.content,
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.gray800,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 12),

          // ── Images ──
          if (post.imageUrls.isNotEmpty) ...[
            ...post.imageUrls.map(
              (url) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    url,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 200,
                      color: AppColors.gray200,
                      child: const Center(
                        child: Icon(Icons.broken_image, color: AppColors.gray400),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
          ],

          // ── Category tag ──
          CategoryTag(category: post.category),
          const SizedBox(height: 14),

          // ── Action bar ──
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.gray200)),
            ),
            child: Row(
              children: [
                // Like
                GestureDetector(
                  onTap: () => provider.toggleLike(post.id),
                  child: Row(
                    children: [
                      Icon(
                        post.isLiked
                            ? Icons.favorite
                            : Icons.favorite_border,
                        size: 22,
                        color: post.isLiked
                            ? AppColors.danger
                            : AppColors.gray500,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${post.likesCount}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: post.isLiked
                              ? AppColors.danger
                              : AppColors.gray500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                // Comment
                Row(
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      size: 20,
                      color: AppColors.gray500,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${post.commentsCount}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.gray500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 24),
                // Share
                GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Fitur bagikan segera hadir'),
                        backgroundColor: AppColors.info,
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      Icon(
                        Icons.share_outlined,
                        size: 20,
                        color: AppColors.gray500,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Bagikan',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.gray500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final Color bgColor;

  const _Badge({
    required this.label,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

/// Comment input bar at the bottom.
class _CommentInputBar extends StatelessWidget {
  final TextEditingController controller;
  final String? replyingToName;
  final VoidCallback onSubmit;
  final VoidCallback onCancelReply;

  const _CommentInputBar({
    required this.controller,
    this.replyingToName,
    required this.onSubmit,
    required this.onCancelReply,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.gray400.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Reply indicator
            if (replyingToName != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                color: AppColors.primaryBg,
                child: Row(
                  children: [
                    Icon(Icons.reply, size: 16, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Membalas $replyingToName',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: onCancelReply,
                      child: Icon(Icons.close, size: 18, color: AppColors.gray500),
                    ),
                  ],
                ),
              ),
            // Input row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      decoration: InputDecoration(
                        hintText: 'Tulis komentar...',
                        hintStyle: TextStyle(color: AppColors.gray400),
                        filled: true,
                        fillColor: AppColors.gray100,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 1.5,
                          ),
                        ),
                      ),
                      style: const TextStyle(fontSize: 14),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => onSubmit(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onSubmit,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.send,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
