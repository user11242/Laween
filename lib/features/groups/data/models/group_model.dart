// lib/features/groups/data/models/group_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class GroupModel {
  final String id;
  final String name;
  final String? photoUrl;
  final String creatorId;
  final List<String> memberIds;
  final DateTime createdAt;
  final String? groupCode;
  final String? lastMessage;
  final String? lastMessageSender;
  final DateTime? lastMessageTime;
  final Map<String, int> unreadCounts; // userId -> count

  GroupModel({
    required this.id,
    required this.name,
    this.photoUrl,
    required this.creatorId,
    required this.memberIds,
    required this.createdAt,
    this.groupCode,
    this.lastMessage,
    this.lastMessageSender,
    this.lastMessageTime,
    this.unreadCounts = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'photoUrl': photoUrl,
      'creatorId': creatorId,
      'memberIds': memberIds,
      'createdAt': Timestamp.fromDate(createdAt),
      'groupCode': groupCode,
      'lastMessage': lastMessage,
      'lastMessageSender': lastMessageSender,
      'lastMessageTime': lastMessageTime != null ? Timestamp.fromDate(lastMessageTime!) : null,
      'unreadCounts': unreadCounts,
    };
  }

  factory GroupModel.fromMap(Map<String, dynamic> map) {
    return GroupModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      photoUrl: map['photoUrl'],
      creatorId: map['creatorId'] ?? '',
      memberIds: List<String>.from(map['memberIds'] ?? []),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      groupCode: map['groupCode'],
      lastMessage: map['lastMessage'],
      lastMessageSender: map['lastMessageSender'],
      lastMessageTime: map['lastMessageTime'] != null ? (map['lastMessageTime'] as Timestamp).toDate() : null,
      unreadCounts: Map<String, int>.from(map['unreadCounts'] ?? {}),
    );
  }
}
