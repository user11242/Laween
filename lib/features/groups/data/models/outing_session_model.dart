// lib/features/groups/data/models/outing_session_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

enum OutingStatus {
  waiting, // Friends are joining
  thinking, // Algorithm is calculating
  voting, // Friends are voting on Top 3
  completed, // Location picked
  finished, // Collecting memories (24h window)
  archived, // Session finished/closed
  cancelled, // Session aborted
}

class OutingParticipant {
  final String uid;
  final String name;
  final String? photoUrl;
  final GeoPoint? location; // Last known location
  final GeoPoint? startLocation; // Baseline for journey progress
  final DateTime joinedAt;
  final int? etaMinutes; // Real Google ETA
  final double? distanceKm; // Real Google distance
  final DateTime? lastEtaUpdate; // Throttling field
  final bool arrived;
  final bool isSosActive;

  OutingParticipant({
    required this.uid,
    required this.name,
    this.photoUrl,
    this.location,
    this.startLocation,
    required this.joinedAt,
    this.etaMinutes,
    this.distanceKm,
    this.lastEtaUpdate,
    this.arrived = false,
    this.isSosActive = false,
  });

  OutingParticipant copyWith({
    String? uid,
    String? name,
    String? photoUrl,
    GeoPoint? location,
    GeoPoint? startLocation,
    DateTime? joinedAt,
    int? etaMinutes,
    double? distanceKm,
    DateTime? lastEtaUpdate,
    bool? arrived,
    bool? isSosActive,
  }) {
    return OutingParticipant(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      location: location ?? this.location,
      startLocation: startLocation ?? this.startLocation,
      joinedAt: joinedAt ?? this.joinedAt,
      etaMinutes: etaMinutes ?? this.etaMinutes,
      distanceKm: distanceKm ?? this.distanceKm,
      lastEtaUpdate: lastEtaUpdate ?? this.lastEtaUpdate,
      arrived: arrived ?? this.arrived,
      isSosActive: isSosActive ?? this.isSosActive,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'photoUrl': photoUrl,
      'location': location,
      'startLocation': startLocation,
      'joinedAt': Timestamp.fromDate(joinedAt),
      'etaMinutes': etaMinutes,
      'distanceKm': distanceKm,
      'lastEtaUpdate': lastEtaUpdate != null ? Timestamp.fromDate(lastEtaUpdate!) : null,
      'arrived': arrived,
      'isSosActive': isSosActive,
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
      etaMinutes: map['etaMinutes'],
      distanceKm: (map['distanceKm'] as num?)?.toDouble(),
      lastEtaUpdate: (map['lastEtaUpdate'] as Timestamp?)?.toDate(),
      arrived: map['arrived'] ?? false,
      isSosActive: map['isSosActive'] ?? false,
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
  final String? firstArrivedUid; // The UID of the friend who reached first
  
  // Memories & Archive Metadata
  final List<String> favoritedBy;
  final List<String>? memoryPhotos;
  final String? memoryTitle;
  final String? memoryRecap;
  final String? coverPhotoUrl;
  final DateTime? finishedAt;
  final DateTime? scheduledAt;

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
    this.firstArrivedUid,
    this.favoritedBy = const [],
    this.memoryPhotos,
    this.memoryTitle,
    this.memoryRecap,
    this.coverPhotoUrl,
    this.finishedAt,
    this.scheduledAt,
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
      'firstArrivedUid': firstArrivedUid,
      'favoritedBy': favoritedBy,
      'memoryPhotos': memoryPhotos,
      'memoryTitle': memoryTitle,
      'memoryRecap': memoryRecap,
      'coverPhotoUrl': coverPhotoUrl,
      'finishedAt': finishedAt != null ? Timestamp.fromDate(finishedAt!) : null,
      'scheduledAt': scheduledAt != null ? Timestamp.fromDate(scheduledAt!) : null,
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
      firstArrivedUid: map['firstArrivedUid'],
      favoritedBy: List<String>.from(map['favoritedBy'] ?? []),
      memoryPhotos: map['memoryPhotos'] != null ? List<String>.from(map['memoryPhotos']) : null,
      memoryTitle: map['memoryTitle'],
      memoryRecap: map['memoryRecap'],
      coverPhotoUrl: map['coverPhotoUrl'],
      finishedAt: map['finishedAt'] != null ? (map['finishedAt'] as Timestamp).toDate() : null,
      scheduledAt: map['scheduledAt'] != null ? (map['scheduledAt'] as Timestamp).toDate() : null,
    );
  }

  factory OutingSessionModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    return OutingSessionModel.fromMap({...doc.data()!, 'id': doc.id});
  }
}
