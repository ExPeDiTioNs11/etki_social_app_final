import 'package:flutter/material.dart';
import 'package:etki_social_app/constants/app_colors.dart';
import 'package:etki_social_app/models/post_model.dart';
import 'package:etki_social_app/widgets/post_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:etki_social_app/services/auth_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'followers_list_modal.dart';
import 'following_list_modal.dart';

class OtherUserProfileScreen extends StatefulWidget {
  final String userId;

  const OtherUserProfileScreen({
    super.key,
    required this.userId,
  });

  @override
  State<OtherUserProfileScreen> createState() => _OtherUserProfileScreenState();
}

class _OtherUserProfileScreenState extends State<OtherUserProfileScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _userData;
  List<Post> _userPosts = [];
  List<Post> _userMissions = [];
  bool _isLoading = true;
  bool _isFollowing = false;
  final AuthService _authService = AuthService();
  int _followersCount = 0;
  int _followingCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserData();
    _loadUserPosts();
    _loadUserMissions();
    _checkFollowStatus();
    _loadFollowCounts();
  }

  Future<void> _loadUserData() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();
      
      if (mounted && userDoc.exists) {
        setState(() {
          _userData = userDoc.data();
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadUserPosts() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('posts')
          .where('userId', isEqualTo: widget.userId)
          .orderBy('createdAt', descending: true)
          .get();

      setState(() {
        _userPosts = snapshot.docs.map((doc) {
          final data = doc.data();
          return Post(
            id: doc.id,
            userId: data['userId'],
            content: data['content'] ?? '',
            type: PostType.text,
            imageUrls: List<String>.from(data['imageUrls'] ?? []),
            createdAt: (data['createdAt'] as Timestamp).toDate(),
            likes: List<String>.from(data['likes'] ?? []),
            comments: List<Comment>.from((data['comments'] ?? []).map((c) => Comment.fromMap(c))),
          );
        }).toList();
      });
    } catch (e) {
      print('Error loading user posts: $e');
    }
  }

  Future<void> _loadUserMissions() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('tasks')
          .where('creatorId', isEqualTo: widget.userId)
          .get();

      setState(() {
        _userMissions = snapshot.docs.map((doc) {
          final data = doc.data();
          return Post(
            id: doc.id,
            userId: data['creatorId'],
            content: data['description'] ?? '',
            type: PostType.mission,
            missionTitle: data['title'],
            missionDescription: data['description'],
            missionReward: data['coinAmount'],
            missionDeadline: data['deadline'] != null ? (data['deadline'] as Timestamp).toDate() : null,
            missionParticipants: List<MissionParticipant>.from((data['participants'] ?? []).map((p) => MissionParticipant.fromMap(p))),
            maxParticipants: data['participantCount'],
            createdAt: (data['createdAt'] as Timestamp).toDate(),
            likes: List<String>.from(data['likes'] ?? []),
            comments: List<Comment>.from((data['comments'] ?? []).map((c) => Comment.fromMap(c))),
          );
        }).toList();
      });
    } catch (e) {
      print('Error loading user missions: $e');
    }
  }

  Future<void> _checkFollowStatus() async {
    try {
      final isFollowing = await _authService.isFollowingUser(widget.userId);
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
    try {
      if (_isFollowing) {
        await _authService.unfollowUser(widget.userId);
      } else {
        await _authService.followUser(widget.userId);
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
    }
  }

  Future<void> _loadFollowCounts() async {
    try {
      // Kullanıcı dokümanını al
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        setState(() {
          _followersCount = (data['followers'] as List<dynamic>?)?.length ?? 0;
          _followingCount = (data['following'] as List<dynamic>?)?.length ?? 0;
        });
      }
    } catch (e) {
      print('Error loading follow counts: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime dateTime) {
    final months = [
      'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
    ];
    return '${dateTime.day} ${months[dateTime.month - 1]} ${dateTime.year}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  // Banner Image
                  Container(
                    height: 150,
                    color: AppColors.primary.withOpacity(0.8),
                    child: _userData?['bannerImageUrl'] != null || _userData?['bannerImage'] != null
                        ? CachedNetworkImage(
                            imageUrl: _userData?['bannerImageUrl'] ?? _userData?['bannerImage'] ?? '',
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: Colors.grey[200],
                              child: const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey[200],
                              child: const Icon(
                                Icons.error_outline,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : null,
                  ),
                  // Profil fotoğrafı
                  Positioned(
                    left: 16,
                    top: 100,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: AppColors.primary,
                            backgroundImage: _userData?['profileImageUrl'] != null || _userData?['profileImage'] != null
                                ? NetworkImage(_userData?['profileImageUrl'] ?? _userData?['profileImage'] ?? '')
                                : null,
                            child: _userData?['profileImageUrl'] == null && _userData?['profileImage'] == null
                                ? Text(
                                    (_userData?['username'] ?? 'K')[0].toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 32,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _userData?['username'] ?? 'Kullanıcı',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '@${_userData?['username'] ?? 'Kullanıcı'}',
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_userData?['bio'] != null && _userData!['bio'].toString().isNotEmpty)
                          Text(
                            _userData!['bio'],
                            style: TextStyle(
                              color: Colors.grey[800],
                              fontSize: 14,
                            ),
                          ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              _userData?['createdAt'] != null
                                  ? '${_formatDate((_userData!['createdAt'] as Timestamp).toDate())} tarihinden beri üye'
                                  : 'Ocak 2024\'ten beri üye',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Profile Stats
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // Followers
                            InkWell(
                              onTap: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (context) => const FollowersListModal(),
                                );
                              },
                              child: Row(
                                children: [
                                  Text(
                                    _followersCount.toString(),
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Takipçi',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 24),
                            // Following
                            InkWell(
                              onTap: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (context) => const FollowingListModal(),
                                );
                              },
                              child: Row(
                                children: [
                                  Text(
                                    _followingCount.toString(),
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Takip',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 24),
                            // Shared Missions
                            Row(
                              children: [
                                Text(
                                  _userMissions.length.toString(),
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.assignment_outlined,
                                  size: 16,
                                  color: Colors.grey[600],
                                ),
                              ],
                            ),
                            const SizedBox(width: 24),
                            // Completed Missions
                            Row(
                              children: [
                                Text(
                                  '12',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.check_circle_outline,
                                  size: 16,
                                  color: Colors.grey[600],
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Follow Button
                        if (widget.userId != _authService.currentUser?.uid)
                          SizedBox(
                            width: double.infinity,
                            child: TextButton(
                              onPressed: _toggleFollow,
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
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
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPersistentHeader(
            delegate: _SliverAppBarDelegate(
              TabBar(
                controller: _tabController,
                labelColor: AppColors.primary,
                unselectedLabelColor: Colors.grey,
                indicatorColor: AppColors.primary,
                indicatorWeight: 3,
                tabs: const [
                  Tab(text: 'Gönderiler'),
                  Tab(text: 'Görevler'),
                  Tab(text: 'Medya'),
                ],
              ),
            ),
            pinned: true,
          ),
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Posts Tab
                ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _userPosts.length,
                  itemBuilder: (context, index) {
                    final post = _userPosts[index];
                    return PostCard(
                      post: post,
                      onLike: () {
                        // TODO: Implement like functionality
                      },
                      onComment: () {
                        // TODO: Implement comment functionality
                      },
                      onShare: () {
                        // TODO: Implement share functionality
                      },
                    );
                  },
                ),
                // Missions Tab
                ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _userMissions.length,
                  itemBuilder: (context, index) {
                    final post = _userMissions[index];
                    return PostCard(
                      post: post,
                      onLike: () {
                        // TODO: Implement like functionality
                      },
                      onComment: () {
                        // TODO: Implement comment functionality
                      },
                      onShare: () {
                        // TODO: Implement share functionality
                      },
                    );
                  },
                ),
                // Media Tab
                _buildMediaGrid(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaGrid() {
    // Tüm gönderilerden resim içerenleri filtrele ve resim URL'lerini topla
    List<String> allImages = [];
    for (var post in _userPosts) {
      if (post.imageUrls != null && post.imageUrls!.isNotEmpty) {
        allImages.addAll(post.imageUrls!);
      }
    }

    if (allImages.isEmpty) {
      return const Center(
        child: Text(
          'Henüz medya paylaşılmamış',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 16,
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: allImages.length,
      itemBuilder: (context, index) {
        return CachedNetworkImage(
          imageUrl: allImages[index],
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: Colors.grey[200],
            child: const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            color: Colors.grey[200],
            child: const Icon(
              Icons.error_outline,
              color: Colors.grey,
            ),
          ),
        );
      },
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
} 