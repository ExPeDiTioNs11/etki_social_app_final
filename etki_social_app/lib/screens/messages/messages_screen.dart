import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../constants/app_colors.dart';
import 'chat_screen.dart';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';

enum MessageCategory {
  all,
  unread,
  group,
  archived,
}

class Message {
  final String userId;
  final String userName;
  final String userImage;
  final String lastMessage;
  final DateTime lastMessageTime;
  final bool isUnread;
  final bool isGroup;
  final bool isArchived;

  Message({
    required this.userId,
    required this.userName,
    required this.userImage,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.isUnread,
    this.isGroup = false,
    this.isArchived = false,
  });
}

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({Key? key}) : super(key: key);

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> with SingleTickerProviderStateMixin {
  MessageCategory _selectedCategory = MessageCategory.all;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  late AnimationController _animationController;
  late Animation<double> _animation;
  double _dragDistance = 0.0;
  final AuthService _authService = AuthService();
  List<Map<String, dynamic>> _followedUsers = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
      parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    // Arama değişikliklerini dinle
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        title: Text(
          'Mesajlar',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.add, color: AppColors.primary, size: 18),
            ),
            onPressed: () => _showNewMessageModal(),
                ),
              ],
            ),
      body: Column(
        children: [
          // Arama Çubuğu
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Mesajlarda ara...',
                hintStyle: TextStyle(color: AppColors.textSecondary),
                prefixIcon: Icon(Icons.search, color: AppColors.primary),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: AppColors.primary),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),

          // Kategori Filtreleri
          Container(
            height: 50,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: MessageCategory.values.length,
              itemBuilder: (context, index) {
                final category = MessageCategory.values[index];
                final isSelected = _selectedCategory == category;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCategory = category;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      gradient: isSelected 
                          ? LinearGradient(
                              colors: [AppColors.primary, AppColors.primaryLight],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: isSelected ? null : AppColors.surface,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.shadow.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                          category == MessageCategory.all
                              ? 'Tümü'
                              : category == MessageCategory.unread
                                  ? 'Okunmamış'
                                  : category == MessageCategory.group
                                      ? 'Gruplar'
                                      : 'Arşivlenmiş',
                          style: TextStyle(
                          color: isSelected ? AppColors.surface : AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                          fontSize: 13,
                          ),
                        ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // Mesaj Listesi
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .where('participants', arrayContains: _authService.currentUser?.uid ?? '')
                  .orderBy('updatedAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState();
                }

                final chats = snapshot.data!.docs;
                final filteredChats = chats.where((chat) {
                  final data = chat.data() as Map<String, dynamic>;
                  
                  // Önce kategori filtrelemesi yap
                  if (!_filterChat(data)) return false;

                  // Eğer arama sorgusu varsa, mesaj içeriğinde ara
                  if (_searchQuery.isNotEmpty) {
                    final searchLower = _searchQuery.toLowerCase();
                    final lastMessage = (data['lastMessage'] ?? '').toString().toLowerCase();
                    return lastMessage.contains(searchLower);
                  }

                  return true;
                }).toList();

                if (filteredChats.isEmpty) {
                  return _buildEmptyState();
                }

                return _buildChatList(filteredChats);
              },
                          ),
                        ),
                      ],
      ),
    );
  }

  void _showMessageOptionsModal(BuildContext context, Message message) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            _buildOptionItem(
              icon: Icons.notifications_off_outlined,
              title: 'Sessize Al',
              subtitle: 'Bildirimleri kapat',
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement mute notifications
              },
            ),
            _buildOptionItem(
              icon: Icons.archive_outlined,
              title: 'Arşivle',
              subtitle: 'Mesajları arşivle',
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement archive messages
              },
            ),
            _buildOptionItem(
              icon: Icons.block_outlined,
              title: 'Engelle',
              subtitle: 'Kullanıcıyı engelle',
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement block user
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: AppColors.primary,
                  size: 20,
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
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNewMessageModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
                  decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(20),
                      ),
                  ),
                  child: Column(
          mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
              padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.divider,
                    width: 1,
                  ),
                        ),
                      ),
              child: Row(
                        children: [
                  Text(
                    'Yeni Mesaj',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                          IconButton(
                    icon: Icon(
                      Icons.close,
                      color: AppColors.textSecondary,
                    ),
                            onPressed: () => Navigator.pop(context),
                          ),
                ],
              ),
            ),
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(_authService.currentUser?.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final userData = snapshot.data!.data() as Map<String, dynamic>;
                final followingList = List<String>.from(userData['following'] ?? []);

                if (followingList.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 48,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Henüz kimseyi takip etmiyorsunuz',
                                style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            ),
                          ),
                        const SizedBox(height: 8),
                        Text(
                          'Yeni mesaj göndermek için önce kullanıcıları takip etmelisiniz',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  );
                }

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .where(FieldPath.documentId, whereIn: followingList)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    final users = snapshot.data!.docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return {
                        'id': doc.id,
                        'name': data['username'] ?? data['name'] ?? 'İsimsiz Kullanıcı',
                        'profileImage': data['profileImage'] ?? data['profileImageUrl'],
                        'isOnline': data['isOnline'] ?? false,
                      };
                    }).toList();

                    return Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: users.length,
                        itemBuilder: (context, index) {
                          final user = users[index];
                          return ListTile(
                            leading: Stack(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: AppColors.surface,
                                  child: user['profileImage'] != null && 
                                         user['profileImage'].toString().isNotEmpty
                                      ? ClipOval(
                                          child: CachedNetworkImage(
                                            imageUrl: user['profileImage'].toString(),
                                            width: 48,
                                            height: 48,
                                            fit: BoxFit.cover,
                                            placeholder: (context, url) => const CircularProgressIndicator(),
                                            errorWidget: (context, url, error) => const Icon(
                                              Icons.person,
                                              size: 24,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        )
                                      : const Icon(
                                          Icons.person,
                                          size: 24,
                                          color: AppColors.textSecondary,
                                        ),
                                ),
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    width: 12,
                                    height: 12,
                  decoration: BoxDecoration(
                                      color: user['isOnline'] ? AppColors.success : AppColors.error,
                                      shape: BoxShape.circle,
                    border: Border.all(
                                        color: AppColors.surface,
                                        width: 2,
                    ),
                  ),
                                  ),
                                ),
                              ],
                            ),
                            title: Text(
                              user['name'] ?? 'İsimsiz Kullanıcı',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              user['isOnline'] ? 'Çevrimiçi' : 'Çevrimdışı',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChatScreen(
                                    isGroup: false,
                                    chatId: user['id'],
                                    chatName: user['name'] ?? 'İsimsiz Kullanıcı',
                                    chatImage: user['profileImage']?.toString() ?? '',
                                    participants: [user['id']],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}d';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}s';
    } else {
      return '${difference.inDays}g';
    }
  }

  bool _filterChat(Map<String, dynamic> data) {
    final isArchived = data['isArchived'] ?? false;
    final unreadCount = data['unreadCount'] ?? 0;
    final isGroup = data['isGroup'] ?? false;
    final lastSenderId = data['lastSenderId'];
    final currentUserId = _authService.currentUser?.uid;
    
    final bool isUnread = unreadCount > 0 && lastSenderId != null && lastSenderId != currentUserId;
    
    switch (_selectedCategory) {
      case MessageCategory.all:
        return !isArchived;
      case MessageCategory.unread:
        return !isArchived && isUnread;
      case MessageCategory.group:
        return !isArchived && isGroup;
      case MessageCategory.archived:
        return isArchived;
      default:
        return !isArchived;
    }
  }

  Widget _buildEmptyState() {
    String title;
    String description;

    switch (_selectedCategory) {
      case MessageCategory.unread:
        title = 'Okunmamış mesaj yok';
        description = 'Tüm mesajlarınızı okumuşsunuz';
        break;
      case MessageCategory.group:
        title = 'Grup mesajı yok';
        description = 'Henüz bir grup sohbetiniz bulunmuyor';
        break;
      case MessageCategory.archived:
        title = 'Arşivlenmiş mesaj yok';
        description = 'Arşivlenmiş sohbetiniz bulunmuyor';
        break;
      default:
        if (_searchQuery.isNotEmpty) {
          title = 'Sonuç bulunamadı';
          description = 'Farklı bir arama terimi deneyin';
        } else {
          title = 'Mesaj yok';
          description = 'Henüz bir sohbetiniz bulunmuyor';
        }
    }

    return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primaryLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
                                  shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  spreadRadius: 1,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
                                ),
                                child: Icon(
              _selectedCategory == MessageCategory.unread ? Icons.mark_email_read :
              _selectedCategory == MessageCategory.group ? Icons.group :
              _selectedCategory == MessageCategory.archived ? Icons.archive :
              _searchQuery.isNotEmpty ? Icons.search_off : Icons.chat_bubble_outline,
                                  size: 48,
              color: AppColors.surface,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
            title,
                                style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
            description,
                                style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
                                ),
            textAlign: TextAlign.center,
                              ),
                            ],
                          ),
    );
  }

  Widget _buildChatList(List<QueryDocumentSnapshot> chats) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: chats.length,
                          itemBuilder: (context, index) {
        final chatDoc = chats[index];
        final chatData = chatDoc.data() as Map<String, dynamic>;
        final participants = List<String>.from(chatData['participants'] ?? []);
        
        final otherParticipantId = participants.firstWhere(
          (id) => id != _authService.currentUser?.uid,
          orElse: () => participants.first,
        );

        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(otherParticipantId)
              .snapshots(),
          builder: (context, userSnapshot) {
            if (!userSnapshot.hasData) return const SizedBox();

            final userData = userSnapshot.data!.data() as Map<String, dynamic>;
            return _buildMessageItem(context, chatDoc, chatData, userData);
          },
        );
      },
    );
  }

  Widget _buildMessageItem(
    BuildContext context,
    QueryDocumentSnapshot chatDoc,
    Map<String, dynamic> chatData,
    Map<String, dynamic> userData,
  ) {
    final userName = userData['username'] ?? userData['name'] ?? 'İsimsiz Kullanıcı';
    final userImage = userData['profileImage'] ?? userData['profileImageUrl'];
    final isOnline = userData['isOnline'] ?? false;
    final participants = List<String>.from(chatData['participants'] ?? []);
    
    // Check if message is unread
    final unreadCount = chatData['unreadCount'] ?? 0;
    final lastSenderId = chatData['lastSenderId'];
    final currentUserId = _authService.currentUser?.uid;
    final bool isUnread = unreadCount > 0 && lastSenderId != null && lastSenderId != currentUserId;

    // Function to mark message as read
    void markAsRead() {
      if (isUnread) {
        FirebaseFirestore.instance
            .collection('chats')
            .doc(chatDoc.id)
            .update({
              'unreadCount': 0,
              'readBy': FieldValue.arrayUnion([currentUserId]),
              'lastReadAt': FieldValue.serverTimestamp(),
            });
      }
    }

    return Dismissible(
      key: Key(chatDoc.id),
      background: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.error, AppColors.error.withOpacity(0.8)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Icon(Icons.delete, color: AppColors.surface, size: 24),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        FirebaseFirestore.instance
            .collection('chats')
            .doc(chatDoc.id)
            .delete();
      },
      child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
          color: isUnread ? AppColors.surface : AppColors.surface.withOpacity(0.8),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow.withOpacity(isUnread ? 0.1 : 0.05),
              spreadRadius: isUnread ? 1 : 0,
              blurRadius: isUnread ? 5 : 3,
              offset: const Offset(0, 2),
                                ),
          ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
              // Mark as read before navigating
              markAsRead();
              
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ChatScreen(
                    isGroup: chatData['isGroup'] ?? false,
                    chatId: chatDoc.id,
                    chatName: userName,
                    chatImage: userImage ?? '',
                    participants: participants,
                                        ),
                                      ),
                                    );
                                  },
            borderRadius: BorderRadius.circular(12),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Row(
                                      children: [
                  _buildAvatar(userImage, isOnline),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(userName, isUnread, chatData),
                        const SizedBox(height: 2),
                        _buildLastMessage(chatData, isUnread),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(String? userImage, bool isOnline) {
    return Stack(
                                          children: [
                                            CircleAvatar(
          radius: 24,
          backgroundColor: AppColors.surface,
          child: userImage != null && userImage.isNotEmpty
              ? ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: userImage,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const CircularProgressIndicator(),
                    errorWidget: (context, url, error) => const Icon(
                      Icons.person,
                      size: 24,
                      color: AppColors.textSecondary,
                    ),
                  ),
                )
              : const Icon(
                  Icons.person,
                  size: 24,
                  color: AppColors.textSecondary,
                ),
        ),
        if (isOnline)
                                              Positioned(
                                                right: 0,
                                                bottom: 0,
                                                child: Container(
              width: 12,
              height: 12,
                                                  decoration: BoxDecoration(
                color: AppColors.success,
                                                    shape: BoxShape.circle,
                                                    border: Border.all(
                  color: AppColors.surface,
                                                      width: 2,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                          ],
    );
  }

  Widget _buildHeader(String userName, bool isUnread, Map<String, dynamic> chatData) {
    return Row(
                                            children: [
        Expanded(
          child: Text(
            userName,
                                                style: TextStyle(
              color: isUnread ? AppColors.textPrimary : AppColors.textPrimary.withOpacity(0.8),
              fontWeight: isUnread ? FontWeight.bold : FontWeight.w500,
                                                  fontSize: 14,
                                                ),
                                              ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: isUnread 
                ? AppColors.primary.withOpacity(0.15)
                : AppColors.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            _getTimeAgo((chatData['lastMessageTime'] as Timestamp).toDate()),
                                                    style: TextStyle(
              fontSize: 11,
              color: isUnread 
                  ? AppColors.primary
                  : AppColors.primary.withOpacity(0.7),
              fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                                                    ),
                                                  ),
                                              ),
                                            ],
    );
  }

  Widget _buildLastMessage(Map<String, dynamic> chatData, bool isUnread) {
    return Row(
      children: [
        Expanded(
          child: Text(
            chatData['lastMessage'] ?? '',
            style: TextStyle(
              color: isUnread
                  ? AppColors.textPrimary
                  : AppColors.textSecondary.withOpacity(0.8),
              fontWeight: isUnread ? FontWeight.w500 : FontWeight.normal,
              fontSize: 13,
                                        ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
                                  ),
                                ),
        if (isUnread)
          Container(
            margin: const EdgeInsets.only(left: 8),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
                        ),
                ),
              ],
    );
  }
} 