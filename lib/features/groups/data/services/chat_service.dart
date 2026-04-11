import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/message_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Send a message to a specific group
  Future<void> sendMessage({
    required String groupId,
    required String senderId,
    required String senderName,
    String? senderPhotoUrl,
    required String text,
    String type = 'text',
  }) async {
    final messageRef = _firestore
        .collection('groups')
        .doc(groupId)
        .collection('messages')
        .doc();

    final message = MessageModel(
      id: messageRef.id,
      senderId: senderId,
      senderName: senderName,
      senderPhotoUrl: senderPhotoUrl,
      text: text,
      timestamp: DateTime.now(),
      type: type,
    );

    await messageRef.set(message.toMap());
    
    // Determine last message text for the group list
    String lastMessageText = text;
    if (type == 'image') {
      lastMessageText = '📷 Photo';
    } else if (type == 'location') {
      lastMessageText = '📍 Location';
    }

    // Update the group's "latestMessage" and increment unread counts
    final groupRef = _firestore.collection('groups').doc(groupId);
    final groupDoc = await groupRef.get();
    if (groupDoc.exists) {
      final List<String> memberIds = List<String>.from(groupDoc.data()!['memberIds'] ?? []);
      final Map<String, dynamic> updates = {
        'lastMessage': lastMessageText,
        'lastMessageSender': senderName,
        'lastMessageTime': FieldValue.serverTimestamp(),
      };
      
      // Increment unread count for everyone EXCEPT the sender
      for (final memberId in memberIds) {
        if (memberId != senderId) {
          updates['unreadCounts.$memberId'] = FieldValue.increment(1);
        }
      }
      
      await groupRef.update(updates);
    }
  }

  // Reset unread count for a specific user in a group
  Future<void> resetUnreadCount(String groupId, String userId) async {
    await _firestore.collection('groups').doc(groupId).update({
      'unreadCounts.$userId': 0,
    });
  }

  // Upload image to Firebase Storage
  Future<String> uploadImage(File file, String groupId) async {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final storageRef = FirebaseStorage.instance
        .ref()
        .child('groups')
        .child(groupId)
        .child('messages')
        .child(fileName);

    final uploadTask = storageRef.putFile(file);
    final snapshot = await uploadTask.whenComplete(() => null);
    return await snapshot.ref.getDownloadURL();
  }

  // Reactions
  Future<void> addReaction(String groupId, String messageId, String uid, String emoji) async {
    final docRef = _firestore.collection('groups').doc(groupId).collection('messages').doc(messageId);
    
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return;
      
      final data = snapshot.data()!;
      final Map<String, dynamic> reactions = Map<String, dynamic>.from(data['reactions'] ?? {});
      final List<String> currentUids = List<String>.from(reactions[emoji] ?? []);
      
      if (!currentUids.contains(uid)) {
        currentUids.add(uid);
        reactions[emoji] = currentUids;
        transaction.update(docRef, {'reactions': reactions});
      }
    });
  }

  Future<void> removeReaction(String groupId, String messageId, String uid, String emoji) async {
    final docRef = _firestore.collection('groups').doc(groupId).collection('messages').doc(messageId);
    
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return;
      
      final data = snapshot.data()!;
      final Map<String, dynamic> reactions = Map<String, dynamic>.from(data['reactions'] ?? {});
      final List<String> currentUids = List<String>.from(reactions[emoji] ?? []);
      
      if (currentUids.contains(uid)) {
        currentUids.remove(uid);
        if (currentUids.isEmpty) {
          reactions.remove(emoji);
        } else {
          reactions[emoji] = currentUids;
        }
        transaction.update(docRef, {'reactions': reactions});
      }
    });
  }

  // Edit Message
  Future<void> editMessage(String groupId, String messageId, String newText) async {
    await _firestore.collection('groups').doc(groupId).collection('messages').doc(messageId).update({
      'text': newText,
      'isEdited': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Delete Message
  Future<void> deleteMessage(String groupId, String messageId, {required bool forEveryone, String? uid}) async {
    final docRef = _firestore.collection('groups').doc(groupId).collection('messages').doc(messageId);
    
    if (forEveryone) {
      final doc = await docRef.get();
      if (!doc.exists) return;
      
      final timestamp = (doc.data()!['timestamp'] as Timestamp).toDate();
      final now = DateTime.now();
      
      // WhatsApp-style: Limit "Delete for everyone" to 1 hour
      if (now.difference(timestamp).inHours >= 1) {
        throw Exception("Cannot delete for everyone after 1 hour");
      }
      
      await docRef.update({
        'text': 'This message was deleted',
        'isDeleted': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else if (uid != null) {
      // "Delete for me" - Add user ID to deletedFor list
      await docRef.update({
        'deletedFor': FieldValue.arrayUnion([uid]),
      });
    }
  }

  // Mark as Read
  Future<void> markAsRead(String groupId, String messageId, String uid) async {
    final docRef = _firestore.collection('groups').doc(groupId).collection('messages').doc(messageId);
    await docRef.update({
      'readBy': FieldValue.arrayUnion([uid]),
    });
  }

  // Get real-time messages stream for a group
  Stream<List<MessageModel>> getMessagesStream(String groupId) {
    return _firestore
        .collection('groups')
        .doc(groupId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MessageModel.fromMap(doc.data()))
          .toList();
    });
  }
}
