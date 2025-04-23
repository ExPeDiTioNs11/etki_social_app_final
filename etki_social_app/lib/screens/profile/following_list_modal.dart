import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme/colors.dart';

class FollowingListModal extends StatefulWidget {
  const FollowingListModal({Key? key}) : super(key: key);

  @override
  State<FollowingListModal> createState() => _FollowingListModalState();
}

class _FollowingListModalState extends State<FollowingListModal> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Örnek takip edilen kullanıcı verileri
  final List<Map<String, dynamic>> _following = [
    {
      'id': '1',
      'name': 'Ahmet Yılmaz',
      'username': '@ahmetyilmaz',
      'image': 'https://picsum.photos/200',
      'isFollowing': true,
    },
    {
      'id': '2',
      'name': 'Ayşe Demir',
      'username': '@aysedemir',
      'image': 'https://picsum.photos/201',
      'isFollowing': true,
    },
    {
      'id': '3',
      'name': 'Mehmet Kaya',
      'username': '@mehmetkaya',
      'image': 'https://picsum.photos/202',
      'isFollowing': true,
    },
    {
      'id': '4',
      'name': 'Zeynep Şahin',
      'username': '@zeynepsahin',
      'image': 'https://picsum.photos/203',
      'isFollowing': true,
    },
    {
      'id': '5',
      'name': 'Can Öztürk',
      'username': '@canozturk',
      'image': 'https://picsum.photos/204',
      'isFollowing': true,
    },
  ];

  List<Map<String, dynamic>> get _filteredFollowing {
    if (_searchQuery.isEmpty) {
      return _following;
    }
    
    final query = _searchQuery.toLowerCase();
    return _following.where((user) {
      final name = user['name'].toString().toLowerCase();
      final username = user['username'].toString().toLowerCase();
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
                          'Takip Edilenler',
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
                hintText: 'Takip edilenlerde ara...',
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
          // Takip edilenler listesi
          Expanded(
            child: _filteredFollowing.isEmpty
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
                          'Kullanıcı bulunamadı',
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
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredFollowing.length,
                    itemBuilder: (context, index) {
                      final user = _filteredFollowing[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: Colors.grey[200]!,
                            width: 1,
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
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
                                    backgroundImage: CachedNetworkImageProvider(user['image']),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          user['name'],
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          user['username'],
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        user['isFollowing'] = !user['isFollowing'];
                                      });
                                    },
                                    style: TextButton.styleFrom(
                                      backgroundColor: user['isFollowing']
                                          ? Colors.grey[200]
                                          : AppColors.primary,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                    child: Text(
                                      user['isFollowing'] ? 'Takip Ediliyor' : 'Takip Et',
                                      style: TextStyle(
                                        color: user['isFollowing']
                                            ? Colors.black87
                                            : Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
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