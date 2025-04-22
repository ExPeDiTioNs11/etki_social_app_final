import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme/colors.dart';
import 'chat_screen.dart';

enum MessageCategory {
  all,
  unread,
  group,
}

class Message {
  final String userId;
  final String userName;
  final String userImage;
  final String lastMessage;
  final DateTime lastMessageTime;
  final bool isUnread;
  final bool isGroup;

  Message({
    required this.userId,
    required this.userName,
    required this.userImage,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.isUnread,
    this.isGroup = false,
  });
}

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({Key? key}) : super(key: key);

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  MessageCategory _selectedCategory = MessageCategory.all;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Example messages data
  final List<Message> _messages = [
    Message(
      userId: '1',
      userName: 'Ahmet Yılmaz',
      userImage: 'https://picsum.photos/200',
      lastMessage: 'Projeyi ne zaman tamamlayabiliriz?',
      lastMessageTime: DateTime.now().subtract(const Duration(minutes: 5)),
      isUnread: true,
    ),
    Message(
      userId: '2',
      userName: 'Ayşe Demir',
      userImage: 'https://picsum.photos/201',
      lastMessage: 'Görev tamamlandı, kontrol edebilir misin?',
      lastMessageTime: DateTime.now().subtract(const Duration(hours: 1)),
      isUnread: false,
    ),
    Message(
      userId: '3',
      userName: 'Mehmet Kaya',
      userImage: 'https://picsum.photos/202',
      lastMessage: 'Yeni bir sosyal sorumluluk projesi başlatıyoruz',
      lastMessageTime: DateTime.now().subtract(const Duration(hours: 2)),
      isUnread: true,
    ),
    Message(
      userId: '4',
      userName: 'Flutter Türkiye',
      userImage: 'https://picsum.photos/203',
      lastMessage: 'Yeni bir etkinlik planlıyoruz',
      lastMessageTime: DateTime.now().subtract(const Duration(hours: 3)),
      isUnread: true,
      isGroup: true,
    ),
  ];

  List<Message> get _filteredMessages {
    return _messages.where((message) {
      final matchesCategory = _selectedCategory == MessageCategory.all ||
          (_selectedCategory == MessageCategory.unread && message.isUnread) ||
          (_selectedCategory == MessageCategory.group && message.isGroup);

      final matchesSearch = _searchQuery.isEmpty ||
          message.userName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          message.lastMessage.toLowerCase().contains(_searchQuery.toLowerCase());

      return matchesCategory && matchesSearch;
    }).toList();
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mesajlar', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            margin: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Mesajlarda ara...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: Colors.grey[400]),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          // Categories
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
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (category == MessageCategory.unread)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(right: 6),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.white : AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        Text(
                          category == MessageCategory.all
                              ? 'Tümü'
                              : category == MessageCategory.unread
                                  ? 'Okunmamış'
                                  : 'Gruplar',
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          // Messages List
          Expanded(
            child: ListView.builder(
              itemCount: _filteredMessages.length,
              itemBuilder: (context, index) {
                final message = _filteredMessages[index];
                return Dismissible(
                  key: Key(message.userId),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.delete,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  confirmDismiss: (direction) async {
                    return await showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Mesajları Sil'),
                        content: Text('${message.userName} ile olan tüm mesajlarınızı silmek istediğinize emin misiniz?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('İptal'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text(
                              'Sil',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  onDismissed: (direction) {
                    setState(() {
                      _messages.removeAt(index);
                    });
                  },
                  child: ListTile(
                    leading: CircleAvatar(
                      radius: 28,
                      backgroundImage: CachedNetworkImageProvider(message.userImage),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            message.userName,
                            style: TextStyle(
                              fontWeight: message.isUnread ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                        Text(
                          _getTimeAgo(message.lastMessageTime),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: message.isUnread ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                    subtitle: Text(
                      message.lastMessage,
                      style: TextStyle(
                        color: message.isUnread ? Colors.black87 : Colors.grey[600],
                        fontWeight: message.isUnread ? FontWeight.w500 : FontWeight.normal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            isGroup: message.isGroup,
                            chatId: message.userId,
                            chatName: message.userName,
                            chatImage: message.userImage,
                            participants: [],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Create new message
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.edit),
      ),
    );
  }
} 