// lib/features/groups/data/services/outing_service.dart

import 'dart:convert';
import 'dart:math' as math;
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:live_activities/live_activities.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../../../../core/services/google_maps_service.dart';
import '../models/outing_session_model.dart';
import '../models/message_model.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/services/favorite_service.dart';

class FavoriteInsight {
  final Set<String> favoritedByUids;
  final bool isGroupHistoryFavorite;

  FavoriteInsight({
    required this.favoritedByUids,
    required this.isGroupHistoryFavorite,
  });
}

class OutingService {
  static final OutingService _instance = OutingService._internal();
  factory OutingService() => _instance;
  OutingService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LiveActivities _liveActivitiesPlugin = LiveActivities();
  String? _activityId;
  String? _lastParticipantsJson;
  
  /// Fetches favorite data for all current session participants and group history.
  /// Used to classify venues into High/Medium/Normal priority buckets.
  Future<Map<String, FavoriteInsight>> _getFavoriteInsights(
    String groupId,
    List<String> participantUids,
  ) async {
    final Map<String, FavoriteInsight> insights = {};

    try {
      // 1. Participant Global Favorites
      // We map placeId -> Set of UIDs who favorited it
      final Map<String, Set<String>> placeToUsers = {};
      
      for (var uid in participantUids) {
        final snapshot = await _firestore
            .collection('users')
            .doc(uid)
            .collection('favoritePlaces')
            .get();
            
        for (var doc in snapshot.docs) {
          final pid = doc.id;
          placeToUsers.putIfAbsent(pid, () => {}).add(uid);
        }
      }

      // 2. Group History Favorites
      // Only count favorites from the same group
      final Set<String> historyFavIds = {};
      final historySnapshot = await _firestore
          .collection('groups')
          .doc(groupId)
          .collection('outings')
          .where('status', whereIn: [
            OutingStatus.archived.name,
            OutingStatus.finished.name,
            OutingStatus.completed.name
          ])
          .get();

      for (var doc in historySnapshot.docs) {
        final data = doc.data();
        final List favList = data['favoritedBy'] ?? [];
        if (favList.isNotEmpty) {
          final winner = data['winner'];
          if (winner != null && winner['id'] != null) {
            historyFavIds.add(winner['id'].toString());
          }
        }
      }

      // Combine into insights
      final allPlaceIds = {...placeToUsers.keys, ...historyFavIds};
      for (var pid in allPlaceIds) {
        insights[pid] = FavoriteInsight(
          favoritedByUids: placeToUsers[pid] ?? {},
          isGroupHistoryFavorite: historyFavIds.contains(pid),
        );
      }
    } catch (e) {
      debugPrint("Error fetching favorite insights: $e");
    }

    return insights;
  }

  // Create a direct outing session to a specific place
  Future<String> createDirectSession({
    required String groupId,
    required String creatorId,
    required String creatorName,
    String? creatorPhotoUrl,
    required Map<String, dynamic> venue,
    required int timeLimitMinutes,
    GeoPoint? creatorLocation,
    DateTime? scheduledAt,
  }) async {
    final sessionRef = _firestore
        .collection('groups')
        .doc(groupId)
        .collection('outings')
        .doc();

    final now = DateTime.now();
    final expiresAt = now.add(Duration(minutes: timeLimitMinutes));

    int? initialEta;
    double? initialDist;
    if (creatorLocation != null && venue['location'] != null) {
      try {
        final etaResult = await GoogleMapsService().getETA(
          originLat: creatorLocation.latitude,
          originLng: creatorLocation.longitude,
          destLat: (venue['location']['latitude'] as num).toDouble(),
          destLng: (venue['location']['longitude'] as num).toDouble(),
        );
        if (etaResult != null) {
          initialEta = etaResult['etaMinutes'];
          initialDist = etaResult['distanceKm'];
        }
      } catch (e) {
        debugPrint("Error fetching direct session ETA: $e");
      }
    }

    final session = OutingSessionModel(
      id: sessionRef.id,
      groupId: groupId,
      creatorId: creatorId,
      status: OutingStatus.waiting, // Let people join first
      category: venue['category'] ?? 'Custom',
      calculationMode: 'Fixed',
      timeLimitMinutes: timeLimitMinutes,
      participants: [
        OutingParticipant(
          uid: creatorId,
          name: creatorName,
          photoUrl: creatorPhotoUrl,
          joinedAt: now,
          location: creatorLocation,
          startLocation: creatorLocation,
          etaMinutes: initialEta,
          distanceKm: initialDist,
          lastEtaUpdate: initialEta != null ? now : null,
        ),
      ],
      winner: venue, // Set the selected venue as winner
      createdAt: now,
      expiresAt: expiresAt,
      scheduledAt: scheduledAt,
    );

    // 1. Create the session document
    await sessionRef.set(session.toMap());

    // 2. Send the 'outing' message to the chat
    final messageRef = _firestore
        .collection('groups')
        .doc(groupId)
        .collection('messages')
        .doc();

    final message = MessageModel(
      id: messageRef.id,
      senderId: creatorId,
      senderName: creatorName,
      senderPhotoUrl: creatorPhotoUrl,
      text: scheduledAt != null
          ? "📅 Scheduled Outing to ${venue['name']} at ${scheduledAt.day}/${scheduledAt.month} ${scheduledAt.hour}:${scheduledAt.minute.toString().padLeft(2, '0')}"
          : "⚡ Locked Destination: ${venue['name']}",
      timestamp: now,
      type: 'outing',
      outingSessionId: sessionRef.id,
    );

    await messageRef.set(message.toMap());

    // 3. Update group's last message
    await _firestore.collection('groups').doc(groupId).update({
      'lastMessage': scheduledAt != null
          ? "📅 Scheduled: ${venue['name']}"
          : "📍 Session: ${venue['name']}",
      'lastMessageTime': FieldValue.serverTimestamp(),
    });

    return sessionRef.id;
  }

  // Create a new outing session (Discovery Mode)
  Future<String> createSession({
    required String groupId,
    required String creatorId,
    required String creatorName,
    String? creatorPhotoUrl,
    required String category,
    required String calculationMode,
    required int timeLimitMinutes,
    GeoPoint? location,
    DateTime? scheduledAt,
  }) async {
    final sessionRef = _firestore
        .collection('groups')
        .doc(groupId)
        .collection('outings')
        .doc();

    final now = DateTime.now();
    final expiresAt = now.add(Duration(minutes: timeLimitMinutes));

    final session = OutingSessionModel(
      id: sessionRef.id,
      groupId: groupId,
      creatorId: creatorId,
      status: OutingStatus.waiting,
      category: category,
      calculationMode: calculationMode,
      timeLimitMinutes: timeLimitMinutes,
      participants: [
        OutingParticipant(
          uid: creatorId,
          name: creatorName,
          photoUrl: creatorPhotoUrl,
          joinedAt: now,
          location: location,
          startLocation: location,
        ),
      ],
      createdAt: now,
      expiresAt: expiresAt,
      scheduledAt: scheduledAt,
    );

    // 1. Create the session document
    await sessionRef.set(session.toMap());

    // 2. Send the 'outing' message to the chat
    final messageRef = _firestore
        .collection('groups')
        .doc(groupId)
        .collection('messages')
        .doc();

    final message = MessageModel(
      id: messageRef.id,
      senderId: creatorId,
      senderName: creatorName,
      senderPhotoUrl: creatorPhotoUrl,
      text: scheduledAt != null
          ? "📅 Scheduled Discovery Session ($category) at ${scheduledAt.day}/${scheduledAt.month} ${scheduledAt.hour}:${scheduledAt.minute.toString().padLeft(2, '0')}"
          : "Started an Outing Session for $category",
      timestamp: now,
      type: 'outing',
      outingSessionId: sessionRef.id,
    );

    await messageRef.set(message.toMap());

    // 3. Update group's last message
    await _firestore.collection('groups').doc(groupId).update({
      'lastMessage': scheduledAt != null
          ? "📅 Scheduled: $category"
          : "🔥 Outing Session: $category",
      'lastMessageTime': FieldValue.serverTimestamp(),
    });

    return sessionRef.id;
  }

  // Join an existing session
  Future<void> joinSession({
    required String groupId,
    required String sessionId,
    required String uid,
    required String name,
    String? photoUrl,
    GeoPoint? location,
  }) async {
    final sessionRef = _firestore
        .collection('groups')
        .doc(groupId)
        .collection('outings')
        .doc(sessionId);

    int? initialEta;
    double? initialDist;
    if (location != null) {
      try {
        final snapshot = await sessionRef.get();
        if (snapshot.exists) {
          final data = snapshot.data()!;
          if (data['winner'] != null && data['winner']['location'] != null) {
            final destLat = (data['winner']['location']['latitude'] as num).toDouble();
            final destLng = (data['winner']['location']['longitude'] as num).toDouble();
            final etaResult = await GoogleMapsService().getETA(
              originLat: location.latitude,
              originLng: location.longitude,
              destLat: destLat,
              destLng: destLng,
            );
            if (etaResult != null) {
              initialEta = etaResult['etaMinutes'];
              initialDist = etaResult['distanceKm'];
            }
          }
        }
      } catch (e) {
        debugPrint("Error fetching join session ETA: $e");
      }
    }

    final now = DateTime.now();
    final participant = OutingParticipant(
      uid: uid,
      name: name,
      photoUrl: photoUrl,
      location: location,
      startLocation: location,
      joinedAt: now,
      etaMinutes: initialEta,
      distanceKm: initialDist,
      lastEtaUpdate: initialEta != null ? now : null,
    );

    await sessionRef.update({
      'participants': FieldValue.arrayUnion([participant.toMap()]),
    });
  }

  // Leave a session
  Future<void> leaveSession(
    String groupId,
    String sessionId,
    String uid,
  ) async {
    final sessionRef = _firestore
        .collection('groups')
        .doc(groupId)
        .collection('outings')
        .doc(sessionId);

    final snapshot = await sessionRef.get();
    if (!snapshot.exists) return;

    final data = snapshot.data()!;
    final List participants = data['participants'] ?? [];

    // Find and remove the participant with the matching UID
    participants.removeWhere((p) => p['uid'] == uid);

    await sessionRef.update({'participants': participants});
  }

  // Stream a specific session's state
  Stream<OutingSessionModel?> streamSession(String groupId, String sessionId) {
    return _firestore
        .collection('groups')
        .doc(groupId)
        .collection('outings')
        .doc(sessionId)
        .snapshots()
        .map((doc) {
          if (!doc.exists) return null;
          return OutingSessionModel.fromFirestore(doc);
        });
  }

  // Telegram-style Telemetry (Managed by LocationService)
  // This class now only provides the updateParticipantLocation sink.

  // Close a session (when timer expires or manually)
  Future<void> updateStatus(
    String groupId,
    String sessionId,
    OutingStatus status,
  ) async {
    final updates = <String, dynamic>{'status': status.name};
    
    // When an outing moves to 'completed' (Journey starts), set 10-hour life
    if (status == OutingStatus.completed) {
      updates['expiresAt'] = Timestamp.fromDate(
        DateTime.now().add(const Duration(hours: 10)),
      );
    }

    await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('outings')
        .doc(sessionId)
        .update(updates);

    // End Live Activity if terminal state
    if (status == OutingStatus.completed || status == OutingStatus.cancelled) {
      if (_activityId != null) {
        _liveActivitiesPlugin.endActivity(_activityId!);
        _activityId = null;
      }
    }

    // If moving to 'thinking', trigger the calculation
    if (status == OutingStatus.thinking) {
      _processThinkingPhase(groupId, sessionId);
    }
  }

  Future<void> archiveSession(String groupId, String sessionId) async {
    await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('outings')
        .doc(sessionId)
        .update({'status': OutingStatus.archived.name});
  }

  /// Record the first participant to arrive
  Future<void> recordFirstArrival(
    String groupId,
    String sessionId,
    String uid,
  ) async {
    await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('outings')
        .doc(sessionId)
        .update({'firstArrivedUid': uid});
  }

  // Update session category or mode during waiting phase
  Future<void> updateSessionDetails({
    required String groupId,
    required String sessionId,
    String? category,
    String? calculationMode,
  }) async {
    final Map<String, dynamic> updates = {};
    if (category != null) updates['category'] = category;
    if (calculationMode != null) updates['calculationMode'] = calculationMode;

    if (updates.isEmpty) return;

    await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('outings')
        .doc(sessionId)
        .update(updates);
  }

  /// THE CORE ALGORITHM: Calculate Middle Point and Fetch Venues from Google
  Future<void> _processThinkingPhase(String groupId, String sessionId) async {
    final sessionRef = _firestore
        .collection('groups')
        .doc(groupId)
        .collection('outings')
        .doc(sessionId);
    final snapshot = await sessionRef.get();
    if (!snapshot.exists) return;

    final session = OutingSessionModel.fromFirestore(snapshot);

    // IF FIXED DESTINATION: Jump directly to completed!
    if (session.calculationMode == 'Fixed') {
      await updateStatus(groupId, sessionId, OutingStatus.completed);
      return;
    }

    final participants = session.participants
        .where((p) => p.location != null)
        .toList();

    if (participants.isEmpty) {
      await updateStatus(groupId, sessionId, OutingStatus.cancelled);
      return;
    }

    // 1. Calculate Geographic Midpoint (Bounding Box Center)
    double minLat = 90.0;
    double maxLat = -90.0;
    double minLng = 180.0;
    double maxLng = -180.0;

    for (var p in participants) {
      final lat = p.location!.latitude;
      final lng = p.location!.longitude;
      if (lat < minLat) minLat = lat;
      if (lat > maxLat) maxLat = lat;
      if (lng < minLng) minLng = lng;
      if (lng > maxLng) maxLng = lng;
    }

    final midLat = (minLat + maxLat) / 2;
    final midLng = (minLng + maxLng) / 2;

    // 2. Generate Search Anchors
    final List<LatLng> searchAnchors = [
      LatLng(midLat, midLng), // center anchor
      LatLng(midLat + 0.015, midLng), // north anchor (~1.65km)
      LatLng(midLat - 0.015, midLng), // south anchor
      LatLng(midLat, midLng + 0.015), // east anchor
      LatLng(midLat, midLng - 0.015), // west anchor
    ];

    // Corridor anchors if exactly 2 participants
    if (participants.length == 2) {
      final p1 = participants[0].location!;
      final p2 = participants[1].location!;
      
      searchAnchors.add(LatLng(
        p1.latitude + 0.25 * (midLat - p1.latitude),
        p1.longitude + 0.25 * (midLng - p1.longitude),
      ));
      
      searchAnchors.add(LatLng(
        p2.latitude + 0.25 * (midLat - p2.latitude),
        p2.longitude + 0.25 * (midLng - p2.longitude),
      ));
    }

    final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'];
    final category = session.category.toLowerCase();
    final url = Uri.parse('https://places.googleapis.com/v1/places:searchText');
    
    final Set<String> seenPlaceIds = {};
    final List<Map<String, dynamic>> candidatePlaces = [];

    // 3. Diversified Candidate Discovery
    for (var anchor in searchAnchors) {
      try {
        final response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'X-Goog-Api-Key': apiKey!,
            'X-Goog-FieldMask':
                'places.displayName,places.formattedAddress,places.rating,places.userRatingCount,places.photos,places.location,places.id,places.currentOpeningHours,places.businessStatus',
          },
          body: jsonEncode({
            'textQuery': category,
            'locationBias': {
              'circle': {
                'center': {'latitude': anchor.latitude, 'longitude': anchor.longitude},
                'radius': 3000.0,
              },
            },
            'maxResultCount': 20,
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final List rawPlaces = data['places'] ?? [];

          for (var p in rawPlaces) {
            final pId = p['id']?.toString() ?? '';
            if (pId.isEmpty || seenPlaceIds.contains(pId)) continue;
            if (p['location'] == null) continue;
            if (p['displayName'] == null || p['displayName']['text'] == null) continue;

            // Rating below 3.0 only if rating exists
            if (p['rating'] != null && (p['rating'] as num) < 3.0) continue;
            if (p['businessStatus'] != null && p['businessStatus'] != 'OPERATIONAL') continue;

            seenPlaceIds.add(pId);
            candidatePlaces.add(p);
          }
        }
      } catch (_) {}
    }

    if (candidatePlaces.isEmpty) {
      await updateStatus(groupId, sessionId, OutingStatus.cancelled);
      return;
    }

    // 4. Candidate Limit before routing
    int maxCandidatesForRouting = 25;
    if (participants.length <= 3) {
      maxCandidatesForRouting = 25;
    } else if (participants.length <= 5) {
      maxCandidatesForRouting = 20;
    } else {
      maxCandidatesForRouting = 12;
    }

    final List<Map<String, dynamic>> limitedPlaces = candidatePlaces.take(maxCandidatesForRouting).toList();
    final List<LatLng> origins = participants.map<LatLng>((p) => LatLng(p.location!.latitude, p.location!.longitude)).toList();
    final List<LatLng> destinations = limitedPlaces.map<LatLng>((p) => LatLng((p['location']['latitude'] as num).toDouble(), (p['location']['longitude'] as num).toDouble())).toList();

    // 5. Compute Route Matrix
    final routeMatrix = await GoogleMapsService().getRouteMatrix(
      origins: origins,
      destinations: destinations,
    );

    // 6. Fetch Favorite Insights for current participants only
    final List<String> participantUids = participants.map((p) => p.uid).toList();
    final favoriteInsights = await _getFavoriteInsights(groupId, participantUids);

    List<Map<String, dynamic>> processedVenues = [];

    for (int i = 0; i < limitedPlaces.length; i++) {
      final place = limitedPlaces[i];
      final String placeId = place['id'].toString();
      
      final venueRoutes = routeMatrix.where((r) => r['destinationIndex'] == i).toList();
      
      int validRoutes = 0;
      int failedRoutes = 0;
      int sumEta = 0;
      int maxEta = 0;
      int minEta = 999999;
      int sumDistMeters = 0;
      int maxDistMeters = 0;
      int minDistMeters = 99999999;

      for (var r in venueRoutes) {
        if (r['routeAvailable'] == true) {
          validRoutes++;
          int eta = (r['durationSeconds'] as int) ~/ 60;
          sumEta += eta;
          if (eta > maxEta) maxEta = eta;
          if (eta < minEta) minEta = eta;

          int dist = r['distanceMeters'] as int;
          sumDistMeters += dist;
          if (dist > maxDistMeters) maxDistMeters = dist;
          if (dist < minDistMeters) minDistMeters = dist;
        } else {
          failedRoutes++;
        }
      }

      double timeFairnessScore = 9999.0;
      double distanceFairnessScore = 9999.0;
      int avgEta = 0;
      int avgDistMeters = 0;
      int etaSpread = 0;
      int distSpreadMeters = 0;

      if (validRoutes > 0) {
        avgEta = sumEta ~/ validRoutes;
        avgDistMeters = sumDistMeters ~/ validRoutes;
        etaSpread = maxEta - minEta;
        distSpreadMeters = maxDistMeters - minDistMeters;
        
        // Stricter time score with penalties (NO FAKE BOOSTS)
        timeFairnessScore = avgEta + (etaSpread * 1.0);
        if (etaSpread > 10) {
          timeFairnessScore += (etaSpread - 10) * 2.0;
        }
        if (maxEta > 30) {
          timeFairnessScore += (maxEta - 30) * 1.5;
        }
        
        // Distance score with penalties (NO FAKE BOOSTS)
        double avgDistKm = avgDistMeters / 1000.0;
        double maxDistKm = maxDistMeters / 1000.0;
        double distSpreadKm = distSpreadMeters / 1000.0;
        
        distanceFairnessScore = avgDistKm + (distSpreadKm * 1.0);
        if (distSpreadKm > 5) {
          distanceFairnessScore += (distSpreadKm - 5) * 1.5;
        }
        if (maxDistKm > 20) {
          distanceFairnessScore += (maxDistKm - 20) * 1.2;
        }
      }

      // Add failure penalties to BOTH scores (High penalty for unreachable)
      timeFairnessScore += failedRoutes * 999.0;
      distanceFairnessScore += failedRoutes * 999.0;

      // Select primary score based on calculation mode preference
      double selectedFairnessScore = session.calculationMode == 'Time' ? timeFairnessScore : distanceFairnessScore;
      String selectedFairnessMode = session.calculationMode == 'Time' ? 'time' : 'distance';

      // --- NEW FAVORITE PRIORITY BUCKETING ---
      final insight = favoriteInsights[placeId];
      final favoritedByCurrent = insight?.favoritedByUids ?? {};
      final isGroupHistoryFav = insight?.isGroupHistoryFavorite ?? false;
      
      int priorityLevel = 0; // 0=Normal, 1=Medium, 2=High
      String favoritePriority = "normal";
      String? favoriteReason;

      if (isGroupHistoryFav) {
        priorityLevel = 2;
        favoritePriority = "high";
        favoriteReason = "Favorited from a previous group outing";
      } else if (favoritedByCurrent.length > 1) {
        priorityLevel = 2;
        favoritePriority = "high";
        favoriteReason = "Favorited by multiple members";
      } else if (favoritedByCurrent.length == 1) {
        if (participants.length <= 3) {
          priorityLevel = 2;
          favoritePriority = "high";
          favoriteReason = "Favorited by one member";
        } else {
          priorityLevel = 1;
          favoritePriority = "medium";
          favoriteReason = "Favorited by one member";
        }
      }

      // Build per-member route map keyed by participant uid.
      final Map<String, dynamic> memberRoutes = {};
      for (var r in venueRoutes) {
        final originIdx = r['originIndex'] as int;
        if (originIdx < participants.length) {
          final memberUid = participants[originIdx].uid;
          if (r['routeAvailable'] == true) {
            memberRoutes[memberUid] = {
              'etaMinutes': (r['durationSeconds'] as int) ~/ 60,
              'distanceKm': (r['distanceMeters'] as int) / 1000.0,
              'routeAvailable': true,
            };
          } else {
            memberRoutes[memberUid] = {'routeAvailable': false};
          }
        }
      }

      final venueMap = {
        'id': placeId,
        'name': place['displayName']['text'],
        'address': place['formattedAddress'],
        'rating': (place['rating'] as num?)?.toDouble() ?? 0.0,
        'userRatingCount': place['userRatingCount'],
        'location': place['location'],
        'isFavorite': favoritedByCurrent.isNotEmpty || isGroupHistoryFav,
        'photoReference': (place['photos'] != null && place['photos'].isNotEmpty)
            ? place['photos'][0]['name']
            : null,
        'averageEtaMinutes': avgEta,
        'maxEtaMinutes': maxEta,
        'minEtaMinutes': validRoutes > 0 ? minEta : 0,
        'etaSpreadMinutes': etaSpread,
        'averageRouteDistanceMeters': avgDistMeters,
        'maxRouteDistanceMeters': maxDistMeters,
        'minRouteDistanceMeters': validRoutes > 0 ? minDistMeters : 0,
        'routeDistanceSpreadMeters': distSpreadMeters,
        'timeFairnessScore': timeFairnessScore,
        'distanceFairnessScore': distanceFairnessScore,
        'selectedFairnessScore': selectedFairnessScore,
        'selectedFairnessMode': selectedFairnessMode,
        'routeAvailableCount': validRoutes,
        'failedRouteCount': failedRoutes,
        'routeAvailable': failedRoutes == 0 && validRoutes > 0,
        'memberRoutes': memberRoutes,
        // New Metadata
        'favoritePriority': favoritePriority,
        'favoritePriorityLevel': priorityLevel,
        'favoriteReason': favoriteReason,
        'favoriteUserCount': favoritedByCurrent.length,
        'isGroupOutingFavorite': isGroupHistoryFav,
        'favoriteUserIds': favoritedByCurrent.toList(),
      };

      processedVenues.add(venueMap);

      // VERIFICATION LOG
      debugPrint("📍 [Thinking] Scored: ${venueMap['name']} | "
          "Score: ${selectedFairnessScore.toStringAsFixed(1)} | "
          "Spread: $etaSpread | "
          "Priority: $favoritePriority | "
          "Reason: $favoriteReason");
    }

    if (processedVenues.isEmpty) {
      await updateStatus(groupId, sessionId, OutingStatus.cancelled);
      return;
    }

    // 7. HIERARCHICAL SORTING
    processedVenues.sort((a, b) {
      // 1. Full Availability / Route Success
      if (a['routeAvailable'] != b['routeAvailable']) {
        return (a['routeAvailable'] as bool) ? -1 : 1; 
      }

      // 2. Favorite Priority Level (Descending: 2 -> 1 -> 0)
      final int priorityA = a['favoritePriorityLevel'] as int;
      final int priorityB = b['favoritePriorityLevel'] as int;
      if (priorityA != priorityB) return priorityB.compareTo(priorityA);

      // 3. Real Selected Fairness Score (Lowest First)
      final double scoreA = a['selectedFairnessScore'] as double;
      final double scoreB = b['selectedFairnessScore'] as double;
      if (scoreA != scoreB) return scoreA.compareTo(scoreB);
      
      // 4. Spread Tie-breaker
      if (session.calculationMode == 'Time') {
        final int spreadA = a['etaSpreadMinutes'] as int;
        final int spreadB = b['etaSpreadMinutes'] as int;
        if (spreadA != spreadB) return spreadA.compareTo(spreadB);

        final int maxA = a['maxEtaMinutes'] as int;
        final int maxB = b['maxEtaMinutes'] as int;
        if (maxA != maxB) return maxA.compareTo(maxB);
      } else {
        final int spreadMetersA = a['routeDistanceSpreadMeters'] as int;
        final int spreadMetersB = b['routeDistanceSpreadMeters'] as int;
        if (spreadMetersA != spreadMetersB) return spreadMetersA.compareTo(spreadMetersB);

        final int maxA = a['maxRouteDistanceMeters'] as int;
        final int maxB = b['maxRouteDistanceMeters'] as int;
        if (maxA != maxB) return maxA.compareTo(maxB);
      }
      
      // 5. Rating Tie-breaker (Especially for Normal bucket)
      final double ratingA = (a['rating'] as num?)?.toDouble() ?? 0;
      final double ratingB = (b['rating'] as num?)?.toDouble() ?? 0;
      return ratingB.compareTo(ratingA);
    });

    // LOG FINAL SORTED ORDER
    debugPrint("🏆 [Thinking] TOP SUGGESTIONS:");
    for (int i = 0; i < math.min(processedVenues.length, 5); i++) {
        final v = processedVenues[i];
        debugPrint("  ${i+1}. ${v['name']} [${v['favoritePriority']}] - Score: ${v['selectedFairnessScore'].toStringAsFixed(1)}");
    }

    // 8. Update session
    await sessionRef.update({
      'finalLocation': {
        'center': {'lat': midLat, 'lng': midLng},
        'topVenues': processedVenues.take(8).toList(),
      },
      'status': OutingStatus.voting.name,
    });
  }

  /// Vote for a specific venue
  Future<void> voteForVenue({
    required String groupId,
    required String sessionId,
    required String venueId,
    required String uid,
  }) async {
    final sessionRef = _firestore
        .collection('groups')
        .doc(groupId)
        .collection('outings')
        .doc(sessionId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(sessionRef);
      if (!snapshot.exists) return;

      final data = snapshot.data()!;
      final List topVenues = List.from(data['finalLocation']['topVenues']);

      // Update the vote count for the specific venue (Toggle logic)
      for (var venue in topVenues) {
        if (venue['id'] == venueId) {
          final List currentVotes = List.from(venue['votes'] ?? []);
          if (currentVotes.contains(uid)) {
            currentVotes.remove(uid); // UNVOTE
          } else {
            currentVotes.add(uid); // VOTE
          }
          venue['votes'] = currentVotes;
          break;
        }
      }

      transaction.update(sessionRef, {'finalLocation.topVenues': topVenues});

      // AUTO-FINALIZE: If everyone has voted, finish now
      final List participants = data['participants'] ?? [];
      final int totalJoined = participants.length;
      int totalVotes = 0;
      for (var venue in topVenues) {
        totalVotes += (venue['votes'] as List?)?.length ?? 0;
      }

      if (totalVotes >= totalJoined && totalJoined > 0) {
        // We can't call finalizeSession inside a transaction easily without a ref,
        // so we'll do the sorting logic here or just set a flag to finalize after.
        // For simplicity, let's just update the status to trigger the winner picker logic if we had one,
        // or just perform the winner pick here.

        if (topVenues.isNotEmpty) {
          topVenues.sort((a, b) {
            final votesA = (a['votes'] as List?)?.length ?? 0;
            final votesB = (b['votes'] as List?)?.length ?? 0;
            if (votesA != votesB) return votesB.compareTo(votesA);

            // Tie-breaker 1: Fairness
            final scoreA = (a['selectedFairnessScore'] as num?)?.toDouble() ?? 9999.0;
            final scoreB = (b['selectedFairnessScore'] as num?)?.toDouble() ?? 9999.0;
            if (scoreA != scoreB) return scoreA.compareTo(scoreB);

            // Tie-breaker 2: Host's Choice
            final creatorId = data['creatorId'];
            final hostVotedA = (a['votes'] as List?)?.contains(creatorId) ?? false;
            final hostVotedB = (b['votes'] as List?)?.contains(creatorId) ?? false;
            if (hostVotedA != hostVotedB) return hostVotedA ? -1 : 1;

            // Tie-breaker 3: Mode Max Metric
            if (data['calculationMode'] == 'Time') {
                final maxA = (a['maxEtaMinutes'] as num?)?.toInt() ?? 9999;
                final maxB = (b['maxEtaMinutes'] as num?)?.toInt() ?? 9999;
                if (maxA != maxB) return maxA.compareTo(maxB);
            } else {
                final maxA = (a['maxRouteDistanceMeters'] as num?)?.toInt() ?? 999999;
                final maxB = (b['maxRouteDistanceMeters'] as num?)?.toInt() ?? 999999;
                if (maxA != maxB) return maxA.compareTo(maxB);
            }

            // Tie-breaker 4: Rating
            final ratingA = (a['rating'] as num?)?.toDouble() ?? 0;
            final ratingB = (b['rating'] as num?)?.toDouble() ?? 0;
            return ratingB.compareTo(ratingA);
          });

          final winner = topVenues.first;
          transaction.update(sessionRef, {
            'status': OutingStatus.completed.name,
            'winner': winner,
            'expiresAt': Timestamp.fromDate(
              DateTime.now().add(const Duration(hours: 10)),
            ),
          });
        } else {
          // If no venues, just complete without a winner or cancel
          transaction.update(sessionRef, {
            'status': OutingStatus.completed.name,
          });
        }
      }
    });
  }

  /// Finalize the session and pick the winner
  Future<void> finalizeSession(String groupId, String sessionId) async {
    final sessionRef = _firestore
        .collection('groups')
        .doc(groupId)
        .collection('outings')
        .doc(sessionId);
    final snapshot = await sessionRef.get();
    if (!snapshot.exists) return;

    final data = snapshot.data()!;
    final List topVenues = List.from(data['finalLocation']['topVenues']);

    if (topVenues.isEmpty) {
      await sessionRef.update({
        'status': OutingStatus.completed.name,
        'expiresAt': Timestamp.fromDate(
          DateTime.now().add(const Duration(hours: 10)),
        ),
      });
      return;
    }

    // Sort by votes length descending, then by Fairness, then Host's choice
    topVenues.sort((a, b) {
      final votesA = (a['votes'] as List?)?.length ?? 0;
      final votesB = (b['votes'] as List?)?.length ?? 0;
      if (votesA != votesB) return votesB.compareTo(votesA);

      // Tie-breaker 1: Fairness
      final scoreA = (a['selectedFairnessScore'] as num?)?.toDouble() ?? 9999.0;
      final scoreB = (b['selectedFairnessScore'] as num?)?.toDouble() ?? 9999.0;
      if (scoreA != scoreB) return scoreA.compareTo(scoreB);

      // Tie-breaker 2: Host's Choice
      final creatorId = data['creatorId'];
      final hostVotedA = (a['votes'] as List?)?.contains(creatorId) ?? false;
      final hostVotedB = (b['votes'] as List?)?.contains(creatorId) ?? false;
      if (hostVotedA != hostVotedB) return hostVotedA ? -1 : 1;

      // Tie-breaker 3: Mode Max Metric
      if (data['calculationMode'] == 'Time') {
          final maxA = (a['maxEtaMinutes'] as num?)?.toInt() ?? 9999;
          final maxB = (b['maxEtaMinutes'] as num?)?.toInt() ?? 9999;
          if (maxA != maxB) return maxA.compareTo(maxB);
      } else {
          final maxA = (a['maxRouteDistanceMeters'] as num?)?.toInt() ?? 999999;
          final maxB = (b['maxRouteDistanceMeters'] as num?)?.toInt() ?? 999999;
          if (maxA != maxB) return maxA.compareTo(maxB);
      }

      // Tie-breaker 4: Rating
      final ratingA = (a['rating'] as num?)?.toDouble() ?? 0;
      final ratingB = (b['rating'] as num?)?.toDouble() ?? 0;
      return ratingB.compareTo(ratingA);
    });

    final winner = topVenues.first;

    await sessionRef.update({
      'status': OutingStatus.completed.name,
      'winner': winner,
      'expiresAt': Timestamp.fromDate(
        DateTime.now().add(const Duration(hours: 10)),
      ),
    });
  }

  /// Update a participant's location in real-time
  Future<void> updateParticipantLocation({
    required String groupId,
    required String sessionId,
    required String uid,
    required GeoPoint location,
    double? locationAccuracy,
  }) async {
    final sessionRef = _firestore
        .collection('groups')
        .doc(groupId)
        .collection('outings')
        .doc(sessionId);

    try {
      // 1. Get current session state (outside transaction for async ETA fetch)
      final snapshot = await sessionRef.get();
      if (!snapshot.exists) return;
      final session = OutingSessionModel.fromFirestore(snapshot);

      // 2. Fetch Real Google ETA if winner decided
      int? realEta;
      double? realDist;
      bool shouldUpdateEta = false;

      if (session.winner != null && session.winner?['location'] != null) {
        final p = session.participants.firstWhere((p) => p.uid == uid);
        final lastUpdate = p.lastEtaUpdate;
        final now = DateTime.now();

        // Throttle: Update ETA every 1 minute or if never updated
        if (lastUpdate == null || now.difference(lastUpdate).inMinutes >= 1) {
          final dest = session.winner!['location'];
          final etaResult = await GoogleMapsService().getETA(
            originLat: location.latitude,
            originLng: location.longitude,
            destLat: (dest['latitude'] as num).toDouble(),
            destLng: (dest['longitude'] as num).toDouble(),
          );

          if (etaResult != null) {
            realEta = etaResult['etaMinutes'];
            realDist = etaResult['distanceKm'];
            shouldUpdateEta = true;
          }
        }
      }

      // 3. Update Firestore via Transaction
      await _firestore.runTransaction((transaction) async {
        final freshSnapshot = await transaction.get(sessionRef);
        if (!freshSnapshot.exists) return;

        final data = freshSnapshot.data()!;
        final List participants = List.from(data['participants'] ?? []);

        bool updated = false;
        for (var i = 0; i < participants.length; i++) {
          if (participants[i]['uid'] == uid) {
            participants[i]['location'] = location;
            participants[i]['locationAccuracy'] = locationAccuracy;
            participants[i]['lastLocationUpdate'] = Timestamp.now();
            if (shouldUpdateEta) {
              participants[i]['etaMinutes'] = realEta;
              participants[i]['distanceKm'] = realDist;
              participants[i]['lastEtaUpdate'] = Timestamp.now();
            }
            updated = true;
            break;
          }
        }

        if (updated) {
          transaction.update(sessionRef, {'participants': participants});

          // 4. Sync Live Activity with FRESH data
          final freshSession = OutingSessionModel.fromMap({...data, 'id': snapshot.id});
          // Update local participant to reflect new location/ETA
          for (var i = 0; i < freshSession.participants.length; i++) {
            if (freshSession.participants[i].uid == uid) {
              freshSession.participants[i] = freshSession.participants[i].copyWith(
                location: location,
                locationAccuracy: locationAccuracy,
                lastLocationUpdate: DateTime.now(),
                etaMinutes: shouldUpdateEta ? realEta : freshSession.participants[i].etaMinutes,
                distanceKm: shouldUpdateEta ? realDist : freshSession.participants[i].distanceKm,
                lastEtaUpdate: shouldUpdateEta ? DateTime.now() : freshSession.participants[i].lastEtaUpdate,
              );
              break;
            }
          }
          if (freshSession.winner != null) {
            syncLiveActivity(freshSession);
          }
        }
      });
    } catch (e) {
      print("Telemetry update failed: $e");
    }
  }

  /// Core logic for syncing Live Activity (Lock Screen)
  Future<void> syncLiveActivity(OutingSessionModel session) async {
    final winner = session.winner;
    if (winner == null || winner['location'] == null) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    if (session.participants.isEmpty) return;

    final Map<String, dynamic> win = winner;
    
    // 1. Calculate all participant stats
    int maxEta = 0;
    final participantsList = session.participants
        .where((p) => p.location != null)
        .map((p) {
          final isMe = p.uid == uid;
          
          // Use real Google values from Firestore if available
          final pDist = p.distanceKm ?? double.tryParse(_calculateDistance(
            p.location!.latitude,
            p.location!.longitude,
            (win['location']['latitude'] as num).toDouble(),
            (win['location']['longitude'] as num).toDouble(),
          )) ?? 0.0;

          final pEtaInt = p.etaMinutes ?? int.tryParse(_estimateTime(pDist)) ?? 0;
          if (pEtaInt > maxEta) maxEta = pEtaInt;

          // --- RELATIVE JOURNEY PROGRESS ---
          double progress = 0.0;
          if (p.startLocation != null) {
            final totalDist =
                double.tryParse(
                  _calculateDistance(
                    p.startLocation!.latitude,
                    p.startLocation!.longitude,
                    (winner['location']['latitude'] as num).toDouble(),
                    (winner['location']['longitude'] as num).toDouble(),
                  ),
                ) ??
                0.0;

            if (totalDist > 0.05) {
              progress = (1.0 - (pDist / totalDist)).clamp(0.0, 1.0);
            } else {
              progress = 1.0;
            }
          } else {
            progress = (1.0 - (pDist / 10.0)).clamp(0.0, 1.0);
          }

          return {
            'name': isMe ? "You" : p.name,
            'initial': (p.name.isNotEmpty ? p.name[0] : "?").toUpperCase(),
            'photoUrl': p.photoUrl ?? "",
            'eta': pEtaInt.toString(),
            'dist': "${pDist.toStringAsFixed(1)} km",
            'progress': progress,
            'isMe': isMe,
          };
        })
        .toList();

    // 2. Sort and take top 3 by proximity
    participantsList.sort(
      (a, b) => (b['progress'] as double).compareTo(a['progress'] as double),
    );
    final topParticipants = participantsList.take(3).toList();

    // 3. Serialize and check for changes
    final participantsJson = jsonEncode({
      'list': topParticipants,
      'groupEta': maxEta.toString(),
    });

    if (_lastParticipantsJson == participantsJson) return;
    _lastParticipantsJson = participantsJson;

    // 4. Update or Create Activity
    final payload = {
      'participants': participantsJson,
      'destinationName': winner['name'] ?? 'Destination',
    };

    if (_activityId == null) {
      try {
        _liveActivitiesPlugin.init(appGroupId: "group.laween");
        // End all stale activities to avoid hitting Apple's max limit
        await _liveActivitiesPlugin.endAllActivities();
        _activityId = await _liveActivitiesPlugin.createActivity(
          "laween_tracking",
          payload,
        );
      } catch (e) {
        debugPrint("Live Activity Creation Error in Service: $e");
      }
    } else {
      try {
        await _liveActivitiesPlugin.updateActivity(_activityId!, payload);
      } catch (e) {
        // If activity was ended by user, reset activityId to allow recreation
        _activityId = null;
        debugPrint("Live Activity Update Error in Service - Resetting ID: $e");
      }
    }
  }

  /// Marks the outing as finished (starts the 24h memory collection window)
  Future<void> markAsFinished(OutingSessionModel session) async {
    final sessionRef = _firestore
        .collection('groups')
        .doc(session.groupId)
        .collection('outings')
        .doc(session.id);

    await sessionRef.update({
      'status': OutingStatus.finished.name,
      'finishedAt': FieldValue.serverTimestamp(),
    });

    // Clean up live activity immediately when host finishes tracking
    if (_activityId != null) {
      _liveActivitiesPlugin.endActivity(_activityId!);
      _activityId = null;
    }
  }

  /// Allows any participant to upload photos to the "finished" session
  Future<void> uploadMemories({
    required OutingSessionModel session,
    required List<File> photos,
  }) async {
    final sessionRef = _firestore
        .collection('groups')
        .doc(session.groupId)
        .collection('outings')
        .doc(session.id);

    List<String> uploadedUrls = [];

    // 1. Upload photos to Firebase Storage
    for (int i = 0; i < photos.length; i++) {
      final file = photos[i];
      final ref = FirebaseStorage.instance
          .ref()
          .child('groups')
          .child(session.groupId)
          .child('outings')
          .child(session.id)
          .child('memory_${DateTime.now().millisecondsSinceEpoch}_$i.jpg');
          
      final uploadTask = await ref.putFile(file);
      final url = await uploadTask.ref.getDownloadURL();
      uploadedUrls.add(url);
    }

    // 2. Add to existing photos via arrayUnion
    await sessionRef.update({
      'memoryPhotos': FieldValue.arrayUnion(uploadedUrls),
    });
  }

  /// Finalizes the session, generates the AI recap, selects cover, and archives
  Future<void> finalizeAndArchive(OutingSessionModel session) async {
    final sessionRef = _firestore
        .collection('groups')
        .doc(session.groupId)
        .collection('outings')
        .doc(session.id);

    // Refresh session data to get all photos
    final doc = await sessionRef.get();
    if (!doc.exists) return;
    
    final data = doc.data() as Map<String, dynamic>;
    final photos = List<String>.from(data['memoryPhotos'] ?? []);
    
    String? coverPhotoUrl;
    if (photos.isNotEmpty) {
      // Simulate "AI Cover Selection"
      coverPhotoUrl = photos.first;
    }

    // 2. Generate the "AI Roast & Hype" Recap
    String generatedTitle = "Epic outing at ${session.winner?['name'] ?? session.category}";
    String generatedRecap = "";

    // Build the AI Recap algorithmically using our telemetry data
    final sortedP = List.from(session.participants)..sort((a, b) {
      final aJoin = a.joinedAt.millisecondsSinceEpoch;
      final bJoin = b.joinedAt.millisecondsSinceEpoch;
      return aJoin.compareTo(bJoin);
    });

    String firstArrived = "Someone";
    String lastArrived = "someone else";

    if (session.firstArrivedUid != null) {
      firstArrived = session.participants.firstWhere((p) => p.uid == session.firstArrivedUid).name;
    } else if (sortedP.isNotEmpty) {
       firstArrived = sortedP.first.name; // Fallback
    }
    
    final venueName = session.winner?['name'] ?? session.category;
    
    if (sortedP.length > 1) {
      lastArrived = sortedP.last.name;
      final templates = [
        "Epic night at $venueName! 🔥 $firstArrived secured the table early and was the true MVP, while $lastArrived made everyone starve waiting. Ultimately worth it. 10/10 vibes.",
        "Unforgettable moments at $venueName with the squad. $firstArrived was leading the way as always, and $lastArrived eventually caught up. Pure magic!",
        "The food at $venueName was top tier, but the company was better. Shoutout to $firstArrived for the early arrival, and $lastArrived for making it fashionably late.",
        "Classic outing at $venueName. $firstArrived was on point, while $lastArrived was definitely on 'their own time'. Great times all around!"
      ];
      final int templateIdx = DateTime.now().millisecond % templates.length;
      generatedRecap = templates[templateIdx];
    } else {
      generatedRecap = "A perfect solo trip or intimate hangout at $venueName. Good food, great vibes!";
    }

    if (session.winner != null && session.winner?['name'] != null) {
      final terms = ["Midnight feast", "Unreal cravings", "Legendary dinner", "Vibe check passed"];
      final int idx = DateTime.now().microsecond % terms.length;
      generatedTitle = "${terms[idx]} at ${session.winner!['name']}";
    }

    // 3. Save to Firestore as Archived
    await sessionRef.update({
      'status': OutingStatus.archived.name,
      'coverPhotoUrl': coverPhotoUrl,
      'memoryTitle': generatedTitle,
      'memoryRecap': generatedRecap,
    });
  }

  /// Triggers an SOS emergency for the current user
  Future<void> triggerSOS({
    required OutingSessionModel session,
    required String userUid,
    required String userName,
    required double lat,
    required double lng,
  }) async {
    final sessionRef = _firestore
        .collection('groups')
        .doc(session.groupId)
        .collection('outings')
        .doc(session.id);

    // 1. Update participant status
    final doc = await sessionRef.get();
    if (!doc.exists) return;
    
    final data = doc.data() as Map<String, dynamic>;
    final List participants = data['participants'] ?? [];
    
    final updatedParticipants = participants.map((p) {
      if (p['uid'] == userUid) {
        return {...p, 'isSosActive': true};
      }
      return p;
    }).toList();

    await sessionRef.update({'participants': updatedParticipants});

    // 2. Send SOS Message to Chat
    final googleMapsUrl = "https://www.google.com/maps/search/?api=1&query=$lat,$lng";
    
    await _firestore
        .collection('groups')
        .doc(session.groupId)
        .collection('messages')
        .add({
      'senderId': 'system',
      'senderName': '🚨 EMERGENCY',
      'text': "SOS! $userName needs help! \nLocation: $googleMapsUrl",
      'timestamp': FieldValue.serverTimestamp(),
      'type': 'text',
      'isSos': true, // 🔥 Added to help Cloud Functions route this as an emergency
      'sessionId': session.id, // 🔥 Added to ensure the push notification wakes up the exact session
      'readBy': [userUid],
      'deletedFor': [],
    });
  }

  /// Clears the SOS status
  Future<void> clearSOS({
    required OutingSessionModel session,
    required String userUid,
  }) async {
    final sessionRef = _firestore
        .collection('groups')
        .doc(session.groupId)
        .collection('outings')
        .doc(session.id);

    final doc = await sessionRef.get();
    if (!doc.exists) return;
    
    final data = doc.data() as Map<String, dynamic>;
    final List participants = data['participants'] ?? [];
    
    final updatedParticipants = participants.map((p) {
      if (p['uid'] == userUid) {
        return {...p, 'isSosActive': false};
      }
      return p;
    }).toList();

    await sessionRef.update({'participants': updatedParticipants});
  }

  String _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const p = 0.017453292519943295;
    final a =
        0.5 -
        math.cos((lat2 - lat1) * p) / 2 +
        math.cos(lat1 * p) *
            math.cos(lat2 * p) *
            (1 - math.cos((lon2 - lon1) * p)) /
            2;
    return (12742 * math.asin(math.sqrt(a))).toStringAsFixed(1);
  }

  String _estimateTime(double distanceKm) {
    const averageSpeedKmh = 40.0;
    final timeHours = distanceKm / averageSpeedKmh;
    final timeMinutes = (timeHours * 60).ceil();
    return timeMinutes.toString();
  }
}
