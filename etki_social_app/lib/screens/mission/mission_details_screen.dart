import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/post_model.dart';
import '../../theme/colors.dart';

class MissionDetailsScreen extends StatefulWidget {
  final Post post;

  const MissionDetailsScreen({
    Key? key,
    required this.post,
  }) : super(key: key);

  @override
  State<MissionDetailsScreen> createState() => _MissionDetailsScreenState();
}

class _MissionDetailsScreenState extends State<MissionDetailsScreen> with SingleTickerProviderStateMixin {
  late AnimationController _starController;
  final List<double> _randomOffsets = List.generate(8, (index) => Random().nextDouble() * pi);
  
  @override
  void initState() {
    super.initState();
    _starController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _starController.dispose();
    super.dispose();
  }

  Widget _buildCoinIcon() {
    return SizedBox(
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
          // Coin background glow
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
          // Main coin icon
          const Icon(
            Icons.circle,
            size: 22,
            color: Colors.amber,
          ),
          // Coin symbol
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Görev Detayları',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.share,
              color: Colors.white,
            ),
            onPressed: () {
              // TODO: Implement share functionality
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Section with Mission Title and Description
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 5,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.post.missionTitle ?? 'Görev Başlığı',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.post.missionDescription ?? widget.post.content,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey[700],
                          height: 1.5,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Mission Stats
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Ödül',
                      '${widget.post.missionReward ?? 100}\nCoin',
                      _buildCoinIcon(),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _buildStatCard(
                      'Katılımcı',
                      '${widget.post.maxParticipants ?? "∞"}\nKişi',
                      const Icon(Icons.group, color: AppColors.primary, size: 28),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _buildStatCard(
                      'Süre',
                      widget.post.missionDeadline != null
                          ? _formatRemainingTime()
                          : '∞\nGün',
                      const Icon(Icons.timer, color: AppColors.primary, size: 28),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Mission Requirements
            Padding(
              padding: const EdgeInsets.all(20),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Görev Gereksinimleri',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 15),
                      _buildRequirementItem('Görevi zamanında tamamla'),
                      _buildRequirementItem('Görev kanıtı olarak fotoğraf yükle'),
                      _buildRequirementItem('Görev açıklamasını detaylı yaz'),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: () {
            // TODO: Implement join mission functionality
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: const Text(
            'Göreve Katıl',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Widget icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequirementItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle,
            color: AppColors.primary,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  String _formatRemainingTime() {
    if (widget.post.missionDeadline == null) return '∞\nGün';
    
    final remaining = widget.post.missionDeadline!.difference(DateTime.now());
    if (remaining.isNegative) return 'Süresi\nDoldu';
    
    if (remaining.inDays > 0) {
      return '${remaining.inDays}\nGün';
    } else if (remaining.inHours > 0) {
      return '${remaining.inHours}\nSaat';
    } else {
      return '${remaining.inMinutes}\nDakika';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
} 