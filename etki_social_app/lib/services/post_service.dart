import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:etki_social_app/services/auth_service.dart';

class PostService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  Future<void> toggleLike(String postId) async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return;

    final postRef = _firestore.collection('posts').doc(postId);
    
    await _firestore.runTransaction((transaction) async {
      final postDoc = await transaction.get(postRef);
      if (!postDoc.exists) return;

      final likes = List<String>.from(postDoc.data()?['likes'] ?? []);
      if (likes.contains(currentUser.uid)) {
        likes.remove(currentUser.uid);
      } else {
        likes.add(currentUser.uid);
      }

      transaction.update(postRef, {'likes': likes});
    });
  }
} 