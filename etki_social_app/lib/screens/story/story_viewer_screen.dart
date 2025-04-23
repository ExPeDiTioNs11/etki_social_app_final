import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:async';
import '../../models/story.dart';
import '../../theme/colors.dart';

class StoryViewerScreen extends StatefulWidget {
  final List<Story> stories;
  final int initialIndex;

  const StoryViewerScreen({
    super.key,
    required this.stories,
    this.initialIndex = 0,
  });

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen> with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _progressController;
  VideoPlayerController? _videoController;
  int _currentStoryIndex = 0;
  int _currentItemIndex = 0;
  bool _isPaused = false;
  double _dragOffset = 0.0;
  bool _isDragging = false;
  Timer? _progressTimer;
  double _progressValue = 0.0;
  bool _showOverlay = true;
  double _pageValue = 0.0;

  @override
  void initState() {
    super.initState();
    _currentStoryIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );

    _pageController.addListener(() {
      setState(() {
        _pageValue = _pageController.page ?? 0.0;
      });
    });

    _loadCurrentStory();
    _startProgress();
  }

  void _startProgress() {
    if (_progressTimer != null) {
      _progressTimer!.cancel();
    }

    _progressTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!_isPaused && !_isDragging) {
        setState(() {
          _progressValue += 0.01;
          if (_progressValue >= 1.0) {
            _progressValue = 0.0;
            _nextStory();
          }
        });
      }
    });

    _videoController?.play();
  }

  void _stopProgress() {
    _progressTimer?.cancel();
    _videoController?.pause();
  }

  void _loadCurrentStory() {
    final currentStory = widget.stories[_currentStoryIndex];
    final currentItem = currentStory.items[_currentItemIndex];

    if (currentItem.type == StoryType.video) {
      _videoController?.dispose();
      _videoController = VideoPlayerController.network(currentItem.url)
        ..initialize().then((_) {
          setState(() {});
          _startProgress();
        });
    } else {
      _videoController?.dispose();
      _videoController = null;
      _startProgress();
    }
  }

  void _nextStory() {
    if (_currentStoryIndex < widget.stories.length - 1) {
      setState(() {
        _progressValue = 0.0;
        _currentStoryIndex++;
        _currentItemIndex = 0;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      ).then((_) {
        _loadCurrentStory();
      });
    } else {
      Navigator.pop(context);
    }
  }

  void _previousStory() {
    if (_currentStoryIndex > 0) {
      setState(() {
        _progressValue = 0.0;
        _currentStoryIndex--;
        _currentItemIndex = 0;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      ).then((_) {
        _loadCurrentStory();
      });
    }
  }

  void _handlePageChanged(int index) {
    if (index != _currentStoryIndex) {
      setState(() {
        _progressValue = 0.0;
        _currentStoryIndex = index;
        _currentItemIndex = 0;
      });
      _loadCurrentStory();
    }
  }

  void _handleVerticalDragStart(DragStartDetails details) {
    setState(() {
      _isDragging = true;
      _stopProgress();
    });
  }

  void _handleVerticalDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.delta.dy;
    });
  }

  void _handleVerticalDragEnd(DragEndDetails details) {
    if (_dragOffset.abs() > 100) {
      Navigator.pop(context);
    } else {
      setState(() {
        _dragOffset = 0.0;
        _isDragging = false;
        _startProgress();
      });
    }
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _pageController.dispose();
    _progressController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  Widget _buildStoryContent(Story story, StoryItem item, int index) {
    final isCurrentPage = index == _currentStoryIndex;
    final pageOffset = index - _currentStoryIndex;
    final isAdjacent = (pageOffset.abs() <= 1.0);
    
    // Sadece aktif ve komşu story'ler için transform uygula
    if (!isAdjacent) {
      return Stack(
        key: ValueKey(item.id),
        children: [
          // Story Media
          if (item.type == StoryType.image)
            Image.network(
              item.url,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            )
          else if (_videoController?.value.isInitialized ?? false)
            AspectRatio(
              aspectRatio: _videoController!.value.aspectRatio,
              child: VideoPlayer(_videoController!),
            )
          else
            const Center(child: CircularProgressIndicator()),

          // Overlay Content
          AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: _showOverlay ? 1.0 : 0.0,
            child: Column(
              children: [
                // Progress Bars
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Row(
                    children: List.generate(
                      story.items.length,
                      (index) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: LinearProgressIndicator(
                            value: index == _currentItemIndex
                                ? _progressValue
                                : index < _currentItemIndex
                                    ? 1.0
                                    : 0.0,
                            backgroundColor: Colors.white.withOpacity(0.3),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // User Info
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundImage: story.userImage.isNotEmpty
                            ? NetworkImage(story.userImage)
                            : null,
                        child: story.userImage.isEmpty
                            ? Text(
                                story.userName[0].toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            story.userName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            '${_currentItemIndex + 1}/${story.items.length}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Navigation Gestures
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _previousStory,
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: _nextStory,
                ),
              ),
            ],
          ),
        ],
      );
    }

    final scale = 1.0 - (pageOffset.abs() * 0.02);
    final rotation = pageOffset * 0.05;
    final translateX = pageOffset * MediaQuery.of(context).size.width * 0.1;

    return Transform(
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.001)
        ..translate(translateX)
        ..rotateY(rotation)
        ..scale(scale),
      alignment: Alignment.center,
      child: Stack(
        key: ValueKey(item.id),
        children: [
          // Story Media
          if (item.type == StoryType.image)
            Image.network(
              item.url,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            )
          else if (_videoController?.value.isInitialized ?? false)
            AspectRatio(
              aspectRatio: _videoController!.value.aspectRatio,
              child: VideoPlayer(_videoController!),
            )
          else
            const Center(child: CircularProgressIndicator()),

          // Overlay Content
          AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: _showOverlay ? 1.0 : 0.0,
            child: Column(
              children: [
                // Progress Bars
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Row(
                    children: List.generate(
                      story.items.length,
                      (index) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: LinearProgressIndicator(
                            value: index == _currentItemIndex
                                ? _progressValue
                                : index < _currentItemIndex
                                    ? 1.0
                                    : 0.0,
                            backgroundColor: Colors.white.withOpacity(0.3),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // User Info
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundImage: story.userImage.isNotEmpty
                            ? NetworkImage(story.userImage)
                            : null,
                        child: story.userImage.isEmpty
                            ? Text(
                                story.userName[0].toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            story.userName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            '${_currentItemIndex + 1}/${story.items.length}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Navigation Gestures
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _previousStory,
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: _nextStory,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onVerticalDragStart: _handleVerticalDragStart,
        onVerticalDragUpdate: _handleVerticalDragUpdate,
        onVerticalDragEnd: _handleVerticalDragEnd,
        onTapDown: (_) {
          setState(() {
            _isPaused = true;
            _showOverlay = false;
            _stopProgress();
          });
        },
        onTapUp: (_) {
          setState(() {
            _isPaused = false;
            _showOverlay = true;
            _startProgress();
          });
        },
        onLongPressStart: (_) {
          setState(() {
            _isPaused = true;
            _showOverlay = false;
            _stopProgress();
          });
        },
        onLongPressEnd: (_) {
          setState(() {
            _isPaused = false;
            _showOverlay = true;
            _startProgress();
          });
        },
        child: Transform.translate(
          offset: Offset(0, _dragOffset),
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: _handlePageChanged,
            itemCount: widget.stories.length,
            itemBuilder: (context, index) {
              final story = widget.stories[index];
              final item = story.items[_currentItemIndex];
              return _buildStoryContent(story, item, index);
            },
          ),
        ),
      ),
    );
  }
} 