import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/story.dart';
import '../theme/colors.dart';
import '../screens/story/story_viewer_screen.dart';

class StoryCircle extends StatefulWidget {
  final Story story;
  final double size;
  final VoidCallback? onTap;
  final List<Story> allStories;
  final bool isViewed;

  const StoryCircle({
    super.key,
    required this.story,
    required this.allStories,
    this.size = 80,
    this.onTap,
    this.isViewed = false,
  });

  @override
  State<StoryCircle> createState() => _StoryCircleState();
}

class _StoryCircleState extends State<StoryCircle> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.linear,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    // Start loading animation
    _controller.repeat();

    // Simulate loading delay
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      _controller.stop();

      final initialIndex = widget.allStories.indexOf(widget.story);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => StoryViewerScreen(
            stories: widget.allStories,
            initialIndex: initialIndex,
          ),
        ),
      );
      widget.onTap?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              Container(
                width: widget.size,
                height: widget.size,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: widget.isViewed
                    ? null
                    : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: AppColors.storyGradient,
                        stops: const [0.0, 0.3, 0.7, 1.0],
                      ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Loading animation
                    if (_isLoading)
                      AnimatedBuilder(
                        animation: _animation,
                        builder: (context, child) {
                          return CustomPaint(
                            size: Size(widget.size - 4, widget.size - 4),
                            painter: CircleLoadingPainter(
                              progress: _animation.value,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          );
                        },
                      ),

                    // User avatar
                    Container(
                      width: widget.size - 4,
                      height: widget.size - 4,
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(widget.size / 2),
                        child: widget.story.userImage.isEmpty
                            ? CircleAvatar(
                                radius: widget.size / 2,
                                backgroundColor: AppColors.primary,
                                child: Text(
                                  widget.story.userName[0].toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 24,
                                  ),
                                ),
                              )
                            : CachedNetworkImage(
                                imageUrl: widget.story.userImage,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: Colors.grey[300],
                                ),
                                errorWidget: (context, url, error) => const Center(
                                  child: Icon(Icons.error),
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.story.isVerified)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.verified,
                      size: 16,
                      color: Colors.blue,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: widget.size,
            child: Text(
              widget.story.userName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: widget.size * 0.16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CircleLoadingPainter extends CustomPainter {
  final double progress;
  final Color color;

  CircleLoadingPainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final paint = Paint()
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    // Draw the background circle with gradient
    final backgroundGradient = SweepGradient(
      colors: AppColors.storyGradient,
      stops: const [0.0, 0.3, 0.7, 1.0],
      transform: GradientRotation(0),
    );
    paint.shader = backgroundGradient.createShader(
      Rect.fromCircle(center: center, radius: radius),
    );
    paint.color = color.withOpacity(0.2);
    canvas.drawCircle(center, radius, paint);

    // Draw the progress arc with gradient
    final progressGradient = SweepGradient(
      colors: AppColors.storyGradient,
      stops: const [0.0, 0.3, 0.7, 1.0],
      transform: GradientRotation(-3.14159 / 2 + (2 * 3.14159 * progress)),
    );
    paint.shader = progressGradient.createShader(
      Rect.fromCircle(center: center, radius: radius),
    );
    paint.color = color;

    final sweepAngle = 2 * 3.14159 * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.14159 / 2, // Start from top
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(CircleLoadingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
} 