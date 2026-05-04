import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../features/groups/data/services/outing_service.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  StreamSubscription<Position>? _positionSubscription;

  String? _activeGroupId;
  String? _activeSessionId;

  // Synchronization lock for permission requests
  Future<LocationPermission>? _permissionRequest;

  Future<LocationPermission> _synchronizedRequest() async {
    if (_permissionRequest != null) return _permissionRequest!;
    
    _permissionRequest = Geolocator.requestPermission();
    try {
      final result = await _permissionRequest!;
      return result;
    } finally {
      _permissionRequest = null;
    }
  }

  /// Update the active session for group-level tracking updates
  Future<void> setActiveSession(String? groupId, String? sessionId) async {
    _activeGroupId = groupId;
    _activeSessionId = sessionId;

    // Persist to user document for Home Page stability
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'activeGroupId': groupId ?? '',
        'activeSessionId': sessionId ?? '',
      });
    }
  }

  /// Request permissions and get current position
  Future<Position?> getCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await _synchronizedRequest();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.',
      );
    }

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  /// Start persistent background tracking
  Future<void> startTracking(String userId) async {
    if (_positionSubscription != null) return;
    // 1. Ensure permissions (Request 'Always' for true background)
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission != LocationPermission.always && permission != LocationPermission.whileInUse) {
      permission = await _synchronizedRequest();
    }

    // 2. Cancel existing if any
    await stopTracking(userId);

    // 3. Mark as active in Firestore & Default to Ghost Mode
    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'isTrackingActive': true,
      'isGhostMode': true, // Privacy by default
    });

    // 4. Start Position Stream
    LocationSettings locationSettings;
    
    if (defaultTargetPlatform == TargetPlatform.android) {
      locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 10,
        forceLocationManager: true,
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationText: "Laween is tracking your live location",
          notificationTitle: "Active Outing",
          enableWakeLock: true,
        ),
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS) {
      locationSettings = AppleSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 10,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
      );
    } else {
      locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 10,
      );
    }

    _positionSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position position) {
            final loc = GeoPoint(position.latitude, position.longitude);

            // 1. Update User Document
            FirebaseFirestore.instance.collection('users').doc(userId).update({
              'location': loc,
              'locationAccuracy': position.accuracy,
              'lastLocationUpdate': FieldValue.serverTimestamp(),
            });

            // 2. Update Active Group Session (Persistent Background Sync)
            if (_activeGroupId != null && _activeSessionId != null) {
              OutingService().updateParticipantLocation(
                groupId: _activeGroupId!,
                sessionId: _activeSessionId!,
                uid: userId,
                location: loc,
                locationAccuracy: position.accuracy,
              );
            }
          },
        );
  }

  /// Stop tracking
  Future<void> stopTracking(String userId) async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;

    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'isTrackingActive': false,
      'activeGroupId': '',
      'activeSessionId': '',
    });

    _activeGroupId = null;
    _activeSessionId = null;
  }

  /// Toggle Ghost Mode
  Future<void> updatePrivacy(String userId, bool isGhostMode) async {
    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'isGhostMode': isGhostMode,
    });
  }

  GeoPoint positionToGeoPoint(Position position) {
    return GeoPoint(position.latitude, position.longitude);
  }
}
