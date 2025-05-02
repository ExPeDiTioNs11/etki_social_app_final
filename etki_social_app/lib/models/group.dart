// Group model class to handle group data structure
class Group {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final String creatorId;
  final int maxParticipants;
  final bool isUnlimited;
  final List<String> members;
  final DateTime createdAt;

  Group({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.creatorId,
    required this.maxParticipants,
    required this.isUnlimited,
    required this.members,
    required this.createdAt,
  });

  // Convert Group object to Map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'creatorId': creatorId,
      'maxParticipants': maxParticipants,
      'isUnlimited': isUnlimited,
      'members': members,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Create Group object from Firebase Map
  factory Group.fromMap(Map<String, dynamic> map) {
    return Group(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      creatorId: map['creatorId'] ?? '',
      maxParticipants: map['maxParticipants'] ?? 0,
      isUnlimited: map['isUnlimited'] ?? false,
      members: List<String>.from(map['members'] ?? []),
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
} 