// lib/core/services/favorite_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class FavoriteService {
  static final FavoriteService _instance = FavoriteService._internal();
  factory FavoriteService() => _instance;
  FavoriteService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  /// Adds a place to user's favoritePlaces collection
  Future<void> addFavoritePlace({
    required Map<String, dynamic> place,
    String source = "explore",
    bool visited = false,
    String? sourceOutingId,
    String? groupId,
  }) async {
    final String? currentUid = _uid;
    if (currentUid == null) {
      debugPrint("❌ [FavoriteService] ERROR: No authenticated user found!");
      return;
    }
    
    final String userId = currentUid;
    final String? placeId = place['id']?.toString() ?? place['placeId']?.toString();
    
    if (placeId == null) {
      debugPrint("❌ [FavoriteService] ERROR: placeId is null for venue: ${place['name']}");
      return;
    }

    final docRef = _firestore.collection('users').doc(userId).collection('favoritePlaces').doc(placeId);

    // Extract image URL/reference
    String? imageUrl;
    if (place['photos'] != null && place['photos'].isNotEmpty) {
      imageUrl = place['photos'][0]['name'];
    } else if (place['photoReference'] != null) {
      imageUrl = place['photoReference'];
    } else if (place['imageUrl'] != null) {
      imageUrl = place['imageUrl'];
    }

    final Map<String, dynamic> favoriteData = {
      'userId': userId,
      'placeId': placeId,
      'placeName': place['displayName']?['text'] ?? place['name'] ?? place['placeName'] ?? "Unknown Place",
      'latitude': place['location']?['latitude'] ?? place['latitude'],
      'longitude': place['location']?['longitude'] ?? place['longitude'],
      'address': place['formattedAddress'] ?? place['address'],
      'imageUrl': imageUrl,
      'category': place['primaryType'] ?? place['category'],
      'rating': place['rating'],
      'userRatingCount': place['userRatingCount'] ?? place['ratingCount'],
      'source': source,
      'visited': visited,
      'sourceOutingId': sourceOutingId,
      'groupId': groupId,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    try {
      final docSnapshot = await docRef.get();
      if (!docSnapshot.exists) {
        favoriteData['createdAt'] = FieldValue.serverTimestamp();
      } else {
        // If it exists, we want to PRESERVE previous visited status unless this one is true
        final existingData = docSnapshot.data()!;
        final bool alreadyVisited = existingData['visited'] == true;
        if (alreadyVisited) {
          favoriteData['visited'] = true;
        }
      }

      await docRef.set(favoriteData, SetOptions(merge: true));
      debugPrint("✅ [FavoriteService] WRITE SUCCESS: ${docRef.path}");
    } catch (e) {
      debugPrint("❌ [FavoriteService] WRITE FAILED: ${docRef.path}");
      debugPrint("❌ [FavoriteService] Error: $e");
      rethrow;
    }
  }

  /// Removes a place from favoritePlaces
  Future<void> removeFavoritePlace(String placeId) async {
    if (_uid == null) return;
    
    try {
      final docRef = _firestore.collection('users').doc(_uid).collection('favoritePlaces').doc(placeId);
      debugPrint("🗑️ [FavoriteService] Deleting document: ${docRef.path}");
      await docRef.delete();
      debugPrint("✅ [FavoriteService] Successfully removed favorite: $placeId");
    } catch (e) {
      debugPrint("❌ [FavoriteService] Error removing favorite: $e");
      rethrow;
    }
  }

  /// Fetches all favorite place IDs for the current user
  Future<Set<String>> getUserFavoritePlaceIds() async {
    if (_uid == null) return {};
    
    try {
      final snapshot = await _firestore.collection('users').doc(_uid).collection('favoritePlaces').get();
      final ids = snapshot.docs.map((doc) => doc.id).toSet();
      debugPrint("📥 [FavoriteService] Loaded ${ids.length} favorite IDs for user $_uid");
      debugPrint("📥 [FavoriteService] IDs: $ids");
      return ids;
    } catch (e) {
      debugPrint("❌ [FavoriteService] Error fetching favorite IDs: $e");
      return {};
    }
  }

  /// Streams the favorite place IDs for reactive UI updates
  Stream<Set<String>> streamUserFavoritePlaceIds() {
    if (_uid == null) return Stream.value({});
    
    return _firestore
        .collection('users')
        .doc(_uid)
        .collection('favoritePlaces')
        .snapshots()
        .map((snapshot) {
          final ids = snapshot.docs.map((doc) => doc.id).toSet();
          debugPrint("🔄 [FavoriteService] Stream update: ${ids.length} favorite IDs");
          return ids;
        });
  }

  /// Streams the favorite place objects for the Saved Places list
  Stream<List<Map<String, dynamic>>> getUserFavoritePlacesStream() {
    if (_uid == null) return Stream.value([]);
    
    return _firestore
        .collection('users')
        .doc(_uid)
        .collection('favoritePlaces')
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }
}
