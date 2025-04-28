import 'package:flutter/material.dart';
import 'package:etki_social_app/services/auth_service.dart';
import 'package:etki_social_app/constants/app_colors.dart';

class CreatePostModal extends StatefulWidget {
  // ... (existing code)
  @override
  _CreatePostModalState createState() => _CreatePostModalState();
}

class _CreatePostModalState extends State<CreatePostModal> {
  final AuthService _authService = AuthService();
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final userData = await _authService.getUserProfile();
      if (mounted && userData != null) {
        setState(() {
          _userData = {
            'username': userData['username'] ?? 'Kullanıcı',
            'profileImage': userData['profileImage'] ?? userData['profileImageUrl'] ?? '',
          };
        });
      }
    } catch (e) {
      print('Error loading user profile: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [
          // ... existing code ...
          // Profil resmi ve kullanıcı adı
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary,
                  backgroundImage: _userData?['profileImage']?.isNotEmpty == true
                      ? NetworkImage(_userData!['profileImage'])
                      : null,
                  child: _userData?['profileImage']?.isEmpty != false
                      ? Text(
                          (_userData?['username'] ?? 'K')[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Text(
                  _userData?['username'] ?? 'Kullanıcı',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // ... existing code ...
        ],
      ),
    );
  }
} 