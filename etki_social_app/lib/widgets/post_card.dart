import 'dart:math';
import 'package:flutter/material.dart';
import 'package:etki_social_app/constants/app_colors.dart';
import 'package:etki_social_app/models/post_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:etki_social_app/utils/user_utils.dart';
import '../screens/mission/mission_details_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:etki_social_app/services/auth_service.dart';
import 'package:go_router/go_router.dart';
import 'package:etki_social_app/screens/comments/comment_screen.dart';

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
  int _currentPage = 0;
  Map<String, dynamic>? _userData;
  final AuthService _authService = AuthService();
  bool _isFollowing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.post.userId)
          .get();
      
      if (mounted && userDoc.exists) {
        setState(() {
          _userData = userDoc.data();
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
    await _checkFollowStatus();
  }

  Future<void> _checkFollowStatus() async {
    try {
      final isFollowing = await _authService.isFollowingUser(widget.post.userId);
      if (mounted) {
        setState(() {
          _isFollowing = isFollowing;
        });
      }
    } catch (e) {
      print('Error checking follow status: $e');
    }
  }

  Future<void> _toggleFollow() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isFollowing) {
        await _authService.unfollowUser(widget.post.userId);
      } else {
        await _authService.followUser(widget.post.userId);
      }

      setState(() {
        _isFollowing = !_isFollowing;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isFollowing ? 'Kullanıcı takip edildi' : 'Kullanıcı takipten çıkarıldı'),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bir hata oluştu. Lütfen tekrar deneyin.'),
          duration: Duration(seconds: 2),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MissionDetailsScreen(post: widget.post),
          ),
        );
      },
      child: Container(
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
                fontSize: 16,
                fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          if (widget.post.content.isNotEmpty) ...[
              const SizedBox(height: 6),
            Text(
              widget.post.content,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
            ),
          ],
            const SizedBox(height: 10),
          
          // Mission details row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Reward
              Row(
                children: [
                    _buildCoinIcon(size: 14),
                  const SizedBox(width: 4),
                  Text(
                    '${widget.post.missionReward ?? 100} Coin',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.amber[700],
                    ),
                  ),
                ],
              ),
              
              // Participants
              Row(
                children: [
                  const Icon(
                    Icons.group,
                      size: 14,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${widget.post.missionParticipants?.length ?? 0}/${widget.post.maxParticipants ?? "∞"}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              
              // Deadline
              if (widget.post.missionDeadline != null)
                Row(
                  children: [
                    const Icon(
                        Icons.access_time,
                        size: 14,
                        color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                        _formatDeadline(widget.post.missionDeadline!),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
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
                  'Göreve Katıl',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildCoinIcon({double size = 16}) {
    return Container(
      width: size,
      height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
        color: Colors.amber,
              boxShadow: [
                BoxShadow(
            color: Colors.amber.withOpacity(0.3),
            blurRadius: 4,
            spreadRadius: 1,
                ),
              ],
            ),
      child: Center(
        child: Text(
            '₺',
            style: TextStyle(
              color: Colors.white,
            fontSize: size * 0.7,
              fontWeight: FontWeight.bold,
            ),
          ),
      ),
    );
  }

  String _formatDeadline(DateTime deadline) {
    final remaining = deadline.difference(DateTime.now());
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
    if (_userData == null) {
      return const SizedBox.shrink();
    }

    return Stack(
      children: [
        GestureDetector(
          onDoubleTap: _handleDoubleTap,
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: Colors.grey.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Post Header
                Padding(
                  padding: const EdgeInsets.all(16),
                    child: _buildUserInfo(),
                ),

                // Post Content
                if (widget.post.type == PostType.text) ...[
                    if (widget.post.content.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      widget.post.content,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.grey,
                            height: 1.5,
                          ),
                        ),
                      ),
                    if (widget.post.imageUrls != null && widget.post.imageUrls!.isNotEmpty)
                      _buildPostImages(),
                  ] else if (widget.post.type == PostType.image) ...[
                    if (widget.post.content.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      widget.post.content,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.grey,
                            height: 1.5,
                          ),
                        ),
                      ),
                    if (widget.post.imageUrls != null && widget.post.imageUrls!.isNotEmpty)
                      _buildPostImages(),
                  ] else if (widget.post.type == PostType.mission) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: _buildMissionContent(),
                    ),
                ],

                // Post Actions
                Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: _buildPostActions(),
                      ),
                    ],
                  ),
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

  Widget _buildUserInfo() {
    return GestureDetector(
      onTap: () {
        GoRouter.of(context).push('/profile/${widget.post.userId}');
      },
      child: Row(
        children: [
          // Profile Image
          Stack(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primary.withOpacity(0.2),
                backgroundImage: _userData?['profileImageUrl'] != null || _userData?['profileImage'] != null
                    ? NetworkImage(_userData?['profileImageUrl'] ?? _userData?['profileImage'] ?? '')
                    : null,
                child: _userData?['profileImageUrl'] == null && _userData?['profileImage'] == null
                    ? Text(
                        (_userData?['username'] ?? 'K')[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      )
                    : null,
              ),
              if (_userData?['isVerified'] ?? false)
                Positioned(
                  right: -2,
                  bottom: -2,
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
              if (_userData?['missionCount'] != null && _userData!['missionCount'] >= 10)
                Positioned(
                  right: 12,
                  bottom: -2,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.verified,
                      size: 12,
                      color: Colors.amber,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          // Username and time
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _userData?['username'] ?? 'Kullanıcı',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  _formatDate(widget.post.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          // Follow button
          if (widget.post.userId != _authService.currentUser?.uid)
            _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : TextButton(
                    onPressed: _toggleFollow,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: _isFollowing ? Colors.grey[300]! : AppColors.primary,
                          width: 1,
                        ),
                      ),
                      backgroundColor: _isFollowing ? Colors.grey[100] : AppColors.primary,
                    ),
                    child: Text(
                      _isFollowing ? 'Takibi Bırak' : 'Takip Et',
                      style: TextStyle(
                        color: _isFollowing ? Colors.grey[700] : Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
        ],
      ),
    );
  }

  Widget _buildPostActions() {
    return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              // Like button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _handleLikePressed,
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: AnimatedBuilder(
                      animation: _likeController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _scaleAnimation.value,
                          child: Icon(
                            _isLiked ? Icons.favorite : Icons.favorite_border,
                            color: _isLiked ? Colors.red : Colors.grey[600],
                            size: 20,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
                      Text(
                        widget.post.likes.length.toString(),
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 16),
              
              // Comment button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _handleCommentTap,
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      Icons.chat_bubble_outline,
                      color: Colors.grey[600],
                      size: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
                      Text(
                        widget.post.comments.length.toString(),
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          
          // Share button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onShare,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  Icons.share_outlined,
                  color: Colors.grey[600],
                  size: 20,
                ),
              ),
            ),
          ),
      ],
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    
    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} yıl önce';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} ay önce';
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

  Widget _buildPostImages() {
    if (widget.post.imageUrls == null || widget.post.imageUrls!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        // Image carousel
        SizedBox(
          height: 300,
          child: PageView.builder(
            itemCount: widget.post.imageUrls!.length,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              return CachedNetworkImage(
                imageUrl: widget.post.imageUrls![index],
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[100],
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary.withOpacity(0.5),
                      strokeWidth: 2,
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[100],
                  child: const Center(
                    child: Icon(
                      Icons.error_outline,
                      color: Colors.grey,
                      size: 32,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        // Image indicators
        if (widget.post.imageUrls!.length > 1)
          Container(
            padding: const EdgeInsets.only(bottom: 8.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.transparent,
                ],
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.post.imageUrls!.length,
                (index) => Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentPage == index
                        ? Colors.white
                        : Colors.white.withOpacity(0.5),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _handleCommentTap() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => CommentScreen(
          post: widget.post,
          onCommentAdded: (comment) {
            setState(() {
              widget.post.comments.add(comment);
            });
          },
          collection: widget.post.type == PostType.mission ? 'tasks' : 'posts',
        ),
      ),
    );
  }
} 