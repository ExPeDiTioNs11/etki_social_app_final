import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key});

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  bool _isPrivateAccount = false;
  bool _showActivityStatus = true;
  bool _showOnlineStatus = true;
  bool _allowMessageRequests = true;
  bool _allowStoryReplies = true;
  bool _allowStorySharing = true;
  bool _allowTagging = true;
  bool _allowComments = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Gizlilik', style: TextStyle(color: AppColors.textPrimary)),
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hesap Gizliliği
            _buildSection(
              title: 'Hesap Gizliliği',
              children: [
                _buildPrivacySwitch(
                  title: 'Gizli Hesap',
                  subtitle: 'Hesabınızı gizli yapın. Sadece onayladığınız kişiler görebilir.',
                  value: _isPrivateAccount,
                  onChanged: (value) {
                    setState(() {
                      _isPrivateAccount = value;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Etkileşim
            _buildSection(
              title: 'Etkileşim',
              children: [
                _buildPrivacySwitch(
                  title: 'Yorumlar',
                  subtitle: 'Gönderilerinize yorum yapılmasına izin verin.',
                  value: _allowComments,
                  onChanged: (value) {
                    setState(() {
                      _allowComments = value;
                    });
                  },
                ),
                _buildPrivacySwitch(
                  title: 'Etiketleme',
                  subtitle: 'Gönderilerde etiketlenmenize izin verin.',
                  value: _allowTagging,
                  onChanged: (value) {
                    setState(() {
                      _allowTagging = value;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Hikayeler
            _buildSection(
              title: 'Hikayeler',
              children: [
                _buildPrivacySwitch(
                  title: 'Hikaye Yanıtları',
                  subtitle: 'Hikayelerinize yanıt verilmesine izin verin.',
                  value: _allowStoryReplies,
                  onChanged: (value) {
                    setState(() {
                      _allowStoryReplies = value;
                    });
                  },
                ),
                _buildPrivacySwitch(
                  title: 'Hikaye Paylaşımı',
                  subtitle: 'Hikayelerinizin paylaşılmasına izin verin.',
                  value: _allowStorySharing,
                  onChanged: (value) {
                    setState(() {
                      _allowStorySharing = value;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Mesajlar
            _buildSection(
              title: 'Mesajlar',
              children: [
                _buildPrivacySwitch(
                  title: 'Mesaj İstekleri',
                  subtitle: 'Takip etmediğiniz kişilerden mesaj isteği alın.',
                  value: _allowMessageRequests,
                  onChanged: (value) {
                    setState(() {
                      _allowMessageRequests = value;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Durum
            _buildSection(
              title: 'Durum',
              children: [
                _buildPrivacySwitch(
                  title: 'Aktif Durum',
                  subtitle: 'Son görülme zamanınızı gösterin.',
                  value: _showActivityStatus,
                  onChanged: (value) {
                    setState(() {
                      _showActivityStatus = value;
                    });
                  },
                ),
                _buildPrivacySwitch(
                  title: 'Çevrimiçi Durumu',
                  subtitle: 'Çevrimiçi olduğunuzu gösterin.',
                  value: _showOnlineStatus,
                  onChanged: (value) {
                    setState(() {
                      _showOnlineStatus = value;
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withOpacity(0.1),
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
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildPrivacySwitch({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Column(
      children: [
        SwitchListTile(
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.primary,
          inactiveTrackColor: AppColors.divider,
        ),
        if (title != 'Çevrimiçi Durumu') // Son item değilse divider ekle
          const Divider(color: AppColors.divider),
      ],
    );
  }
} 