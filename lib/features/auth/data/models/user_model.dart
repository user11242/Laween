// lib/features/auth/models/user_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  // --- IDENTIFIERS ---
  final String uid;
  final String email;
  final String phone; // ✅ Added back to main fields
  final String authProvider; // 'email' | 'google'

  // --- PUBLIC PROFILE ---
  final String name;
  final String photoUrl;
  final String language; // ✅ Added for localization

  // --- LEGAL ---
  final bool acceptedTerms;
  final DateTime createdAt;

  // --- TRACKING & PRIVACY ---
  final bool isTrackingActive;
  final bool isGhostMode;
  final String activeGroupId;
  final String activeSessionId;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    this.authProvider = 'email',
    this.phone = '',
    this.photoUrl = '',
    this.acceptedTerms = false,
    this.language = 'en',
    this.isTrackingActive = false,
    this.isGhostMode = false,
    this.activeGroupId = '',
    this.activeSessionId = '',
    required this.createdAt,
  });

  // ==========================================================
  // 1. READ (From Firebase)
  // ==========================================================
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      authProvider: map['authProvider'] ?? 'email',
      phone: map['phone'] ?? '',
      name: map['name'] ?? '',
      acceptedTerms: map['acceptedTerms'] ?? false,
      photoUrl: map['photoUrl'] ?? '',
      language: map['language'] ?? 'en',
      isTrackingActive: map['isTrackingActive'] ?? false,
      isGhostMode: map['isGhostMode'] ?? false,
      activeGroupId: map['activeGroupId'] ?? '',
      activeSessionId: map['activeSessionId'] ?? '',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  // ==========================================================
  // 2. WRITE (To Firebase)
  // ==========================================================
  Map<String, dynamic> toMap() {
    return {
      "uid": uid,
      "email": email,
      "authProvider": authProvider,
      "phone": phone,
      "name": name,
      "name_lower": name.toLowerCase(),
      "photoUrl": photoUrl,
      "language": language,
      "acceptedTerms": acceptedTerms,
      "isTrackingActive": isTrackingActive,
      "isGhostMode": isGhostMode,
      "activeGroupId": activeGroupId,
      "activeSessionId": activeSessionId,
      "createdAt": Timestamp.fromDate(createdAt),
    };
  }
}
