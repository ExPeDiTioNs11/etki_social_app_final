import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:etki_social_app/models/post_model.dart';
import 'package:etki_social_app/widgets/post_card.dart';
import 'package:etki_social_app/services/auth_service.dart';
import 'package:etki_social_app/constants/app_colors.dart';
import 'package:etki_social_app/services/post_service.dart';

class FollowingTab extends StatefulWidget {
  const FollowingTab({super.key});

  @override
  State<FollowingTab> createState() => _FollowingTabState();
}

class _FollowingTabState extends State<FollowingTab> {
  final AuthService _authService = AuthService();
  final PostService _postService = PostService();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  List<Post> _posts = [];
  String? _lastDocumentId;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadPosts();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadPosts() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) return;

      // Get user's following list
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();
      
      final following = List<String>.from(userDoc.data()?['following'] ?? []);
      if (following.isEmpty) {
        setState(() {
          _hasMore = false;
          _isLoading = false;
        });
        return;
      }

      // Build query
      Query query = FirebaseFirestore.instance
          .collection('posts')
          .where('userId', whereIn: following)
          .orderBy('createdAt', descending: true)
          .limit(10);

      if (_lastDocumentId != null) {
        final lastDoc = await FirebaseFirestore.instance
            .collection('posts')
            .doc(_lastDocumentId)
            .get();
        query = query.startAfterDocument(lastDoc);
      }

      final snapshot = await query.get();
      
      if (snapshot.docs.isEmpty) {
        setState(() {
          _hasMore = false;
        });
      } else {
        _lastDocumentId = snapshot.docs.last.id;
        final newPosts = snapshot.docs.map((doc) {
          final post = Post.fromMap(doc.data() as Map<String, dynamic>, id: doc.id);
          // Filter out mission posts locally
          return post.type != PostType.mission ? post : null;
        }).where((post) => post != null).cast<Post>().toList();

        setState(() {
          _posts.addAll(newPosts);
        });
      }
    } catch (e) {
      print('Error loading posts: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gönderiler yüklenirken bir hata oluştu'),
          duration: Duration(seconds: 2),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadPosts();
    }
  }

  Future<void> _refreshPosts() async {
    setState(() {
      _posts = [];
      _lastDocumentId = null;
      _hasMore = true;
    });
    await _loadPosts();
  }

  Future<void> _handleLike(Post post) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) return;

      await _postService.toggleLike(post.id);
      
      setState(() {
        final index = _posts.indexWhere((p) => p.id == post.id);
        if (index != -1) {
          final updatedPost = _posts[index];
          if (updatedPost.likes.contains(currentUser.uid)) {
            updatedPost.likes.remove(currentUser.uid);
          } else {
            updatedPost.likes.add(currentUser.uid);
          }
          _posts[index] = updatedPost;
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Beğeni işlemi sırasında bir hata oluştu'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_posts.isEmpty && !_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Henüz kimseyi takip etmiyorsunuz',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Takip ettiğiniz kullanıcıların gönderileri burada görünecek',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshPosts,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _posts.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _posts.length) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                ),
              ),
            );
          }

          final post = _posts[index];
          return PostCard(
            post: post,
            onLike: () => _handleLike(post),
            onComment: () {
              // TODO: Implement comment functionality
            },
            onShare: () {
              // TODO: Implement share functionality
            },
          );
        },
      ),
    );
  }
} 