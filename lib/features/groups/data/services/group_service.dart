// lib/features/groups/data/services/group_service.dart

import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../../../core/utils/numeric_utils.dart';
import '../models/group_model.dart';

class GroupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Generate a random 6-digit numeric code
  Future<String> _generateUniqueGroupCode() async {
    final random = Random();
    while (true) {
      final code = (100000 + random.nextInt(900000)).toString();
      final query = await _firestore
          .collection('groups')
          .where('groupCode', isEqualTo: code)
          .limit(1)
          .get();
      if (query.docs.isEmpty) return code;
    }
  }

  Future<Map<String, dynamic>?> createGroup({
    required String name,
    required List<String> memberPhoneNumbers,
    File? imageFile,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return {"error": "User not authenticated"};

    try {
      final groupId = _firestore.collection('groups').doc().id;
      String? photoUrl;

      if (imageFile != null && await imageFile.exists()) {
        final ref = _storage.ref().child('groups/$groupId/photo.jpg');
        final metadata = SettableMetadata(contentType: 'image/jpeg');
        await ref.putFile(imageFile, metadata);
        photoUrl = await ref.getDownloadURL();
      }

      final groupCode = await _generateUniqueGroupCode();

      // 🔍 RESOLVE MEMBERS (App Users vs. Invites)
      final List<String> resolvedMemberIds = [user.uid];
      final List<String> pendingPhoneNumbers = [];

      // Normalize unique phone numbers
      final normalizedPhones = memberPhoneNumbers
          .map((p) => NumericUtils.normalize(p, clean: true))
          .where((p) => p.isNotEmpty)
          .toSet()
          .toList();

      if (normalizedPhones.isNotEmpty) {
        // Firestore whereIn only allows 30 items per query
        // We chunk the lookup to handle many contacts
        const int chunkSize = 30;
        for (var i = 0; i < normalizedPhones.length; i += chunkSize) {
          final end = (i + chunkSize < normalizedPhones.length)
              ? i + chunkSize
              : normalizedPhones.length;
          final chunk = normalizedPhones.sublist(i, end);

          final query = await _firestore
              .collection('users')
              .where('phone', whereIn: chunk)
              .get();

          final foundUids = query.docs.map((d) => d.id).toList();
          final foundPhones = query.docs
              .map((d) => d.data()['phone'] as String)
              .toList();

          resolvedMemberIds.addAll(foundUids);

          // Identify which chunk numbers were NOT found
          for (var p in chunk) {
            if (!foundPhones.contains(p)) {
              pendingPhoneNumbers.add(p);
            }
          }
        }
      }

      final group = GroupModel(
        id: groupId,
        name: name,
        photoUrl: photoUrl,
        creatorId: user.uid,
        memberIds: resolvedMemberIds.toSet().toList(), // Ensure uniqueness
        createdAt: DateTime.now(),
        lastMessageTime: DateTime.now(), // 🚀 Set this so it appears at the top
        groupCode: groupCode,
        pendingPhoneNumbers: pendingPhoneNumbers,
      );

      await _firestore.collection('groups').doc(groupId).set(group.toMap());
      return {"groupCode": groupCode, "groupId": groupId};
    } catch (e) {
      return {"error": e.toString()};
    }
  }

  Future<GroupModel?> joinGroupWithCode(String code, String userId) async {
    // Brute-force protection
    final activityDoc = _firestore.collection('user_activity').doc(userId);
    final activity = await activityDoc.get();

    if (activity.exists) {
      final data = activity.data();
      final count = data?['failedJoinAttempts'] ?? 0;
      final lastFailed = (data?['lastFailedAttempt'] as Timestamp?)?.toDate();

      if (count >= 5 &&
          lastFailed != null &&
          DateTime.now().difference(lastFailed).inMinutes < 30) {
        throw Exception("Too many attempts. Locked for 30 mins.");
      }
    }

    final query = await _firestore
        .collection('groups')
        .where('groupCode', isEqualTo: code)
        .limit(1)
        .get();
    if (query.docs.isEmpty) {
      await activityDoc.set({
        'failedJoinAttempts': FieldValue.increment(1),
        'lastFailedAttempt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      throw Exception("Invalid group code.");
    }

    final groupDoc = query.docs.first;
    final memberIds = List<String>.from(groupDoc.data()['memberIds'] ?? []);
    if (memberIds.contains(userId)) throw Exception("Already a member.");

    // Success: Reset failures and join
    await activityDoc.set({'failedJoinAttempts': 0}, SetOptions(merge: true));
    await _firestore.collection('groups').doc(groupDoc.id).update({
      'memberIds': FieldValue.arrayUnion([userId]),
      'lastMessageTime': FieldValue.serverTimestamp(), // 🚀 Bring to top on join
    });

    // Fetch the updated group model to return
    final updatedDoc = await _firestore
        .collection('groups')
        .doc(groupDoc.id)
        .get();
    return GroupModel.fromMap(updatedDoc.data()!);
  }

  Future<void> leaveGroup(String groupId, String userId) async {
    final groupRef = _firestore.collection('groups').doc(groupId);
    final groupDoc = await groupRef.get();

    if (!groupDoc.exists) throw Exception("Group not found");

    final data = groupDoc.data()!;
    final List<String> memberIds = List<String>.from(data['memberIds'] ?? []);

    if (!memberIds.contains(userId)) throw Exception("Not a member");

    await groupRef.update({
      'memberIds': FieldValue.arrayRemove([userId]),
    });
  }

  Future<void> deleteGroup(String groupId, String userId) async {
    final groupRef = _firestore.collection('groups').doc(groupId);
    final groupDoc = await groupRef.get();

    if (!groupDoc.exists) throw Exception("Group not found");

    final data = groupDoc.data()!;
    if (data['creatorId'] != userId) {
      throw Exception("Only the creator can delete the group");
    }

    // Delete all messages subcollection first
    final messages = await groupRef.collection('messages').get();
    final batch = _firestore.batch();
    for (var doc in messages.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();

    // Finally delete the group document
    await groupRef.delete();
  }

  Future<void> updateGroup(
    String groupId, {
    String? newName,
    File? newImageFile,
  }) async {
    final groupRef = _firestore.collection('groups').doc(groupId);
    final groupDoc = await groupRef.get();

    if (!groupDoc.exists) throw Exception("Group not found");

    Map<String, dynamic> updates = {};

    if (newName != null && newName.trim().isNotEmpty) {
      updates['name'] = newName.trim();
    }

    if (newImageFile != null && await newImageFile.exists()) {
      final ref = _storage.ref().child('groups/$groupId/photo.jpg');
      final metadata = SettableMetadata(contentType: 'image/jpeg');
      await ref.putFile(newImageFile, metadata);
      final photoUrl = await ref.getDownloadURL();
      updates['photoUrl'] = photoUrl;
    }

    if (updates.isNotEmpty) {
      await groupRef.update(updates);
    }
  }

  Stream<List<Map<String, dynamic>>> getGroupMedia(String groupId) {
    return _firestore
        .collection('groups')
        .doc(groupId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(50) // Increased limit since we filter in memory
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => doc.data())
              .where(
                (data) =>
                    data['type'] == 'image' ||
                    (data['mediaUrls'] as List?)?.isNotEmpty == true,
              )
              .toList(),
        );
  }

  Stream<List<Map<String, dynamic>>> getGroupLocations(String groupId) {
    return _firestore
        .collection('groups')
        .doc(groupId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => doc.data())
              .where((data) => data['type'] == 'location')
              .toList(),
        );
  }
}
