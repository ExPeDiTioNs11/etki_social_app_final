import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import 'edit_profile_screen.dart';
import 'privacy_screen.dart';
import 'notifications_screen.dart';
import 'security_screen.dart';
import 'language_screen.dart';
import 'theme_screen.dart';
import 'storage_screen.dart';
import 'help_screen.dart';
import 'about_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayarlar'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        children: [
          // Hesap Ayarları
          _buildSection(
            title: 'Hesap',
            items: [
              _buildSettingItem(
                icon: Icons.person_outline,
                title: 'Profil Düzenle',
                subtitle: 'Profil bilgilerini güncelle',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EditProfileScreen(),
                    ),
                  );
                },
              ),
              _buildSettingItem(
                icon: Icons.lock_outline,
                title: 'Gizlilik',
                subtitle: 'Hesap gizlilik ayarları',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PrivacyScreen(),
                    ),
                  );
                },
              ),
              _buildSettingItem(
                icon: Icons.notifications_outlined,
                title: 'Bildirimler',
                subtitle: 'Bildirim tercihleri',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationsScreen(),
                    ),
                  );
                },
              ),
              _buildSettingItem(
                icon: Icons.security_outlined,
                title: 'Güvenlik',
                subtitle: 'Hesap güvenliği ve şifre',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SecurityScreen(),
                    ),
                  );
                },
              ),
            ],
          ),

          // Uygulama Ayarları
          _buildSection(
            title: 'Uygulama',
            items: [
              _buildSettingItem(
                icon: Icons.language_outlined,
                title: 'Dil',
                subtitle: 'Türkçe',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LanguageScreen(),
                    ),
                  );
                },
              ),
              _buildSettingItem(
                icon: Icons.dark_mode_outlined,
                title: 'Tema',
                subtitle: 'Sistem',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ThemeScreen(),
                    ),
                  );
                },
              ),
              _buildSettingItem(
                icon: Icons.storage_outlined,
                title: 'Depolama',
                subtitle: 'Önbellek ve veri kullanımı',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const StorageScreen(),
                    ),
                  );
                },
              ),
              _buildSettingItem(
                icon: Icons.help_outline,
                title: 'Yardım',
                subtitle: 'Yardım merkezi ve destek',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HelpScreen(),
                    ),
                  );
                },
              ),
            ],
          ),

          // Hakkında
          _buildSection(
            title: 'Hakkında',
            items: [
              _buildSettingItem(
                icon: Icons.info_outline,
                title: 'Hakkında',
                subtitle: 'Uygulama bilgileri',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AboutScreen(),
                    ),
                  );
                },
              ),
            ],
          ),

          // Versiyon
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Text(
                'Versiyon 1.0.0',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            title,
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        ...items,
      ],
    );
  }

  Widget _buildSettingItem({
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
                    const SizedBox(height: 2),
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
              Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }
} 