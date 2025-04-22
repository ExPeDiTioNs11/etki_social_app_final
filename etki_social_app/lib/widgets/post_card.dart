import 'dart:math';
import 'package:flutter/material.dart';
import 'package:etki_social_app/constants/app_colors.dart';
import 'package:etki_social_app/models/post_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:etki_social_app/utils/user_utils.dart';
import '../screens/mission/mission_details_screen.dart';

class PostCard extends StatefulWidget {
  final Post post;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onShare;

  const PostCard({
    super.key,
    required this.post,
    this.onLike,
    this.onComment,
    this.onShare,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> with TickerProviderStateMixin {
  late AnimationController _likeController;
  late AnimationController _heartController;
  late AnimationController _starController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _heartAnimation;
  bool _showHeart = false;
  final List<double> _randomOffsets = List.generate(8, (index) => Random().nextDouble() * pi);

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _likeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _heartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _starController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.3),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.3, end: 1.0),
        weight: 50,
      ),
    ]).animate(CurvedAnimation(
      parent: _likeController,
      curve: Curves.easeInOut,
    ));

    _heartAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0),
        weight: 80,
      ),
    ]).animate(CurvedAnimation(
      parent: _heartController,
      curve: Curves.easeOut,
    ));

    _heartController.addStatusListener(_handleHeartAnimationStatus);
  }

  void _handleHeartAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      if (mounted) {
        setState(() {
          _showHeart = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _starController.dispose();
    _heartController.removeStatusListener(_handleHeartAnimationStatus);
    _likeController.dispose();
    _heartController.dispose();
    super.dispose();
  }

  void _handleLikePressed() {
    if (!mounted) return;
    _likeController.forward(from: 0.0);
    widget.onLike?.call();
  }

  void _handleDoubleTap() {
    if (!widget.post.likes.contains(UserUtils.getCurrentUser()) && mounted) {
      setState(() {
        _showHeart = true;
      });
      _likeController.forward(from: 0.0);
      _heartController.forward(from: 0.0);
      widget.onLike?.call();
    }
  }

  bool get _isLiked => widget.post.likes.contains(UserUtils.getCurrentUser());

  Widget _buildMissionContent() {
    if (widget.post.missionTitle == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mission title
          Text(
            widget.post.missionTitle!,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          if (widget.post.content.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              widget.post.content,
              style: const TextStyle(fontSize: 14),
            ),
          ],
          const SizedBox(height: 12),
          
          // Mission details row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Reward
              Row(
                children: [
                  _buildCoinIcon(),
                  const SizedBox(width: 4),
                  Text(
                    '${widget.post.missionReward ?? 100} Coin',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.amber,
                    ),
                  ),
                ],
              ),
              
              // Participants
              Row(
                children: [
                  const Icon(
                    Icons.group,
                    size: 16,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${widget.post.missionParticipants?.length ?? 0}/${widget.post.maxParticipants ?? "∞"}',
                    style: const TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              
              // Deadline
              if (widget.post.missionDeadline != null)
                Row(
                  children: [
                    const Icon(
                      Icons.timer,
                      size: 16,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _getRemainingTime(),
                      style: const TextStyle(
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Participants list
          if ((widget.post.missionParticipants?.length ?? 0) > 0) ...[
            const Text(
              'Katılımcılar',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 32,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: widget.post.missionParticipants!.length,
                itemBuilder: (context, index) {
                  final participant = widget.post.missionParticipants![index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: _getStatusColor(participant.status),
                      child: Text(
                        (participant.username ?? participant.userId)[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          
          const SizedBox(height: 12),
          
          // Participate button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MissionDetailsScreen(post: widget.post),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                'Detayları Görüntüle',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoinIcon() {
    return SizedBox(
      width: 32,
      height: 32,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Rotating stars
          AnimatedBuilder(
            animation: _starController,
            builder: (context, child) {
              return Stack(
                alignment: Alignment.center,
                children: List.generate(8, (index) {
                  final baseAngle = (index / 8) * 2 * pi;
                  final randomOffset = _randomOffsets[index];
                  final oscillation = sin(_starController.value * 2 * pi + randomOffset);
                  final distance = 12 + oscillation * 2;
                  final starRotation = _starController.value * 4 * pi + randomOffset;
                  final opacity = 0.3 + (0.7 * (sin(_starController.value * 2 * pi + randomOffset) + 1) / 2);
                  
                  return Transform.translate(
                    offset: Offset(
                      cos(baseAngle + _starController.value * pi) * distance,
                      sin(baseAngle + _starController.value * pi) * distance,
                    ),
                    child: Transform.rotate(
                      angle: starRotation,
                      child: Icon(
                        Icons.star,
                        size: 6,
                        color: Colors.amber.withOpacity(opacity),
                      ),
                    ),
                  );
                }),
              );
            },
          ),
          // Coin background glow
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.amber[300]!.withOpacity(0.5),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
          // Main coin icon
          const Icon(
            Icons.circle,
            size: 16,
            color: Colors.amber,
          ),
          // Coin symbol
          const Text(
            '₺',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  color: Colors.black26,
                  offset: Offset(0, 1),
                  blurRadius: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getRemainingTime() {
    if (widget.post.missionDeadline == null) return '∞';
    
    final remaining = widget.post.missionDeadline!.difference(DateTime.now());
    if (remaining.isNegative) return 'Süresi doldu';
    
    if (remaining.inDays > 0) {
      return '${remaining.inDays}g';
    } else if (remaining.inHours > 0) {
      return '${remaining.inHours}s';
    } else {
      return '${remaining.inMinutes}d';
    }
  }

  Color _getStatusColor(MissionStatus status) {
    switch (status) {
      case MissionStatus.pending:
        return Colors.grey;
      case MissionStatus.accepted:
        return Colors.blue;
      case MissionStatus.inProgress:
        return Colors.orange;
      case MissionStatus.submitted:
        return Colors.purple;
      case MissionStatus.completed:
        return Colors.green;
      case MissionStatus.rejected:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          onDoubleTap: _handleDoubleTap,
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.divider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Post Header
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: AppColors.primary,
                            child: Text(
                              widget.post.userId[0].toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (widget.post.isVerified)
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
                                  size: 14,
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
                            Text(
                              widget.post.userId,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _getTimeAgo(widget.post.createdAt),
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.more_vert),
                        onPressed: () {
                          // TODO: Show post options
                        },
                      ),
                    ],
                  ),
                ),

                // Post Content
                if (widget.post.type == PostType.text) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      widget.post.content,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ] else if (widget.post.type == PostType.image && widget.post.imageUrls != null) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      widget.post.content,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  SizedBox(
                    height: 300,
                    child: PageView.builder(
                      itemCount: widget.post.imageUrls!.length,
                      itemBuilder: (context, index) {
                        return CachedNetworkImage(
                          imageUrl: widget.post.imageUrls![index],
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Colors.grey[300],
                          ),
                          errorWidget: (context, url, error) => const Center(
                            child: Icon(Icons.error),
                          ),
                        );
                      },
                    ),
                  ),
                ] else if (widget.post.type == PostType.mission) ...[
                  _buildMissionContent(),
                ],

                // Post Actions
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: IconButton(
                          icon: Icon(
                            _isLiked ? Icons.favorite : Icons.favorite_border,
                            color: _isLiked ? Colors.red : null,
                          ),
                          onPressed: _handleLikePressed,
                        ),
                      ),
                      Text(
                        widget.post.likes.length.toString(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: const Icon(Icons.comment_outlined),
                        onPressed: widget.onComment,
                      ),
                      Text(
                        widget.post.comments.length.toString(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: const Icon(Icons.share_outlined),
                        onPressed: widget.onShare,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_showHeart)
          Positioned.fill(
            child: ScaleTransition(
              scale: _heartAnimation,
              child: const Icon(
                Icons.favorite,
                color: Colors.red,
                size: 80,
              ),
            ),
          ),
      ],
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inDays > 7) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} gün önce';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} saat önce';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} dakika önce';
    } else {
      return 'Az önce';
    }
  }
} 