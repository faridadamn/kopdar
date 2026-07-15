import 'package:flutter/material.dart';
import '../../../../config/theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../data/models/post_model.dart';
import 'category_tag.dart';

/// Post card widget for the community feed.
class PostCard extends StatelessWidget {
  final PostModel post;
  final VoidCallback? onTap;
  final VoidCallback? onLike;
  final VoidCallback? onComment;

  const PostCard({
    super.key,
    required this.post,
    this.onTap,
    this.onLike,
    this.onComment,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
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
            // ── Header: Avatar, name, badges, time ──
            _PostHeader(post: post),
            const SizedBox(height: 10),

            // ── Content ──
            Text(
              post.content,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.gray800,
                height: 1.5,
              ),
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),

            // ── Images ──
            if (post.imageUrls.isNotEmpty) ...[
              _ImageGrid(imageUrls: post.imageUrls),
              const SizedBox(height: 10),
            ],

            // ── Category tag ──
            CategoryTag(category: post.category, compact: true),
            const SizedBox(height: 10),

            // ── Action bar ──
            _ActionBar(
              post: post,
              onLike: onLike,
              onComment: onComment,
            ),
          ],
        ),
      ),
    );
  }
}

class _PostHeader extends StatelessWidget {
  final PostModel post;

  const _PostHeader({required this.post});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Avatar
        _Avatar(
          name: post.driverName,
          avatarUrl: post.driverAvatar,
          radius: 18,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      post.driverName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.gray900,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (post.isPinned) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.push_pin, size: 14, color: AppColors.accent),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Wrap(
                spacing: 6,
                children: [
                  if (post.driverZone != null)
                    _MiniBadge(
                      label: post.driverZone!,
                      color: AppColors.blue,
                      bgColor: AppColors.blueLight,
                    ),
                  if (post.driverPlatform != null)
                    _MiniBadge(
                      label: post.driverPlatform!,
                      color: AppColors.primary,
                      bgColor: AppColors.primaryBg,
                    ),
                  Text(
                    Formatters.relativeTime(post.createdAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.gray500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MiniBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color bgColor;

  const _MiniBadge({
    required this.label,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _ImageGrid extends StatelessWidget {
  final List<String> imageUrls;

  const _ImageGrid({required this.imageUrls});

  @override
  Widget build(BuildContext context) {
    final displayUrls = imageUrls.take(3).toList();

    if (displayUrls.length == 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Image.network(
            displayUrls[0],
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: AppColors.gray200,
              child: const Center(
                child: Icon(Icons.broken_image, color: AppColors.gray400),
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: displayUrls.asMap().entries.map((entry) {
        final index = entry.key;
        final url = entry.value;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: index < displayUrls.length - 1 ? 4 : 0,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: AspectRatio(
                aspectRatio: 1,
                child: Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: AppColors.gray200,
                    child: const Center(
                      child: Icon(Icons.broken_image, color: AppColors.gray400),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ActionBar extends StatelessWidget {
  final PostModel post;
  final VoidCallback? onLike;
  final VoidCallback? onComment;

  const _ActionBar({
    required this.post,
    this.onLike,
    this.onComment,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Like button
        GestureDetector(
          onTap: onLike,
          child: Row(
            children: [
              Icon(
                post.isLiked ? Icons.favorite : Icons.favorite_border,
                size: 20,
                color: post.isLiked ? AppColors.danger : AppColors.gray500,
              ),
              const SizedBox(width: 4),
              Text(
                post.likesCount > 0 ? '${post.likesCount}' : '',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: post.isLiked ? AppColors.danger : AppColors.gray500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 20),
        // Comment button
        GestureDetector(
          onTap: onComment,
          child: Row(
            children: [
              Icon(
                Icons.chat_bubble_outline,
                size: 18,
                color: AppColors.gray500,
              ),
              const SizedBox(width: 4),
              Text(
                post.commentsCount > 0 ? '${post.commentsCount}' : '',
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
    );
  }
}

/// Reusable avatar widget with first-letter fallback.
class _Avatar extends StatelessWidget {
  final String name;
  final String? avatarUrl;
  final double radius;

  const _Avatar({
    required this.name,
    this.avatarUrl,
    this.radius = 18,
  });

  @override
  Widget build(BuildContext context) {
    final firstLetter = name.isNotEmpty ? name[0].toUpperCase() : '?';

    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(avatarUrl!),
        onBackgroundImageError: (_, __) {},
        child: avatarUrl!.isEmpty
            ? _FallbackAvatar(letter: firstLetter, radius: radius)
            : null,
      );
    }

    return _FallbackAvatar(letter: firstLetter, radius: radius);
  }
}

class _FallbackAvatar extends StatelessWidget {
  final String letter;
  final double radius;

  const _FallbackAvatar({required this.letter, required this.radius});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primaryBg,
      child: Text(
        letter,
        style: TextStyle(
          fontSize: radius * 0.8,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
