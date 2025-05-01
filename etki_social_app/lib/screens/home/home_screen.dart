import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';  // DragStartBehavior için import
import 'package:go_router/go_router.dart';
import 'package:etki_social_app/constants/app_colors.dart';
import 'package:etki_social_app/models/post_model.dart';
import 'package:etki_social_app/models/story.dart';
import 'package:etki_social_app/widgets/post_card.dart';
import 'package:etki_social_app/widgets/comment_card.dart';
import 'package:etki_social_app/screens/profile/other_user_profile_screen.dart';
import 'package:etki_social_app/screens/profile/profile_screen.dart';
import 'package:etki_social_app/utils/user_utils.dart';
import 'package:etki_social_app/screens/create_post/create_post_screen.dart';
import 'following_tab.dart';
import '../notifications/notifications_screen.dart';
import '../messages/messages_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:etki_social_app/services/auth_service.dart';
import 'package:etki_social_app/screens/create_group/create_group_screen.dart';
import 'package:etki_social_app/widgets/group_card.dart';
import 'package:etki_social_app/screens/group/group_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isSpeedDialOpen = false;
  late AnimationController _speedDialController;
  late Animation<double> _speedDialAnimation;
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  List<Post> _missions = []; // Görevler için state değişkeni
  
  // Post lists for different tabs
  final List<Post> _explorePosts = List.generate(10, (index) {
    // Her 3. gönderi bir görev olacak
    if (index % 3 == 0) {
      return Post(
        id: 'mission_$index',
        userId: 'mission_creator_$index',
        content: 'Bu görev için detaylı açıklama burada yer alacak.',
        type: PostType.mission,
        missionTitle: 'Görev ${index + 1}',
        missionDescription: 'Bu görevi tamamlamak için yapmanız gerekenler...',
        missionReward: (index + 1) * 100, // Her görev için farklı ödül
        missionDeadline: DateTime.now().add(Duration(days: index + 1)), // Her görev için farklı son tarih
        missionParticipants: List.generate(
          index % 4, // Her görev için farklı sayıda katılımcı
          (i) => MissionParticipant(
            userId: 'participant_$i',
            username: 'Katılımcı $i',
            status: MissionStatus.values[i % MissionStatus.values.length],
          ),
        ),
        maxParticipants: 10,
        createdAt: DateTime.now().subtract(Duration(hours: index)),
        isVerified: true,
        comments: [
          Comment(
            id: 'comment_${index}_1',
            userId: 'commenter_1',
            username: 'Ahmet Yılmaz',
            content: 'Bu görevi tamamlamak için yardıma ihtiyacım var.',
            createdAt: DateTime.now().subtract(Duration(minutes: 30)),
            isVerified: true,
            likes: [],
            replies: [],
          ),
          Comment(
            id: 'comment_${index}_2',
            userId: 'commenter_2',
            username: 'Ayşe Demir',
            content: 'Ben de katılmak istiyorum!',
            createdAt: DateTime.now().subtract(Duration(hours: 1)),
            likes: [],
            replies: [],
          ),
        ],
        likes: [],
      );
    } else {
      return Post(
    id: 'explore_$index',
    userId: 'user_$index',
    content: 'Keşfet tabındaki örnek gönderi $index',
    type: PostType.text,
    createdAt: DateTime.now().subtract(Duration(hours: index)),
        isVerified: index % 3 == 0,
    comments: [
      Comment(
        id: 'comment_${index}_1',
        userId: 'commenter_1',
        username: 'Ahmet Yılmaz',
        content: 'Harika bir gönderi!',
        createdAt: DateTime.now().subtract(Duration(minutes: 30)),
            isVerified: true,
        likes: [],
        replies: [],
      ),
      Comment(
        id: 'comment_${index}_2',
        userId: 'commenter_2',
        username: 'Ayşe Demir',
        content: 'Bunu denemek istiyorum.',
        createdAt: DateTime.now().subtract(Duration(hours: 1)),
        likes: [],
        replies: [],
      ),
    ],
    likes: [],
      );
    }
  });

  final List<Post> _followingPosts = [
    Post(
      id: '1',
      userId: 'john_doe',
      content: 'Bu bir test gönderisidir!',
      type: PostType.text,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      isVerified: true, // Onaylı kullanıcı
      comments: [
        Comment(
          id: 'comment_1',
          userId: 'jane_doe',
          username: 'Jane Doe',
          content: 'Harika bir gönderi!',
          createdAt: DateTime.now().subtract(const Duration(hours: 1)),
          isVerified: true, // Onaylı yorumcu
          likes: [],
          replies: [
            Comment(
              id: 'reply_1',
              userId: 'john_doe',
              username: 'John Doe',
              content: 'Teşekkür ederim!',
              createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
              isVerified: true, // Onaylı kullanıcı
              likes: [],
              replies: [],
            ),
          ],
        ),
      ],
      likes: [],
    ),
    Post(
      id: '2',
      userId: 'jane_doe',
      content: 'Bugün harika bir gün!',
      type: PostType.image,
      imageUrls: [
        'https://picsum.photos/800/600',
        'https://picsum.photos/800/600?random=1',
      ],
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      isVerified: true, // Onaylı kullanıcı
      comments: [],
      likes: [],
    ),
    Post(
      id: '3',
      userId: 'mission_master',
      content: 'Bu hafta 5 km koşu yapın ve fotoğrafını paylaşın.',
      type: PostType.mission,
      missionTitle: 'Haftalık Koşu Görevi',
      missionDescription: 'Sağlıklı yaşam için spor yapmayı unutmayın!',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      isVerified: true, // Onaylı kullanıcı
      comments: [],
      likes: [],
    ),
  ];

  final List<Post> _groupPosts = List.generate(3, (index) => Post(
    id: 'group_$index',
    userId: 'group_user_$index',
    content: 'Grup gönderisi $index',
    type: PostType.text,
    createdAt: DateTime.now().subtract(Duration(hours: index)),
    isVerified: index == 0, // Sadece ilk grup onaylı
    comments: [
      Comment(
        id: 'group_comment_${index}_1',
        userId: 'group_member_1',
        username: 'Grup Üyesi 1',
        content: 'Bu etkinliğe katılmak istiyorum!',
        createdAt: DateTime.now().subtract(Duration(minutes: 45)),
        isVerified: index == 0, // Sadece ilk gruptaki yorumcu onaylı
        likes: [],
        replies: [],
      ),
    ],
    likes: [],
  ));

  // Örnek arama verileri
  final List<Map<String, dynamic>> _recentSearches = [
    {'query': 'Ahmet Yılmaz', 'type': 'user'},
    {'query': 'Proje Yönetimi', 'type': 'mission'},
    {'query': 'Tasarım Görevi', 'type': 'mission'},
  ];

  final List<Map<String, dynamic>> _searchResults = [
    {
      'title': 'Ahmet Yılmaz',
      'subtitle': 'Kullanıcı',
      'image': 'https://picsum.photos/200',
      'isUser': true,
      'type': 'user'
    },
    {
      'title': 'Proje Yönetimi Görevi',
      'subtitle': 'Görev',
      'image': 'https://picsum.photos/201',
      'isUser': false,
      'type': 'mission'
    },
    {
      'title': 'Tasarım Görevi',
      'subtitle': 'Görev',
      'image': 'https://picsum.photos/202',
      'isUser': false,
      'type': 'mission'
    },
  ];

  String _selectedCategory = 'Tümü';
  List<Map<String, dynamic>> _filteredResults = [];

  final AuthService _authService = AuthService();

  // Arama geçmişi için yeni değişken
  List<Map<String, dynamic>> _searchHistory = [];
  
  // Arama geçmişini Firebase'den yükle
  Future<void> _loadSearchHistory() async {
    try {
      final user = _authService.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('search_history')
            .doc('recent')
            .get();

        if (doc.exists) {
          setState(() {
            _searchHistory = List<Map<String, dynamic>>.from(doc.data()?['searches'] ?? []);
          });
        }
      }
    } catch (e) {
      print('Arama geçmişi yüklenirken hata: $e');
    }
  }

  // Arama geçmişini Firebase'e kaydet
  Future<void> _saveSearchHistory() async {
    try {
      final user = _authService.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('search_history')
            .doc('recent')
            .set({
          'searches': _searchHistory,
        });
      }
    } catch (e) {
      print('Arama geçmişi kaydedilirken hata: $e');
    }
  }

  // Arama geçmişine yeni öğe ekle
  void _addToSearchHistory(String query, String type) {
    if (query.trim().isEmpty) return;

    setState(() {
      // Varsa eski aramayı kaldır
      _searchHistory.removeWhere((item) => item['query'] == query);
      
      // Yeni aramayı başa ekle
      _searchHistory.insert(0, {
        'query': query,
        'type': type,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      
      // Son 10 aramayı tut
      if (_searchHistory.length > 10) {
        _searchHistory = _searchHistory.sublist(0, 10);
      }
    });
    
    // Firebase'e kaydet
    _saveSearchHistory();
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this, initialIndex: 1);
    _speedDialController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _speedDialAnimation = CurvedAnimation(
      parent: _speedDialController,
      curve: Curves.easeInOut,
    );
    _searchController.addListener(() {
      _filterSearchResults();
    });
    _filteredResults = _searchResults;

    // Tab değişikliklerini dinle
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        return;
      }
      // Görevler tabına geçildiğinde görevleri yükle
      if (_tabController.index == 2) {
        _loadMissions();
      }
      if (mounted) {
        setState(() {});
      }
    });

    // İlk yükleme
    _loadMissions();
    _loadSearchHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _speedDialController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSpeedDial() {
    setState(() {
      _isSpeedDialOpen = !_isSpeedDialOpen;
      if (_isSpeedDialOpen) {
        _speedDialController.forward();
      } else {
        _speedDialController.reverse();
      }
    });
  }

  void _closeSpeedDial() {
    if (_isSpeedDialOpen) {
      setState(() {
        _isSpeedDialOpen = false;
      });
    }
  }

  String getCurrentUser() {
    // TODO: implement actual user management
    return "Kullanıcı";  // Default value until user management is implemented
  }

  final _stories = [
    Story(
      id: '1',
      userId: 'john_doe',
      userName: 'John Doe',
      userImage: 'https://picsum.photos/200',
      items: [
        StoryItem(
          id: '1',
          url: 'https://picsum.photos/800/1200',
          type: StoryType.image,
          createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        ),
      ],
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      isVerified: true,
    ),
    Story(
      id: '2',
      userId: 'jane_doe',
      userName: 'Jane Doe',
      userImage: 'https://picsum.photos/201',
      items: [
        StoryItem(
          id: '2',
          url: 'https://picsum.photos/800/1200?random=1',
          type: StoryType.image,
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
      ],
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      isVerified: true,
    ),
    Story(
      id: '3',
      userId: 'mission_master',
      userName: 'Mission Master',
      userImage: '',
      items: [
        StoryItem(
          id: '3',
          url: 'https://picsum.photos/800/1200?random=2',
          type: StoryType.image,
          createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        ),
      ],
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      isVerified: true,
    ),
  ];

  void _handleStoryTap(Story story) {
    // TODO: Implement story viewing
    print('Story tapped: ${story.userName}');
  }

  void _handlePostLike(Post post) async {
    final user = _authService.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Beğeni işlemi için giriş yapmanız gerekiyor'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final isLiked = post.likes.contains(user.uid);

    // Önce UI'ı güncelle
    setState(() {
      if (isLiked) {
        post.likes.remove(user.uid);
      } else {
        post.likes.add(user.uid);
      }
    });

    try {
      if (post.type == PostType.mission) {
        // Firebase'i güncelle
        await FirebaseFirestore.instance
            .collection('tasks')
            .doc(post.id)
            .update({
          'likes': isLiked 
              ? FieldValue.arrayRemove([user.uid])
              : FieldValue.arrayUnion([user.uid]),
        });
      }
    } catch (e) {
      // Hata durumunda UI'ı eski haline getir
      setState(() {
        if (isLiked) {
          post.likes.add(user.uid);
        } else {
          post.likes.remove(user.uid);
        }
      });
      
      print('Beğeni işlemi sırasında hata: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Beğeni işlemi sırasında bir hata oluştu'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _filterSearchResults() async {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _isLoading = true;
    });

    try {
      if (query.isEmpty) {
        setState(() {
          _filteredResults = [];
          _isLoading = false;
        });
        return;
      }

      // Görev araması - tasks koleksiyonundan
      final tasksQuery = await FirebaseFirestore.instance
          .collection('tasks')
          .get();

      // Kullanıcı araması
      final usersQuery = await FirebaseFirestore.instance
          .collection('users')
          .get();

      List<Map<String, dynamic>> results = [];

      // Kullanıcı sonuçlarını filtrele ve ekle
      if (_selectedCategory == 'Tümü' || _selectedCategory == 'Kullanıcılar') {
        results.addAll(usersQuery.docs.where((doc) {
          final data = doc.data();
          final username = (data['username'] ?? '').toString().toLowerCase();
          return username.contains(query);
        }).map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'title': data['username'] ?? 'İsimsiz Kullanıcı',
            'subtitle': data['bio'] ?? '',
            'image': data['profileImage'] ?? '',
            'type': 'user',
            'isUser': true,
          };
        }));
      }

      // Görev sonuçlarını filtrele ve ekle
      if (_selectedCategory == 'Tümü' || _selectedCategory == 'Görevler') {
        results.addAll(tasksQuery.docs.where((doc) {
          final data = doc.data();
          final title = (data['title'] ?? '').toString().toLowerCase();
          final description = (data['description'] ?? '').toString().toLowerCase();
          return title.contains(query) || description.contains(query);
        }).map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'title': data['title'] ?? 'İsimsiz Görev',
            'subtitle': data['description'] ?? '',
            'image': data['image'] ?? '',
            'type': 'mission',
            'isUser': false,
            'reward': data['coinAmount'],
          };
        }));
      }

      // Sonuçları benzerlik skoruna göre sırala
      results.sort((a, b) {
        final aTitle = a['title'].toString().toLowerCase();
        final bTitle = b['title'].toString().toLowerCase();
        final aScore = _calculateSimilarity(aTitle, query);
        final bScore = _calculateSimilarity(bTitle, query);
        return bScore.compareTo(aScore);
      });

      setState(() {
        _filteredResults = results;
        _isLoading = false;
      });
    } catch (e) {
      print('Arama hatası: $e');
      setState(() {
        _filteredResults = [];
        _isLoading = false;
      });
    }
  }

  // Benzerlik skorunu hesaplayan yardımcı fonksiyon
  double _calculateSimilarity(String text, String query) {
    text = text.toLowerCase();
    query = query.toLowerCase();
    
    if (text == query) return 1.0;
    if (text.contains(query)) return 0.8;
    
    int matchCount = 0;
    for (int i = 0; i < query.length && i < text.length; i++) {
      if (text[i] == query[i]) matchCount++;
    }
    
    return matchCount / query.length;
  }

  void _handleCategorySelect(String category) {
    setState(() {
      _selectedCategory = category;
    });
    _filterSearchResults();
  }

  void _handleSearchItemTap(Map<String, dynamic> item) {
    // Arama geçmişine ekle
    _addToSearchHistory(item['title'], item['type']);
    
    if (item['type'] == 'user') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OtherUserProfileScreen(
            userId: item['id'],
          ),
        ),
      );
    } else if (item['type'] == 'mission') {
      // TODO: Görev detay sayfasına yönlendir
      print('Görev detayına git: ${item['id']}');
    }
  }

  void _showSearchScreen() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          builder: (context, scrollController) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.black),
                            onPressed: () => Navigator.pop(context),
                          ),
                          Expanded(
                            child: Container(
                              height: 45,
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: TextField(
                                controller: _searchController,
                                autofocus: true,
                                decoration: InputDecoration(
                                  hintText: 'Kullanıcı veya görev ara...',
                                  hintStyle: TextStyle(color: Colors.grey[600]),
                                  prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                                ),
                                onChanged: (value) {
                                  _filterSearchResults();
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildSearchCategory('Tümü', _selectedCategory == 'Tümü', setModalState),
                            _buildSearchCategory('Kullanıcılar', _selectedCategory == 'Kullanıcılar', setModalState),
                            _buildSearchCategory('Görevler', _selectedCategory == 'Görevler', setModalState),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _searchController.text.isEmpty
                          ? _buildRecentSearches(scrollController)
                          : _buildSearchResults(scrollController),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchCategory(String title, bool isSelected, StateSetter setModalState) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setModalState(() {
              _selectedCategory = title;
            });
            _filterSearchResults();
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentSearches(ScrollController scrollController) {
    if (_searchHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.history, size: 48, color: AppColors.primary.withOpacity(0.5)),
            ),
            const SizedBox(height: 16),
            Text(
              'Henüz arama geçmişi yok',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Yaptığınız aramalar burada görünecek',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.history,
                    size: 20,
                    color: AppColors.primary.withOpacity(0.7),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Son Aramalar',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: () async {
                  // Silme animasyonu için
                  setState(() {
                    _searchHistory.clear();
                  });
                  await _saveSearchHistory();
                },
                icon: Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: AppColors.primary.withOpacity(0.7),
                ),
                label: Text(
                  'Temizle',
                  style: TextStyle(
                    color: AppColors.primary.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ..._searchHistory.asMap().entries.map((entry) {
          final index = entry.key;
          final search = entry.value;
          return AnimatedContainer(
            duration: Duration(milliseconds: 200 + (index * 50)),
            curve: Curves.easeInOut,
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  _searchController.text = search['query'];
                  _filterSearchResults();
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          search['type'] == 'user' ? Icons.person : Icons.assignment,
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
                              search['query'],
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 15,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              search['type'] == 'user' ? 'Kullanıcı' : 'Görev',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          color: Colors.grey[400],
                          size: 18,
                        ),
                        onPressed: () async {
                          setState(() {
                            _searchHistory.removeAt(index);
                          });
                          await _saveSearchHistory();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildSearchResults(ScrollController scrollController) {
    if (_filteredResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _selectedCategory == 'Kullanıcılar' ? Icons.person_off :
              _selectedCategory == 'Görevler' ? Icons.assignment_turned_in_outlined :
              Icons.search_off,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _selectedCategory == 'Kullanıcılar' ? 'Kullanıcı bulunamadı' :
              _selectedCategory == 'Görevler' ? 'Görev bulunamadı' :
              'Sonuç bulunamadı',
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
      );
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _filteredResults.length,
      itemBuilder: (context, index) {
        final result = _filteredResults[index];
        return _buildSearchResultItem(
          title: result['title'],
          subtitle: result['subtitle'],
          image: result['image'],
          isUser: result['isUser'],
          onTap: () => _handleSearchItemTap(result),
        );
      },
    );
  }

  Widget _buildSearchResultItem({
    required String title,
    required String subtitle,
    required String image,
    required bool isUser,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: image.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(image),
                          fit: BoxFit.cover,
                        )
                      : null,
                  color: image.isEmpty ? Colors.grey[200] : null,
                ),
                child: image.isEmpty
                    ? Icon(
                        isUser ? Icons.person : Icons.assignment,
                        color: Colors.grey[400],
                        size: 20,
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                isUser ? Icons.person : Icons.assignment,
                color: Colors.grey[400],
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return true;
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: const Text('Etki'),
          centerTitle: true,
          elevation: 0,
          leading: Container(
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.primary.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.group_add, color: Colors.white, size: 20),
              padding: const EdgeInsets.all(8),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateGroupScreen(),
                  ),
                );
              },
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: _showSearchScreen,
            ),
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationsScreen(),
                  ),
                );
              },
            ),
            Container(
              margin: const EdgeInsets.only(right: 8),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MessagesScreen(),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.chat_bubble,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(kToolbarHeight),
            child: Container(
              height: 70,
              alignment: Alignment.center,
              child: TabBar(
                controller: _tabController,
                indicator: const BoxDecoration(),
                isScrollable: true,
                padding: EdgeInsets.zero,
                labelPadding: const EdgeInsets.symmetric(horizontal: 24),
                enableFeedback: false,
                onTap: (index) {
                  setState(() {
                    _tabController.animateTo(index);
                  });
                },
                tabs: [
                  _buildTab(
                    icon: Icons.person,
                    label: 'Profilim',
                    index: 0,
                  ),
                  _buildTab(
                    icon: Icons.people_outline,
                    label: 'Takip',
                    index: 1,
                  ),
                  _buildTab(
                    icon: Icons.assignment,
                    label: 'Görevler',
                    index: 2,
                  ),
                  _buildTab(
                    icon: Icons.groups,
                    label: 'Gruplar',
                    index: 3,
                  ),
                ],
              ),
            ),
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          dragStartBehavior: DragStartBehavior.down,
          children: [
            // Profilim Tab
            const ProfileScreen(),
            
            // Takip Tab
            const FollowingTab(),
            
            // Görevler Tab
            RefreshIndicator(
              onRefresh: () async {
                await _loadMissions();
              },
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _missions.isEmpty
                      ? ListView(
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
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: _missions.length,
                          itemBuilder: (context, index) {
                            final post = _missions[index];
                            return PostCard(
                              post: post,
                              onLike: () => _handlePostLike(post),
                              onComment: () => _showComments(context, post),
                              onShare: () {
                                print('Post shared: ${post.id}');
                              },
                            );
                          },
                        ),
            ),
            
            // Gruplar Tab
            RefreshIndicator(
              onRefresh: () async {
                // TODO: Implement refresh for groups tab
                await Future.delayed(const Duration(seconds: 1));
              },
              child: ListView.builder(
                itemCount: _groups.length,
                itemBuilder: (context, index) {
                  final group = _groups[index];
                  return GroupCard(
                    groupId: group['id'],
                    groupName: group['name'],
                    groupImage: group['image'],
                    bio: group['bio'],
                    memberCount: group['memberCount'],
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GroupScreen(
                            groupId: group['id'],
                            groupName: group['name'],
                            groupImage: group['image'],
                            memberCount: group['memberCount'],
                            isAdmin: false, // TODO: Implement admin check
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
              onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => DraggableScrollableSheet(
                initialChildSize: 0.9,
                minChildSize: 0.5,
                maxChildSize: 0.9,
                builder: (context, scrollController) => Container(
                  decoration: const BoxDecoration(
                              color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                  child: const CreatePostScreen(),
                          ),
              ),
            );
                            },
          backgroundColor: AppColors.primary,
          child: const Icon(Icons.add, size: 28),
        ),
      ),
    );
  }

  Widget _buildTab({
    required IconData icon,
    required String label,
    required int index,
  }) {
    return AnimatedBuilder(
      animation: _tabController.animation!,
      builder: (context, child) {
        final double value = _tabController.animation!.value;
        final double distance = (index - value).abs();
        final bool isSelected = distance < 0.5;

        // Tab genişliği ve opaklığını hesapla
        final double width = isSelected ? 160.0 : 80.0;
        final double opacity = (1 - distance).clamp(0.5, 1.0);
        final double scale = (1 - distance * 0.3).clamp(0.7, 1.0);

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: width,
          child: Transform.scale(
            scale: scale,
            child: Opacity(
              opacity: opacity,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      size: 20,
                      color: isSelected ? AppColors.primary : AppColors.textSecondary.withOpacity(0.7),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected ? AppColors.primary : AppColors.textSecondary.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showComments(BuildContext context, Post post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                        'Yorumlar',
                        style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                  controller: controller,
                    itemCount: post.comments.length,
                    itemBuilder: (context, index) {
                      final comment = post.comments[index];
                    return CommentCard(comment: comment);
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Görevleri yükleme fonksiyonu
  Future<void> _loadMissions() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('tasks')
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
      
      if (mounted) {
        setState(() {
          _missions = missions;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Görevler yüklenirken hata: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Görevler yüklenirken bir hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Gruplar için örnek veriler
  final List<Map<String, dynamic>> _groups = List.generate(5, (index) => {
    'id': 'group_$index',
    'name': 'Grup ${index + 1}',
    'image': 'https://picsum.photos/200?random=$index',
    'bio': 'Bu grup ${index + 1} için örnek bir açıklama metni. Grup hakkında kısa bilgiler burada yer alacak.',
    'memberCount': (index + 1) * 10,
  });
} 