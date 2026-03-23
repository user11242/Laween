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

  // --- METADATA ---
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    this.authProvider = 'email', // Default to email for backward compatibility
    this.phone = '', // Default empty if not provided
    this.photoUrl = '',
    this.acceptedTerms = false,
    this.language = 'en', // Default to English
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
      // Handle Timestamp conversion safely
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  // ==========================================================
  // 2. WRITE (To Firebase - users & lock collections)
  // ==========================================================
  Map<String, dynamic> toMap() {
    return {
      // Identity
      "uid": uid,
      "email": email, // ✅ Vital for account management
      "authProvider": authProvider,
      "phone": phone, // ✅ Vital for account management
      // Search Helpers
      "name": name,
      "name_lower": name.toLowerCase(), // ✅ Kept your search optimization
      // Profile
      "photoUrl": photoUrl,
      "language": language, // ✅ Persist language
      // State
      "acceptedTerms": acceptedTerms,
      "createdAt": Timestamp.fromDate(createdAt),
    };
  }
}
