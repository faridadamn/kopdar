import 'package:flutter/material.dart';
import '../../../../config/theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../data/models/post_model.dart';

/// Comment tile widget showing a single comment with optional replies.
class CommentTile extends StatelessWidget {
  final CommentModel comment;
  final VoidCallback? onReply;
  final VoidCallback? onDelete;
  final bool isReply;

  const CommentTile({
    super.key,
    required this.comment,
    this.onReply,
    this.onDelete,
    this.isReply = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: isReply ? 40 : 0, top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CommentAvatar(
                name: comment.driverName,
                avatarUrl: comment.driverAvatar,
                size: isReply ? 14 : 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name + time
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            comment.driverName,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.gray900,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          Formatters.relativeTime(comment.createdAt),
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.gray500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Content
                    Text(
                      comment.content,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.gray700,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Action buttons
                    if (!isReply)
                      Row(
                        children: [
                          GestureDetector(
                            onTap: onReply,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.reply,
                                  size: 14,
                                  color: AppColors.gray500,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Balas',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.gray500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (onDelete != null) ...[
                            const SizedBox(width: 16),
                            GestureDetector(
                              onTap: onDelete,
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.delete_outline,
                                    size: 14,
                                    color: AppColors.danger.withOpacity(0.7),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Hapus',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.danger.withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),

          // ── Nested replies ──
          if (comment.replies.isNotEmpty)
            ...comment.replies.map(
              (reply) => CommentTile(
                comment: reply,
                isReply: true,
                onDelete: onDelete,
              ),
            ),
        ],
      ),
    );
  }
}

class _CommentAvatar extends StatelessWidget {
  final String name;
  final String? avatarUrl;
  final double size;

  const _CommentAvatar({
    required this.name,
    this.avatarUrl,
    this.size = 16,
  });

  @override
  Widget build(BuildContext context) {
    final firstLetter = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return CircleAvatar(
      radius: size,
      backgroundColor: AppColors.primaryBg,
      child: avatarUrl != null && avatarUrl!.isNotEmpty
          ? ClipOval(
              child: Image.network(
                avatarUrl!,
                width: size * 2,
                height: size * 2,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Text(
                  firstLetter,
                  style: TextStyle(
                    fontSize: size * 0.75,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            )
          : Text(
              firstLetter,
              style: TextStyle(
                fontSize: size * 0.75,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
    );
  }
}
