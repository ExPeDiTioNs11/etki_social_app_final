import 'package:flutter/material.dart';
import '../../theme/colors.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  // Genel Bildirimler
  bool _pushNotifications = true;
  bool _emailNotifications = false;
  bool _smsNotifications = false;

  // Etkileşim Bildirimleri
  bool _likeNotifications = true;
  bool _commentNotifications = true;
  bool _mentionNotifications = true;
  bool _followNotifications = true;
  bool _tagNotifications = true;

  // Hikaye Bildirimleri
  bool _storyReactionNotifications = true;
  bool _storyMentionNotifications = true;
  bool _storyReplyNotifications = true;

  // Mesaj Bildirimleri
  bool _messageNotifications = true;
  bool _messageRequestNotifications = true;
  bool _groupMessageNotifications = true;

  // Görev Bildirimleri
  bool _missionNotifications = true;
  bool _missionReminderNotifications = true;
  bool _missionRewardNotifications = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Bildirimler'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Genel Bildirimler
            _buildSection(
              title: 'Genel Bildirimler',
              children: [
                _buildNotificationSwitch(
                  title: 'Push Bildirimleri',
                  subtitle: 'Uygulama içi bildirimler',
                  value: _pushNotifications,
                  onChanged: (value) {
                    setState(() {
                      _pushNotifications = value;
                    });
                  },
                ),
                _buildNotificationSwitch(
                  title: 'E-posta Bildirimleri',
                  subtitle: 'E-posta ile bildirimler',
                  value: _emailNotifications,
                  onChanged: (value) {
                    setState(() {
                      _emailNotifications = value;
                    });
                  },
                ),
                _buildNotificationSwitch(
                  title: 'SMS Bildirimleri',
                  subtitle: 'SMS ile bildirimler',
                  value: _smsNotifications,
                  onChanged: (value) {
                    setState(() {
                      _smsNotifications = value;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Etkileşim Bildirimleri
            _buildSection(
              title: 'Etkileşim Bildirimleri',
              children: [
                _buildNotificationSwitch(
                  title: 'Beğeni Bildirimleri',
                  subtitle: 'Gönderilerinize gelen beğeniler',
                  value: _likeNotifications,
                  onChanged: (value) {
                    setState(() {
                      _likeNotifications = value;
                    });
                  },
                ),
                _buildNotificationSwitch(
                  title: 'Yorum Bildirimleri',
                  subtitle: 'Gönderilerinize gelen yorumlar',
                  value: _commentNotifications,
                  onChanged: (value) {
                    setState(() {
                      _commentNotifications = value;
                    });
                  },
                ),
                _buildNotificationSwitch(
                  title: 'Etiket Bildirimleri',
                  subtitle: 'Gönderilerde etiketlenmeler',
                  value: _tagNotifications,
                  onChanged: (value) {
                    setState(() {
                      _tagNotifications = value;
                    });
                  },
                ),
                _buildNotificationSwitch(
                  title: 'Bahsetme Bildirimleri',
                  subtitle: 'Gönderilerde bahsedilmeler',
                  value: _mentionNotifications,
                  onChanged: (value) {
                    setState(() {
                      _mentionNotifications = value;
                    });
                  },
                ),
                _buildNotificationSwitch(
                  title: 'Takip Bildirimleri',
                  subtitle: 'Yeni takipçiler',
                  value: _followNotifications,
                  onChanged: (value) {
                    setState(() {
                      _followNotifications = value;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Hikaye Bildirimleri
            _buildSection(
              title: 'Hikaye Bildirimleri',
              children: [
                _buildNotificationSwitch(
                  title: 'Hikaye Tepki Bildirimleri',
                  subtitle: 'Hikayelerinize gelen tepkiler',
                  value: _storyReactionNotifications,
                  onChanged: (value) {
                    setState(() {
                      _storyReactionNotifications = value;
                    });
                  },
                ),
                _buildNotificationSwitch(
                  title: 'Hikaye Bahsetme Bildirimleri',
                  subtitle: 'Hikayelerde bahsedilmeler',
                  value: _storyMentionNotifications,
                  onChanged: (value) {
                    setState(() {
                      _storyMentionNotifications = value;
                    });
                  },
                ),
                _buildNotificationSwitch(
                  title: 'Hikaye Yanıt Bildirimleri',
                  subtitle: 'Hikayelerinize gelen yanıtlar',
                  value: _storyReplyNotifications,
                  onChanged: (value) {
                    setState(() {
                      _storyReplyNotifications = value;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Mesaj Bildirimleri
            _buildSection(
              title: 'Mesaj Bildirimleri',
              children: [
                _buildNotificationSwitch(
                  title: 'Mesaj Bildirimleri',
                  subtitle: 'Yeni mesajlar',
                  value: _messageNotifications,
                  onChanged: (value) {
                    setState(() {
                      _messageNotifications = value;
                    });
                  },
                ),
                _buildNotificationSwitch(
                  title: 'Mesaj İstek Bildirimleri',
                  subtitle: 'Yeni mesaj istekleri',
                  value: _messageRequestNotifications,
                  onChanged: (value) {
                    setState(() {
                      _messageRequestNotifications = value;
                    });
                  },
                ),
                _buildNotificationSwitch(
                  title: 'Grup Mesaj Bildirimleri',
                  subtitle: 'Grup mesajları',
                  value: _groupMessageNotifications,
                  onChanged: (value) {
                    setState(() {
                      _groupMessageNotifications = value;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Görev Bildirimleri
            _buildSection(
              title: 'Görev Bildirimleri',
              children: [
                _buildNotificationSwitch(
                  title: 'Görev Bildirimleri',
                  subtitle: 'Yeni görevler ve güncellemeler',
                  value: _missionNotifications,
                  onChanged: (value) {
                    setState(() {
                      _missionNotifications = value;
                    });
                  },
                ),
                _buildNotificationSwitch(
                  title: 'Görev Hatırlatmaları',
                  subtitle: 'Görev son tarihi hatırlatmaları',
                  value: _missionReminderNotifications,
                  onChanged: (value) {
                    setState(() {
                      _missionReminderNotifications = value;
                    });
                  },
                ),
                _buildNotificationSwitch(
                  title: 'Ödül Bildirimleri',
                  subtitle: 'Görev ödülleri ve kazanımlar',
                  value: _missionRewardNotifications,
                  onChanged: (value) {
                    setState(() {
                      _missionRewardNotifications = value;
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildNotificationSwitch({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
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
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
            activeTrackColor: AppColors.primary.withOpacity(0.3),
          ),
        ],
      ),
    );
  }
} 