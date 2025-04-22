import 'package:uuid/uuid.dart';

enum NotificationType {
  groupInvite,
  postLike,
  commentReply,
  followRequest,
  securityAlert,
}

class NotificationModel {
  final String id;
  final NotificationType type;
  final String userId; // Bildirimi gönderen kullanıcı
  final String? userImage; // Kullanıcı profil resmi
  final String? userName; // Kullanıcı adı
  final String? groupId; // Grup daveti için
  final String? groupName; // Grup adı
  final String? groupImage; // Grup resmi
  final String? postId; // Beğenilen gönderi için
  final String? postImage; // Gönderi resmi
  final String? commentId; // Yorum yanıtı için
  final DateTime createdAt;
  bool isRead;
  bool isAccepted;
  bool isRejected;

  NotificationModel({
    String? id,
    required this.type,
    required this.userId,
    this.userImage,
    this.userName,
    this.groupId,
    this.groupName,
    this.groupImage,
    this.postId,
    this.postImage,
    this.commentId,
    DateTime? createdAt,
    this.isRead = false,
    this.isAccepted = false,
    this.isRejected = false,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  String get message {
    switch (type) {
      case NotificationType.groupInvite:
        return '$userName sizi $groupName grubuna davet etti';
      case NotificationType.postLike:
        return '$userName gönderinizi beğendi';
      case NotificationType.commentReply:
        return '$userName yorumunuza yanıt verdi';
      case NotificationType.followRequest:
        return '$userName sizi takip etmek istiyor';
      case NotificationType.securityAlert:
        return 'Hesabınızda şüpheli bir aktivite tespit edildi';
    }
  }
} 