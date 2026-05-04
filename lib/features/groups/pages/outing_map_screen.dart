// lib/features/groups/pages/outing_map_screen.dart

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/theme/colors.dart';
import '../data/models/outing_session_model.dart';
import '../data/models/message_model.dart';
import 'outing_tracking_screen.dart';
import 'outing_memory_upload_screen.dart';
import '../data/services/outing_service.dart';
import '../data/services/chat_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/google_maps_service.dart';
import '../widgets/sos_alarm_overlay.dart';
import 'ar_friend_compass_page.dart';
import 'receipt_splitter_screen.dart';

class OutingMapScreen extends StatefulWidget {
  final String groupId;
  final String sessionId;

  const OutingMapScreen({
    super.key,
    required this.groupId,
    required this.sessionId,
  });

  @override
  State<OutingMapScreen> createState() => _OutingMapScreenState();
}

class _OutingMapScreenState extends State<OutingMapScreen> {
  final OutingService _outingService = OutingService();
  final Completer<GoogleMapController> _controller = Completer();

  Set<Marker> _markers = {};
  int _currentVenueIndex = 0;
  int? _openSwipeIndex;
  bool _isDisposed = false;
  final bool _isTrackingMode = false;
  bool _showWinnerDetails = true;
  bool _showChat = false; // toggle between Suggested Places and Mini Chat
  // Global selected member — drives which member's ETA/distance is shown in every venue card.
  // Defaults to the current logged-in user on first load.
  String? _selectedParticipantUid;
  bool _selectedParticipantInitialized = false;
  Set<Polyline> _polylines = {};
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  final ChatService _chatService = ChatService();


  // Premium Map Style (Electric Midnight / High Contrast)
  static const String _mapStyle = '''
[
  {
    "elementType": "geometry",
    "stylers": [{"color": "#1d2c4d"}]
  },
  {
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#8ec3b9"}]
  },
  {
    "elementType": "labels.text.stroke",
    "stylers": [{"color": "#1a3646"}]
  },
  {
    "featureType": "administrative.locality",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#d59563"}]
  },
  {
    "featureType": "poi",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#d59563"}]
  },
  {
    "featureType": "poi.park",
    "elementType": "geometry",
    "stylers": [{"color": "#263c3f"}]
  },
  {
    "featureType": "poi.park",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#6b9a76"}]
  },
  {
    "featureType": "road",
    "elementType": "geometry",
    "stylers": [{"color": "#304a7d"}]
  },
  {
    "featureType": "road",
    "elementType": "geometry.stroke",
    "stylers": [{"color": "#283d6a"}]
  },
  {
    "featureType": "road",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#9ca5b3"}]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry",
    "stylers": [{"color": "#2c6675"}]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry.stroke",
    "stylers": [{"color": "#255762"}]
  },
  {
    "featureType": "road.highway",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#b0d5ce"}]
  },
  {
    "featureType": "transit",
    "elementType": "geometry",
    "stylers": [{"color": "#2f3948"}]
  },
  {
    "featureType": "transit.station",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#d59563"}]
  },
  {
    "featureType": "water",
    "elementType": "geometry",
    "stylers": [{"color": "#0e1626"}]
  },
  {
    "featureType": "water",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#515c6d"}]
  },
  {
    "featureType": "water",
    "elementType": "labels.text.stroke",
    "stylers": [{"color": "#17263c"}]
  }
]
''';

  final Map<String, BitmapDescriptor> _customMarkers = {};

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  void _startLiveTracking() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      LocationService().setActiveSession(widget.groupId, widget.sessionId);
      LocationService().startTracking(uid);
    }
  }

  Future<BitmapDescriptor> _getAvatarIcon(String name, String? photoUrl, Color color, {bool isSelected = false}) async {
    final cacheKey = "avatar_${photoUrl ?? name}_${color.toARGB32()}_$isSelected";
    if (_customMarkers.containsKey(cacheKey)) return _customMarkers[cacheKey]!;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const size = 95.0;
    const radius = size / 2;

    // Outer glow ring — stronger when this member is the selected metric member
    final glowPaint = Paint()
      ..color = color.withValues(alpha: isSelected ? 0.9 : 0.6)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, isSelected ? 22 : 14);
    canvas.drawCircle(Offset(radius, radius), radius - 6, glowPaint);

    // Extra white pulse ring for selected state
    if (isSelected) {
      final pulsePaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5;
      canvas.drawCircle(Offset(radius, radius), radius - 2, pulsePaint);
    }

    // Colored border ring
    final ringPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 8 : 6;
    canvas.drawCircle(Offset(radius, radius), radius - 6, ringPaint);

    // White inner border (separates image from colored ring)
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    if (photoUrl != null && photoUrl.isNotEmpty) {
      try {
        final Completer<ui.Image> completer = Completer();
        final imageStream = NetworkImage(photoUrl).resolve(ImageConfiguration.empty);
        imageStream.addListener(ImageStreamListener((info, _) {
          if (!completer.isCompleted) completer.complete(info.image);
        }, onError: (exception, stackTrace) {
           if (!completer.isCompleted) completer.completeError(exception);
        }));
        
        final ui.Image image = await completer.future.timeout(const Duration(seconds: 4));
        
        canvas.save();
        Path path = Path()..addOval(Rect.fromCircle(center: Offset(radius, radius), radius: radius - 14));
        canvas.clipPath(path);
        
        paintImage(
          canvas: canvas,
          rect: Rect.fromCircle(center: Offset(radius, radius), radius: radius - 14),
          image: image,
          fit: BoxFit.cover,
        );
        canvas.restore();
        canvas.drawCircle(const Offset(radius, radius), radius - 14, borderPaint);
      } catch (e) {
        _drawInitialMarker(canvas, radius, color, name, borderPaint);
      }
    } else {
      _drawInitialMarker(canvas, radius, color, name, borderPaint);
    }

    final picture = recorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final descriptor = BitmapDescriptor.bytes(byteData!.buffer.asUint8List());

    _customMarkers[cacheKey] = descriptor;
    return descriptor;
  }

  void _drawInitialMarker(Canvas canvas, double radius, Color color, String name, Paint borderPaint) {
    final paint = Paint()..color = color;
    canvas.drawCircle(Offset(radius, radius), radius - 15, paint);
    canvas.drawCircle(Offset(radius, radius), radius - 15, borderPaint);

    final textPainter = TextPainter(
      text: TextSpan(
        text: name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: GoogleFonts.outfit(
          fontSize: 45,
          fontWeight: FontWeight.w900,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(radius - textPainter.width / 2, radius - textPainter.height / 2),
    );
  }

  Future<BitmapDescriptor> _getVenueMarker(String venueId, String? photoUrl, bool isSelected, int? index) async {
    final cacheKey = "venue_${venueId}_$isSelected";
    if (_customMarkers.containsKey(cacheKey)) return _customMarkers[cacheKey]!;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const size = 100.0;
    const radius = size / 2;

    // Rank index (1-based)


    // Outer glow (More subtle)
    final glowPaint = Paint()
      ..color = (isSelected ? AppColors.teal : Colors.pinkAccent).withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(Offset(radius, radius), radius - 8, glowPaint);

    // Frame
    final borderPaint = Paint()
      ..color = isSelected ? AppColors.teal : Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 4 : 3;

    if (photoUrl != null && photoUrl.isNotEmpty) {
      try {
        final Completer<ui.Image> completer = Completer();
        final imageStream = NetworkImage(photoUrl).resolve(ImageConfiguration.empty);
        imageStream.addListener(ImageStreamListener((info, _) {
          if (!completer.isCompleted) completer.complete(info.image);
        }, onError: (exception, stackTrace) {
           if (!completer.isCompleted) completer.completeError(exception);
        }));
        
        final ui.Image image = await completer.future.timeout(const Duration(seconds: 4));
        
        canvas.save();
        Path path = Path()..addOval(Rect.fromCircle(center: Offset(radius, radius), radius: radius - 12));
        canvas.clipPath(path);
        
        paintImage(
          canvas: canvas,
          rect: Rect.fromCircle(center: Offset(radius, radius), radius: radius - 12),
          image: image,
          fit: BoxFit.cover,
        );
        canvas.restore();
        canvas.drawCircle(Offset(radius, radius), radius - 12, borderPaint);
      } catch (e) {
        _drawVenuePlaceholder(canvas, radius, isSelected, borderPaint);
      }
    } else {
      _drawVenuePlaceholder(canvas, radius, isSelected, borderPaint);
    }

    // Rank Badge
    final rankPaint = Paint()..color = isSelected ? AppColors.teal : AppColors.darkSlate;
    const rankSize = 24.0;
    canvas.drawCircle(Offset(size - rankSize / 2, rankSize / 2), rankSize / 2, rankPaint);
    
    final textPainter = TextPainter(
      text: TextSpan(
        text: index != null ? "${index + 1}" : '?',
        style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, Offset(size - rankSize / 2 - textPainter.width / 2, rankSize / 2 - textPainter.height / 2));


    final picture = recorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final descriptor = BitmapDescriptor.bytes(byteData!.buffer.asUint8List());

    _customMarkers[cacheKey] = descriptor;
    return descriptor;
  }

  void _drawVenuePlaceholder(Canvas canvas, double radius, bool isSelected, Paint borderPaint) {
    final paint = Paint()..color = isSelected ? AppColors.teal : Colors.pinkAccent;
    canvas.drawCircle(Offset(radius, radius), radius - 12, paint);
    canvas.drawCircle(Offset(radius, radius), radius - 12, borderPaint);
    
    // Draw an icon placeholder
    final textPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(Icons.restaurant_rounded.codePoint),
        style: TextStyle(
          fontSize: 30,
          fontFamily: Icons.restaurant_rounded.fontFamily,
          package: Icons.restaurant_rounded.fontPackage,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(radius - textPainter.width / 2, radius - textPainter.height / 2),
    );
  }

  Future<void> _glideToVenue(double lat, double lng) async {
    final controller = await _controller.future;
    if (_isDisposed || !mounted) return;

    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(lat, lng),
          zoom: 16.0,
          tilt: 45,
        ),
      ),
    );
  }

  String _getPriceLevel(dynamic level) {
    if (level == null) return r"$$";
    if (level is int) return r"$" * (level > 0 ? level : 1);
    final s = level.toString().toUpperCase();
    if (s.contains('INEXPENSIVE')) return r"$";
    if (s.contains('MODERATE')) return r"$$";
    if (s.contains('EXPENSIVE')) return r"$$$";
    return r"$$";
  }

  Widget _buildMapControl({required IconData icon, required VoidCallback onTap}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Icon(icon, color: AppColors.darkSlate, size: 24),
          ),
        ),
      ),
    );
  }

  Future<void> _updateMarkers(OutingSessionModel session) async {
    if (_isDisposed || !mounted) return;

    // Default selected member to current user on first load
    if (!_selectedParticipantInitialized && session.participants.isNotEmpty) {
      final myUid = FirebaseAuth.instance.currentUser?.uid;
      final defaultUid = myUid != null &&
              session.participants.any((p) => p.uid == myUid)
          ? myUid
          : session.participants.first.uid;
      if (mounted) {
        setState(() {
          _selectedParticipantUid = defaultUid;
          _selectedParticipantInitialized = true;
        });
      }
    }

    final Set<Marker> newMarkers = {};

    // 1. Participant Markers
    for (int i = 0; i < session.participants.length; i++) {
      final p = session.participants[i];
      if (p.location != null) {
        final userColor = AppColors.getUserColor(p.uid);
        final isThisMemberSelected = _selectedParticipantUid == p.uid;
        final icon = await _getAvatarIcon(p.name, p.photoUrl, userColor,
            isSelected: isThisMemberSelected);
        newMarkers.add(
          Marker(
            markerId: MarkerId('p_${p.uid}'),
            position: LatLng(p.location!.latitude, p.location!.longitude),
            infoWindow: InfoWindow(title: p.name),
            icon: icon,
            // Always keep someone selected — tapping a member sets them as
            // the metric source for all venue cards.
            zIndexInt: isThisMemberSelected ? 210 : 200, // members always above venues
            onTap: () {
              setState(() => _selectedParticipantUid = p.uid);
              _updateMarkers(session);
            },
          ),
        );
      }
    }

    // 2. Venue Markers
    final List venues = session.finalLocation?['topVenues'] ?? [];
    for (int i = 0; i < venues.length; i++) {
      final v = venues[i];
      final loc = v['location'];
      if (loc != null) {
        final photoRef = v['photoReference'];
        String? photoUrl;
        if (photoRef != null) {
          if (photoRef.startsWith('places/')) {
            // New Places API (V1) Photo URL
            photoUrl = "https://places.googleapis.com/v1/$photoRef/media?key=${dotenv.env['GOOGLE_MAPS_API_KEY']}&maxHeightPx=800&maxWidthPx=800";
          } else {
            // Legacy Places API Photo URL
            photoUrl = "https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=$photoRef&key=${dotenv.env['GOOGLE_MAPS_API_KEY']}";
          }
        }
            
        final icon = await _getVenueMarker(v['id'], photoUrl, i == _currentVenueIndex, i);

        newMarkers.add(
          Marker(
            markerId: MarkerId('v_${v['id']}'),
            position: LatLng(loc['latitude'], loc['longitude']),
            zIndexInt: i == _currentVenueIndex ? 100 : (10 - i),
            onTap: () {
              if (mounted) {
                setState(() => _currentVenueIndex = i);
                _glideToVenue(loc['latitude'], loc['longitude']);
              }
            },
            icon: icon,
          ),
        );
      }
    }

    // 3. Participant Routes (if selected)
    final Set<Polyline> newPolylines = {};
    if (_selectedParticipantUid != null) {
      final p = session.participants.firstWhere((p) => p.uid == _selectedParticipantUid);
      final dest = session.winner != null ? session.winner! : (session.finalLocation != null ? session.finalLocation : null);
      final destLoc = dest?['location'];
      
      if (p.location != null && destLoc != null) {
        final route = await GoogleMapsService().getRoutePolyline(
          originLat: p.location!.latitude,
          originLng: p.location!.longitude,
          destLat: (destLoc['latitude'] as num).toDouble(),
          destLng: (destLoc['longitude'] as num).toDouble(),
        );

        if (route != null && mounted) {
          final userColor = AppColors.getUserColor(p.uid);
          newPolylines.add(
            Polyline(
              polylineId: PolylineId('route_${p.uid}'),
              points: route,
              color: userColor,
              width: 5,
              jointType: JointType.round,
              startCap: Cap.roundCap,
              endCap: Cap.roundCap,
            ),
          );
        }
      }
    }

    if (_isDisposed || !mounted) return;
    
    // Guard against infinite rebuild loops: Only update if markers or polylines actually changed
    bool markersChanged = _markers.length != newMarkers.length || !_markers.containsAll(newMarkers);
    bool polylinesChanged = _polylines.length != newPolylines.length; // Simplified for performance
    
    if (markersChanged || polylinesChanged) {
      if (mounted) {
        setState(() {
          _markers = newMarkers;
          _polylines = newPolylines;
        });
      }
    }
  }

  Future<void> _fitParticipants() async {
    if (_isDisposed || !mounted || !_controller.isCompleted) return;
    final controller = await _controller.future;
    
    double? minLat, maxLat, minLng, maxLng;
    int count = 0;
    for (var m in _markers) {
      if (m.markerId.value.startsWith('p_')) {
        count++;
        final pos = m.position;
        if (minLat == null || pos.latitude < minLat) minLat = pos.latitude;
        if (maxLat == null || pos.latitude > maxLat) maxLat = pos.latitude;
        if (minLng == null || pos.longitude < minLng) minLng = pos.longitude;
        if (maxLng == null || pos.longitude > maxLng) maxLng = pos.longitude;
      }
    }

    if (count > 0 && minLat != null) {
      final bounds = LatLngBounds(
        southwest: LatLng(minLat, minLng!),
        northeast: LatLng(maxLat!, maxLng!),
      );
      controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 120));
    }
  }

  Future<void> _fitBounds() async {
    if (_isDisposed || !mounted || !_controller.isCompleted) return;

    final controller = await _controller.future;
    if (_isDisposed || !mounted) return;

    if (_markers.isEmpty) return;

    double? minLat, maxLat, minLng, maxLng;
    for (var m in _markers) {
      final pos = m.position;
      if (minLat == null || pos.latitude < minLat) minLat = pos.latitude;
      if (maxLat == null || pos.latitude > maxLat) maxLat = pos.latitude;
      if (minLng == null || pos.longitude < minLng) minLng = pos.longitude;
      if (maxLng == null || pos.longitude > maxLng) maxLng = pos.longitude;
    }

    if (minLat != null && maxLat != null && minLng != null && maxLng != null) {
      final bounds = LatLngBounds(
        southwest: LatLng(minLat, minLng),
        northeast: LatLng(maxLat, maxLng),
      );
      final padding = _isTrackingMode ? 120.0 : 100.0;
      controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, padding));
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<OutingSessionModel?>(
      stream: _outingService.streamSession(widget.groupId, widget.sessionId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return Scaffold(
            backgroundColor: AppColors.darkSlate,
            body: const Center(
              child: CircularProgressIndicator(color: AppColors.teal),
            ),
          );
        }

        final session = snapshot.data!;
        if (session.status == OutingStatus.completed) {
          _startLiveTracking();
        }

        // Initialize the selected member synchronously on first data arrival
        // so venue cards always have a valid UID to look up — never null.
        if (!_selectedParticipantInitialized && session.participants.isNotEmpty) {
          final myUid = FirebaseAuth.instance.currentUser?.uid;
          _selectedParticipantUid = myUid != null &&
                  session.participants.any((p) => p.uid == myUid)
              ? myUid
              : session.participants.first.uid;
          _selectedParticipantInitialized = true;
        }

        return PopScope(
          canPop: session.status == OutingStatus.completed,
          child: Scaffold(
            extendBodyBehindAppBar: true,
            backgroundColor: AppColors.darkSlate,
            body: Builder(
              builder: (context) {
                final List venuesRaw = session.finalLocation?['topVenues'] ?? [];
                final venues = List<Map<String, dynamic>>.from(venuesRaw);
                venues.sort((a, b) {
                  final rA = (a['rating'] ?? 0.0) as num;
                  final rB = (b['rating'] ?? 0.0) as num;
                  if (rA != rB) return rB.compareTo(rA);
                  final cA = (a['userRatingCount'] ?? 0) as int;
                  final cB = (b['userRatingCount'] ?? 0) as int;
                  return cB.compareTo(cA);
                });
                final midLat = session.finalLocation?['center']?['lat'] ?? 0.0;
                final midLng = session.finalLocation?['center']?['lng'] ?? 0.0;

                // Update markers on every stream tick
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && !_isDisposed) _updateMarkers(session);
                });


                return Column(
                  children: [
                    // TOP 50%: MAP (Only during voting)
                    if (session.status != OutingStatus.completed && session.status != OutingStatus.archived)
                      Expanded(
                        flex: 1,
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border(bottom: BorderSide(color: Colors.grey.shade300, width: 1)),
                          ),
                          child: Stack(
                            children: [
                              GoogleMap(
                                key: const ValueKey('outing_map'),
                                initialCameraPosition: CameraPosition(
                                  target: LatLng(midLat, midLng),
                                  zoom: 14.5,
                                ),
                                style: _mapStyle,
                                markers: _markers,
                                polylines: _polylines,
                                onMapCreated: (controller) {
                                  if (!_controller.isCompleted) {
                                    _controller.complete(controller);
                                    Future.delayed(const Duration(milliseconds: 500), () => _fitBounds());
                                  }
                                },
                                zoomControlsEnabled: false,
                                zoomGesturesEnabled: true,
                                scrollGesturesEnabled: true,
                                rotateGesturesEnabled: true,
                                tiltGesturesEnabled: true,
                                myLocationButtonEnabled: false,
                                compassEnabled: false,
                                mapToolbarEnabled: false,
                              ),
                              
                              // 🔭 CUSTOM PREMIUM ZOOM CONTROLS
                              Positioned(
                top: 50,
                left: 20,
                child: _buildBackButton(context),
              ),
                              Positioned(
                                right: 20,
                                bottom: 20,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _buildMapControl(
                                    icon: Icons.people_alt_rounded,
                                    onTap: () => _fitParticipants(),
                                  ),
                                  const SizedBox(height: 12),
                                  _buildMapControl(
                                    icon: Icons.my_location_rounded,
                                    onTap: () => _fitBounds(),
                                  ),
                                  const SizedBox(height: 12),
                                  _buildMapControl(
                                    icon: Icons.add_rounded,
                                    onTap: () async {
                                      final controller = await _controller.future;
                                      controller.animateCamera(CameraUpdate.zoomIn());
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  _buildMapControl(
                                    icon: Icons.remove_rounded,
                                    onTap: () async {
                                      final controller = await _controller.future;
                                      controller.animateCamera(CameraUpdate.zoomOut());
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // BOTTOM CONTENT: VENUE LIST or WINNER PANEL
                    if (session.status == OutingStatus.voting && venues.isNotEmpty)
                      Expanded(
                        flex: 1,
                        child: _buildVenueListPanel(venues, session),
                      ),
                    
                    if (session.status == OutingStatus.completed && session.winner != null)
                      Expanded(
                        flex: 1, // Will occupy full screen if map is hidden
                        child: _buildWinnerPanel(session),
                      ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildVenueListPanel(List venues, OutingSessionModel session) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.zero,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── PILL TAB TOGGLE ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                children: [
                  _buildPillTab(
                    label: '📍 Places',
                    selected: !_showChat,
                    onTap: () => setState(() => _showChat = false),
                  ),
                  _buildPillTab(
                    label: '💬 Chat',
                    selected: _showChat,
                    onTap: () => setState(() => _showChat = true),
                  ),
                ],
              ),
            ),
          ),

          // ── CONTENT ──────────────────────────────────────────────
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              transitionBuilder: (child, anim) =>
                  FadeTransition(opacity: anim, child: child),
              child: _showChat
                  ? _buildMiniChatPanel(key: const ValueKey('chat'))
                  : ListView.builder(
                      key: const ValueKey('places'),
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                      itemCount: venues.length,
                      itemBuilder: (context, index) {
                        final venue = venues[index];
                        return _buildVenueListItem(
                            venue, session, index == _currentVenueIndex, index);
                      },
                    ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2);
  }

  Widget _buildPillTab({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: selected ? AppColors.teal : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.teal.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ]
                : [],
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: selected ? Colors.white : Colors.grey.shade500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniChatPanel({Key? key}) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return Column(
      key: key,
      children: [
        // Message list
        Expanded(
          child: StreamBuilder<List<MessageModel>>(
            stream: _chatService.getMessagesStream(widget.groupId),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.teal,
                    strokeWidth: 2,
                  ),
                );
              }
              final messages = snapshot.data!
                  .where((m) =>
                      (m.type == 'text' || m.type == 'voice') && !m.isDeleted)
                  .toList()
                  .reversed
                  .toList();

              if (messages.isEmpty) {
                return Center(
                  child: Text(
                    'No messages yet.\nBe the first to say hi! 👋',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                        fontSize: 13, color: Colors.grey.shade400),
                  ),
                );
              }

              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (_chatScrollController.hasClients) {
                  _chatScrollController.jumpTo(
                      _chatScrollController.position.maxScrollExtent);
                }
              });

              return ListView.builder(
                controller: _chatScrollController,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                itemCount: messages.length,
                itemBuilder: (context, i) {
                  final msg = messages[i];
                  final isMe = msg.senderId == uid;
                  final userColor = AppColors.getUserColor(msg.senderId);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      mainAxisAlignment: isMe
                          ? MainAxisAlignment.end
                          : MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (!isMe) ...[
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: userColor.withValues(alpha: 0.15),
                            backgroundImage: msg.senderPhotoUrl != null &&
                                    msg.senderPhotoUrl!.isNotEmpty
                                ? NetworkImage(msg.senderPhotoUrl!)
                                : null,
                            child: (msg.senderPhotoUrl == null ||
                                    msg.senderPhotoUrl!.isEmpty)
                                ? Text(
                                    msg.senderName.isNotEmpty
                                        ? msg.senderName[0].toUpperCase()
                                        : '?',
                                    style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: userColor),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 6),
                        ],
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isMe
                                  ? AppColors.teal
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(16),
                                topRight: const Radius.circular(16),
                                bottomLeft: Radius.circular(isMe ? 16 : 4),
                                bottomRight: Radius.circular(isMe ? 4 : 16),
                              ),
                              border: !isMe
                                  ? Border.all(
                                      color: userColor.withValues(alpha: 0.3),
                                      width: 1.5)
                                  : null,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (!isMe)
                                  Text(
                                    msg.senderName.split(' ').first,
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: userColor,
                                    ),
                                  ),
                                Text(
                                  msg.type == 'voice'
                                      ? '🎤 Voice message'
                                      : msg.text,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: isMe
                                        ? Colors.white
                                        : AppColors.darkSlate,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),

        // Quick-reply input
        Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(color: Colors.grey.shade100, width: 1),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _chatController,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(uid),
                  style: GoogleFonts.inter(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Say something...',
                    hintStyle: GoogleFonts.inter(
                        fontSize: 13, color: Colors.grey.shade400),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _sendMessage(uid),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                    color: AppColors.teal,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.send_rounded,
                      color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _sendMessage(String? uid) {
    final text = _chatController.text.trim();
    if (text.isEmpty || uid == null) return;
    final user = FirebaseAuth.instance.currentUser;
    _chatService.sendMessage(
      groupId: widget.groupId,
      senderId: uid,
      senderName: user?.displayName ?? 'User',
      senderPhotoUrl: user?.photoURL,
      text: text,
    );
    _chatController.clear();
  }



  Widget _buildVenueListItem(Map<String, dynamic> venue, OutingSessionModel session, bool isSelected, int index) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final loc = venue['location'];
    final photoRef = venue['photoReference'];
    String? photoUrl;
    if (photoRef != null) {
      if (photoRef.startsWith('places/')) {
        photoUrl = "https://places.googleapis.com/v1/$photoRef/media?key=${dotenv.env['GOOGLE_MAPS_API_KEY']}&maxHeightPx=800&maxWidthPx=800";
      } else {
        photoUrl = "https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=$photoRef&key=${dotenv.env['GOOGLE_MAPS_API_KEY']}";
      }
    }

    final isTrending = _isVenueTrending(venue, session);
    final hasVotedForThis = (venue['votes'] as List?)?.contains(uid) ?? false;
    final votesCount = (venue['votes'] as List?)?.length ?? 0;

    final isOpen = _openSwipeIndex == index;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      height: 150, // Increased to fit per-member route metric row
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Background Swipe Actions (The "Sticking" Vote Button)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: hasVotedForThis ? Colors.redAccent.shade400 : AppColors.teal,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        if (uid != null) {
                          _outingService.voteForVenue(
                            groupId: widget.groupId,
                            sessionId: widget.sessionId,
                            venueId: venue['id'],
                            uid: uid,
                          );
                          setState(() => _openSwipeIndex = null); // Close after vote
                        }
                      },
                      borderRadius: const BorderRadius.horizontal(right: Radius.circular(24)),
                      child: Container(
                        width: 100,
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              hasVotedForThis ? Icons.heart_broken_rounded : Icons.thumb_up_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              hasVotedForThis ? "Unvote" : "Vote Now",
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Foreground Card with Horizontal Drag
          AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            left: isOpen ? -100 : 0,
            right: isOpen ? 100 : 0,
            top: 0,
            bottom: 0,
            child: GestureDetector(
              onHorizontalDragUpdate: (details) {
                if (details.primaryDelta! < -10) {
                  setState(() => _openSwipeIndex = index);
                } else if (details.primaryDelta! > 10) {
                  setState(() => _openSwipeIndex = null);
                }
              },
              onTap: () {
                if (isOpen) {
                  setState(() => _openSwipeIndex = null);
                } else {
                  setState(() => _currentVenueIndex = index);
                  _glideToVenue(loc['latitude'], loc['longitude']);
                }
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isSelected ? AppColors.teal.withValues(alpha: 0.3) : Colors.grey.shade100,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                    if (isSelected)
                      BoxShadow(
                        color: AppColors.teal.withValues(alpha: 0.1),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      )
                  ],
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        width: 90,
                        height: 90,
                        color: Colors.grey.shade100,
                        child: photoUrl != null 
                          ? CachedNetworkImage(imageUrl: photoUrl, fit: BoxFit.cover)
                          : const Icon(Icons.restaurant_rounded),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.teal.withValues(alpha: 0.1) : AppColors.darkSlate.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  "#${index + 1}",
                                  style: GoogleFonts.outfit(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    color: isSelected ? AppColors.teal : AppColors.darkSlate,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _getPriceLevel(venue['price_level']),
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.teal,
                                ),
                              ),
                              const Spacer(),
                              const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                "${venue['rating'] ?? '?.?'}",
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.darkSlate,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            venue['name'] ?? "Unknown",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.darkSlate,
                            ),
                          ),
                          const SizedBox(height: 6),
                          // ── SELECTED MEMBER ROUTE METRIC ─────────────────
                          Builder(builder: (context) {
                            final memberRoutes = venue['memberRoutes'] as Map<String, dynamic>?;
                            final fallbackEta = venue['averageEtaMinutes'] as int?;
                            final fallbackDistMeters = venue['averageRouteDistanceMeters'] as int?;

                            if (memberRoutes != null) {
                              final myUid = FirebaseAuth.instance.currentUser?.uid;
                              
                              // Build list of UIDs to show route metrics for
                              List<String> uidsToShow = [];
                              
                              if (session.participants.length <= 3) {
                                // Add current user first if present
                                if (myUid != null && session.participants.any((p) => p.uid == myUid)) {
                                  uidsToShow.add(myUid);
                                }
                                // Add the rest
                                for (var p in session.participants) {
                                  if (!uidsToShow.contains(p.uid)) {
                                    uidsToShow.add(p.uid);
                                  }
                                }
                              } else {
                                // > 3 members: show current user + selected member
                                if (myUid != null && session.participants.any((p) => p.uid == myUid)) {
                                  uidsToShow.add(myUid);
                                }
                                if (_selectedParticipantUid != null && !uidsToShow.contains(_selectedParticipantUid)) {
                                  uidsToShow.add(_selectedParticipantUid!);
                                }
                              }

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: uidsToShow.map((pUid) {
                                  final p = session.participants.firstWhere(
                                    (p) => p.uid == pUid,
                                    orElse: () => session.participants.first,
                                  );
                                  final route = memberRoutes[pUid] as Map<String, dynamic>?;
                                  final routeOk = route?['routeAvailable'] == true;
                                  final etaMin = route?['etaMinutes'] as int?;
                                  final distKm = (route?['distanceKm'] as num?)?.toDouble();

                                  String metricLabel;
                                  if (routeOk && etaMin != null && distKm != null) {
                                    if (session.calculationMode == 'Time') {
                                      metricLabel = '$etaMin min  •  ${distKm.toStringAsFixed(1)} km';
                                    } else {
                                      metricLabel = '${distKm.toStringAsFixed(1)} km  •  $etaMin min';
                                    }
                                  } else {
                                    metricLabel = 'Route unavailable';
                                  }

                                  final userColor = AppColors.getUserColor(pUid);
                                  final isMe = pUid == myUid;

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 4.0),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        CircleAvatar(
                                          radius: 9,
                                          backgroundColor: userColor.withValues(alpha: 0.15),
                                          backgroundImage: p.photoUrl != null && p.photoUrl!.isNotEmpty
                                              ? NetworkImage(p.photoUrl!)
                                              : null,
                                          child: (p.photoUrl == null || p.photoUrl!.isEmpty)
                                              ? Text(
                                                  p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                                                  style: GoogleFonts.outfit(
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.bold,
                                                    color: userColor,
                                                  ),
                                                )
                                              : null,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          metricLabel,
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            fontWeight: isMe ? FontWeight.w700 : FontWeight.w600,
                                            color: routeOk ? AppColors.darkSlate : Colors.grey.shade400,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              );
                            } else {
                              // Fallback logic for legacy sessions without memberRoutes
                              final fallbackDistKm = fallbackDistMeters != null ? fallbackDistMeters / 1000.0 : null;
                              String metricLabel;
                              bool isUnavailable = false;

                              if (fallbackEta != null && fallbackEta > 0) {
                                if (session.calculationMode == 'Time') {
                                  metricLabel = fallbackDistKm != null
                                      ? '~$fallbackEta min avg  •  ${fallbackDistKm.toStringAsFixed(1)} km'
                                      : '~$fallbackEta min avg';
                                } else {
                                  metricLabel = fallbackDistKm != null
                                      ? '~${fallbackDistKm.toStringAsFixed(1)} km avg  •  $fallbackEta min'
                                      : '~$fallbackEta min avg';
                                }
                              } else {
                                metricLabel = 'Route unavailable';
                                isUnavailable = true;
                              }

                              return Row(
                                children: [
                                  Icon(
                                    isUnavailable ? Icons.warning_amber_rounded : Icons.near_me_rounded,
                                    size: 14,
                                    color: isUnavailable ? Colors.grey.shade400 : Colors.orange.shade400,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    metricLabel,
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isUnavailable ? Colors.grey.shade400 : Colors.orange.shade700,
                                    ),
                                  ),
                                ],
                              );
                            }
                          }),
                          const SizedBox(height: 6),
                          // ── VOTES + SWIPE HINT ────────────────────────────
                          Row(
                            children: [
                              if (isTrending)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(Icons.bolt_rounded, color: Colors.orange, size: 14),
                                ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: hasVotedForThis ? AppColors.teal : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: hasVotedForThis ? AppColors.teal : Colors.transparent,
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  "$votesCount Votes",
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: hasVotedForThis ? Colors.white : Colors.grey.shade600,
                                  ),
                                ),
                              ),
                              const Spacer(),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Hint Icon (Fades out when open)
                    if (!isOpen)
                      const Icon(Icons.swipe_left_alt_rounded, size: 16, color: Colors.grey),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWinnerPanel(OutingSessionModel session) {
    final winner = session.winner!;
    final name = winner['name'] ?? 'Unknown';
    final rating = winner['rating'];
    final address = winner['vicinity'] ?? winner['address'] ?? '';
    final photoRef = winner['photoReference'];
    String? photoUrl;
    if (photoRef != null) {
      if (photoRef.startsWith('places/')) {
        photoUrl = "https://places.googleapis.com/v1/$photoRef/media?key=${dotenv.env['GOOGLE_MAPS_API_KEY']}&maxHeightPx=800&maxWidthPx=800";
      } else {
        photoUrl = "https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=$photoRef&key=${dotenv.env['GOOGLE_MAPS_API_KEY']}";
      }
    }

    final winnerLoc = winner['location'];
    final vLat = winnerLoc?['latitude'] as double?;
    final vLng = winnerLoc?['longitude'] as double?;

    // Sort participants by distance to the venue
    final sortedP = List<OutingParticipant>.from(session.participants);
    if (vLat != null && vLng != null) {
      sortedP.sort((a, b) {
        if (a.location == null && b.location != null) return 1;
        if (a.location != null && b.location == null) return -1;
        if (a.location == null && b.location == null) return 0;
        final distA = double.parse(_calculateDistance(a.location!.latitude, a.location!.longitude, vLat, vLng));
        final distB = double.parse(_calculateDistance(b.location!.latitude, b.location!.longitude, vLat, vLng));
        return distA.compareTo(distB);
      });
    }

    final myUid = FirebaseAuth.instance.currentUser?.uid;
    final isHost = session.creatorId == myUid;

    return Container(
      color: Colors.white,
      child: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
          ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 10, 24, 40),
          child: Column(
            children: [
              // Back Button & Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.darkSlate.withValues(alpha: 0.05),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: AppColors.darkSlate,
                        size: 18,
                      ),
                    ),
                  ),
                  // Confetti header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.celebration_rounded, color: Colors.amber, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          "WINNER DECIDED",
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: Colors.amber.shade700,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 48), // Spacer to balance the back button
                ],
              ),
              const SizedBox(height: 20),

            // Venue photo
            if (photoUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: SizedBox(
                  height: 140,
                  width: double.infinity,
                  child: CachedNetworkImage(
                    imageUrl: photoUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: Colors.grey.shade100),
                    errorWidget: (_, __, ___) => Container(
                      color: Colors.grey.shade100,
                      child: const Icon(Icons.restaurant_rounded, size: 40),
                    ),
                  ),
                ),
              ),
            if (photoUrl != null) const SizedBox(height: 16),

            // Venue Name
            Text(
              name,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.darkSlate,
              ),
            ),
            const SizedBox(height: 8),

            // Rating + Address
            if (rating != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    '$rating',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkSlate,
                    ),
                  ),
                ],
              ),
            if (address.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                address,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
            const SizedBox(height: 24),
            
            // --- FRIENDS ETA SECTION ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.darkSlate.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.people_alt_rounded, color: AppColors.darkSlate, size: 18),
                      const SizedBox(width: 10),
                      Text(
                        "Friends on the way",
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkSlate,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    itemCount: sortedP.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final p = sortedP[i];
                      final userColor = AppColors.getUserColor(p.uid);
                      
                      String statusText = "Calculating...";
                      bool isArrived = false;

                      if (p.location != null && vLat != null && vLng != null) {
                        // Use real Google values from Firestore if available
                        final dist = p.distanceKm ?? double.parse(_calculateDistance(p.location!.latitude, p.location!.longitude, vLat, vLng));
                        
                        if (dist < 0.1) {
                          isArrived = true;
                          statusText = "Arrived";
                        } else {
                          // Display Google ETA if fresh, otherwise fallback
                          if (p.etaMinutes != null) {
                            statusText = "${p.etaMinutes} min (${dist.toStringAsFixed(1)} km)";
                          } else {
                            statusText = "${_estimateTime(dist)} min (${dist.toStringAsFixed(1)} km)";
                          }
                        }
                      }

                      return Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: userColor, width: 2),
                              image: p.photoUrl != null 
                                ? DecorationImage(image: CachedNetworkImageProvider(p.photoUrl!), fit: BoxFit.cover)
                                : null,
                            ),
                            child: p.photoUrl == null
                              ? Center(child: Text(p.name[0], style: GoogleFonts.outfit(color: userColor, fontWeight: FontWeight.bold)))
                              : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              p.name + (p.uid == myUid ? " (You)" : ""),
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.darkSlate,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isArrived ? AppColors.teal.withValues(alpha: 0.1) : Colors.amber.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              statusText,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isArrived ? AppColors.teal : Colors.amber.shade800,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Navigation Button
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: AppColors.tealGradient),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: AppColors.teal.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8)),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () {
                  final loc = winner['location'];
                  if (loc != null) _glideToVenue(loc['latitude'], loc['longitude']);
                },
                icon: const Icon(Icons.navigation_rounded),
                label: Text("Navigate to Venue", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Live Track Button
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OutingTrackingScreen(
                        groupId: session.groupId,
                        sessionId: session.id,
                        initialSession: session,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.people_alt_rounded, color: AppColors.teal),
                label: Text("Live Track Group", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.darkSlate)),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: AppColors.teal.withValues(alpha: 0.3)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ➕ OUTING TOOLS & SAFETY MENU (PLUS BUTTON)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.white,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    builder: (context) {
                      return StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('groups')
                            .doc(widget.groupId)
                            .collection('outings')
                            .doc(widget.sessionId)
                            .snapshots(),
                        builder: (context, snapshot) {
                          bool mySosActive = false;
                          if (snapshot.hasData && snapshot.data!.exists) {
                            final data = snapshot.data!.data() as Map<String, dynamic>;
                            final participants = data['participants'] as List? ?? [];
                            final me = participants.where((p) => p['uid'] == myUid).firstOrNull;
                            mySosActive = me?['isSosActive'] ?? false;
                          }

                          return Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Outing Tools & Safety",
                                  style: GoogleFonts.outfit(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.darkSlate,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                
                                // 🚨 SOS Emergency
                                ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: mySosActive ? Colors.green : Colors.red,
                                    child: Icon(
                                      mySosActive ? Icons.check_circle_outline : Icons.emergency_rounded,
                                      color: Colors.white,
                                    ),
                                  ),
                                  title: Text(
                                    mySosActive ? "Cancel SOS Emergency" : "SOS Emergency",
                                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: mySosActive ? Colors.green.shade700 : Colors.red.shade700),
                                  ),
                                  subtitle: Text(
                                    mySosActive ? "Click to clear your SOS alert" : "Alert everyone in case of emergency",
                                    style: GoogleFonts.outfit(fontSize: 13),
                                  ),
                                  onTap: () async {
                                    Navigator.pop(context);
                                    if (mySosActive) {
                                      await OutingService().clearSOS(
                                        session: session,
                                        userUid: FirebaseAuth.instance.currentUser?.uid ?? '',
                                      );
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text("SOS Cleared")),
                                        );
                                      }
                                    } else {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: Text("🚨 Trigger SOS?", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.red)),
                                          content: const Text("This will alert everyone in the session and send your location to the group chat. Continue?"),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
                                            TextButton(
                                              onPressed: () => Navigator.pop(context, true),
                                              style: TextButton.styleFrom(foregroundColor: Colors.red),
                                              child: const Text("YES, SOS", style: TextStyle(fontWeight: FontWeight.bold)),
                                            ),
                                          ],
                                        ),
                                      );

                                      if (confirm == true) {
                                        try {
                                          final pos = await Geolocator.getCurrentPosition();
                                          final user = FirebaseAuth.instance.currentUser;
                                          await OutingService().triggerSOS(
                                            session: session,
                                            userUid: user?.uid ?? '',
                                            userName: user?.displayName ?? 'A Friend',
                                            lat: pos.latitude,
                                            lng: pos.longitude,
                                          );
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text("🚨 SOS ACTIVATED. Stay where you are!"),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                        } catch (e) {
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text("Error triggering SOS: $e")),
                                            );
                                          }
                                        }
                                      }
                                    }
                                  },
                                ),

                                // 🧭 AR Compass
                                ListTile(
                                  leading: const CircleAvatar(
                                    backgroundColor: AppColors.teal,
                                    child: Icon(Icons.explore_rounded, color: Colors.white),
                                  ),
                                  title: Text("AR Friend Compass", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                                  subtitle: const Text("Visual 3D pointer to find friends"),
                                  onTap: () {
                                    Navigator.pop(context);
                                    final others = session.participants.where((p) => p.uid != myUid).toList();
                                    if (others.isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text("No other participants in this outing")),
                                      );
                                      return;
                                    }
                                    showModalBottomSheet(
                                      context: context,
                                      backgroundColor: Colors.white,
                                      shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                                      ),
                                      builder: (context) {
                                        return Padding(
                                          padding: const EdgeInsets.all(24.0),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "🧭 AR Friend Compass",
                                                style: GoogleFonts.outfit(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.darkSlate,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                "Select a participant to find with the visual AR pointer",
                                                style: GoogleFonts.outfit(
                                                  fontSize: 14,
                                                  color: Colors.grey.shade600,
                                                ),
                                              ),
                                              const SizedBox(height: 16),
                                              Flexible(
                                                child: ListView.separated(
                                                  shrinkWrap: true,
                                                  itemCount: others.length,
                                                  separatorBuilder: (context, i) => const SizedBox(height: 12),
                                                  itemBuilder: (context, index) {
                                                    final p = others[index];
                                                    return InkWell(
                                                      onTap: () {
                                                        Navigator.pop(context);
                                                        if (p.location != null) {
                                                          Navigator.push(
                                                            context,
                                                            MaterialPageRoute(
                                                              builder: (context) => ArFriendCompassPage(
                                                                friendLat: p.location!.latitude,
                                                                friendLng: p.location!.longitude,
                                                                friendName: p.name,
                                                                friendImageUrl: p.photoUrl,
                                                              ),
                                                            ),
                                                          );
                                                        } else {
                                                          ScaffoldMessenger.of(context).showSnackBar(
                                                            const SnackBar(content: Text("No location available for this friend")),
                                                          );
                                                        }
                                                      },
                                                      borderRadius: BorderRadius.circular(16),
                                                      child: Container(
                                                        padding: const EdgeInsets.all(12),
                                                        decoration: BoxDecoration(
                                                          border: Border.all(color: Colors.grey.shade200),
                                                          borderRadius: BorderRadius.circular(16),
                                                        ),
                                                        child: Row(
                                                          children: [
                                                            ClipOval(
                                                              child: p.photoUrl != null && p.photoUrl!.isNotEmpty
                                                                  ? CachedNetworkImage(
                                                                      imageUrl: p.photoUrl!,
                                                                      width: 44,
                                                                      height: 44,
                                                                      fit: BoxFit.cover,
                                                                    )
                                                                  : Container(
                                                                      width: 44,
                                                                      height: 44,
                                                                      color: Colors.grey.shade200,
                                                                      child: const Icon(Icons.person, color: Colors.grey),
                                                                    ),
                                                            ),
                                                            const SizedBox(width: 16),
                                                            Expanded(
                                                              child: Text(
                                                                p.name,
                                                                style: GoogleFonts.outfit(
                                                                  fontSize: 16,
                                                                  fontWeight: FontWeight.bold,
                                                                  color: AppColors.darkSlate,
                                                                ),
                                                              ),
                                                            ),
                                                            const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
                                                          ],
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),

                                // 🧾 Split Bill
                                ListTile(
                                  leading: const CircleAvatar(
                                    backgroundColor: AppColors.teal,
                                    child: Icon(Icons.receipt_long_rounded, color: Colors.white),
                                  ),
                                  title: Text("Split Bill (AI)", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                                  subtitle: const Text("Auto extract items and parse prices"),
                                  onTap: () {
                                    Navigator.pop(context);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ReceiptSplitterScreen(
                                          participants: session.participants,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  );
                },
                icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.white),
                label: Text("OUTING TOOLS & SAFETY", style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.teal,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 0,
                ),
              ),
            ),
            // Finish session button (Host only)
            if (isHost) ...[
              const SizedBox(height: 24),
              const Divider(height: 1),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text("Finish Outing?", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                        content: const Text("This will close the session for everyone. Are you sure you're done?"),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Not yet")),
                          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Yes, finish!", style: TextStyle(color: Colors.red))),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      if (mounted) {
                        try {
                          await OutingService().markAsFinished(session);
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OutingMemoryUploadScreen(
                                session: session,
                              ),
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Error finishing outing: $e")),
                          );
                        }
                      }
                    }
                  },
                  icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
                  label: Text("Finish Outing", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.2)),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    backgroundColor: Colors.redAccent.withValues(alpha: 0.03),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  ),
).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2);
}

  Widget _buildBackButton(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.darkSlate, size: 20),
      ),
    );
  }

  bool _isVenueTrending(Map<String, dynamic> venue, OutingSessionModel session) {
    final venues = session.finalLocation?['topVenues'] ?? [];
    if (venues.isEmpty) return false;
    int maxVotes = 0;
    for (var v in venues) {
      final vCount = (v['votes'] as List?)?.length ?? 0;
      if (vCount > maxVotes) maxVotes = vCount;
    }
    if (maxVotes == 0) return false;
    final currentVotes = (venue['votes'] as List?)?.length ?? 0;
    return currentVotes == maxVotes;
  }

  String _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295;
    final a = 0.5 -
        math.cos((lat2 - lat1) * p) / 2 +
        math.cos(lat1 * p) *
            math.cos(lat2 * p) *
            (1 - math.cos((lon2 - lon1) * p)) /
            2;
    final double dist = 12742 * math.asin(math.sqrt(a));
    return dist.toStringAsFixed(1);
  }

  String _estimateTime(double distanceKm) {
    // Basic city estimation: 1.5 mins per km + 2 mins traffic pad
    final mins = (distanceKm * 1.5) + 2;
    return mins.toInt().toString();
  }
}

