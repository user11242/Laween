// lib/features/groups/data/services/outing_service.dart

import 'dart:convert';
import 'dart:math' as math;
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:geolocator_apple/geolocator_apple.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/outing_session_model.dart';
import '../models/message_model.dart';

class OutingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<Position>? _positionStream;

  // Create a direct outing session to a specific place
  Future<String> createDirectSession({
    required String groupId,
    required String creatorId,
    required String creatorName,
    String? creatorPhotoUrl,
    required Map<String, dynamic> venue,
    required int timeLimitMinutes,
    GeoPoint? creatorLocation,
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
        ),
      ],
      winner: venue, // Set the selected venue as winner
      createdAt: now,
      expiresAt: expiresAt,
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
      text: "⚡ Locked Destination: ${venue['name']}",
      timestamp: now,
      type: 'outing',
      outingSessionId: sessionRef.id,
    );

    await messageRef.set(message.toMap());

    // 3. Update group's last message
    await _firestore.collection('groups').doc(groupId).update({
      'lastMessage': "📍 Session: ${venue['name']}",
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
      text: "Started an Outing Session for $category",
      timestamp: now,
      type: 'outing',
      outingSessionId: sessionRef.id,
    );

    await messageRef.set(message.toMap());

    // 3. Update group's last message
    await _firestore.collection('groups').doc(groupId).update({
      'lastMessage': "🔥 Outing Session: $category",
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

    final participant = OutingParticipant(
      uid: uid,
      name: name,
      photoUrl: photoUrl,
      location: location,
      startLocation: location,
      joinedAt: DateTime.now(),
    );

    await sessionRef.update({
      'participants': FieldValue.arrayUnion([participant.toMap()]),
    });
  }

  // Leave a session
  Future<void> leaveSession(String groupId, String sessionId, String uid) async {
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

    await sessionRef.update({
      'participants': participants,
    });
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
      return OutingSessionModel.fromMap(doc.data()!);
    });
  }

  // Live GPS Telemetry Broadcaster (Legacy/Background)
  // Note: Most tracking is now handled via updateParticipantLocation from Screens
  // to avoid redundant streams and document contention.
  Future<void> startLiveTracking(String groupId, String sessionId, String uid) async {
    stopLiveTracking();
    
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    _positionStream = Geolocator.getPositionStream(
      locationSettings: AppleSettings(
        accuracy: LocationAccuracy.medium,
        distanceFilter: 30,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
      ),
    ).listen((Position position) {
      updateParticipantLocation(
        groupId: groupId,
        sessionId: sessionId,
        uid: uid,
        location: GeoPoint(position.latitude, position.longitude),
      ).catchError((_) { /* Silent fail */ });
    });
  }

  void stopLiveTracking() {
    _positionStream?.cancel();
    _positionStream = null;
  }

  // Close a session (when timer expires or manually)
  Future<void> updateStatus(String groupId, String sessionId, OutingStatus status) async {
    await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('outings')
        .doc(sessionId)
        .update({'status': status.name});

    // If moving to 'thinking', trigger the calculation
    if (status == OutingStatus.thinking) {
      _processThinkingPhase(groupId, sessionId);
    }
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
    final sessionRef = _firestore.collection('groups').doc(groupId).collection('outings').doc(sessionId);
    final snapshot = await sessionRef.get();
    if (!snapshot.exists) return;

    final session = OutingSessionModel.fromMap(snapshot.data()!);
    
    // IF FIXED DESTINATION: Jump directly to completed!
    if (session.calculationMode == 'Fixed') {
      await updateStatus(groupId, sessionId, OutingStatus.completed);
      return;
    }

    final participants = session.participants.where((p) => p.location != null).toList();

    if (participants.isEmpty) {
      await updateStatus(groupId, sessionId, OutingStatus.cancelled);
      return;
    }

    // 1. Calculate Geographic Midpoint (True Spherical Centroid)
    double x = 0;
    double y = 0;
    double z = 0;

    for (var p in participants) {
      // Convert to radians
      final latRad = p.location!.latitude * math.pi / 180;
      final lngRad = p.location!.longitude * math.pi / 180;

      // Convert to Cartesian coordinates
      x += math.cos(latRad) * math.cos(lngRad);
      y += math.cos(latRad) * math.sin(lngRad);
      z += math.sin(latRad);
    }

    // Average the coordinates
    x = x / participants.length;
    y = y / participants.length;
    z = z / participants.length;

    // Convert average Cartesian back to latitude/longitude
    final centralLng = math.atan2(y, x);
    final centralSquareRoot = math.sqrt(x * x + y * y);
    final centralLat = math.atan2(z, centralSquareRoot);

    final midLat = centralLat * 180 / math.pi;
    final midLng = centralLng * 180 / math.pi;
    
    // 2. Query Google Places API
    final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'];
    final category = session.category.toLowerCase();
    
    // Use the New Places API (Text Search) for better results
    final url = Uri.parse('https://places.googleapis.com/v1/places:searchText');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': apiKey!,
        'X-Goog-FieldMask': 'places.displayName,places.formattedAddress,places.rating,places.userRatingCount,places.photos,places.location,places.id',
      },
      body: jsonEncode({
        'textQuery': '$category near $midLat, $midLng',
        'locationBias': {
          'circle': {
            'center': {'latitude': midLat, 'longitude': midLng},
            'radius': 2000.0 // 2km radius
          }
        },
        'maxResultCount': 3,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List places = data['places'] ?? [];
      
      // 3. Update session with results and move to 'voting'
      await sessionRef.update({
        'finalLocation': {
          'center': {'lat': midLat, 'lng': midLng},
          'topVenues': places.map((p) => {
            'id': p['id'],
            'name': p['displayName']['text'],
            'address': p['formattedAddress'],
            'rating': p['rating'],
            'userRatingCount': p['userRatingCount'],
            'location': p['location'],
            'photoReference': (p['photos'] != null && p['photos'].isNotEmpty) ? p['photos'][0]['name'] : null,
          }).toList(),
        },
        'status': OutingStatus.voting.name,
      });
    } else {
      // Fallback or cancel
      await updateStatus(groupId, sessionId, OutingStatus.cancelled);
    }
  }

  /// Vote for a specific venue
  Future<void> voteForVenue({
    required String groupId,
    required String sessionId,
    required String venueId,
    required String uid,
  }) async {
    final sessionRef = _firestore.collection('groups').doc(groupId).collection('outings').doc(sessionId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(sessionRef);
      if (!snapshot.exists) return;

      final data = snapshot.data()!;
      final List topVenues = List.from(data['finalLocation']['topVenues']);
      
      // Update the vote count for the specific venue
      for (var venue in topVenues) {
        if (venue['id'] == venueId) {
          final List currentVotes = List.from(venue['votes'] ?? []);
          if (!currentVotes.contains(uid)) {
            currentVotes.add(uid);
            venue['votes'] = currentVotes;
          }
          break;
        }
      }

      transaction.update(sessionRef, {
        'finalLocation.topVenues': topVenues,
      });

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
            final ratingA = (a['rating'] as num?)?.toDouble() ?? 0;
            final ratingB = (b['rating'] as num?)?.toDouble() ?? 0;
            return ratingB.compareTo(ratingA);
          });

          final winner = topVenues.first;
          transaction.update(sessionRef, {
            'status': OutingStatus.completed.name,
            'winner': winner,
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
    final sessionRef = _firestore.collection('groups').doc(groupId).collection('outings').doc(sessionId);
    final snapshot = await sessionRef.get();
    if (!snapshot.exists) return;

    final data = snapshot.data()!;
    final List topVenues = List.from(data['finalLocation']['topVenues']);
    
    if (topVenues.isEmpty) {
      await sessionRef.update({
        'status': OutingStatus.completed.name,
      });
      return;
    }

    // Sort by votes length descending, then by rating
    topVenues.sort((a, b) {
      final votesA = (a['votes'] as List?)?.length ?? 0;
      final votesB = (b['votes'] as List?)?.length ?? 0;
      if (votesA != votesB) return votesB.compareTo(votesA);
      final ratingA = (a['rating'] as num?)?.toDouble() ?? 0;
      final ratingB = (b['rating'] as num?)?.toDouble() ?? 0;
      return ratingB.compareTo(ratingA);
    });

    final winner = topVenues.first;

    await sessionRef.update({
      'status': OutingStatus.completed.name,
      'winner': winner,
    });
  }

  /// Update a participant's location in real-time
  Future<void> updateParticipantLocation({
    required String groupId,
    required String sessionId,
    required String uid,
    required GeoPoint location,
  }) async {
    final sessionRef = _firestore
        .collection('groups')
        .doc(groupId)
        .collection('outings')
        .doc(sessionId);

    try {
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(sessionRef);
        if (!snapshot.exists) return;

        final data = snapshot.data()!;
        final List participants = List.from(data['participants'] ?? []);
        
        bool updated = false;
        for (var i = 0; i < participants.length; i++) {
          if (participants[i]['uid'] == uid) {
            participants[i]['location'] = location;
            updated = true;
            break;
          }
        }

        if (updated) {
          transaction.update(sessionRef, {
            'participants': participants,
          });
        }
      }); // Restored default resilience (5 attempts)
    } catch (e) {
      // Background location updates should not crash the app
      print("Telemetry update skipped: $e");
    }
  }
}
