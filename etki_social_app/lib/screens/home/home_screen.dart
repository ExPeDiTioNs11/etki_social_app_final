import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';  // DragStartBehavior için import
import 'package:go_router/go_router.dart';
import 'package:etki_social_app/constants/app_colors.dart';
import 'package:etki_social_app/models/post_model.dart';
import 'package:etki_social_app/models/story.dart';
import 'package:etki_social_app/widgets/post_card.dart';
import 'package:etki_social_app/widgets/comment_card.dart';
import 'package:etki_social_app/screens/profile/profile_screen.dart';
import 'package:etki_social_app/utils/user_utils.dart';
import 'package:etki_social_app/screens/create_post/create_post_screen.dart';
import 'following_tab.dart';
import '../notifications/notifications_screen.dart';
import '../messages/messages_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isSpeedDialOpen = false;
  late AnimationController _speedDialController;
  late Animation<double> _speedDialAnimation;
  final TextEditingController _searchController = TextEditingController();
  
  // Post lists for different tabs
  final List<Post> _explorePosts = List.generate(10, (index) {
    // Her 3. gönderi bir görev olacak
    if (index % 3 == 0) {
      return Post(
        id: 'mission_$index',
        userId: 'mission_creator_$index',
        content: 'Bu görev için detaylı açıklama burada yer alacak.',
        type: PostType.mission,
        missionTitle: 'Görev ${index + 1}',
        missionDescription: 'Bu görevi tamamlamak için yapmanız gerekenler...',
        missionReward: (index + 1) * 100, // Her görev için farklı ödül
        missionDeadline: DateTime.now().add(Duration(days: index + 1)), // Her görev için farklı son tarih
        missionParticipants: List.generate(
          index % 4, // Her görev için farklı sayıda katılımcı
          (i) => MissionParticipant(
            userId: 'participant_$i',
            username: 'Katılımcı $i',
            status: MissionStatus.values[i % MissionStatus.values.length],
          ),
        ),
        maxParticipants: 10,
        createdAt: DateTime.now().subtract(Duration(hours: index)),
        isVerified: true,
        comments: [
          Comment(
            id: 'comment_${index}_1',
            userId: 'commenter_1',
            username: 'Ahmet Yılmaz',
            content: 'Bu görevi tamamlamak için yardıma ihtiyacım var.',
            createdAt: DateTime.now().subtract(Duration(minutes: 30)),
            isVerified: true,
            likes: [],
            replies: [],
          ),
          Comment(
            id: 'comment_${index}_2',
            userId: 'commenter_2',
            username: 'Ayşe Demir',
            content: 'Ben de katılmak istiyorum!',
            createdAt: DateTime.now().subtract(Duration(hours: 1)),
            likes: [],
            replies: [],
          ),
        ],
        likes: [],
      );
    } else {
      return Post(
    id: 'explore_$index',
    userId: 'user_$index',
    content: 'Keşfet tabındaki örnek gönderi $index',
    type: PostType.text,
    createdAt: DateTime.now().subtract(Duration(hours: index)),
        isVerified: index % 3 == 0,
    comments: [
      Comment(
        id: 'comment_${index}_1',
        userId: 'commenter_1',
        username: 'Ahmet Yılmaz',
        content: 'Harika bir gönderi!',
        createdAt: DateTime.now().subtract(Duration(minutes: 30)),
            isVerified: true,
        likes: [],
        replies: [],
      ),
      Comment(
        id: 'comment_${index}_2',
        userId: 'commenter_2',
        username: 'Ayşe Demir',
        content: 'Bunu denemek istiyorum.',
        createdAt: DateTime.now().subtract(Duration(hours: 1)),
        likes: [],
        replies: [],
      ),
    ],
    likes: [],
      );
    }
  });

  final List<Post> _followingPosts = [
    Post(
      id: '1',
      userId: 'john_doe',
      content: 'Bu bir test gönderisidir!',
      type: PostType.text,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      isVerified: true, // Onaylı kullanıcı
      comments: [
        Comment(
          id: 'comment_1',
          userId: 'jane_doe',
          username: 'Jane Doe',
          content: 'Harika bir gönderi!',
          createdAt: DateTime.now().subtract(const Duration(hours: 1)),
          isVerified: true, // Onaylı yorumcu
          likes: [],
          replies: [
            Comment(
              id: 'reply_1',
              userId: 'john_doe',
              username: 'John Doe',
              content: 'Teşekkür ederim!',
              createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
              isVerified: true, // Onaylı kullanıcı
              likes: [],
              replies: [],
            ),
          ],
        ),
      ],
      likes: [],
    ),
    Post(
      id: '2',
      userId: 'jane_doe',
      content: 'Bugün harika bir gün!',
      type: PostType.image,
      imageUrls: [
        'https://picsum.photos/800/600',
        'https://picsum.photos/800/600?random=1',
      ],
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      isVerified: true, // Onaylı kullanıcı
      comments: [],
      likes: [],
    ),
    Post(
      id: '3',
      userId: 'mission_master',
      content: 'Bu hafta 5 km koşu yapın ve fotoğrafını paylaşın.',
      type: PostType.mission,
      missionTitle: 'Haftalık Koşu Görevi',
      missionDescription: 'Sağlıklı yaşam için spor yapmayı unutmayın!',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      isVerified: true, // Onaylı kullanıcı
      comments: [],
      likes: [],
    ),
  ];

  final List<Post> _groupPosts = List.generate(3, (index) => Post(
    id: 'group_$index',
    userId: 'group_user_$index',
    content: 'Grup gönderisi $index',
    type: PostType.text,
    createdAt: DateTime.now().subtract(Duration(hours: index)),
    isVerified: index == 0, // Sadece ilk grup onaylı
    comments: [
      Comment(
        id: 'group_comment_${index}_1',
        userId: 'group_member_1',
        username: 'Grup Üyesi 1',
        content: 'Bu etkinliğe katılmak istiyorum!',
        createdAt: DateTime.now().subtract(Duration(minutes: 45)),
        isVerified: index == 0, // Sadece ilk gruptaki yorumcu onaylı
        likes: [],
        replies: [],
      ),
    ],
    likes: [],
  ));

  // Örnek arama verileri
  final List<Map<String, dynamic>> _recentSearches = [
    {'query': 'Ahmet Yılmaz', 'type': 'user'},
    {'query': 'Proje Yönetimi', 'type': 'mission'},
    {'query': 'Tasarım Görevi', 'type': 'mission'},
  ];

  final List<Map<String, dynamic>> _searchResults = [
    {
      'title': 'Ahmet Yılmaz',
      'subtitle': 'Kullanıcı',
      'image': 'https://picsum.photos/200',
      'isUser': true,
      'type': 'user'
    },
    {
      'title': 'Proje Yönetimi Görevi',
      'subtitle': 'Görev',
      'image': 'https://picsum.photos/201',
      'isUser': false,
      'type': 'mission'
    },
    {
      'title': 'Tasarım Görevi',
      'subtitle': 'Görev',
      'image': 'https://picsum.photos/202',
      'isUser': false,
      'type': 'mission'
    },
  ];

  String _selectedCategory = 'Tümü';
  List<Map<String, dynamic>> _filteredResults = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this, initialIndex: 2);
    _speedDialController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _speedDialAnimation = CurvedAnimation(
      parent: _speedDialController,
      curve: Curves.easeInOut,
    );
    _searchController.addListener(() {
      _filterSearchResults();
    });
    _filteredResults = _searchResults;

    // Tab değişikliklerini dinle
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        return;
      }
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _speedDialController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSpeedDial() {
    setState(() {
      _isSpeedDialOpen = !_isSpeedDialOpen;
      if (_isSpeedDialOpen) {
        _speedDialController.forward();
      } else {
        _speedDialController.reverse();
      }
    });
  }

  void _closeSpeedDial() {
    if (_isSpeedDialOpen) {
      setState(() {
        _isSpeedDialOpen = false;
      });
    }
  }

  String getCurrentUser() {
    // TODO: implement actual user management
    return "Kullanıcı";  // Default value until user management is implemented
  }

  final _stories = [
    Story(
      id: '1',
      userId: 'john_doe',
      userName: 'John Doe',
      userImage: 'https://picsum.photos/200',
      items: [
        StoryItem(
          id: '1',
          url: 'https://picsum.photos/800/1200',
          type: StoryType.image,
          createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        ),
      ],
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      isVerified: true,
    ),
    Story(
      id: '2',
      userId: 'jane_doe',
      userName: 'Jane Doe',
      userImage: 'https://picsum.photos/201',
      items: [
        StoryItem(
          id: '2',
          url: 'https://picsum.photos/800/1200?random=1',
          type: StoryType.image,
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
      ],
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      isVerified: true,
    ),
    Story(
      id: '3',
      userId: 'mission_master',
      userName: 'Mission Master',
      userImage: '',
      items: [
        StoryItem(
          id: '3',
          url: 'https://picsum.photos/800/1200?random=2',
          type: StoryType.image,
          createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        ),
      ],
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      isVerified: true,
    ),
  ];

  void _handleStoryTap(Story story) {
    // TODO: Implement story viewing
    print('Story tapped: ${story.userName}');
  }

  void _handlePostLike(Post post) {
    setState(() {
      final currentUser = UserUtils.getCurrentUser();
      if (post.likes.contains(currentUser)) {
        post.likes.remove(currentUser);
      } else {
        post.likes.add(currentUser);
      }
    });
  }

  void _filterSearchResults() {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _filteredResults = _searchResults;
      });
      return;
    }

    setState(() {
      _filteredResults = _searchResults.where((result) {
        final matchesQuery = result['title'].toLowerCase().contains(query) ||
            result['subtitle'].toLowerCase().contains(query);
        
        if (_selectedCategory == 'Tümü') {
          return matchesQuery;
        } else if (_selectedCategory == 'Kullanıcılar') {
          return matchesQuery && result['type'] == 'user';
        } else if (_selectedCategory == 'Görevler') {
          return matchesQuery && result['type'] == 'mission';
        }
        return false;
      }).toList();
    });
  }

  void _handleCategorySelect(String category) {
    setState(() {
      _selectedCategory = category;
    });
    _filterSearchResults();
  }

  void _handleSearchItemTap(Map<String, dynamic> item) {
    // TODO: Navigate to appropriate screen based on item type
    print('Selected item: ${item['title']}');
  }

  void _showSearchScreen() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          builder: (context, scrollController) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Search Header
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.black),
                            onPressed: () => Navigator.pop(context),
                          ),
                          Expanded(
                            child: Container(
                              height: 45,
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: TextField(
                                controller: _searchController,
                                autofocus: true,
                                decoration: InputDecoration(
                                  hintText: 'Kullanıcı, görev veya mesaj ara...',
                                  hintStyle: TextStyle(color: Colors.grey[600]),
                                  prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Search Categories
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildSearchCategory('Tümü', _selectedCategory == 'Tümü', setModalState),
                            _buildSearchCategory('Kullanıcılar', _selectedCategory == 'Kullanıcılar', setModalState),
                            _buildSearchCategory('Görevler', _selectedCategory == 'Görevler', setModalState),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Search Results
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Recent Searches
                      if (_searchController.text.isEmpty) ...[
                        const Text(
                          'Son Aramalar',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ..._recentSearches.map((search) => _buildRecentSearchItem(search['query'])),
                      ],
                      // Search Results
                      if (_searchController.text.isNotEmpty) ...[
                        ..._filteredResults.map((result) => _buildSearchResultItem(
                          title: result['title'],
                          subtitle: result['subtitle'],
                          image: result['image'],
                          isUser: result['isUser'],
                          onTap: () => _handleSearchItemTap(result),
                        )),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchCategory(String title, bool isSelected, StateSetter setModalState) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setModalState(() {
              _selectedCategory = title;
            });
            _filterSearchResults();
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentSearchItem(String query) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          _searchController.text = query;
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Icon(Icons.history, color: Colors.grey[600], size: 20),
              const SizedBox(width: 16),
              Text(
                query,
                style: TextStyle(
                  color: Colors.grey[800],
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              Icon(Icons.north_west, color: Colors.grey[600], size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResultItem({
    required String title,
    required String subtitle,
    required String image,
    required bool isUser,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: NetworkImage(image),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                isUser ? Icons.person : Icons.assignment,
                color: Colors.grey[400],
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return true;
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: const Text('Etki'),
          centerTitle: true,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: _showSearchScreen,
            ),
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationsScreen(),
                  ),
                );
              },
            ),
            Container(
              margin: const EdgeInsets.only(right: 8),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MessagesScreen(),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.chat_bubble,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(kToolbarHeight),
            child: Container(
              height: 70,
              alignment: Alignment.center,
              child: TabBar(
                controller: _tabController,
                indicator: const BoxDecoration(),
                isScrollable: true,
                padding: EdgeInsets.zero,
                labelPadding: const EdgeInsets.symmetric(horizontal: 24),
                enableFeedback: false,
                onTap: (index) {
                  setState(() {
                    _tabController.animateTo(index);
                  });
                },
                tabs: [
                  _buildTab(
                    icon: Icons.person,
                    label: 'Profilim',
                    index: 0,
                  ),
                  _buildTab(
                    icon: Icons.explore,
                    label: 'Keşfet',
                    index: 1,
                  ),
                  _buildTab(
                    icon: Icons.people,
                    label: 'Takip',
                    index: 2,
                  ),
                  _buildTab(
                    icon: Icons.assignment,
                    label: 'Görevler',
                    index: 3,
                  ),
                  _buildTab(
                    icon: Icons.groups,
                    label: 'Gruplar',
                    index: 4,
                  ),
                ],
              ),
            ),
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          dragStartBehavior: DragStartBehavior.down,
          children: [
            // Profilim Tab
            const ProfileScreen(),
            
            // Keşfet Tab
            RefreshIndicator(
              onRefresh: () async {
                // TODO: Implement refresh for explore tab
                await Future.delayed(const Duration(seconds: 1));
              },
              child: ListView.builder(
                itemCount: _explorePosts.where((post) => post.type != PostType.mission).length,
                itemBuilder: (context, index) {
                  final nonMissionPosts = _explorePosts.where((post) => post.type != PostType.mission).toList();
                  final post = nonMissionPosts[index];
                  return PostCard(
                    post: post,
                    onLike: () => _handlePostLike(post),
                    onComment: () => _showComments(context, post),
                    onShare: () {
                      print('Post shared: ${post.id}');
                    },
                  );
                },
              ),
            ),
            
            // Takip Tab
            FollowingTab(
              posts: _followingPosts.where((post) => post.type != PostType.mission).toList(),
              stories: _stories,
              onLike: _handlePostLike,
              onComment: (post) => _showComments(context, post),
              onShare: (post) {
                print('Share post: ${post.id}');
              },
            ),
            
            // Görevler Tab
            RefreshIndicator(
              onRefresh: () async {
                // TODO: Implement refresh for missions tab
                await Future.delayed(const Duration(seconds: 1));
              },
              child: ListView.builder(
                itemCount: _explorePosts.where((post) => post.type == PostType.mission).length,
                itemBuilder: (context, index) {
                  final missionPosts = _explorePosts.where((post) => post.type == PostType.mission).toList();
                  final post = missionPosts[index];
                  return PostCard(
                    post: post,
                    onLike: () => _handlePostLike(post),
                    onComment: () => _showComments(context, post),
                    onShare: () {
                      print('Post shared: ${post.id}');
                    },
                  );
                },
              ),
            ),
            
            // Gruplar Tab
            RefreshIndicator(
              onRefresh: () async {
                // TODO: Implement refresh for groups tab
                await Future.delayed(const Duration(seconds: 1));
              },
              child: ListView.builder(
                itemCount: _groupPosts.length,
                itemBuilder: (context, index) {
                  final post = _groupPosts[index];
                  return PostCard(
                    post: post,
                    onLike: () => _handlePostLike(post),
                    onComment: () => _showComments(context, post),
                    onShare: () {
                      print('Post shared: ${post.id}');
                    },
                  );
                },
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
              onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => DraggableScrollableSheet(
                initialChildSize: 0.9,
                minChildSize: 0.5,
                maxChildSize: 0.9,
                builder: (context, scrollController) => Container(
                  decoration: const BoxDecoration(
                              color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                  child: const CreatePostScreen(),
                          ),
              ),
            );
                            },
          backgroundColor: AppColors.primary,
          child: const Icon(Icons.add, size: 28),
        ),
      ),
    );
  }

  Widget _buildTab({
    required IconData icon,
    required String label,
    required int index,
  }) {
    return AnimatedBuilder(
      animation: _tabController.animation!,
      builder: (context, child) {
        final double value = _tabController.animation!.value;
        final double distance = (index - value).abs();
        final bool isSelected = distance < 0.5;

        // Tab genişliği ve opaklığını hesapla
        final double width = isSelected ? 160.0 : 80.0;
        final double opacity = (1 - distance).clamp(0.5, 1.0);
        final double scale = (1 - distance * 0.3).clamp(0.7, 1.0);

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: width,
          child: Transform.scale(
            scale: scale,
            child: Opacity(
              opacity: opacity,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      size: 20,
                      color: isSelected ? AppColors.primary : AppColors.textSecondary.withOpacity(0.7),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected ? AppColors.primary : AppColors.textSecondary.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showComments(BuildContext context, Post post) {
    final TextEditingController commentController = TextEditingController();
    String? replyingTo;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          builder: (context, scrollController) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.all(8),
                  height: 4,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Yorumlar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (replyingTo != null)
                        TextButton(
                          onPressed: () {
                            setModalState(() {
                              replyingTo = null;
                              commentController.clear();
                            });
                          },
                          child: const Text('İptal'),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: post.comments.length,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemBuilder: (context, index) {
                      final comment = post.comments[index];
                      return CommentCard(
                        comment: comment,
                        onReply: () {
                          setModalState(() {
                            replyingTo = comment.id;
                          });
                          commentController.text = '@${comment.username ?? comment.userId} ';
                          commentController.selection = TextSelection.fromPosition(
                            TextPosition(offset: commentController.text.length),
                          );
                        },
                        onLike: () {
                          setModalState(() {
                            if (comment.likes.contains(UserUtils.getCurrentUser())) {
                              comment.likes.remove(UserUtils.getCurrentUser());
                            } else {
                              comment.likes.add(UserUtils.getCurrentUser());
                            }
                          });
                          setState(() {}); // Ana state'i güncelle
                        },
                        isLiked: comment.likes.contains(UserUtils.getCurrentUser()),
                        onViewProfile: (userId) {
                          // TODO: Navigate to user profile
                        },
                      );
                    },
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                    left: 16,
                    right: 16,
                    top: 8,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey,
                        ),
                        child: const Icon(Icons.person, size: 20, color: Colors.white),
                      ),
                      Expanded(
                        child: TextField(
                          controller: commentController,
                          decoration: const InputDecoration(
                            hintText: 'Yorum yaz...',
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 8),
                          ),
                          maxLines: null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ValueListenableBuilder<TextEditingValue>(
                        valueListenable: commentController,
                        builder: (context, value, child) {
                          return TextButton(
                            onPressed: value.text.trim().isEmpty ? null : () {
                              final newComment = Comment(
                                userId: UserUtils.getCurrentUser(),
                                content: value.text.trim(),
                                username: 'current_user', // TODO: Get actual username
                              );
                              
                              setModalState(() {
                                if (replyingTo != null) {
                                  final parentComment = post.comments.firstWhere(
                                    (c) => c.id == replyingTo,
                                  );
                                  parentComment.replies.add(newComment);
                                } else {
                                  post.comments.add(newComment);
                                }
                                
                                commentController.clear();
                                replyingTo = null;
                              });
                              setState(() {}); // Ana state'i güncelle
                            },
                            child: Text(
                              'Paylaş',
                              style: TextStyle(
                                color: value.text.trim().isEmpty
                                    ? Colors.blue.withOpacity(0.5)
                                    : Colors.blue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 