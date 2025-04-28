import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Comment {
  final String id;
  final String userId;
  final String content;
  final DateTime createdAt;
  final List<Comment> replies;
  final List<String> likes;
  final String? userAvatar;
  final String? username;
  final bool isVerified;

  Comment({
    String? id,
    required this.userId,
    required this.content,
    DateTime? createdAt,
    List<Comment>? replies,
    List<String>? likes,
    this.userAvatar,
    this.username,
    bool? isVerified,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        likes = likes ?? [],
        replies = replies ?? [],
        isVerified = isVerified ?? false;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
      'replies': replies.map((reply) => reply.toMap()).toList(),
      'likes': likes,
      'userAvatar': userAvatar,
      'username': username,
      'isVerified': isVerified,
    };
  }

  factory Comment.fromMap(Map<String, dynamic> map) {
    return Comment(
      id: map['id'],
      userId: map['userId'],
      content: map['content'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      replies: (map['replies'] as List?)
          ?.map((reply) => Comment.fromMap(reply))
          .toList() ?? [],
      likes: List<String>.from(map['likes'] ?? []),
      userAvatar: map['userAvatar'],
      username: map['username'],
      isVerified: map['isVerified'] ?? false,
    );
  }
}

class MissionParticipant {
  final String userId;
  final String? username;
  final String? userAvatar;
  final bool isVerified;
  final MissionStatus status;
  final String? submissionContent;
  final List<String>? submissionImages;
  final DateTime? submissionDate;

  MissionParticipant({
    required this.userId,
    this.username,
    this.userAvatar,
    this.isVerified = false,
    this.status = MissionStatus.pending,
    this.submissionContent,
    this.submissionImages,
    this.submissionDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'username': username,
      'userAvatar': userAvatar,
      'isVerified': isVerified,
      'status': status.toString(),
      'submissionContent': submissionContent,
      'submissionImages': submissionImages,
      'submissionDate': submissionDate != null ? Timestamp.fromDate(submissionDate!) : null,
    };
  }

  factory MissionParticipant.fromMap(Map<String, dynamic> map) {
    return MissionParticipant(
      userId: map['userId'],
      username: map['username'],
      userAvatar: map['userAvatar'],
      isVerified: map['isVerified'] ?? false,
      status: MissionStatus.values.firstWhere(
        (e) => e.toString() == map['status'],
        orElse: () => MissionStatus.pending,
      ),
      submissionContent: map['submissionContent'],
      submissionImages: List<String>.from(map['submissionImages'] ?? []),
      submissionDate: map['submissionDate'] != null
          ? (map['submissionDate'] as Timestamp).toDate()
          : null,
    );
  }
}

enum MissionStatus {
  pending, // Katılım talebi bekliyor
  accepted, // Katılım talebi kabul edildi
  inProgress, // Görev devam ediyor
  submitted, // Görev tamamlandı, onay bekliyor
  completed, // Görev tamamlandı ve onaylandı
  rejected, // Görev reddedildi
}

class Post {
  final String id;
  final String userId;
  final String content;
  final List<String>? imageUrls;
  final String? missionTitle;
  final String? missionDescription;
  final int? missionReward; // Görev için verilecek coin miktarı
  final int? maxParticipants; // Maximum katılımcı sayısı
  final DateTime? missionDeadline; // Görev son tarihi
  final List<MissionParticipant>? missionParticipants; // Görev katılımcıları
  final PostType type;
  final List<String> likes;
  final List<Comment> comments;
  final DateTime createdAt;
  final bool isVerified;

  Post({
    String? id,
    required this.userId,
    required this.content,
    this.imageUrls,
    this.missionTitle,
    this.missionDescription,
    this.missionReward,
    this.maxParticipants,
    this.missionDeadline,
    this.missionParticipants,
    required this.type,
    List<String>? likes,
    List<Comment>? comments,
    DateTime? createdAt,
    bool? isVerified,
  })  : id = id ?? const Uuid().v4(),
        likes = likes ?? [],
        comments = comments ?? [],
        createdAt = createdAt ?? DateTime.now(),
        isVerified = isVerified ?? false;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'content': content,
      'imageUrls': imageUrls,
      'missionTitle': missionTitle,
      'missionDescription': missionDescription,
      'missionReward': missionReward,
      'maxParticipants': maxParticipants,
      'missionDeadline': missionDeadline != null ? Timestamp.fromDate(missionDeadline!) : null,
      'missionParticipants': missionParticipants?.map((p) => p.toMap()).toList(),
      'type': type.toString(),
      'likes': likes,
      'comments': comments.map((comment) => comment.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'isVerified': isVerified,
    };
  }

  factory Post.fromMap(Map<String, dynamic> map, {String? id}) {
    return Post(
      id: id ?? map['id'],
      userId: map['userId'] ?? map['creatorId'] ?? '',
      content: map['content'] ?? '',
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      missionTitle: map['missionTitle'],
      missionDescription: map['missionDescription'],
      missionReward: map['missionReward'],
      maxParticipants: map['maxParticipants'],
      missionDeadline: map['missionDeadline'] != null
          ? (map['missionDeadline'] as Timestamp).toDate()
          : null,
      missionParticipants: (map['missionParticipants'] as List?)
          ?.map((p) => MissionParticipant.fromMap(p))
          .toList(),
      type: PostType.values.firstWhere(
        (e) => e.toString() == map['type'],
        orElse: () => PostType.text,
      ),
      likes: List<String>.from(map['likes'] ?? []),
      comments: (map['comments'] as List?)
          ?.map((comment) => Comment.fromMap(comment))
          .toList() ?? [],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      isVerified: map['isVerified'] ?? false,
    );
  }

  bool get isMissionAvailable =>
      type == PostType.mission &&
      (maxParticipants == null ||
          (missionParticipants?.length ?? 0) < maxParticipants!) &&
      (missionDeadline == null || missionDeadline!.isAfter(DateTime.now()));
}

enum PostType {
  text,
  image,
  mission,
} 