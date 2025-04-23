import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:etki_social_app/constants/app_colors.dart';
import 'package:etki_social_app/models/post_model.dart';
import 'package:etki_social_app/widgets/post_card.dart';
import '../settings/settings_screen.dart';
import 'followers_list_modal.dart';
import 'following_list_modal.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _starController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _starController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 200,
              floating: false,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  children: [
                    // Kapak fotoğrafı
                    Container(
                      height: 150,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.8),
                        image: const DecorationImage(
                          image: NetworkImage('https://picsum.photos/800/400'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    // Profil fotoğrafı
                    Positioned(
                      left: 16,
                      top: 100,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                        ),
                        child: CircleAvatar(
                          radius: 40,
                          backgroundColor: AppColors.primary,
                          child: Text(
                            'K',
                            style: TextStyle(
                              fontSize: 32,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Kullanıcı Adı',
                          style: TextStyle(
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
                      '@kullanici',
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Profil açıklaması burada yer alacak. Kullanıcı hakkında kısa bir bilgi.',
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          'Konum',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(width: 16),
                        Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          'Ocak 2024\'ten beri üye',
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
                                '256',
                                style: TextStyle(fontWeight: FontWeight.bold),
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
                                '128',
                                style: TextStyle(fontWeight: FontWeight.bold),
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
                              '24',
                              style: TextStyle(fontWeight: FontWeight.bold),
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
                              style: TextStyle(fontWeight: FontWeight.bold),
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
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildPostsList(),
            _buildMissionsList(),
            _buildMediaList(),
            _buildLikesList(),
          ],
        ),
      ),
    );
  }

  Widget _buildPostsList() {
    return ListView.builder(
      itemCount: 5,
      itemBuilder: (context, index) {
        return PostCard(
          post: Post(
            id: 'profile_$index',
            userId: 'kullanici',
            content: 'Profil gönderisi $index',
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

  Widget _buildMissionsList() {
    return ListView.builder(
      itemCount: 3,
      itemBuilder: (context, index) {
        return PostCard(
          post: Post(
            id: 'mission_$index',
            userId: 'kullanici',
            content: 'Görev $index',
            type: PostType.mission,
            missionTitle: 'Görev ${index + 1}',
            missionDescription: 'Görev açıklaması burada yer alacak.',
            createdAt: DateTime.now().subtract(Duration(days: index)),
          ),
          onLike: () {},
          onComment: () {},
          onShare: () {},
        );
      },
    );
  }

  Widget _buildMediaList() {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: 9,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            image: DecorationImage(
              image: NetworkImage('https://picsum.photos/200/200?random=$index'),
              fit: BoxFit.cover,
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