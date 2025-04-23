import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme/colors.dart';

class FollowersListModal extends StatefulWidget {
  const FollowersListModal({Key? key}) : super(key: key);

  @override
  State<FollowersListModal> createState() => _FollowersListModalState();
}

class _FollowersListModalState extends State<FollowersListModal> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Örnek takipçi verileri
  final List<Map<String, dynamic>> _followers = [
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
      'isFollowing': false,
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
      'isFollowing': false,
    },
    {
      'id': '5',
      'name': 'Can Öztürk',
      'username': '@canozturk',
      'image': 'https://picsum.photos/204',
      'isFollowing': true,
    },
  ];

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
            child: _filteredFollowers.isEmpty
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
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredFollowers.length,
                    itemBuilder: (context, index) {
                      final follower = _filteredFollowers[index];
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
                                    backgroundImage: CachedNetworkImageProvider(follower['image']),
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
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        follower['isFollowing'] = !follower['isFollowing'];
                                      });
                                    },
                                    style: TextButton.styleFrom(
                                      backgroundColor: follower['isFollowing']
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
                                      follower['isFollowing'] ? 'Takip Ediliyor' : 'Takip Et',
                                      style: TextStyle(
                                        color: follower['isFollowing']
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