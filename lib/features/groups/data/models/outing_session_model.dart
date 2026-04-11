// lib/features/groups/data/models/outing_session_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

enum OutingStatus { 
  waiting,   // Friends are joining
  thinking,  // Algorithm is calculating
  voting,    // Friends are voting on Top 3
  completed, // Location picked
  cancelled  // Session aborted
}

class OutingParticipant {
  final String uid;
  final String name;
  final String? photoUrl;
  final GeoPoint? location; // Last known location
  final GeoPoint? startLocation; // Baseline for journey progress
  final DateTime joinedAt;

  OutingParticipant({
    required this.uid,
    required this.name,
    this.photoUrl,
    this.location,
    this.startLocation,
    required this.joinedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'photoUrl': photoUrl,
      'location': location,
      'startLocation': startLocation,
      'joinedAt': Timestamp.fromDate(joinedAt),
    };
  }

  factory OutingParticipant.fromMap(Map<String, dynamic> map) {
    return OutingParticipant(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      photoUrl: map['photoUrl'],
      location: map['location'],
      startLocation: map['startLocation'],
      joinedAt: (map['joinedAt'] as Timestamp).toDate(),
    );
  }
}

class OutingSessionModel {
  final String id;
  final String groupId;
  final String creatorId;
  final OutingStatus status;
  final String category; // 'restaurant', 'cafe', etc.
  final String calculationMode; // 'KM' or 'Time'
  final int timeLimitMinutes;
  final List<OutingParticipant> participants;
  final DateTime createdAt;
  final DateTime expiresAt;
  final Map<String, dynamic>? finalLocation; // Result of the session
  final Map<String, dynamic>? winner; // The winning venue

  OutingSessionModel({
    required this.id,
    required this.groupId,
    required this.creatorId,
    required this.status,
    required this.category,
    required this.calculationMode,
    required this.timeLimitMinutes,
    required this.participants,
    required this.createdAt,
    required this.expiresAt,
    this.finalLocation,
    this.winner,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'groupId': groupId,
      'creatorId': creatorId,
      'status': status.name,
      'category': category,
      'calculationMode': calculationMode,
      'timeLimitMinutes': timeLimitMinutes,
      'participants': participants.map((p) => p.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'finalLocation': finalLocation,
      'winner': winner,
    };
  }

  factory OutingSessionModel.fromMap(Map<String, dynamic> map) {
    return OutingSessionModel(
      id: map['id'] ?? '',
      groupId: map['groupId'] ?? '',
      creatorId: map['creatorId'] ?? '',
      status: OutingStatus.values.byName(map['status'] ?? 'waiting'),
      category: map['category'] ?? 'restaurant',
      calculationMode: map['calculationMode'] ?? 'KM',
      timeLimitMinutes: map['timeLimitMinutes'] ?? 5,
      participants: (map['participants'] as List? ?? [])
          .map((p) => OutingParticipant.fromMap(p))
          .toList(),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      expiresAt: (map['expiresAt'] as Timestamp).toDate(),
      finalLocation: map['finalLocation'],
      winner: map['winner'],
    );
  }
}
