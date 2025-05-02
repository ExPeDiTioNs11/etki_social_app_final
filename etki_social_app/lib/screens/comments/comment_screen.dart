import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:etki_social_app/models/post_model.dart';
import 'package:etki_social_app/constants/app_colors.dart';

class CommentScreen extends StatefulWidget {
  final Post post;
  final Function(Comment) onCommentAdded;
  final String collection; // 'posts' veya 'tasks'

  const CommentScreen({
    super.key,
    required this.post,
    required this.onCommentAdded,
    this.collection = 'posts',
  });

  @override
  State<CommentScreen> createState() => _CommentScreenState();
}

class _CommentScreenState extends State<CommentScreen> {
  final TextEditingController _commentController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;
  bool _isSubmitting = false;
  List<Comment> _comments = [];
  Comment? _replyingTo;
  String? _userProfileImage;
  Map<String, String?> _profileImageCache = {}; // Kullanıcı profil resimlerini cache'le
  bool _isInputNotEmpty = false;

  @override
  void initState() {
    super.initState();
    _loadComments();
    _loadUserProfile();
    _commentController.addListener(_onInputChanged);
  }

  void _onInputChanged() {
    final isNotEmpty = _commentController.text.trim().isNotEmpty;
    if (_isInputNotEmpty != isNotEmpty) {
      setState(() {
        _isInputNotEmpty = isNotEmpty;
      });
    }
  }

  Future<void> _loadComments() async {
    setState(() => _isLoading = true);

    try {
      final doc = await _firestore.collection(widget.collection).doc(widget.post.id).get();
      if (!doc.exists) {
        throw Exception('Gönderi bulunamadı');
      }

      final data = doc.data()!;
      final allComments = List<Comment>.from(
        (data['comments'] ?? []).map((c) => Comment.fromMap(c)),
      );

      // Yorumları ana yorumlar ve yanıtlar olarak grupla
      final List<Comment> mainComments = [];
      final Map<String, List<Comment>> repliesMap = {};
      final Set<String> userIds = {};
      for (final comment in allComments) {
        userIds.add(comment.userId);
        if (comment.replyTo == null) {
          mainComments.add(comment);
        } else {
          repliesMap.putIfAbsent(comment.replyTo!, () => []).add(comment);
        }
      }
      // Ana yorumların altına yanıtlarını ekle
      for (final main in mainComments) {
        main.replies.clear();
        if (repliesMap.containsKey(main.id)) {
          main.replies.addAll(repliesMap[main.id]!);
        }
      }

      // Kullanıcı profil resimlerini yükle ve cache'le
      for (final userId in userIds) {
        if (!_profileImageCache.containsKey(userId)) {
          final userDoc = await _firestore.collection('users').doc(userId).get();
          if (userDoc.exists) {
            _profileImageCache[userId] = userDoc.data()?['profileImage'] ?? userDoc.data()?['profileImageUrl'];
          } else {
            _profileImageCache[userId] = null;
          }
        }
      }

      setState(() {
        _comments = mainComments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Yorumlar yüklenirken hata: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        setState(() {
          _userProfileImage = userDoc.data()?['profileImage'] ?? userDoc.data()?['profileImageUrl'];
        });
      }
    } catch (e) {
      print('Error loading user profile: $e');
    }
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;

    setState(() => _isSubmitting = true);

    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Kullanıcı girişi yapılmamış');

      // Kullanıcı bilgilerini al
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) throw Exception('Kullanıcı bilgileri bulunamadı');

      final userData = userDoc.data()!;

      final newComment = Comment(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: user.uid,
        username: userData['username'] ?? 'İsimsiz Kullanıcı',
        content: _commentController.text.trim(),
        createdAt: DateTime.now(),
        isVerified: userData['isVerified'] ?? false,
        likes: [],
        replies: [],
        replyTo: _replyingTo?.id,
      );

      // Yorumu Firestore'a ekle
      await _firestore.collection(widget.collection).doc(widget.post.id).update({
        'comments': FieldValue.arrayUnion([newComment.toMap()])
      });

      setState(() {
        if (_replyingTo != null) {
          // Yanıt olarak ekleniyor
          final parentIndex = _comments.indexWhere((c) => c.id == _replyingTo!.id);
          if (parentIndex != -1) {
            _comments[parentIndex].replies.add(newComment);
          }
        } else {
          // Ana yorum olarak ekleniyor
          _comments.add(newComment);
        }
        _commentController.clear();
        _replyingTo = null;
      });

      // Callback'i çağır
      widget.onCommentAdded(newComment);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Yorum eklenirken hata: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _handleReply(Comment comment) {
    setState(() {
      _replyingTo = comment;
      _commentController.text = '@${comment.username} ';
    });
    _commentController.selection = TextSelection.fromPosition(
      TextPosition(offset: _commentController.text.length),
    );
    FocusScope.of(context).requestFocus();
  }

  Future<void> _toggleLike(Comment comment) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final isLiked = comment.likes.contains(user.uid);
    try {
      // Firestore'daki postu çek
      final postRef = _firestore.collection(widget.collection).doc(widget.post.id);
      final postDoc = await postRef.get();
      if (!postDoc.exists) return;
      final data = postDoc.data()!;
      final commentsRaw = List<Map<String, dynamic>>.from(data['comments'] ?? []);
      // Yorumu bul ve güncelle
      for (var c in commentsRaw) {
        if (c['id'] == comment.id) {
          List likes = List<String>.from(c['likes'] ?? []);
          if (isLiked) {
            likes.remove(user.uid);
          } else {
            likes.add(user.uid);
          }
          c['likes'] = likes;
          break;
        }
      }
      // Firestore'a güncellenmiş yorumları kaydet
      await postRef.update({'comments': commentsRaw});
      // Ekranda da güncelle
      setState(() {
        if (isLiked) {
          comment.likes.remove(user.uid);
        } else {
          comment.likes.add(user.uid);
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Beğeni işlemi sırasında hata: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _commentController.removeListener(_onInputChanged);
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            // Top handle bar
            Container(
              padding: const EdgeInsets.only(top: 8),
              child: Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            // AppBar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Color(0xFFEEEEEE),
                    width: 1,
                  ),
                ),
              ),
              child: const Center(
                child: Text(
                  'Yorumlar',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            // Comments List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _comments.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline,
                                size: 48,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Henüz yorum yapılmamış',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'İlk yorumu sen yap!',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _comments.length,
                          itemBuilder: (context, index) {
                            final comment = _comments[index];
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildCommentItem(comment),
                                if (comment.replies.isNotEmpty) ...[
                                  ...comment.replies.map((reply) => _buildCommentItem(reply, isReply: true)).toList(),
                                ],
                                const Divider(),
                              ],
                            );
                          },
                        ),
            ),
            // Yanıtlama Çubuğu
            if (_replyingTo != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.grey[100],
                child: Row(
                  children: [
                    Text(
                      '${_replyingTo!.username} kullanıcısına yanıt veriliyor',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      onPressed: () {
                        setState(() {
                          _replyingTo = null;
                          _commentController.clear();
                        });
                      },
                    ),
                  ],
                ),
              ),
            // Yorum Yazma Alanı
            Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 8,
              ),
              decoration: BoxDecoration(
                color: Colors.transparent,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    // Profil resmi
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: _userProfileImage != null
                          ? NetworkImage(_userProfileImage!)
                          : null,
                      child: _userProfileImage == null
                          ? const Icon(Icons.person, color: Colors.grey)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    // Yorum yazma alanı
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        decoration: InputDecoration(
                          hintText: 'Yorum yaz...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          isDense: true,
                          filled: true,
                          fillColor: Colors.grey[100],
                        ),
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Gönder butonu
                    _isSubmitting
                        ? Container(
                            width: 36,
                            height: 36,
                            padding: const EdgeInsets.all(8),
                            child: const CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: _isInputNotEmpty
                                  ? AppColors.primary
                                  : Colors.grey[300],
                              shape: BoxShape.circle,
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(18),
                                onTap: _isInputNotEmpty
                                    ? _addComment
                                    : null,
                                child: Center(
                                  child: Icon(
                                    Icons.send,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentItem(Comment comment, {bool isReply = false}) {
    final profileImage = _profileImageCache[comment.userId];
    return Padding(
      padding: EdgeInsets.only(
        top: 8,
        bottom: 8,
        left: isReply ? 40 : 0, // Yanıtlar için girinti
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.grey[200],
            backgroundImage: profileImage != null && profileImage.isNotEmpty
                ? NetworkImage(profileImage)
                : null,
            child: (profileImage == null || profileImage.isEmpty)
                ? const Icon(Icons.person, color: Colors.grey)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.username,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    if (comment.isVerified) ...[
                      const SizedBox(width: 4),
                      Icon(
                        Icons.verified,
                        size: 14,
                        color: Colors.blue,
                      ),
                    ],
                    const SizedBox(width: 8),
                    Text(
                      _getTimeAgo(comment.createdAt),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(comment.content),
                const SizedBox(height: 8),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => _toggleLike(comment),
                      child: Icon(
                        comment.likes.contains(_auth.currentUser?.uid)
                            ? Icons.favorite
                            : Icons.favorite_border,
                        size: 16,
                        color: comment.likes.contains(_auth.currentUser?.uid)
                            ? Colors.red
                            : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      comment.likes.length.toString(),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 16),
                    if (!isReply)
                      GestureDetector(
                        onTap: () => _handleReply(comment),
                        child: Text(
                          'Yanıtla',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
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
      return 'şimdi';
    }
  }
} 