import 'package:flutter/material.dart';
import 'package:etki_social_app/constants/app_colors.dart';
import 'package:etki_social_app/models/post_model.dart';
import 'package:etki_social_app/widgets/post_card.dart';
import 'package:etki_social_app/widgets/comment_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadGroupData();
  }

  Future<void> _loadGroupData() async {
    setState(() => _isLoading = true);
    
    try {
      // Grup katılımcılarını yükle
      final groupDoc = await _firestore.collection('groups').doc(widget.groupId).get();
      if (!groupDoc.exists) {
        throw Exception('Grup bulunamadı');
      }

      final groupData = groupDoc.data()!;
      final List<String> memberIds = List<String>.from(groupData['members'] ?? []);

      // Katılımcı bilgilerini yükle
      final participants = await Future.wait(
        memberIds.map((userId) async {
          final userDoc = await _firestore.collection('users').doc(userId).get();
          if (!userDoc.exists) return null;

          final userData = userDoc.data()!;
          return {
            'id': userId,
            'name': userData['username'] ?? 'İsimsiz Kullanıcı',
            'image': userData['profileImage'] ?? '',
            'isAdmin': userId == groupData['creatorId'],
          };
        }),
      );

      setState(() {
        _participants = participants.whereType<Map<String, dynamic>>().toList();
        _isLoading = false;
      });
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
                    child: _groupPosts.isEmpty
                        ? ListView(
                            children: [
                              SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                              Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.post_add,
                                        size: 32,
                                        color: Colors.grey[400],
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Henüz bir gönderi paylaşılmamış',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    if (widget.isAdmin) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        'İlk gönderiyi paylaşmak için + butonuna tıklayın',
                                        style: TextStyle(
                                          color: Colors.grey[400],
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
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
                            backgroundImage: participant['image'].isNotEmpty
                                ? NetworkImage(participant['image'])
                                : null,
                            child: participant['image'].isEmpty
                                ? const Icon(Icons.person)
                                : null,
                          ),
                          title: Text(participant['name']),
                          subtitle: participant['isAdmin']
                              ? const Text('Grup Yöneticisi')
                              : null,
                          trailing: widget.isAdmin
                              ? IconButton(
                                  icon: const Icon(Icons.more_vert),
                                  onPressed: () {
                                    _showParticipantOptions(participant);
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
                    child: _groupTasks.isEmpty
                        ? ListView(
                            children: [
                              SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                              Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.assignment_outlined,
                                        size: 32,
                                        color: Colors.grey[400],
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Henüz bir görev oluşturulmamış',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    if (widget.isAdmin) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        'İlk görevi oluşturmak için + butonuna tıklayın',
                                        style: TextStyle(
                                          color: Colors.grey[400],
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
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

  void _showParticipantOptions(Map<String, dynamic> participant) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.remove_circle_outline),
              title: const Text('Gruptan Çıkar'),
              onTap: () async {
                Navigator.pop(context);
                await _removeParticipant(participant['id']);
              },
            ),
            if (participant['isAdmin'])
              ListTile(
                leading: const Icon(Icons.admin_panel_settings),
                title: const Text('Yöneticilikten Çıkar'),
                onTap: () async {
                  Navigator.pop(context);
                  await _removeAdmin(participant['id']);
                },
              )
            else
              ListTile(
                leading: const Icon(Icons.admin_panel_settings),
                title: const Text('Yönetici Yap'),
                onTap: () async {
                  Navigator.pop(context);
                  await _makeAdmin(participant['id']);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _removeParticipant(String userId) async {
    try {
      await _firestore.collection('groups').doc(widget.groupId).update({
        'members': FieldValue.arrayRemove([userId])
      });

      await _firestore.collection('users').doc(userId).update({
        'groups': FieldValue.arrayRemove([widget.groupId])
      });

      setState(() {
        _participants.removeWhere((p) => p['id'] == userId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kullanıcı gruptan çıkarıldı'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _makeAdmin(String userId) async {
    try {
      await _firestore.collection('groups').doc(widget.groupId).update({
        'admins': FieldValue.arrayUnion([userId])
      });

      setState(() {
        final index = _participants.indexWhere((p) => p['id'] == userId);
        if (index != -1) {
          _participants[index]['isAdmin'] = true;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kullanıcı yönetici yapıldı'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _removeAdmin(String userId) async {
    try {
      await _firestore.collection('groups').doc(widget.groupId).update({
        'admins': FieldValue.arrayRemove([userId])
      });

      setState(() {
        final index = _participants.indexWhere((p) => p['id'] == userId);
        if (index != -1) {
          _participants[index]['isAdmin'] = false;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kullanıcının yöneticiliği kaldırıldı'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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