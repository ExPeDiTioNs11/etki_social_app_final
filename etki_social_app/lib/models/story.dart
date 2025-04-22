class Story {
  final String id;
  final String userId;
  final String userImage;
  final String userName;
  final List<StoryItem> items;
  final DateTime createdAt;
  final bool isViewed;
  final bool isVerified;

  Story({
    required this.id,
    required this.userId,
    required this.userImage,
    required this.userName,
    required this.items,
    required this.createdAt,
    this.isViewed = false,
    this.isVerified = false,
  });
}

class StoryItem {
  final String id;
  final String url;
  final StoryType type;
  final DateTime createdAt;
  final Duration duration;

  StoryItem({
    required this.id,
    required this.url,
    required this.type,
    required this.createdAt,
    this.duration = const Duration(seconds: 5),
  });
}

enum StoryType {
  image,
  video,
} 