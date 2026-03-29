// lib/features/groups/data/models/message_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String senderId;
  final String senderName;
  final String? senderPhotoUrl;
  final String text;
  final DateTime timestamp;
  final String type; // 'text', 'image', 'system', 'outing'
  final String? outingSessionId;
  final Map<String, List<String>> reactions; // emoji -> list of uids
  final List<String> readBy; // list of uids
  final bool isDeleted;
  final bool isEdited;
  final DateTime? updatedAt;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.senderPhotoUrl,
    required this.text,
    required this.timestamp,
    this.type = 'text',
    this.outingSessionId,
    this.reactions = const {},
    this.readBy = const [],
    this.isDeleted = false,
    this.isEdited = false,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'senderName': senderName,
      'senderPhotoUrl': senderPhotoUrl,
      'text': text,
      'timestamp': Timestamp.fromDate(timestamp),
      'type': type,
      'outingSessionId': outingSessionId,
      'reactions': reactions,
      'readBy': readBy,
      'isDeleted': isDeleted,
      'isEdited': isEdited,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      id: map['id'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      senderPhotoUrl: map['senderPhotoUrl'],
      text: map['text'] ?? '',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      type: map['type'] ?? 'text',
      outingSessionId: map['outingSessionId'],
      reactions: Map<String, List<String>>.from(
        (map['reactions'] as Map? ?? {}).map(
          (k, v) => MapEntry(k, List<String>.from(v)),
        ),
      ),
      readBy: List<String>.from(map['readBy'] ?? []),
      isDeleted: map['isDeleted'] ?? false,
      isEdited: map['isEdited'] ?? false,
      updatedAt: map['updatedAt'] != null ? (map['updatedAt'] as Timestamp).toDate() : null,
    );
  }
}
