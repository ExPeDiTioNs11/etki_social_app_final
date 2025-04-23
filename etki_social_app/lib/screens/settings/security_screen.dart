import 'package:flutter/material.dart';
import '../../theme/colors.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  bool _twoFactorAuth = false;
  bool _loginAlerts = true;
  bool _saveLoginInfo = true;
  bool _rememberDevices = true;

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
                    // TODO: Implement password change
                  },
                ),
                _buildSecurityButton(
                  icon: Icons.email_outlined,
                  title: 'E-posta Değiştir',
                  subtitle: 'Hesap e-posta adresinizi güncelleyin',
                  onTap: () {
                    // TODO: Implement email change
                  },
                ),
                _buildSecurityButton(
                  icon: Icons.phone_outlined,
                  title: 'Telefon Numarası',
                  subtitle: 'Hesap telefon numaranızı güncelleyin',
                  onTap: () {
                    // TODO: Implement phone number change
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // İki Faktörlü Doğrulama
            _buildSection(
              title: 'İki Faktörlü Doğrulama',
              children: [
                _buildSecuritySwitch(
                  title: 'İki Faktörlü Doğrulama',
                  subtitle: 'Hesabınızı daha güvenli hale getirin',
                  value: _twoFactorAuth,
                  onChanged: (value) {
                    setState(() {
                      _twoFactorAuth = value;
                    });
                  },
                ),
                if (_twoFactorAuth) ...[
                  const SizedBox(height: 16),
                  _buildSecurityButton(
                    icon: Icons.qr_code_scanner,
                    title: 'QR Kod ile Kur',
                    subtitle: 'Google Authenticator ile kurulum yapın',
                    onTap: () {
                      // TODO: Implement QR code setup
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildSecurityButton(
                    icon: Icons.sms_outlined,
                    title: 'SMS ile Kur',
                    subtitle: 'Telefon numaranız ile kurulum yapın',
                    onTap: () {
                      // TODO: Implement SMS setup
                    },
                  ),
                ],
              ],
            ),
            const SizedBox(height: 24),

            // Giriş Güvenliği
            _buildSection(
              title: 'Giriş Güvenliği',
              children: [
                _buildSecuritySwitch(
                  title: 'Giriş Uyarıları',
                  subtitle: 'Yeni girişler hakkında bildirim alın',
                  value: _loginAlerts,
                  onChanged: (value) {
                    setState(() {
                      _loginAlerts = value;
                    });
                  },
                ),
                _buildSecuritySwitch(
                  title: 'Giriş Bilgilerini Kaydet',
                  subtitle: 'Cihazınızda giriş bilgilerinizi saklayın',
                  value: _saveLoginInfo,
                  onChanged: (value) {
                    setState(() {
                      _saveLoginInfo = value;
                    });
                  },
                ),
                _buildSecuritySwitch(
                  title: 'Cihazları Hatırla',
                  subtitle: 'Güvendiğiniz cihazları kaydedin',
                  value: _rememberDevices,
                  onChanged: (value) {
                    setState(() {
                      _rememberDevices = value;
                    });
                  },
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
                    // TODO: Implement active sessions view
                  },
                ),
                _buildSecurityButton(
                  icon: Icons.logout_outlined,
                  title: 'Tüm Oturumları Kapat',
                  subtitle: 'Tüm cihazlardaki oturumları sonlandırın',
                  onTap: () {
                    // TODO: Implement logout all sessions
                  },
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
                  onTap: () {
                    // TODO: Implement logout
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