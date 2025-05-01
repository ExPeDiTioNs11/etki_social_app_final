import 'package:flutter/material.dart';
import 'package:etki_social_app/constants/app_colors.dart';
import 'package:etki_social_app/models/post_model.dart';
import 'package:etki_social_app/widgets/post_card.dart';
import 'package:etki_social_app/widgets/comment_card.dart';

class GroupScreen extends StatefulWidget {
  final String groupId;
  final String groupName;
  final String groupImage;
  final int memberCount;
  final bool isAdmin;

  const GroupScreen({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.groupImage,
    required this.memberCount,
    this.isAdmin = false,
  });

  @override
  State<GroupScreen> createState() => _GroupScreenState();
}

class _GroupScreenState extends State<GroupScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  List<Post> _groupPosts = [];
  List<Map<String, dynamic>> _participants = [];
  List<Post> _groupTasks = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadGroupData();
  }

  Future<void> _loadGroupData() async {
    setState(() => _isLoading = true);
    
    try {
      // TODO: Implement actual data loading from Firebase
      await Future.delayed(const Duration(seconds: 1));
      
      // Örnek veriler
      _groupPosts = List.generate(5, (index) => Post(
        id: 'post_$index',
        userId: 'user_$index',
        content: 'Grup gönderisi $index',
        type: PostType.text,
        createdAt: DateTime.now().subtract(Duration(hours: index)),
        isVerified: true,
        comments: [],
        likes: [],
      ));

      _participants = List.generate(10, (index) => {
        'id': 'user_$index',
        'name': 'Kullanıcı $index',
        'image': 'https://picsum.photos/200?random=$index',
        'isAdmin': index == 0,
      });

      _groupTasks = List.generate(3, (index) => Post(
        id: 'task_$index',
        userId: 'admin',
        content: 'Grup görevi $index',
        type: PostType.mission,
        missionTitle: 'Görev ${index + 1}',
        missionDescription: 'Bu görevi tamamlamak için yapmanız gerekenler...',
        missionReward: (index + 1) * 100,
        missionDeadline: DateTime.now().add(Duration(days: index + 1)),
        missionParticipants: [],
        maxParticipants: 10,
        createdAt: DateTime.now().subtract(Duration(hours: index)),
        isVerified: true,
        comments: [],
        likes: [],
      ));

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Veriler yüklenirken hata oluştu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showComments(BuildContext context, Post post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  'Yorumlar',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: controller,
                  itemCount: post.comments.length,
                  itemBuilder: (context, index) {
                    final comment = post.comments[index];
                    return CommentCard(comment: comment);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 300,
              pinned: true,
              stretch: true,
              backgroundColor: Colors.white,
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      widget.groupImage,
                      fit: BoxFit.cover,
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 16,
                      left: 16,
                      right: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.groupName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.people,
                                color: Colors.white.withOpacity(0.8),
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${widget.memberCount} üye',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onPressed: () {
                    // TODO: Show group options menu
                  },
                ),
              ],
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: AppColors.primary,
                  tabs: const [
                    Tab(text: 'Gönderiler'),
                    Tab(text: 'Katılımcılar'),
                    Tab(text: 'Grup Görevleri'),
                  ],
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            // Gönderiler Tab
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadGroupData,
                    child: ListView.builder(
                      itemCount: _groupPosts.length,
                      itemBuilder: (context, index) {
                        final post = _groupPosts[index];
                        return PostCard(
                          post: post,
                          onLike: () {
                            // TODO: Implement like functionality
                          },
                          onComment: () => _showComments(context, post),
                          onShare: () {
                            // TODO: Implement share functionality
                          },
                        );
                      },
                    ),
                  ),

            // Katılımcılar Tab
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadGroupData,
                    child: ListView.builder(
                      itemCount: _participants.length,
                      itemBuilder: (context, index) {
                        final participant = _participants[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: NetworkImage(participant['image']),
                          ),
                          title: Text(participant['name']),
                          subtitle: participant['isAdmin']
                              ? const Text('Grup Yöneticisi')
                              : null,
                          trailing: widget.isAdmin
                              ? IconButton(
                                  icon: const Icon(Icons.more_vert),
                                  onPressed: () {
                                    // TODO: Show participant options menu
                                  },
                                )
                              : null,
                        );
                      },
                    ),
                  ),

            // Grup Görevleri Tab
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadGroupData,
                    child: ListView.builder(
                      itemCount: _groupTasks.length,
                      itemBuilder: (context, index) {
                        final task = _groupTasks[index];
                        return PostCard(
                          post: task,
                          onLike: () {
                            // TODO: Implement like functionality
                          },
                          onComment: () => _showComments(context, task),
                          onShare: () {
                            // TODO: Implement share functionality
                          },
                        );
                      },
                    ),
                  ),
          ],
        ),
      ),
      floatingActionButton: widget.isAdmin
          ? FloatingActionButton(
              onPressed: () {
                // TODO: Navigate to create post/task screen
              },
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add),
            )
          : null,
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