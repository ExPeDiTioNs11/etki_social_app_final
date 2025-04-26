import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../services/auth_service.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'change_password_screen.dart';
import 'change_email_screen.dart';
import 'active_sessions_screen.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  bool _saveLoginInfo = false;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _saveLoginInfo = prefs.getBool('saveLoginInfo') ?? false;
    });
  }

  Future<void> _toggleSaveLoginInfo(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('saveLoginInfo', value);
    
    if (!value) {
      // Eğer özellik kapatılırsa, kaydedilmiş giriş bilgilerini sil
      await prefs.remove('savedEmails');
      await prefs.remove('lastUsedEmail');
    }

    setState(() {
      _saveLoginInfo = value;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(value 
            ? 'Giriş bilgileri kaydedilecek' 
            : 'Giriş bilgileri artık kaydedilmeyecek'),
          backgroundColor: value ? Colors.green : Colors.grey,
        ),
      );
    }
  }

  Future<void> _handleLogout() async {
    try {
      await _authService.signOut();
      if (mounted) {
        context.go('/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Çıkış yapılırken bir hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleLogoutAllSessions() async {
    try {
      // Onay modalını göster
      final bool? confirm = await showModalBottomSheet<bool>(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Icon(
                Icons.logout,
                color: Colors.red[400],
                size: 40,
              ),
              const SizedBox(height: 16),
              const Text(
                'Tüm Oturumları Kapat',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tüm cihazlardaki oturumlarınız sonlandırılacak. Devam etmek istiyor musunuz?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                      child: const Text(
                        'İptal',
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Tümünü Kapat',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

      if (confirm == true && mounted) {
        await _authService.signOutAllSessions();
        if (mounted) {
          context.go('/login');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Oturumlar kapatılırken bir hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Güvenlik'),
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
            // Şifre Değiştir
            _buildSection(
              title: 'Hesap Güvenliği',
              children: [
                _buildSecurityButton(
                  icon: Icons.lock_outline,
                  title: 'Şifre Değiştir',
                  subtitle: 'Hesap şifrenizi güncelleyin',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ChangePasswordScreen(),
                      ),
                    );
                  },
                ),
                _buildSecurityButton(
                  icon: Icons.email_outlined,
                  title: 'E-posta Değiştir',
                  subtitle: 'Hesap e-posta adresinizi güncelleyin',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ChangeEmailScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Giriş Güvenliği
            _buildSection(
              title: 'Giriş Güvenliği',
              children: [
                _buildSecuritySwitch(
                  title: 'Giriş Bilgilerini Kaydet',
                  subtitle: 'Cihazınızda giriş bilgilerinizi saklayın',
                  value: _saveLoginInfo,
                  onChanged: _toggleSaveLoginInfo,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Oturum Yönetimi
            _buildSection(
              title: 'Oturum Yönetimi',
              children: [
                _buildSecurityButton(
                  icon: Icons.devices_outlined,
                  title: 'Aktif Oturumlar',
                  subtitle: 'Açık olan tüm oturumları görüntüleyin',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ActiveSessionsScreen(),
                      ),
                    );
                  },
                ),
                _buildSecurityButton(
                  icon: Icons.logout_outlined,
                  title: 'Tüm Oturumları Kapat',
                  subtitle: 'Tüm cihazlardaki oturumları sonlandırın',
                  onTap: _handleLogoutAllSessions,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Hesap İşlemleri
            _buildSection(
              title: 'Hesap İşlemleri',
              children: [
                _buildSecurityButton(
                  icon: Icons.delete_outline,
                  title: 'Hesabı Devre Dışı Bırak',
                  subtitle: 'Hesabınızı geçici olarak devre dışı bırakın',
                  onTap: () {
                    // TODO: Implement account deactivation
                  },
                ),
                _buildSecurityButton(
                  icon: Icons.delete_forever_outlined,
                  title: 'Hesabı Sil',
                  subtitle: 'Hesabınızı kalıcı olarak silin',
                  onTap: () {
                    // TODO: Implement account deletion
                  },
                ),
                _buildSecurityButton(
                  icon: Icons.logout_rounded,
                  title: 'Çıkış Yap',
                  subtitle: 'Hesabınızdan güvenli çıkış yapın',
                  onTap: _handleLogout,
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

  Widget _buildSecurityButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
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

  Widget _buildSecuritySwitch({
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