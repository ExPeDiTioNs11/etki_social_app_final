import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../constants/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';

class ChatScreen extends StatefulWidget {
  final bool isGroup;
  final String chatId;
  final String chatName;
  final String chatImage;
  final List<String> participants;

  const ChatScreen({
    Key? key,
    required this.isGroup,
    required this.chatId,
    required this.chatName,
    required this.chatImage,
    required this.participants,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _isLoadingMore = false;
  DocumentSnapshot? _lastDocument;
  final int _messagesPerPage = 20;
  bool _hasMoreMessages = true;
  Map<String, dynamic>? _chatUserData;
  bool _isUserOnline = false;

  @override
  void initState() {
    super.initState();
    _markMessagesAsRead();
    _scrollController.addListener(_onScroll);
    _loadChatUserData();
    _listenToUserStatus();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.minScrollExtent) {
      if (!_isLoadingMore && _hasMoreMessages) {
        _loadMoreMessages();
      }
    }
  }

  Future<void> _loadMoreMessages() async {
    if (_isLoadingMore || !_hasMoreMessages) return;

      setState(() {
      _isLoadingMore = true;
      });

    try {
      Query query = FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages')
          .orderBy('timestamp', descending: false)
          .limit(_messagesPerPage);

      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      final snapshot = await query.get();

      if (snapshot.docs.isEmpty) {
        setState(() {
          _hasMoreMessages = false;
        });
        return;
      }

      _lastDocument = snapshot.docs.last;

      // Mesajları mevcut listeye ekle
      final newMessages = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return <String, dynamic>{
          'id': doc.id,
          'senderId': data['senderId'],
          'receiverId': data['receiverId'],
          'content': data['content'],
          'timestamp': data['timestamp'],
          'isRead': data['isRead'] ?? false,
        };
      }).toList();

      setState(() {
        _messages.addAll(newMessages);
      });
    } catch (e) {
      print('Error loading more messages: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mesajlar yüklenirken bir hata oluştu'),
          duration: Duration(seconds: 2),
        ),
      );
    } finally {
      setState(() {
        _isLoadingMore = false;
                                });
    }
  }

  List<Map<String, dynamic>> _messages = [];

  Future<void> _markMessagesAsRead() async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages')
          .where('receiverId', isEqualTo: currentUser.uid)
          .where('isRead', isEqualTo: false)
          .get()
          .then((snapshot) {
        for (var doc in snapshot.docs) {
          doc.reference.update({'isRead': true});
        }
      });
    } catch (e) {
      print('Error marking messages as read: $e');
  }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final currentUser = _authService.currentUser;
    if (currentUser == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      print('Sending message to chat: ${widget.chatId}'); // Debug log
      print('Current user: ${currentUser.uid}'); // Debug log
      print('Participants: ${widget.participants}'); // Debug log

      // Eğer chat ID boşsa, yeni bir chat ID oluştur
      String chatId = widget.chatId;
      if (chatId.isEmpty) {
        // Katılımcıları sırala ve birleştirerek benzersiz bir ID oluştur
        final sortedParticipants = [currentUser.uid, ...widget.participants]..sort();
        chatId = sortedParticipants.join('_');
        print('Generated new chat ID: $chatId'); // Debug log
      }

      final chatRef = FirebaseFirestore.instance.collection('chats').doc(chatId);
      final messageRef = chatRef.collection('messages');

      // Yeni mesaj verisi
      final message = {
        'senderId': currentUser.uid,
        'receiverId': widget.participants.first,
        'content': _messageController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      };

      print('Message data: $message'); // Debug log

      // Önce chat belgesini oluştur/güncelle
      final chatData = {
        'participants': [currentUser.uid, ...widget.participants],
        'lastMessage': message['content'],
        'lastMessageTime': message['timestamp'],
        'lastSenderId': currentUser.uid,
        'isGroup': widget.isGroup,
        'unreadCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      print('Chat data to be saved: $chatData'); // Debug log

      await chatRef.set(chatData, SetOptions(merge: true));
      print('Chat document updated successfully'); // Debug log

      // Sonra mesajı ekle
      final newMessage = await messageRef.add(message);
      print('Message added successfully with ID: ${newMessage.id}'); // Debug log

      _messageController.clear();
    _scrollToBottom();
    } catch (e) {
      print('Error sending message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mesaj gönderilirken bir hata oluştu'),
          duration: Duration(seconds: 2),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _loadChatUserData() async {
    if (widget.participants.isEmpty) {
      print('No participants found');
      return;
    }

    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) return;

      // Find the other participant (not the current user)
      final otherParticipant = widget.participants.firstWhere(
        (id) => id != currentUser.uid,
        orElse: () => widget.participants.first,
      );

      print('Loading user data for: $otherParticipant');

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(otherParticipant)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        print('User data loaded: ${userData['name']}');
        print('Profile image URL: ${userData['profileImage']}');

        setState(() {
          _chatUserData = userData;
        });
    } else {
        print('User document not found');
    }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  void _listenToUserStatus() {
    if (widget.participants.isEmpty) {
      print('No participants found');
      return;
    }

    final currentUser = _authService.currentUser;
    if (currentUser == null) return;

    // Find the other participant (not the current user)
    final otherParticipant = widget.participants.firstWhere(
      (id) => id != currentUser.uid,
      orElse: () => widget.participants.first,
    );

    FirebaseFirestore.instance
        .collection('users')
        .doc(otherParticipant)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        setState(() {
          _isUserOnline = data['isOnline'] ?? false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        title: Row(
            children: [
            Stack(
                children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryLight],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: CircleAvatar(
                radius: 20,
                    backgroundColor: AppColors.surface,
                    child: CircleAvatar(
                      radius: 18,
                      backgroundImage: _chatUserData?['profileImage'] != null && 
                                     _chatUserData!['profileImage'].toString().isNotEmpty
                          ? CachedNetworkImageProvider(_chatUserData!['profileImage'])
                          : widget.chatImage.isNotEmpty
                              ? CachedNetworkImageProvider(widget.chatImage)
                              : null,
                      child: _chatUserData?['profileImage'] == null || 
                             _chatUserData!['profileImage'].toString().isEmpty
                          ? const Icon(Icons.person, color: AppColors.textSecondary)
                          : null,
                    ),
            ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _isUserOnline ? AppColors.success : AppColors.error,
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
              const SizedBox(width: 12),
          Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                  _chatUserData?['name'] ?? widget.chatName,
                    style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                            Text(
                  _isUserOnline ? 'Çevrimiçi' : 'Çevrimdışı',
                              style: TextStyle(
                    color: AppColors.textSecondary,
                        fontSize: 12,
                              ),
                            ),
                          ],
                    ),
                  ],
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
              child: const Icon(
                Icons.more_vert,
                color: AppColors.primary,
                size: 20,
                            ),
            ),
            onPressed: () {
              // TODO: Implement chat options
            },
                      ),
                    ],
                  ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(widget.chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: false)
                  .limit(_messagesPerPage)
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
                          child: const Icon(
                            Icons.chat_bubble_outline,
                            size: 48,
                            color: AppColors.surface,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                          'Henüz mesaj yok',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                          'İlk mesajı siz gönderin',
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

                final newMessages = snapshot.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return <String, dynamic>{
                    'id': doc.id,
                    'senderId': data['senderId'],
                    'receiverId': data['receiverId'],
                    'content': data['content'],
                    'timestamp': data['timestamp'],
                    'isRead': data['isRead'] ?? false,
                  };
                }).toList();

                _messages = newMessages;
                _lastDocument = snapshot.data!.docs.last;

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  reverse: true,
                  itemCount: _messages.length + (_hasMoreMessages ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _messages.length) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: _isLoadingMore
                              ? const CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                                )
                              : TextButton(
                                  onPressed: _loadMoreMessages,
                                  child: Text(
                                    'Daha fazla mesaj yükle',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                        ),
                      );
                    }

                    final message = _messages[_messages.length - 1 - index];
                    final isMe = message['senderId'] == _authService.currentUser?.uid;
                    final timestamp = message['timestamp'] as Timestamp?;
                    final time = timestamp?.toDate() ?? DateTime.now();
                                            
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                          gradient: isMe
                              ? LinearGradient(
                                  colors: [AppColors.primary, AppColors.primaryLight],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                          color: isMe ? null : AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                              color: AppColors.shadow.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              message['content'],
                              style: TextStyle(
                                color: isMe ? AppColors.surface : AppColors.textPrimary,
                                fontSize: 14,
                                    ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                            Text(
                                  '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                                      style: TextStyle(
                                    color: isMe ? AppColors.surface.withOpacity(0.7) : AppColors.textSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                                if (isMe) ...[
                                  const SizedBox(width: 4),
                                  Icon(
                                    message['isRead'] ? Icons.done_all : Icons.done,
                                    size: 14,
                                    color: AppColors.surface.withOpacity(0.7),
                                  ),
                                ],
                              ],
                                ),
                          ],
                            ),
                          ),
                        );
                      },
                        );
                      },
                    ),
              ),
                    Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
              color: AppColors.surface,
                  boxShadow: [
                    BoxShadow(
                  color: AppColors.shadow.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, -2),
              ),
            ],
          ),
                  child: Row(
                    children: [
                      Expanded(
                          child: TextField(
                            controller: _messageController,
                            decoration: InputDecoration(
                              hintText: 'Mesajınızı yazın...',
                      hintStyle: TextStyle(color: AppColors.textSecondary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: AppColors.divider),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: AppColors.divider),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: AppColors.primary),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      filled: true,
                      fillColor: AppColors.primaryBackground,
                    ),
                    maxLines: null,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
          Container(
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
                  child: IconButton(
                    icon: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                  child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.surface),
                    strokeWidth: 2,
                            ),
                          )
                        : const Icon(
                            Icons.send,
                            color: AppColors.surface,
                            size: 24,
                          ),
                    onPressed: _isLoading ? null : _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 