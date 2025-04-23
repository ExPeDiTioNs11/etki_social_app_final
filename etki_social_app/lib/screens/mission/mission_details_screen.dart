import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/post_model.dart';
import '../../theme/colors.dart';
import 'package:etki_social_app/widgets/post_card.dart';

class MissionDetailsScreen extends StatefulWidget {
  final Post post;

  const MissionDetailsScreen({
    super.key,
    required this.post,
  });

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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Görev Detayları'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              // TODO: Implement share functionality
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Mission Card
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Mission Header
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.assignment,
                            color: AppColors.primary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.post.missionTitle!,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${widget.post.missionParticipants?.length ?? 0} Katılımcı',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Mission Description
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      widget.post.content,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[800],
                        height: 1.5,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Mission Details
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildDetailItem(
                          icon: Icons.access_time,
                          label: 'Son Tarih',
                          value: _formatDeadline(widget.post.missionDeadline!),
                        ),
                        _buildDetailItem(
                          icon: Icons.group,
                          label: 'Katılımcı',
                          value: '${widget.post.missionParticipants?.length ?? 0}/${widget.post.maxParticipants ?? "∞"}',
                        ),
                        _buildDetailItem(
                          icon: Icons.monetization_on,
                          label: 'Ödül',
                          value: '${widget.post.missionReward ?? 100}',
                          isCoin: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Participants Section
            if ((widget.post.missionParticipants?.length ?? 0) > 0) ...[
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Katılımcılar',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 60,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: widget.post.missionParticipants!.length,
                        itemBuilder: (context, index) {
                          final participant = widget.post.missionParticipants![index];
                          return Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: Column(
                              children: [
                                Stack(
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: _getStatusColor(participant.status),
                                      child: Text(
                                        (participant.username ?? participant.userId)[0].toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      right: 0,
                                      bottom: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.1),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Icon(
                                          Icons.circle,
                                          size: 8,
                                          color: _getStatusColor(participant.status),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  participant.username ?? participant.userId,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            // Participate Button
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // TODO: Implement mission participation
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
    bool isCoin = false,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          size: 24,
          color: isCoin ? Colors.amber : Colors.grey[600],
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        if (isCoin)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildCoinIcon(),
              const SizedBox(width: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                ),
              ),
            ],
          )
        else
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
      ],
    );
  }

  Color _getStatusColor(MissionStatus status) {
    switch (status) {
      case MissionStatus.pending:
        return Colors.grey;
      case MissionStatus.accepted:
        return Colors.blue;
      case MissionStatus.inProgress:
        return Colors.orange;
      case MissionStatus.submitted:
        return Colors.purple;
      case MissionStatus.completed:
        return Colors.green;
      case MissionStatus.rejected:
        return Colors.red;
    }
  }

  String _formatDeadline(DateTime deadline) {
    final remaining = deadline.difference(DateTime.now());
    if (remaining.isNegative) return 'Süresi doldu';
    
    if (remaining.inDays > 0) {
      return '${remaining.inDays}g';
    } else if (remaining.inHours > 0) {
      return '${remaining.inHours}s';
    } else {
      return '${remaining.inMinutes}d';
    }
  }
} 