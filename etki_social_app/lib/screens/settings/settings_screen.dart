import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../services/auth_service.dart';
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
  final bool navigateToProfileEdit;
  const SettingsScreen({this.navigateToProfileEdit = false, super.key});

  // Calculate profile completion percentage
  Future<double> _calculateProfileCompletion(BuildContext context) async {
    final authService = AuthService();
    final userData = await authService.getUserProfile();
    if (userData == null) return 0.0;

    int totalFields = 5; // username, fullName, bio, phoneNumber, city
    int completedFields = 0;

    if (userData['username']?.isNotEmpty ?? false) completedFields++;
    if (userData['fullName']?.isNotEmpty ?? false) completedFields++;
    if (userData['bio']?.isNotEmpty ?? false) completedFields++;
    if (userData['phoneNumber']?.isNotEmpty ?? false) completedFields++;
    if (userData['city']?.isNotEmpty ?? false) completedFields++;

    return (completedFields / totalFields) * 100;
  }

  @override
  Widget build(BuildContext context) {
    if (navigateToProfileEdit) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const EditProfileScreen(),
          ),
        );
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayarlar', style: TextStyle(color: AppColors.textPrimary)),
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<double>(
        future: _calculateProfileCompletion(context),
        builder: (context, snapshot) {
          return Container(
            color: AppColors.primaryBackground,
            child: ListView(
              children: [
                // Profil Tamamlama Butonu - sadece %100 değilse göster
                if (!snapshot.hasData || snapshot.data! < 100)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Material(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const EditProfileScreen(),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.person_add_outlined,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Profilinizi Tamamlayın',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Profilinizi tamamlayarak daha iyi bir deneyim yaşayın',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                color: AppColors.primary,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

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
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
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
              color: AppColors.textSecondary,
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
                  color: AppColors.iconBackground,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
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
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: AppColors.divider,
              ),
            ],
          ),
        ),
      ),
    );
  }
} 