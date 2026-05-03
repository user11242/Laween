// lib/features/groups/data/models/group_model.dart

import 'dart:convert';
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
  final Map<String, dynamic>
  typingUsers; // userId -> {isTyping: bool, userName: String}
  final List<String>
  pendingPhoneNumbers; // Normalized numbers for users not yet on app

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
    this.typingUsers = const {},
    this.pendingPhoneNumbers = const [],
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
      'lastMessageTime': lastMessageTime != null
          ? Timestamp.fromDate(lastMessageTime!)
          : null,
      'unreadCounts': unreadCounts,
      'typingUsers': typingUsers,
      'pendingPhoneNumbers': pendingPhoneNumbers,
    };
  }

  static String? _sanitize(dynamic input) {
    if (input == null) return null;
    String str = input.toString();
    List<int> cleanUnits = [];
    for (int i = 0; i < str.length; i++) {
      int c = str.codeUnitAt(i);
      if (c >= 0xD800 && c <= 0xDBFF) { // High surrogate
        if (i + 1 < str.length) {
          int n = str.codeUnitAt(i + 1);
          if (n >= 0xDC00 && n <= 0xDFFF) { // Valid pair
            cleanUnits.add(c);
            cleanUnits.add(n);
            i++;
          } else {
            cleanUnits.add(0xFFFD); // Replacement char
          }
        } else {
          cleanUnits.add(0xFFFD); // Replacement char
        }
      } else if (c >= 0xDC00 && c <= 0xDFFF) { // Unpaired low surrogate
        cleanUnits.add(0xFFFD); // Replacement char
      } else {
        cleanUnits.add(c);
      }
    }
    return String.fromCharCodes(cleanUnits);
  }

  factory GroupModel.fromMap(Map<String, dynamic> map) {
    return GroupModel(
      id: map['id'] ?? '',
      name: _sanitize(map['name']) ?? '',
      photoUrl: map['photoUrl'],
      creatorId: map['creatorId'] ?? '',
      memberIds: List<String>.from(map['memberIds'] ?? []),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      groupCode: map['groupCode'],
      lastMessage: _sanitize(map['lastMessage']),
      lastMessageSender: _sanitize(map['lastMessageSender']),
      lastMessageTime: map['lastMessageTime'] != null
          ? (map['lastMessageTime'] as Timestamp).toDate()
          : null,
      unreadCounts: Map<String, int>.from(map['unreadCounts'] ?? {}),
      typingUsers: Map<String, dynamic>.from(map['typingUsers'] ?? {}).map((key, value) {
        if (value is Map) {
          final newValue = Map<String, dynamic>.from(value);
          if (newValue['userName'] != null) {
            newValue['userName'] = _sanitize(newValue['userName']);
          }
          return MapEntry(key, newValue);
        }
        return MapEntry(key, value);
      }),
      pendingPhoneNumbers: List<String>.from(map['pendingPhoneNumbers'] ?? []),
    );
  }
}
