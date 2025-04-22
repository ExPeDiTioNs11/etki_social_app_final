import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme/colors.dart';
import 'dart:math';
import 'dart:async';

class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String senderImage;
  final String content;
  final DateTime timestamp;
  final bool isMe;
  final MessageType type;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderImage,
    required this.content,
    required this.timestamp,
    required this.isMe,
    this.type = MessageType.text,
  });
}

enum MessageType {
  text,
  image,
  video,
  file,
}

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

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;
  late final AnimationController _starController;
  late final AnimationController _callController;
  late final AnimationController _waveController;
  late final AnimationController _timerController;
  final _randomOffsets = List.generate(8, (_) => Random().nextDouble() * 2 * pi);
  bool _isMuted = false;
  bool _isSpeakerOn = false;
  bool _isVideoOn = false;
  bool _isCallActive = false;
  Duration _callDuration = Duration.zero;
  Timer? _callTimer;

  // Örnek mesajlar
  final List<ChatMessage> _messages = [
    ChatMessage(
      id: '1',
      senderId: 'user1',
      senderName: 'Ahmet Yılmaz',
      senderImage: 'https://picsum.photos/200',
      content: 'Merhaba, nasılsın?',
      timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
      isMe: false,
    ),
    ChatMessage(
      id: '2',
      senderId: 'me',
      senderName: 'Ben',
      senderImage: 'https://picsum.photos/201',
      content: 'İyiyim, teşekkürler! Sen nasılsın?',
      timestamp: DateTime.now().subtract(const Duration(minutes: 25)),
      isMe: true,
    ),
    ChatMessage(
      id: '3',
      senderId: 'user1',
      senderName: 'Ahmet Yılmaz',
      senderImage: 'https://picsum.photos/200',
      content: 'Ben de iyiyim. Yeni projeyi duydun mu?',
      timestamp: DateTime.now().subtract(const Duration(minutes: 20)),
      isMe: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _starController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _callController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _timerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _starController.dispose();
    _callController.dispose();
    _waveController.dispose();
    _timerController.dispose();
    _callTimer?.cancel();
    super.dispose();
  }

  void _startCallTimer() {
    _callTimer?.cancel();
    _callDuration = Duration.zero;
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _callDuration += const Duration(seconds: 1);
      });
    });
  }

  void _resetCallState() {
    _callTimer?.cancel();
    _callDuration = Duration.zero;
    _isCallActive = false;
    _isMuted = false;
    _isSpeakerOn = false;
    _isVideoOn = false;
  }

  void _showCallScreen(BuildContext context) {
    _isCallActive = true;
    _startCallTimer();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: false,
      isDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Call Header
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
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
                          const Spacer(),
                          Text(
                            'Görüşme',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Call Status
                      Text(
                        'Görüşme Devam Ediyor',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Call Duration
                      AnimatedBuilder(
                        animation: _timerController,
                        builder: (context, child) {
                          return Text(
                            _formatDuration(_callDuration),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                // Call Content
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Profile Image with Wave Effect
                        SizedBox(
                          height: 300,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              AnimatedBuilder(
                                animation: _waveController,
                                builder: (context, child) {
                                  return Positioned(
                                    child: Container(
                                      width: 200 + (_waveController.value * 40),
                                      height: 200 + (_waveController.value * 40),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: AppColors.primary.withOpacity(0.5 - (_waveController.value * 0.5)),
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              Container(
                                width: 200,
                                height: 200,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  image: DecorationImage(
                                    image: CachedNetworkImageProvider(widget.chatImage),
                                    fit: BoxFit.cover,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 20,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Caller Name
                        Text(
                          widget.chatName,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Call Status
                        Text(
                          'Mobil',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                        const Spacer(),
                        // Call Controls
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildCallControl(
                              icon: _isMuted ? Icons.mic_off : Icons.mic,
                              label: 'Sessiz',
                              color: _isMuted ? AppColors.primary : Colors.grey[600]!,
                              onTap: () {
                                setModalState(() {
                                  _isMuted = !_isMuted;
                                });
                              },
                            ),
                            _buildCallControl(
                              icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_off,
                              label: 'Hoparlör',
                              color: _isSpeakerOn ? AppColors.primary : Colors.grey[600]!,
                              onTap: () {
                                setModalState(() {
                                  _isSpeakerOn = !_isSpeakerOn;
                                });
                              },
                            ),
                            _buildCallControl(
                              icon: _isVideoOn ? Icons.videocam : Icons.videocam_off,
                              label: 'Video',
                              color: _isVideoOn ? AppColors.primary : Colors.grey[600]!,
                              onTap: () {
                                setModalState(() {
                                  _isVideoOn = !_isVideoOn;
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        // End Call Button
                        ScaleTransition(
                          scale: Tween<double>(begin: 1.0, end: 0.9).animate(
                            CurvedAnimation(
                              parent: _callController,
                              curve: Curves.easeInOut,
                            ),
                          ),
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withOpacity(0.3),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.call_end, color: Colors.white),
                              iconSize: 30,
                              onPressed: () {
                                _callController.forward().then((_) {
                                  _callController.reverse();
                                  _resetCallState();
                                  Navigator.pop(context);
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCallControl({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 30),
        ),
      ),
    );
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    final newMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: 'me',
      senderName: 'Ben',
      senderImage: 'https://picsum.photos/201',
      content: _messageController.text,
      timestamp: DateTime.now(),
      isMe: true,
    );

    setState(() {
      _messages.add(newMessage);
      _messageController.clear();
    });

    _scrollToBottom();
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

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return duration.inHours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: GestureDetector(
          onTap: () {
            _showUserProfileModal(context, ChatMessage(
              id: 'profile',
              senderId: widget.chatId,
              senderName: widget.chatName,
              senderImage: widget.chatImage,
              content: '',
              timestamp: DateTime.now(),
              isMe: false,
            ));
          },
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: CachedNetworkImageProvider(widget.chatImage),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.chatName,
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (widget.isGroup)
                    Text(
                      '${widget.participants.length} üye',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          if (!widget.isGroup)
            IconButton(
              icon: Icon(Icons.video_call, color: Colors.grey[800]),
              onPressed: () {
                // TODO: Start video call
              },
            ),
          if (!widget.isGroup)
            IconButton(
              icon: Icon(Icons.call, color: Colors.grey[800]),
              onPressed: () => _showCallScreen(context),
            ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    return Align(
                      alignment: message.isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: message.isMe ? AppColors.primary : Colors.grey[200],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              message.content,
                              style: TextStyle(
                                color: message.isMe ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _getTimeAgo(message.timestamp),
                              style: TextStyle(
                                color: message.isMe ? Colors.white70 : Colors.black54,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.attach_file, color: Colors.grey[600]),
                        onPressed: () {
                          // TODO: Show attachment options
                        },
                      ),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: TextField(
                            controller: _messageController,
                            decoration: InputDecoration(
                              hintText: 'Mesajınızı yazın...',
                              hintStyle: TextStyle(color: Colors.grey[500]),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            maxLines: null,
                            onChanged: (value) {
                              setState(() {
                                _isTyping = value.isNotEmpty;
                              });
                            },
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          _isTyping ? Icons.send : Icons.mic,
                          color: _isTyping ? AppColors.primary : Colors.grey[600],
                        ),
                        onPressed: _isTyping ? _sendMessage : null,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showUserProfileModal(BuildContext context, ChatMessage message) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: CustomScrollView(
            controller: scrollController,
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(top: 8, bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    CircleAvatar(
                      radius: 40,
                      backgroundImage: CachedNetworkImageProvider(message.senderImage),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      message.senderName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Son görülme: ${_getTimeAgo(message.timestamp)}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildActionButton(
                          icon: Icons.block,
                          label: 'Engelle',
                          color: Colors.red,
                          onTap: () {
                            Navigator.pop(context);
                          },
                        ),
                        _buildActionButton(
                          icon: Icons.delete,
                          label: 'Mesajları Sil',
                          color: Colors.orange,
                          onTap: () {
                            Navigator.pop(context);
                          },
                        ),
                        _buildActionButton(
                          icon: Icons.report,
                          label: 'Şikayet Et',
                          color: Colors.blue,
                          onTap: () {
                            Navigator.pop(context);
                          },
                        ),
                        _buildActionButton(
                          icon: Icons.person,
                          label: 'Profili Gör',
                          color: Colors.green,
                          onTap: () {
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 1.0, end: 1.1),
                      duration: const Duration(milliseconds: 1500),
                      curve: Curves.easeInOut,
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: Container(
                            width: double.infinity,
                            margin: const EdgeInsets.symmetric(horizontal: 24),
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 8,
                                shadowColor: AppColors.primary.withOpacity(0.5),
                              ),
                              icon: SizedBox(
                                width: 20,
                                height: 20,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // Rotating stars
                                    AnimatedBuilder(
                                      animation: _starController,
                                      builder: (context, child) {
                                        return Stack(
                                          alignment: Alignment.center,
                                          children: List.generate(8, (index) {
                                            final baseAngle = (index / 8) * 2 * pi;
                                            final randomOffset = _randomOffsets[index];
                                            final oscillation = sin(_starController.value * 2 * pi + randomOffset);
                                            final distance = 10 + oscillation * 2;
                                            final starRotation = _starController.value * 4 * pi + randomOffset;
                                            final opacity = 0.3 + (0.7 * (sin(_starController.value * 2 * pi + randomOffset) + 1) / 2);
                                            
                                            return Transform.translate(
                                              offset: Offset(
                                                cos(baseAngle + _starController.value * pi) * distance,
                                                sin(baseAngle + _starController.value * pi) * distance,
                                              ),
                                              child: Transform.rotate(
                                                angle: starRotation,
                                                child: Icon(
                                                  Icons.star,
                                                  size: 6,
                                                  color: Colors.amber.withOpacity(opacity),
                                                ),
                                              ),
                                            );
                                          }),
                                        );
                                      },
                                    ),
                                    // Coin background glow
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.amber[300]!.withOpacity(0.5),
                                            blurRadius: 8,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Main coin icon
                                    const Icon(
                                      Icons.circle,
                                      size: 12,
                                      color: Colors.amber,
                                    ),
                                    // Coin symbol
                                    const Text(
                                      '₺',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black26,
                                            offset: Offset(0, 1),
                                            blurRadius: 2,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              label: const Text(
                                'Ona bir görev ver',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 4,
                      width: 40,
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    _buildTabViewWithLoading(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaGrid(List<String> imageUrls) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: imageUrls.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () {
            // TODO: Show full screen image
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: imageUrls[index],
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: Colors.grey[200],
                child: const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey[200],
                child: const Icon(Icons.error),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFileList(List<Map<String, String>> files) {
    return ListView.builder(
      itemCount: files.length,
      itemBuilder: (context, index) {
        final file = files[index];
        return ListTile(
          leading: const Icon(Icons.insert_drive_file),
          title: Text(file['name']!),
          subtitle: Text(file['size']!),
          trailing: IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {
              // TODO: Download file
            },
          ),
        );
      },
    );
  }

  Widget _buildLinkList(List<Map<String, String>> links) {
    return ListView.builder(
      itemCount: links.length,
      itemBuilder: (context, index) {
        final link = links[index];
        return ListTile(
          leading: const Icon(Icons.link),
          title: Text(link['title']!),
          subtitle: Text(link['url']!),
          trailing: IconButton(
            icon: const Icon(Icons.open_in_new),
            onPressed: () {
              // TODO: Open link
            },
          ),
        );
      },
    );
  }

  Widget _buildTabViewWithLoading() {
    return DefaultTabController(
      length: 4,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TabBar(
            isScrollable: true,
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppColors.primary,
            tabs: const [
              Tab(text: 'Fotoğraflar'),
              Tab(text: 'Videolar'),
              Tab(text: 'Dosyalar'),
              Tab(text: 'Bağlantılar'),
            ],
          ),
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.5,
            child: TabBarView(
              children: [
                _buildMediaGrid([
                  'https://picsum.photos/200/300',
                  'https://picsum.photos/201/300',
                  'https://picsum.photos/202/300',
                  'https://picsum.photos/203/300',
                  'https://picsum.photos/204/300',
                  'https://picsum.photos/205/300',
                  'https://picsum.photos/206/300',
                  'https://picsum.photos/207/300',
                  'https://picsum.photos/208/300',
                ]),
                _buildMediaGrid([
                  'https://picsum.photos/209/300',
                  'https://picsum.photos/210/300',
                  'https://picsum.photos/211/300',
                  'https://picsum.photos/212/300',
                ]),
                _buildFileList([
                  {'name': 'Döküman.pdf', 'size': '2.5 MB'},
                  {'name': 'Sunum.pptx', 'size': '5.1 MB'},
                  {'name': 'Rapor.docx', 'size': '1.8 MB'},
                  {'name': 'Proje.zip', 'size': '10.2 MB'},
                  {'name': 'Resimler.rar', 'size': '8.7 MB'},
                ]),
                _buildLinkList([
                  {'title': 'Google', 'url': 'https://google.com'},
                  {'title': 'YouTube', 'url': 'https://youtube.com'},
                  {'title': 'GitHub', 'url': 'https://github.com'},
                  {'title': 'LinkedIn', 'url': 'https://linkedin.com'},
                  {'title': 'Twitter', 'url': 'https://twitter.com'},
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 