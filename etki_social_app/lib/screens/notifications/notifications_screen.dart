import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/notification_model.dart';

// Mor/eflatun tema renkleri
const Color primaryPurple = Color(0xFFF8F6FF);
const Color primaryPurpleLight = Color(0xFFFF7262);
const Color surfaceColor = Colors.white;
const Color backgroundColor = Color(0xFFFFF5F4);

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> with SingleTickerProviderStateMixin {
  late AnimationController _tutorialController;
  late Animation<double> _tutorialAnimation;
  bool _showTutorial = false;
  int _tutorialShownCount = 0;
  
  // Bildirimleri state'e taşıyalım ki güncelleyebilelim
  final List<NotificationModel> _notifications = [
    NotificationModel(
      type: NotificationType.groupInvite,
      userId: 'user1',
      userName: 'Ahmet Yılmaz',
      userImage: 'https://picsum.photos/200?random=1',
      groupId: 'group1',
      groupName: 'Flutter Türkiye',
      groupImage: 'https://picsum.photos/200?random=2',
      createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
    ),
    NotificationModel(
      type: NotificationType.postLike,
      userId: 'user2',
      userName: 'Ayşe Demir',
      userImage: 'https://picsum.photos/200?random=3',
      postId: 'post1',
      postImage: 'https://picsum.photos/200?random=4',
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    NotificationModel(
      type: NotificationType.commentReply,
      userId: 'user3',
      userName: 'Mehmet Kaya',
      userImage: 'https://picsum.photos/200?random=5',
      commentId: 'comment1',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    NotificationModel(
      type: NotificationType.followRequest,
      userId: 'user4',
      userName: 'Zeynep Şahin',
      userImage: 'https://picsum.photos/200?random=6',
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    NotificationModel(
      type: NotificationType.securityAlert,
      userId: 'system',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tutorialController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _tutorialAnimation = Tween<double>(begin: -0.3, end: 0.3).animate(
      CurvedAnimation(
        parent: _tutorialController,
        curve: Curves.easeInOutBack,
      ),
    );
    
    // Animasyonu gecikmeli başlat
    Future.delayed(const Duration(milliseconds: 500), () {
      _loadTutorialState();
    });
  }

  Future<void> _loadTutorialState() async {
    final prefs = await SharedPreferences.getInstance();
    _tutorialShownCount = prefs.getInt('tutorial_shown_count') ?? 0;
    
    if (_tutorialShownCount < 1) {
      setState(() {
        _showTutorial = true;
      });

      // Animasyonu 3 kez tekrarla
      for (var i = 0; i < 3; i++) {
        if (!mounted) return;
        await _tutorialController.forward();
        await Future.delayed(const Duration(milliseconds: 200));
        if (!mounted) return;
        await _tutorialController.reverse();
        await Future.delayed(const Duration(milliseconds: 200));
      }

      if (!mounted) return;
      setState(() {
        _showTutorial = false;
      });
      await prefs.setInt('tutorial_shown_count', _tutorialShownCount + 1);
    }
  }

  @override
  void dispose() {
    _tutorialController.dispose();
    super.dispose();
  }

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inDays > 7) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} gün önce';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} saat önce';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} dakika önce';
    } else {
      return 'Az önce';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Bildirimler', style: TextStyle(color: Color(0xFFFF7262))),
        centerTitle: true,
        elevation: 0,
        backgroundColor: surfaceColor,
        actions: [],
      ),
      body: Stack(
        children: [
          ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: _notifications.length,
            itemBuilder: (context, index) {
              final notification = _notifications[index];
              
              if (notification.type == NotificationType.followRequest) {
                return _buildFollowRequestCard(notification, index);
              }
              
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: notification.isRead ? surfaceColor : primaryPurpleLight,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: primaryPurple.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: InkWell(
                  onTap: () {
                    // TODO: Handle notification tap
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLeading(notification),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                notification.message,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: notification.isRead ? const Color(0xFFFF7262) : primaryPurple,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _getTimeAgo(notification.createdAt),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFFFFFFFF),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: primaryPurple,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          if (_showTutorial)
            Positioned(
              top: 100,
              left: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: _tutorialAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(_tutorialAnimation.value * 100, 0),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.green.withOpacity(0.1),
                            ),
                            child: const Icon(Icons.swipe_right, color: Colors.green),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Kaydırarak İşlem Yapın',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[800],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Arkadaşlık isteklerini sağa kaydırarak kabul edin, sola kaydırarak reddedin',
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
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFollowRequestCard(NotificationModel notification, int index) {
    return Stack(
      children: [
        Dismissible(
          key: Key(notification.userId),
          direction: DismissDirection.horizontal,
          background: Container(
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 20),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.green, size: 24),
                ),
                const SizedBox(width: 8),
                Text(
                  'Kabul Et',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
          ),
          secondaryBackground: Container(
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Reddet',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.red[700],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.red, size: 24),
                ),
              ],
            ),
          ),
          onDismissed: (direction) {
            setState(() {
              if (direction == DismissDirection.startToEnd) {
                notification.isAccepted = true;
              } else {
                notification.isRejected = true;
              }
              _notifications.removeAt(index);
            });
          },
          confirmDismiss: (direction) async {
            return true;
          },
          child: AnimatedBuilder(
            animation: _tutorialAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(_showTutorial ? _tutorialAnimation.value * MediaQuery.of(context).size.width * 0.3 : 0, 0),
                child: child!,
              );
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: notification.isRead ? Colors.white : primaryPurpleLight,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: primaryPurple.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (notification.isAccepted)
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: primaryPurple,
                        ),
                        child: const Icon(Icons.person_add, color: Colors.white, size: 24),
                      )
                    else
                      CachedNetworkImage(
                        imageUrl: notification.userImage ?? '',
                        imageBuilder: (context, imageProvider) => Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            image: DecorationImage(
                              image: imageProvider,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        placeholder: (context, url) => Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey[300],
                          ),
                          child: const Icon(Icons.person, color: Colors.white),
                        ),
                        errorWidget: (context, url, error) => Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey[300],
                          ),
                          child: const Icon(Icons.person, color: Colors.white),
                        ),
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            notification.message,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: notification.isRead ? const Color(0xFFFF7262) : primaryPurple,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getTimeAgo(notification.createdAt),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFFFFFFFF),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!notification.isRead && !notification.isAccepted)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: primaryPurple,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (_showTutorial)
          Positioned(
            top: -40,
            left: 0,
            right: 0,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.swipe_right, color: Colors.green, size: 20),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Kabul Et',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.green[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        'Reddet',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.red[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.swipe_left, color: Colors.red, size: 20),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLeading(NotificationModel notification) {
    if (notification.type == NotificationType.commentReply) {
      return CachedNetworkImage(
        imageUrl: notification.userImage ?? '',
        imageBuilder: (context, imageProvider) => Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            image: DecorationImage(
              image: imageProvider,
              fit: BoxFit.cover,
            ),
          ),
        ),
        placeholder: (context, url) => Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey[300],
          ),
          child: const Icon(Icons.person, color: Colors.white),
        ),
        errorWidget: (context, url, error) => Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey[300],
          ),
          child: const Icon(Icons.person, color: Colors.white),
        ),
      );
    }

    Color iconColor;
    IconData iconData;
    Color backgroundColor;

    switch (notification.type) {
      case NotificationType.groupInvite:
        iconColor = Colors.white;
        iconData = Icons.group_add;
        backgroundColor = Colors.blue;
        break;
      case NotificationType.postLike:
        iconColor = Colors.white;
        iconData = Icons.favorite;
        backgroundColor = Colors.red;
        break;
      case NotificationType.securityAlert:
        iconColor = Colors.white;
        iconData = Icons.security;
        backgroundColor = Colors.orange;
        break;
      default:
        iconColor = Colors.white;
        iconData = Icons.notifications;
        backgroundColor = Colors.grey;
    }

    if (notification.type == NotificationType.groupInvite && notification.groupImage != null) {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: backgroundColor,
        ),
        child: Stack(
          children: [
            CachedNetworkImage(
              imageUrl: notification.groupImage!,
              imageBuilder: (context, imageProvider) => Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: imageProvider,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              placeholder: (context, url) => Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: backgroundColor,
                ),
                child: Icon(iconData, color: iconColor, size: 24),
              ),
              errorWidget: (context, url, error) => Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: backgroundColor,
                ),
                child: Icon(iconData, color: iconColor, size: 24),
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Icon(iconData, color: iconColor, size: 12),
              ),
            ),
          ],
        ),
      );
    }

    if (notification.type == NotificationType.postLike && notification.postImage != null) {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: backgroundColor,
        ),
        child: Stack(
          children: [
            CachedNetworkImage(
              imageUrl: notification.postImage!,
              imageBuilder: (context, imageProvider) => Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: imageProvider,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              placeholder: (context, url) => Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: backgroundColor,
                ),
                child: Icon(iconData, color: iconColor, size: 24),
              ),
              errorWidget: (context, url, error) => Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: backgroundColor,
                ),
                child: Icon(iconData, color: iconColor, size: 24),
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Icon(iconData, color: iconColor, size: 12),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor,
      ),
      child: Icon(iconData, color: iconColor, size: 24),
    );
  }
} 