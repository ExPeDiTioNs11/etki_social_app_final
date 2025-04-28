import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:etki_social_app/constants/app_colors.dart';
import 'package:etki_social_app/models/post_model.dart';
import 'package:etki_social_app/widgets/post_card.dart';
import '../settings/settings_screen.dart';
import 'followers_list_modal.dart';
import 'following_list_modal.dart';
import 'package:etki_social_app/services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _starController;
  final List<double> _randomOffsets = List.generate(8, (index) => Random().nextDouble() * pi);
  String? _selectedPackage;
  final AuthService _authService = AuthService();
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  File? _bannerImage;
  final ImagePicker _picker = ImagePicker();
  bool _isBannerUploading = false;
  bool _isProfileImageUploading = false;
  File? _profileImage;
  List<Post> _userPosts = [];
  List<Post> _userMissions = [];
  int _followersCount = 0;
  int _followingCount = 0;

  // Yenileme animasyonu için controller
  final _refreshController = GlobalKey<RefreshIndicatorState>();
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _starController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    _loadUserData();
    _loadUserPosts();
    _loadInitialMissions();
    _loadFollowCounts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _starController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final userData = await _authService.getUserProfile();
      print('User Data: $userData');
      if (mounted && userData != null) {
        setState(() {
          _userData = {
            'username': userData['username'] ?? 'Kullanıcı',
            'profileImage': userData['profileImage'] ?? userData['profileImageUrl'],
            'bannerImage': userData['bannerImage'] ?? userData['bannerImageUrl'],
            'bio': userData['bio'] ?? '',
            'fullName': userData['fullName'] ?? '',
            'createdAt': userData['createdAt'],
          };
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profil bilgileri yüklenirken bir hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadUserPosts() async {
    try {
      final user = _authService.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kullanıcı girişi yapılmamış'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() => _isLoading = true);
      
      final snapshot = await FirebaseFirestore.instance
          .collection('posts')
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .get();

      setState(() {
        _userPosts = snapshot.docs.map((doc) {
          final data = doc.data();
          
          // Gönderi tipini belirleme
          PostType postType;
          if (data['imageUrls'] != null && (data['imageUrls'] as List).isNotEmpty) {
            postType = PostType.image;
          } else if (data['missionTitle'] != null) {
            postType = PostType.mission;
          } else {
            postType = PostType.text;
          }
          
          return Post(
            id: doc.id,
            userId: data['userId'],
            content: data['content'] ?? '',
            type: postType,
            imageUrls: List<String>.from(data['imageUrls'] ?? []),
            createdAt: (data['createdAt'] as Timestamp).toDate(),
            likes: List<String>.from(data['likes'] ?? []),
            comments: List<Comment>.from((data['comments'] ?? []).map((c) => Comment.fromMap(c))),
          );
        }).toList();
        _isLoading = false;
      });

      if (snapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Henüz gönderi paylaşılmamış'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gönderiler yüklenirken bir hata oluştu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Görevleri yükleme fonksiyonu
  Future<List<Post>> _loadUserMissions() async {
    try {
      final user = _authService.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kullanıcı girişi yapılmamış'),
            backgroundColor: Colors.red,
          ),
        );
        return [];
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('tasks')
          .where('creatorId', isEqualTo: user.uid)
          .get();

      final missions = snapshot.docs.map((doc) {
        final data = doc.data();
        return Post(
          id: doc.id,
          userId: data['creatorId'],
          content: data['description'] ?? '',
          type: PostType.mission,
          missionTitle: data['title'],
          missionDescription: data['description'],
          missionReward: data['coinAmount'],
          missionDeadline: data['deadline'] != null ? (data['deadline'] as Timestamp).toDate() : null,
          missionParticipants: List<MissionParticipant>.from((data['participants'] ?? []).map((p) => MissionParticipant.fromMap(p))),
          maxParticipants: data['participantCount'],
          createdAt: (data['createdAt'] as Timestamp).toDate(),
          likes: List<String>.from(data['likes'] ?? []),
          comments: List<Comment>.from((data['comments'] ?? []).map((c) => Comment.fromMap(c))),
        );
      }).toList();

      // Bellek üzerinde sıralama yap
      missions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return missions;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Görevler yüklenirken bir hata oluştu: $e'),
          backgroundColor: Colors.red,
        ),
      );
      return [];
    }
  }

  // İlk yüklemede görevleri yükle
  Future<void> _loadInitialMissions() async {
    final missions = await _loadUserMissions();
    if (mounted) {
      setState(() {
        _userMissions = missions;
      });
    }
  }

  Future<void> _loadFollowCounts() async {
    try {
      final currentUserId = _authService.currentUser?.uid;
      if (currentUserId == null) return;

      // Kullanıcı dokümanını al
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        setState(() {
          _followersCount = (data['followers'] as List<dynamic>?)?.length ?? 0;
          _followingCount = (data['following'] as List<dynamic>?)?.length ?? 0;
        });
      }
    } catch (e) {
      print('Error loading follow counts: $e');
    }
  }

  Future<void> _pickBannerImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _bannerImage = File(pickedFile.path);
        });
        await _updateBannerImage();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Resim seçilirken bir hata oluştu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateBannerImage() async {
    if (_bannerImage == null) return;

    setState(() => _isBannerUploading = true);

    try {
      final user = _authService.currentUser;
      if (user == null) {
        throw Exception('Kullanıcı girişi yapılmamış');
      }

      final fileName = '${user.uid}_banner_${DateTime.now().millisecondsSinceEpoch}${path.extension(_bannerImage!.path)}';
      
      final ref = FirebaseStorage.instance
          .ref()
          .child('banner_images')
          .child(fileName);

      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'uploadedBy': user.uid,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      final uploadTask = ref.putFile(_bannerImage!, metadata);
      
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
        print('Banner upload progress: $progress%');
      });
      
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      await _authService.updateUserProfile(
        bannerImageUrl: downloadUrl,
      );

      if (mounted) {
        setState(() {
          _userData?['bannerImage'] = downloadUrl;
          _isBannerUploading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Banner resmi başarıyla güncellendi'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isBannerUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Banner resmi güncellenirken bir hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickProfileImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _profileImage = File(pickedFile.path);
        });
        await _updateProfileImage();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Resim seçilirken bir hata oluştu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateProfileImage() async {
    if (_profileImage == null) return;

    setState(() => _isProfileImageUploading = true);

    try {
      final user = _authService.currentUser;
      if (user == null) {
        throw Exception('Kullanıcı girişi yapılmamış');
      }

      final fileName = '${user.uid}_profile_${DateTime.now().millisecondsSinceEpoch}${path.extension(_profileImage!.path)}';
      
      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child(fileName);

      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'uploadedBy': user.uid,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      final uploadTask = ref.putFile(_profileImage!, metadata);
      
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
        print('Profile image upload progress: $progress%');
      });
      
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      await _authService.updateUserProfile(
        profileImageUrl: downloadUrl,
      );

      if (mounted) {
        setState(() {
          _userData?['profileImage'] = downloadUrl;
          _isProfileImageUploading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil resmi başarıyla güncellendi'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProfileImageUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profil resmi güncellenirken bir hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Yenileme fonksiyonu
  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;

    setState(() => _isRefreshing = true);

    try {
      // Paralel olarak verileri yenile
      await Future.wait([
        _loadUserData(),
        _loadUserPosts(),
      ]);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil güncellendi'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Güncelleme sırasında bir hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  Future<void> _handleLike(Post post) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) return;

      // Gönderi tipine göre doğru koleksiyonu seç
      final collection = post.type == PostType.mission ? 'tasks' : 'posts';
      final postRef = FirebaseFirestore.instance.collection(collection).doc(post.id);
      
      // Önce Firestore'dan güncel beğeni listesini al
      final docSnapshot = await postRef.get();
      if (!docSnapshot.exists) return;
      
      final currentLikes = List<String>.from(docSnapshot.data()?['likes'] ?? []);
      final isLiked = currentLikes.contains(currentUser.uid);
      
      // Firestore'u güncelle
      await postRef.update({
        'likes': isLiked
            ? FieldValue.arrayRemove([currentUser.uid])
            : FieldValue.arrayUnion([currentUser.uid]),
      });

      // UI'ı güncelle
      setState(() {
        if (post.type == PostType.mission) {
          // Görevler listesinde güncelle
          final missionIndex = _userMissions.indexWhere((p) => p.id == post.id);
          if (missionIndex != -1) {
            if (isLiked) {
              _userMissions[missionIndex].likes.remove(currentUser.uid);
            } else {
              _userMissions[missionIndex].likes.add(currentUser.uid);
            }
          }

          // Gönderiler listesindeki görevleri de güncelle
          final postIndex = _userPosts.indexWhere((p) => p.id == post.id);
          if (postIndex != -1) {
            if (isLiked) {
              _userPosts[postIndex].likes.remove(currentUser.uid);
            } else {
              _userPosts[postIndex].likes.add(currentUser.uid);
            }
          }
        } else {
          final index = _userPosts.indexWhere((p) => p.id == post.id);
          if (index != -1) {
            if (isLiked) {
              _userPosts[index].likes.remove(currentUser.uid);
            } else {
              _userPosts[index].likes.add(currentUser.uid);
            }
          }
        }
      });
    } catch (e) {
      print('Beğeni işlemi sırasında hata: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Beğeni işlemi sırasında bir hata oluştu'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            )
          : RefreshIndicator(
              onRefresh: _handleRefresh,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
            SliverAppBar(
              expandedHeight: 200,
              floating: false,
              pinned: true,
                    backgroundColor: Colors.white,
                    elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  children: [
                          // Banner Image
                          GestureDetector(
                            onTap: _isBannerUploading ? null : _pickBannerImage,
                            child: Container(
                      height: 150,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.8),
                                image: _userData?['bannerImage'] != null
                                    ? DecorationImage(
                                        image: NetworkImage(_userData!['bannerImage']),
                          fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: _isBannerUploading
                                  ? const Center(
                                      child: CircularProgressIndicator(
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : _userData?['bannerImage'] == null
                                      ? Center(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.add_photo_alternate,
                                                color: Colors.white.withOpacity(0.7),
                                                size: 40,
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                'Banner resmi eklemek için tıklayın',
                                                style: TextStyle(
                                                  color: Colors.white.withOpacity(0.7),
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      : null,
                      ),
                    ),
                    // Profil fotoğrafı
                    Positioned(
                      left: 16,
                      top: 100,
                            child: GestureDetector(
                              onTap: _isProfileImageUploading ? null : _pickProfileImage,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                        ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    CircleAvatar(
                          radius: 40,
                          backgroundColor: AppColors.primary,
                                      backgroundImage: _userData?['profileImage'] != null
                                          ? NetworkImage(_userData!['profileImage']) as ImageProvider
                                          : null,
                                      child: _userData?['profileImage'] == null
                                          ? Text(
                                              (_userData?['username'] ?? 'K')[0].toUpperCase(),
                                              style: const TextStyle(
                              fontSize: 32,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                                            )
                                          : null,
                                    ),
                                    if (_isProfileImageUploading)
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.5),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: CircularProgressIndicator(
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        ),
                                      ),
                                    if (!_isProfileImageUploading)
                                      Positioned(
                                        right: 0,
                                        bottom: 0,
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.white,
                                              width: 2,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.camera_alt,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
                    child: Container(
                      color: Colors.white,
                      child: Column(
                        children: [
                          Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                                    Text(
                                      _userData?['username'] ?? 'Kullanıcı',
                                      style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                                    Row(
                            children: [
                                        IconButton(
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => const SettingsScreen(),
                                              ),
                                            );
                                          },
                                          icon: Icon(
                                            Icons.settings_outlined,
                                  color: AppColors.primary,
                                            size: 20,
                                ),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                              ),
                            ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                                  '@${_userData?['username'] ?? 'Kullanıcı'}',
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Bio veya fullName boş ise profilini tamamla butonu göster
                    (_userData?['bio']?.toString().trim().isEmpty ?? true) && (_userData?['fullName']?.toString().trim().isEmpty ?? true)
                        ? InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SettingsScreen(),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.primary.withOpacity(0.3),
                                  width: 1,
                                ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.edit_outlined,
                                color: AppColors.primary,
                                    size: 18,
                              ),
                                  const SizedBox(width: 8),
                              Text(
                                    'Profilini Tamamla 🎯',
                                style: TextStyle(
                                  color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                          )
                        : Text(
                            _userData?['bio'] ?? 'Profil açıklaması burada yer alacak. Kullanıcı hakkında kısa bir bilgi.',
                      style: TextStyle(
                              color: Colors.grey[800],
                              fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                                      _userData?['createdAt'] != null
                                          ? '${_formatDate(_userData!['createdAt'])} tarihinden beri üye'
                                          : 'Ocak 2024\'ten beri üye',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                                // Profile Stats
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Followers
                        InkWell(
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => const FollowersListModal(),
                            );
                          },
                          child: Row(
                            children: [
                              Text(
                                _followersCount.toString(),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Takipçi',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),
                        // Following
                        InkWell(
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => const FollowingListModal(),
                            );
                          },
                          child: Row(
                            children: [
                              Text(
                                _followingCount.toString(),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Takip',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),
                        // Shared Missions
                        Row(
                          children: [
                            Text(
                              _userMissions.length.toString(),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.assignment_outlined,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                          ],
                        ),
                        const SizedBox(width: 24),
                        // Completed Missions
                        Row(
                          children: [
                            Text(
                              '12',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.check_circle_outline,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildCoinBalance(),
                              ],
                            ),
                          ),
                  ],
                ),
              ),
            ),
            SliverPersistentHeader(
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: AppColors.primary,
                  tabs: const [
                    Tab(text: 'Gönderiler'),
                    Tab(text: 'Görevler'),
                    Tab(text: 'Medya'),
                    Tab(text: 'Beğeniler'),
                  ],
                ),
              ),
              pinned: true,
            ),
                  SliverFillRemaining(
                    child: TabBarView(
          controller: _tabController,
                      physics: const NeverScrollableScrollPhysics(),
          children: [
                        // Gönderiler Tab
                        _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : _userPosts.where((post) => post.type != PostType.mission).isEmpty
                                ? ListView(
                                    physics: const AlwaysScrollableScrollPhysics(),
                                    children: const [
                                      Center(
                                        child: Padding(
                                          padding: EdgeInsets.only(top: 100),
                                          child: Text(
                                            'Henüz gönderi paylaşılmamış',
                                            style: TextStyle(
                                              color: Colors.grey,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : ListView.builder(
                                    padding: const EdgeInsets.all(16),
                                    physics: const AlwaysScrollableScrollPhysics(),
                                    itemCount: _userPosts.where((post) => post.type != PostType.mission).length,
                                    itemBuilder: (context, index) {
                                      final nonMissionPosts = _userPosts.where((post) => post.type != PostType.mission).toList();
                                      final post = nonMissionPosts[index];
                                      return PostCard(
                                        post: post,
                                        onLike: () => _handleLike(post),
                                        onComment: () {
                                          // TODO: Implement comment functionality
                                        },
                                        onShare: () {
                                          // TODO: Implement share functionality
                                        },
                                      );
                                    },
                                  ),
                        // Görevler Tab
                        _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : _buildMissionsTab(),
                        // Medya Tab
            _buildMediaList(),
                        // Beğeniler Tab
                        ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
            _buildLikesList(),
                          ],
                        ),
                      ],
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildMissionsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_userMissions.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          Center(
            child: Padding(
              padding: EdgeInsets.only(top: 100),
              child: Text(
                'Henüz görev paylaşılmamış',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _userMissions.length,
      itemBuilder: (context, index) {
        final post = _userMissions[index];
        return PostCard(
          post: post,
          onLike: () => _handleLike(post),
          onComment: () {
            // TODO: Implement comment functionality
          },
          onShare: () {
            // TODO: Implement share functionality
          },
        );
      },
    );
  }

  Widget _buildMediaList() {
    // Tüm gönderilerden resim içerenleri filtrele ve resim URL'lerini topla
    List<String> allImages = [];
    for (var post in _userPosts) {
      if (post.imageUrls != null && post.imageUrls!.isNotEmpty) {
        allImages.addAll(post.imageUrls!);
      }
    }

    if (allImages.isEmpty) {
      return const Center(
        child: Text(
          'Henüz medya paylaşılmamış',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 16,
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: allImages.length,
      itemBuilder: (context, index) {
        // Son 6 resim için gölgelendirme oranını hesapla
        final isRecentImage = index >= allImages.length - 6;
        final shadowOpacity = isRecentImage 
          ? ((index - (allImages.length - 6)) / 6) * 0.3 
          : 0.0;

        return GestureDetector(
          onTap: () {
            // Resme tıklandığında tam ekran görüntüleme
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Scaffold(
                  backgroundColor: Colors.black,
                  body: SafeArea(
                    child: Stack(
                      children: [
                        // Resim
                        Center(
                          child: InteractiveViewer(
                            minScale: 0.5,
                            maxScale: 4,
                            child: CachedNetworkImage(
                              imageUrl: allImages[index],
                              fit: BoxFit.contain,
                              placeholder: (context, url) => const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                              ),
                              errorWidget: (context, url, error) => const Icon(
                                Icons.error,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        // Kapat butonu
                        Positioned(
                          top: 16,
                          right: 16,
                          child: IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 30,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
          child: Hero(
            tag: 'media_$index',
            child: Container(
          decoration: BoxDecoration(
                color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1 + shadowOpacity),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: allImages[index],
              fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[300],
                        child: const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[300],
                        child: const Icon(
                          Icons.error_outline,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  // Son resimlere doğru gradient efekti
                  if (isRecentImage)
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            AppColors.primary.withOpacity(shadowOpacity),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLikesList() {
    return ListView.builder(
      itemCount: 4,
      itemBuilder: (context, index) {
        return PostCard(
          post: Post(
            id: 'like_$index',
            userId: 'other_user_$index',
            content: 'Beğenilen gönderi $index',
            type: PostType.text,
            createdAt: DateTime.now().subtract(Duration(days: index)),
          ),
          onLike: () {},
          onComment: () {},
          onShare: () {},
        );
      },
    );
  }

  Widget _buildCoinBalance() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary.withOpacity(0.9),
              AppColors.primary.withOpacity(0.7),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row
                  Row(
                    children: [
                      // Coin Icon with Stars
                      SizedBox(
                        width: 40,
                        height: 40,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Rotating stars
                            AnimatedBuilder(
                              animation: _starController,
                              builder: (context, child) {
                                return Stack(
                                  alignment: Alignment.center,
                                  children: List.generate(8, (index) {
                                    final baseAngle = (index / 8) * 2 * pi;
                                    final randomOffset = _randomOffsets[index];
                                    final oscillation = sin(_starController.value * 2 * pi + randomOffset);
                                    final distance = 15 + oscillation * 3;
                                    final starRotation = _starController.value * 4 * pi + randomOffset;
                                    final opacity = 0.3 + (0.7 * (sin(_starController.value * 2 * pi + randomOffset) + 1) / 2);
                                    
                                    return Transform.translate(
                                      offset: Offset(
                                        cos(baseAngle + _starController.value * pi) * distance,
                                        sin(baseAngle + _starController.value * pi) * distance,
                                      ),
                                      child: Transform.rotate(
                                        angle: starRotation,
                                        child: Icon(
                                          Icons.star,
                                          size: 8,
                                          color: Colors.amber.withOpacity(opacity),
                                        ),
                                      ),
                                    );
                                  }),
                                );
                              },
                            ),
                            Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.amber[300]!.withOpacity(0.5),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.circle,
                              size: 22,
                              color: Colors.amber,
                            ),
                            const Text(
                              '₺',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(
                                    color: Colors.black26,
                                    offset: Offset(0, 1),
                                    blurRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Coin Bakiyesi',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Balance Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            '1,250',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              height: 1,
                            ),
                          ),
                          Text(
                            'Toplam Coin',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      // Buy Button
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => const CoinPurchaseModal(),
                            );
                          },
                          borderRadius: BorderRadius.circular(15),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(
                                  Icons.add_circle_outline,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Coin Ekle',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
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
  }

  Widget _buildCoinPackage(String title, String coinAmount, String price, {required IconData icon, required bool isPopular}) {
    final bool isSelected = _selectedPackage == title;
    final bool isGoldPackage = title == 'Altın Paket';
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedPackage = title;
          });
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected 
              ? AppColors.primary.withOpacity(0.1)
              : isGoldPackage
                ? const Color(0xFFFFD700).withOpacity(0.1)
                : isPopular 
                  ? AppColors.primary.withOpacity(0.05)
                  : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected 
                ? AppColors.primary
                : isGoldPackage
                  ? const Color(0xFFFFD700)
                  : isPopular 
                    ? AppColors.primary.withOpacity(0.5)
                    : Colors.grey[200]!,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected 
                    ? AppColors.primary
                    : isGoldPackage
                      ? const Color(0xFFFFD700)
                      : isPopular 
                        ? AppColors.primary.withOpacity(0.8)
                        : Colors.grey[100],
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  icon,
                  color: isSelected || isPopular || isGoldPackage ? Colors.white : Colors.grey[600],
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isSelected || isPopular || isGoldPackage 
                          ? isGoldPackage 
                            ? const Color(0xFFFFD700)
                            : AppColors.primary 
                          : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      coinAmount,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    if (isPopular) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Popüler',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected 
                    ? AppColors.primary
                    : isGoldPackage
                      ? const Color(0xFFFFD700)
                      : isPopular 
                        ? AppColors.primary.withOpacity(0.8)
                        : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  price,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isSelected || isPopular || isGoldPackage ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPurchaseButton() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_selectedPackage != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Seçilen Paket:',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  _selectedPackage!,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Fiyatlandırmalara KDV dahil değildir.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedPackage != null ? () {
                // TODO: Implement purchase logic
                Navigator.pop(context);
              } : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 0,
              ),
              child: Text(
                _selectedPackage != null ? 'Satın Al' : 'Paket Seçin',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date is Timestamp) {
      final dateTime = date.toDate();
      final monthNames = [
        'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
        'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
      ];
      return '${dateTime.day} ${monthNames[dateTime.month - 1]} ${dateTime.year}';
    }
    return 'Ocak 2024';
  }
}

class CoinPurchaseModal extends StatefulWidget {
  const CoinPurchaseModal({super.key});

  @override
  State<CoinPurchaseModal> createState() => _CoinPurchaseModalState();
}

class _CoinPurchaseModalState extends State<CoinPurchaseModal> {
  String? _selectedPackage;

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
          // Modal Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
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
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Coin Satın Al',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Modal Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Current Balance
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Mevcut Bakiyeniz',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              '1,250 Coin',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Packages Title
                  const Text(
                    'Paketler',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Coin Packages
                  _buildCoinPackage(
                    'Başlangıç Paketi',
                    '100 Coin',
                    '₺9.99',
                    icon: Icons.star_border,
                    isPopular: false,
                  ),
                  const SizedBox(height: 12),
                  _buildCoinPackage(
                    'Gümüş Paket',
                    '250 Coin',
                    '₺19.99',
                    icon: Icons.star_half,
                    isPopular: false,
                  ),
                  const SizedBox(height: 12),
                  _buildCoinPackage(
                    'Altın Paket',
                    '500 Coin',
                    '₺39.99',
                    icon: Icons.star,
                    isPopular: true,
                  ),
                  const SizedBox(height: 12),
                  _buildCoinPackage(
                    'Platin Paket',
                    '1000 Coin',
                    '₺69.99',
                    icon: Icons.diamond_outlined,
                    isPopular: false,
                  ),
                  const SizedBox(height: 12),
                  _buildCoinPackage(
                    'Elmas Paket',
                    '2000 Coin',
                    '₺119.99',
                    icon: Icons.diamond,
                    isPopular: false,
                  ),
                ],
              ),
            ),
          ),
          // Satın alma butonu
          _buildPurchaseButton(),
        ],
      ),
    );
  }

  Widget _buildCoinPackage(String title, String coinAmount, String price, {required IconData icon, required bool isPopular}) {
    final bool isSelected = _selectedPackage == title;
    final bool isGoldPackage = title == 'Altın Paket';
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedPackage = title;
          });
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected 
              ? AppColors.primary.withOpacity(0.1)
              : isGoldPackage
                ? const Color(0xFFFFD700).withOpacity(0.1)
                : isPopular 
                  ? AppColors.primary.withOpacity(0.05)
                  : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected 
                ? AppColors.primary
                : isGoldPackage
                  ? const Color(0xFFFFD700)
                  : isPopular 
                    ? AppColors.primary.withOpacity(0.5)
                    : Colors.grey[200]!,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected 
                    ? AppColors.primary
                    : isGoldPackage
                      ? const Color(0xFFFFD700)
                      : isPopular 
                        ? AppColors.primary.withOpacity(0.8)
                        : Colors.grey[100],
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  icon,
                  color: isSelected || isPopular || isGoldPackage ? Colors.white : Colors.grey[600],
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isSelected || isPopular || isGoldPackage 
                          ? isGoldPackage 
                            ? const Color(0xFFFFD700)
                            : AppColors.primary 
                          : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      coinAmount,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    if (isPopular) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Popüler',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected 
                    ? AppColors.primary
                    : isGoldPackage
                      ? const Color(0xFFFFD700)
                      : isPopular 
                        ? AppColors.primary.withOpacity(0.8)
                        : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  price,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isSelected || isPopular || isGoldPackage ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPurchaseButton() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_selectedPackage != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Seçilen Paket:',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  _selectedPackage!,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Fiyatlandırmalara KDV dahil değildir.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedPackage != null ? () {
                // TODO: Implement purchase logic
                Navigator.pop(context);
              } : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 0,
              ),
              child: Text(
                _selectedPackage != null ? 'Satın Al' : 'Paket Seçin',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
} 