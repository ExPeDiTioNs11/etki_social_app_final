import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

class ActiveSessionsScreen extends StatefulWidget {
  const ActiveSessionsScreen({super.key});

  @override
  State<ActiveSessionsScreen> createState() => _ActiveSessionsScreenState();
}

class _ActiveSessionsScreenState extends State<ActiveSessionsScreen> {
  final _authService = AuthService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _sessions = [];

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    setState(() => _isLoading = true);
    try {
      final user = _authService.currentUser;
      if (user != null) {
        // Firebase Auth'dan oturum bilgilerini al
        final List<Map<String, dynamic>> sessions = [];
        final userMetadata = await FirebaseAuth.instance.currentUser?.getIdTokenResult();
        
        if (userMetadata != null) {
          sessions.add({
            'deviceId': 'current_device',
            'platform': Theme.of(context).platform.toString(),
            'lastSignInTime': user.metadata.lastSignInTime,
            'creationTime': user.metadata.creationTime,
            'isCurrentDevice': true,
          });

          // Diğer cihazlardan giriş yapılan oturumları da ekle
          // Not: Bu bilgiler Firebase Console'dan aktif edilmeli
          final fetchedTokens = await user.getIdTokenResult(true);
          if (fetchedTokens.claims?['sessions'] != null) {
            for (var session in fetchedTokens.claims!['sessions']) {
              sessions.add({
                'deviceId': session['deviceId'],
                'platform': session['platform'],
                'lastSignInTime': DateTime.parse(session['lastSignInTime']),
                'isCurrentDevice': false,
              });
            }
          }
        }

        setState(() {
          _sessions = sessions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Oturum bilgileri alınırken bir hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _terminateSession(Map<String, dynamic> session) async {
    try {
      if (!session['isCurrentDevice']) {
        // Firebase'de oturumu sonlandır
        await _authService.terminateSession(session['deviceId']);
        
        setState(() {
          _sessions.removeWhere((s) => s['deviceId'] == session['deviceId']);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Oturum başarıyla sonlandırıldı'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Mevcut cihaz oturumunu sonlandır
        await _authService.signOut();
        if (mounted) {
          context.go('/login');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Oturum sonlandırılırken bir hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Bilinmiyor';
    // Türkiye saatine çevir (UTC+3)
    final turkeyTime = date.add(const Duration(hours: 3));
    return '${turkeyTime.day}/${turkeyTime.month}/${turkeyTime.year} ${turkeyTime.hour.toString().padLeft(2, '0')}:${turkeyTime.minute.toString().padLeft(2, '0')}';
  }

  String _getPlatformName(String platform) {
    if (platform.contains('android')) {
      return 'Android';
    } else if (platform.contains('ios')) {
      return 'iOS';
    } else if (platform.contains('web')) {
      return 'Web';
    } else {
      return 'Diğer';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Aktif Oturumlar'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadSessions,
              child: _sessions.isEmpty
                  ? Center(
                      child: Text(
                        'Aktif oturum bulunamadı',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _sessions.length,
                      itemBuilder: (context, index) {
                        final session = _sessions[index];
                        final isCurrentDevice = session['isCurrentDevice'] ?? false;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isCurrentDevice
                                    ? AppColors.primary.withOpacity(0.1)
                                    : Colors.grey[100],
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.devices,
                                color: isCurrentDevice
                                    ? AppColors.primary
                                    : Colors.grey[600],
                              ),
                            ),
                            title: Row(
                              children: [
                                Text(
                                  isCurrentDevice ? 'Bu Cihaz' : 'Diğer Cihaz',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (isCurrentDevice) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green[50],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'Aktif',
                                      style: TextStyle(
                                        color: Colors.green[700],
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 8),
                                Text(
                                  'Platform: ${_getPlatformName(session['platform'])}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Son Giriş: ${_formatDate(session['lastSignInTime'])}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.logout),
                              color: Colors.red,
                              onPressed: () => showModalBottomSheet(
                                context: context,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(20),
                                  ),
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
                                      Text(
                                        isCurrentDevice
                                            ? 'Çıkış Yap'
                                            : 'Oturumu Sonlandır',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        isCurrentDevice
                                            ? 'Çıkış yapmak istediğinize emin misiniz?'
                                            : 'Bu cihazdaki oturumu sonlandırmak istediğinize emin misiniz?',
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
                                              onPressed: () => Navigator.pop(context),
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
                                              onPressed: () {
                                                Navigator.pop(context);
                                                _terminateSession(session);
                                              },
                                              style: TextButton.styleFrom(
                                                padding: const EdgeInsets.symmetric(vertical: 12),
                                                backgroundColor: Colors.red,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                              ),
                                              child: Text(
                                                isCurrentDevice
                                                    ? 'Çıkış Yap'
                                                    : 'Sonlandır',
                                                style: const TextStyle(
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
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
} 