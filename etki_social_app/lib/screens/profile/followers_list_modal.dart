import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme/colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:etki_social_app/services/auth_service.dart';

class FollowersListModal extends StatefulWidget {
  final String? userId;
  const FollowersListModal({Key? key, this.userId}) : super(key: key);

  @override
  State<FollowersListModal> createState() => _FollowersListModalState();
}

class _FollowersListModalState extends State<FollowersListModal> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<Map<String, dynamic>> _followers = [];
  bool _isLoading = true;
  final AuthService _authService = AuthService();
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = _authService.currentUser?.uid;
    _fetchFollowers();
  }

  Future<void> _fetchFollowers() async {
    setState(() => _isLoading = true);
    try {
      final userId = widget.userId;
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      final followerIds = List<String>.from(userDoc.data()?['followers'] ?? []);
      List<Map<String, dynamic>> followers = [];
      for (final id in followerIds) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(id).get();
        if (doc.exists) {
          final data = doc.data()!;
          followers.add({
            'id': id,
            'name': data['username'] ?? '',
            'username': '@${data['username'] ?? ''}',
            'image': data['profileImage'] ?? data['profileImageUrl'] ?? '',
            'isFollowing': (data['followers'] as List?)?.contains(userId) ?? false,
            'completedMissionsCount': data['completedMissionsCount'] ?? 0,
          });
        }
      }
      setState(() {
        _followers = followers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _unfollow(String targetUserId) async {
    if (_currentUserId == null) return;
    try {
      // Kendi following listesinden çıkar
      await FirebaseFirestore.instance.collection('users').doc(_currentUserId).update({
        'following': FieldValue.arrayRemove([targetUserId])
      });
      // Karşı tarafın followers listesinden çıkar
      await FirebaseFirestore.instance.collection('users').doc(targetUserId).update({
        'followers': FieldValue.arrayRemove([_currentUserId])
      });
      setState(() {
        _followers = _followers.map((f) {
          if (f['id'] == targetUserId) {
            return {...f, 'isFollowing': false};
          }
          return f;
        }).toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Takipten çıkarılırken hata: $e'), backgroundColor: Colors.red),
      );
    }
  }

  List<Map<String, dynamic>> get _filteredFollowers {
    if (_searchQuery.isEmpty) {
      return _followers;
    }
    final query = _searchQuery.toLowerCase();
    return _followers.where((follower) {
      final name = follower['name'].toString().toLowerCase();
      final username = follower['username'].toString().toLowerCase();
      return name.contains(query) || username.contains(query);
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        children: [
          // Modal başlık ve kapatma butonu
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
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
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Center(
                        child: Text(
                          'Takipçiler',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ],
            ),
          ),
          // Arama çubuğu
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: Colors.grey[200]!,
                width: 1,
              ),
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Takipçilerde ara...',
                hintStyle: TextStyle(color: Colors.grey[500]),
                prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: Colors.grey[500]),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          // Takipçi listesi
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredFollowers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.search_off,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Takipçi bulunamadı',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Farklı bir arama terimi deneyin',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredFollowers.length,
                        itemBuilder: (context, index) {
                          final follower = _filteredFollowers[index];
                          return InkWell(
                            onTap: () {
                              // TODO: Profil sayfasına yönlendir
                            },
                            borderRadius: BorderRadius.circular(15),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 28,
                                    backgroundImage: follower['image'].isNotEmpty
                                        ? CachedNetworkImageProvider(follower['image'])
                                        : null,
                                    child: follower['image'].isEmpty
                                        ? const Icon(Icons.person, size: 28, color: Colors.grey)
                                        : null,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          follower['name'],
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          follower['username'],
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (follower['isFollowing'] == true)
                                    TextButton(
                                      onPressed: () => _unfollow(follower['id']),
                                      style: TextButton.styleFrom(
                                        backgroundColor: Colors.red[50],
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                      ),
                                      child: const Text(
                                        'Takipten Çıkar',
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
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
} 