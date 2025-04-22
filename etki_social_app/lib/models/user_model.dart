import 'package:uuid/uuid.dart';

class User {
  final String id;
  final String username;
  final String email;
  final String? profileImageUrl;
  final String? bio;
  final List<String> followers;
  final List<String> following;
  final DateTime createdAt;

  User({
    String? id,
    required this.username,
    required this.email,
    this.profileImageUrl,
    this.bio,
    List<String>? followers,
    List<String>? following,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        followers = followers ?? [],
        following = following ?? [],
        createdAt = createdAt ?? DateTime.now();

  // Convert User to Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'profileImageUrl': profileImageUrl,
      'bio': bio,
      'followers': followers,
      'following': following,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Create User from Map
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      username: map['username'],
      email: map['email'],
      profileImageUrl: map['profileImageUrl'],
      bio: map['bio'],
      followers: List<String>.from(map['followers'] ?? []),
      following: List<String>.from(map['following'] ?? []),
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
} 