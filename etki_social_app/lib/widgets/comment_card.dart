import 'package:flutter/material.dart';
import 'package:etki_social_app/constants/app_colors.dart';
import 'package:etki_social_app/models/post_model.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CommentCard extends StatelessWidget {
  final Comment comment;
  final VoidCallback? onReply;
  final VoidCallback? onLike;
  final bool showReplies;
  final bool isReply;
  final bool isLiked;
  final Function(String)? onViewProfile;

  const CommentCard({
    super.key,
    required this.comment,
    this.onReply,
    this.onLike,
    this.showReplies = true,
    this.isReply = false,
    this.isLiked = false,
    this.onViewProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(
        left: isReply ? 48 : 0,
        right: 16,
        top: 8,
        bottom: 8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.grey[300],
                    child: Text(
                      (comment.username ?? comment.userId)[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  if (comment.isVerified)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.verified,
                          size: 12,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: DefaultTextStyle.of(context).style,
                        children: [
                          TextSpan(
                            text: comment.username ?? 'Kullanıcı',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          TextSpan(
                            text: ' ${comment.content}',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          _getTimeAgo(comment.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 16),
                        if (comment.likes.isNotEmpty)
                          Text(
                            '${comment.likes.length} beğeni',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        const SizedBox(width: 16),
                        if (onReply != null)
                          GestureDetector(
                            onTap: onReply,
                            child: Text(
                              'Yanıtla',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onLike,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Icon(
                    isLiked ? Icons.favorite : Icons.favorite_border,
                    size: 16,
                    color: isLiked ? AppColors.primary : Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
          if (showReplies && comment.replies.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 44, top: 8),
              child: Column(
                children: comment.replies.map((reply) {
                  return CommentCard(
                    comment: reply,
                    onReply: onReply,
                    onLike: onLike,
                    showReplies: false,
                    isReply: true,
                    isLiked: isLiked,
                    onViewProfile: onViewProfile,
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inDays > 7) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}g';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}s';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}d';
    } else {
      return 'Şimdi';
    }
  }
} 