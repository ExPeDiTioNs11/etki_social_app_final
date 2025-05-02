import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:etki_social_app/models/group.dart';
import 'dart:io';

class GroupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Create a new group
  Future<Group> createGroup({
    required String name,
    required String description,
    required File? imageFile,
    required String creatorId,
    required int maxParticipants,
    required bool isUnlimited,
  }) async {
    try {
      // Upload group image if exists
      String imageUrl = '';
      if (imageFile != null) {
        final ref = _storage.ref().child('group_images/${DateTime.now().millisecondsSinceEpoch}');
        await ref.putFile(imageFile);
        imageUrl = await ref.getDownloadURL();
      }

      // Create group document
      final groupRef = _firestore.collection('groups').doc();
      final group = Group(
        id: groupRef.id,
        name: name,
        description: description,
        imageUrl: imageUrl,
        creatorId: creatorId,
        maxParticipants: maxParticipants,
        isUnlimited: isUnlimited,
        members: [creatorId], // Add creator as first member
        createdAt: DateTime.now(),
      );

      // Save to Firestore
      await groupRef.set(group.toMap());

      // Add group to user's groups
      await _firestore.collection('users').doc(creatorId).update({
        'groups': FieldValue.arrayUnion([groupRef.id])
      });

      return group;
    } catch (e) {
      throw Exception('Grup oluşturulurken bir hata oluştu: $e');
    }
  }

  // Get all groups
  Stream<List<Group>> getGroups() {
    return _firestore
        .collection('groups')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Group.fromMap(doc.data()))
          .toList();
    });
  }

  // Get user's groups
  Stream<List<Group>> getUserGroups(String userId) {
    return _firestore
        .collection('groups')
        .where('members', arrayContains: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Group.fromMap(doc.data()))
          .toList();
    });
  }

  // Join a group
  Future<void> joinGroup(String groupId, String userId) async {
    try {
      final groupRef = _firestore.collection('groups').doc(groupId);
      final groupDoc = await groupRef.get();
      
      if (!groupDoc.exists) {
        throw Exception('Grup bulunamadı');
      }

      final group = Group.fromMap(groupDoc.data()!);
      
      // Check if group is full
      if (!group.isUnlimited && group.members.length >= group.maxParticipants) {
        throw Exception('Grup dolu');
      }

      // Add user to group members
      await groupRef.update({
        'members': FieldValue.arrayUnion([userId])
      });

      // Add group to user's groups
      await _firestore.collection('users').doc(userId).update({
        'groups': FieldValue.arrayUnion([groupId])
      });
    } catch (e) {
      throw Exception('Gruba katılırken bir hata oluştu: $e');
    }
  }

  // Leave a group
  Future<void> leaveGroup(String groupId, String userId) async {
    try {
      final groupRef = _firestore.collection('groups').doc(groupId);
      
      // Remove user from group members
      await groupRef.update({
        'members': FieldValue.arrayRemove([userId])
      });

      // Remove group from user's groups
      await _firestore.collection('users').doc(userId).update({
        'groups': FieldValue.arrayRemove([groupId])
      });
    } catch (e) {
      throw Exception('Gruptan ayrılırken bir hata oluştu: $e');
    }
  }
} 