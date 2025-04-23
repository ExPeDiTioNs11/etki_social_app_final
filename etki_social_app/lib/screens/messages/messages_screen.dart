import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme/colors.dart';
import 'chat_screen.dart';
import 'dart:math';

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
  final TextEditingController _newMessageSearchController = TextEditingController();
  String _searchQuery = '';
  String _newMessageSearchQuery = '';
  late AnimationController _animationController;
  late Animation<double> _animation;

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
    // Arşivlenmiş mesajlar
    Message(
      userId: '5',
      userName: 'Eski Proje Ekibi',
      userImage: 'https://picsum.photos/204',
      lastMessage: 'Proje dosyaları arşivlendi',
      lastMessageTime: DateTime.now().subtract(const Duration(days: 5)),
      isUnread: false,
      isGroup: true,
      isArchived: true,
    ),
    Message(
      userId: '6',
      userName: 'Yaz Stajı',
      userImage: 'https://picsum.photos/205',
      lastMessage: 'Staj değerlendirme formları tamamlandı',
      lastMessageTime: DateTime.now().subtract(const Duration(days: 10)),
      isUnread: false,
      isGroup: true,
      isArchived: true,
    ),
    Message(
      userId: '7',
      userName: 'Eski İş Arkadaşı',
      userImage: 'https://picsum.photos/206',
      lastMessage: 'Referans mektubu hazır',
      lastMessageTime: DateTime.now().subtract(const Duration(days: 15)),
      isUnread: false,
      isArchived: true,
    ),
  ];

  // Örnek takip edilen kullanıcılar
  final List<Map<String, dynamic>> _followedUsers = [
    {
      'id': '1',
      'name': 'Ahmet Yılmaz',
      'username': '@ahmetyilmaz',
      'image': 'https://picsum.photos/200',
      'isOnline': true,
    },
    {
      'id': '2',
      'name': 'Ayşe Demir',
      'username': '@aysedemir',
      'image': 'https://picsum.photos/201',
      'isOnline': false,
    },
    {
      'id': '3',
      'name': 'Mehmet Kaya',
      'username': '@mehmetkaya',
      'image': 'https://picsum.photos/202',
      'isOnline': true,
    },
    {
      'id': '4',
      'name': 'Zeynep Şahin',
      'username': '@zeynepsahin',
      'image': 'https://picsum.photos/203',
      'isOnline': false,
    },
    {
      'id': '5',
      'name': 'Can Öztürk',
      'username': '@canozturk',
      'image': 'https://picsum.photos/204',
      'isOnline': true,
    },
  ];

  List<Message> get _filteredMessages {
    return _messages.where((message) {
      final matchesCategory = 
          (_selectedCategory == MessageCategory.all && !message.isArchived) ||
          (_selectedCategory == MessageCategory.unread && message.isUnread && !message.isArchived) ||
          (_selectedCategory == MessageCategory.group && message.isGroup && !message.isArchived) ||
          (_selectedCategory == MessageCategory.archived && message.isArchived);

      final matchesSearch = _searchQuery.isEmpty ||
          message.userName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          message.lastMessage.toLowerCase().contains(_searchQuery.toLowerCase());

      return matchesCategory && matchesSearch;
    }).toList();
  }

  List<Map<String, dynamic>> get _filteredFollowedUsers {
    if (_newMessageSearchQuery.isEmpty) {
      return _followedUsers;
    }
    
    final query = _newMessageSearchQuery.toLowerCase();
    return _followedUsers.where((user) {
      final name = user['name'].toString().toLowerCase();
      final username = user['username'].toString().toLowerCase();
      return name.contains(query) || username.contains(query);
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
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: -0.1,
      end: 0.1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _newMessageSearchController.dispose();
    _animationController.dispose();
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
                                  : category == MessageCategory.group
                                      ? 'Gruplar'
                                      : 'Arşivlenmiş',
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
                    onLongPress: () {
                      _showMessageOptionsModal(context, message);
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
          _showNewMessageModal(context);
        },
        backgroundColor: AppColors.primary,
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Stack(
              alignment: Alignment.center,
              children: [
                // Rüzgar çizgileri
                if (_animation.value > 0)
                  Positioned(
                    left: 0,
                    child: Opacity(
                      opacity: _animation.value.abs() * 2,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(3, (index) {
                          return Transform.translate(
                            offset: Offset(0, sin(index * 0.5 + _animation.value * 2) * 2),
                            child: Container(
                              width: 2,
                              height: 8,
                              margin: const EdgeInsets.only(right: 2),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(1),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                if (_animation.value < 0)
                  Positioned(
                    right: 0,
                    child: Opacity(
                      opacity: _animation.value.abs() * 2,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(3, (index) {
                          return Transform.translate(
                            offset: Offset(0, sin(index * 0.5 + _animation.value * 2) * 2),
                            child: Container(
                              width: 2,
                              height: 8,
                              margin: const EdgeInsets.only(left: 2),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(1),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                // Kağıt uçak ikonu
                Transform.rotate(
                  angle: _animation.value,
                  child: const Icon(Icons.send_rounded),
                ),
              ],
            );
          },
        ),
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

  void _showNewMessageModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
            ),
            child: Column(
              children: [
                // Modal başlık ve kapatma butonu
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
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
                      Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const Expanded(
                            child: Center(
                              child: Text(
                                'Yeni Mesaj',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 48),
                        ],
                      ),
                    ],
                  ),
                ),
                // Arama çubuğu
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: Colors.grey[200]!,
                      width: 1,
                    ),
                  ),
                  child: TextField(
                    controller: _newMessageSearchController,
                    autofocus: true,
                    style: const TextStyle(fontSize: 16),
                    decoration: InputDecoration(
                      hintText: 'Kullanıcı ara...',
                      hintStyle: TextStyle(color: Colors.grey[500]),
                      prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                      suffixIcon: _newMessageSearchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear, color: Colors.grey[500]),
                              onPressed: () {
                                _newMessageSearchController.clear();
                                setModalState(() {
                                  _newMessageSearchQuery = '';
                                });
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onChanged: (value) {
                      setModalState(() {
                        _newMessageSearchQuery = value;
                      });
                    },
                  ),
                ),
                // Kullanıcı listesi
                Expanded(
                  child: _filteredFollowedUsers.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.search_off,
                                  size: 48,
                                  color: Colors.grey[400],
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Kullanıcı bulunamadı',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Farklı bir arama terimi deneyin',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filteredFollowedUsers.length,
                          itemBuilder: (context, index) {
                            final user = _filteredFollowedUsers[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color: Colors.grey[200]!,
                                  width: 1,
                                ),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    Navigator.pop(context);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ChatScreen(
                                          isGroup: false,
                                          chatId: user['id'],
                                          chatName: user['name'],
                                          chatImage: user['image'],
                                          participants: [],
                                        ),
                                      ),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(15),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Row(
                                      children: [
                                        Stack(
                                          children: [
                                            CircleAvatar(
                                              radius: 28,
                                              backgroundImage: CachedNetworkImageProvider(user['image']),
                                            ),
                                            if (user['isOnline'])
                                              Positioned(
                                                right: 0,
                                                bottom: 0,
                                                child: Container(
                                                  width: 14,
                                                  height: 14,
                                                  decoration: BoxDecoration(
                                                    color: Colors.green,
                                                    shape: BoxShape.circle,
                                                    border: Border.all(
                                                      color: Colors.white,
                                                      width: 2,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                user['name'],
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                user['username'],
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 14,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.circle,
                                                    size: 8,
                                                    color: user['isOnline'] ? Colors.green : Colors.grey[400],
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    user['isOnline'] ? 'Çevrimiçi' : 'Çevrimdışı',
                                                    style: TextStyle(
                                                      color: user['isOnline'] ? Colors.green : Colors.grey[500],
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        Icon(
                                          Icons.arrow_forward_ios,
                                          size: 16,
                                          color: Colors.grey[400],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
} 