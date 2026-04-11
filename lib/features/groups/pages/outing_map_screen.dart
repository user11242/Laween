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
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geolocator_apple/geolocator_apple.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/colors.dart';
import '../data/models/outing_session_model.dart';
import 'outing_tracking_screen.dart';
import '../data/services/outing_service.dart';

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
  final PageController _pageController = PageController(viewportFraction: 0.85);
  
  Set<Marker> _markers = {};
  int _currentVenueIndex = 0;
  bool _isDisposed = false;
  final bool _isTrackingMode = false;
  bool _showWinnerDetails = true;
  StreamSubscription<Position>? _positionSubscription;
  DateTime? _lastLocationUpdate;

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
    _stopLiveTracking();
    _pageController.dispose();
    super.dispose();
  }

  void _startLiveTracking() async {
    if (_positionSubscription != null) return;

    // 1. Check Permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    // 2. Listen to Location Stream
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: AppleSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 20,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
      ),
    ).listen((Position position) {
      if (_isDisposed) return;

      // Throttle updates to every 5 seconds to save battery/Firestore writes
      final now = DateTime.now();
      if (_lastLocationUpdate == null || now.difference(_lastLocationUpdate!).inSeconds >= 5) {
        _lastLocationUpdate = now;
        _outingService.updateParticipantLocation(
          groupId: widget.groupId,
          sessionId: widget.sessionId,
          uid: FirebaseAuth.instance.currentUser?.uid ?? "",
          location: GeoPoint(position.latitude, position.longitude),
        );
      }
    });
  }

  void _stopLiveTracking() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  Future<BitmapDescriptor> _getAvatarIcon(String name, int index) async {
    if (_customMarkers.containsKey(name)) return _customMarkers[name]!;

    final colors = [
      const Color(0xFF00C9A7),
      const Color(0xFF0097A7),
      const Color(0xFF00B4CC),
      const Color(0xFF009688),
      const Color(0xFF26A69A),
    ];
    final color = colors[index % colors.length];

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const size = 110.0;
    const radius = size / 2;

    // Outer glow
    final glowPaint = Paint()
      ..color = AppColors.teal.withOpacity(0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(const Offset(radius, radius), radius - 10, glowPaint);

    // Main circle
    final paint = Paint()..color = color;
    canvas.drawCircle(const Offset(radius, radius), radius - 15, paint);

    // Border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawCircle(const Offset(radius, radius), radius - 15, borderPaint);

    // Text
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

    final picture = recorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final descriptor = BitmapDescriptor.bytes(byteData!.buffer.asUint8List());

    _customMarkers[name] = descriptor;
    return descriptor;
  }

  String _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295;
    final a = 0.5 -
        math.cos((lat2 - lat1) * p) / 2 +
        math.cos(lat1 * p) *
            math.cos(lat2 * p) *
            (1 - math.cos((lon2 - lon1) * p)) /
            2;
    final double dist = 12742 * math.asin(math.sqrt(a)); // 2 * R; R = 6371 km
    return dist.toStringAsFixed(1);
  }

  String _estimateTime(double distanceKm) {
    // Rough estimation: 2 mins per km + 3 mins base traffic
    final mins = (distanceKm * 2) + 3;
    return mins.toInt().toString();
  }

  String _getPriceLevel(int? level) {
    if (level == null || level <= 0) return r"$";
    return List.generate(level, (_) => r"$").join("");
  }

  Future<void> _updateMarkers(OutingSessionModel session) async {
    if (_isDisposed || !mounted) return;

    final Set<Marker> newMarkers = {};

    // 1. Participant Markers
    for (int i = 0; i < session.participants.length; i++) {
      final p = session.participants[i];
      if (p.location != null) {
        final icon = await _getAvatarIcon(p.name, i);
        if (_isDisposed || !mounted) return;
        newMarkers.add(
          Marker(
            markerId: MarkerId('p_${p.uid}'),
            position: LatLng(p.location!.latitude, p.location!.longitude),
            infoWindow: InfoWindow(title: p.name),
            icon: icon,
          ),
        );
      }
    }

    // 2. Venue Markers (The suggestions)
    final List venues = session.finalLocation?['topVenues'] ?? [];
    for (int i = 0; i < venues.length; i++) {
      final v = venues[i];
      final loc = v['location'];
      if (loc != null) {
        newMarkers.add(
          Marker(
            markerId: MarkerId('v_${v['id']}'),
            position: LatLng(loc['latitude'], loc['longitude']),
            onTap: () {
              if (mounted) {
                _pageController.animateToPage(i,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut);
              }
            },
            icon: BitmapDescriptor.defaultMarkerWithHue(
                i == _currentVenueIndex
                    ? BitmapDescriptor.hueRose
                    : BitmapDescriptor.hueRed),
          ),
        );
      }
    }

    if (_isDisposed || !mounted) return;

    if (!_markers.containsAll(newMarkers) || _markers.length != newMarkers.length) {
      setState(() {
        _markers = newMarkers;
      });
      
      // Only fit bounds on first load or when participants change significantly
      if (_markers.isNotEmpty) {
        _fitBounds();
      }
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
      
      // If tracking mode is on, be more aggressive with the zoom/padding
      final padding = _isTrackingMode ? 120.0 : 100.0;
      controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, padding));
    }
  }

  Future<void> _moveCamera(LatLng position) async {
    if (_isDisposed || !mounted || !_controller.isCompleted) return;
    final controller = await _controller.future;
    if (_isDisposed || !mounted) return;
    
    controller.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(
        target: position,
        zoom: 16.5,
        tilt: 45,
        bearing: 30,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<OutingSessionModel?>(
      stream: _outingService.streamSession(widget.groupId, widget.sessionId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return Scaffold(
            backgroundColor: AppColors.darkSlate,
            body: const Center(child: CircularProgressIndicator(color: AppColors.teal)),
          );
        }

        final session = snapshot.data!;
        
        // Auto-start tracking if session is completed (winner declared)
        if (session.status == OutingStatus.completed) {
          _startLiveTracking();
        }

        return PopScope(
          canPop: session.status == OutingStatus.completed,
          child: Scaffold(
            backgroundColor: AppColors.darkSlate,
            body: Builder(
              builder: (context) {
                final venues = session.finalLocation?['topVenues'] ?? [];
                
                // Initial camera position (Midpoint)
                final midLat = session.finalLocation?['center']?['lat'] ?? 0.0;
                final midLng = session.finalLocation?['center']?['lng'] ?? 0.0;

                // Side effect: update markers
                WidgetsBinding.instance.addPostFrameCallback((_) => _updateMarkers(session));

                return Stack(
                  children: [
                    // 1. THE MAP
                    GoogleMap(
                      key: const ValueKey('outing_map'),
                      initialCameraPosition: CameraPosition(
                        target: LatLng(midLat, midLng),
                        zoom: 14.5,
                        tilt: 0,
                        bearing: 0,
                      ),
                      style: _mapStyle,
                      markers: _markers,
                      buildingsEnabled: true,
                      indoorViewEnabled: false,
                      onMapCreated: (controller) {
                        if (!_controller.isCompleted) {
                          _controller.complete(controller);
                          Future.delayed(const Duration(milliseconds: 500), () => _fitBounds());
                        }
                      },
                      zoomControlsEnabled: false,
                      myLocationButtonEnabled: false,
                      compassEnabled: false,
                      mapToolbarEnabled: false,
                    ),

                    // 2. PREMIUM HEADER
                    _buildHeader(session),

                    // 3. VENUE MAILBOX (Carousel)
                    if (venues.isNotEmpty && session.calculationMode != 'Fixed')
                      _buildVenueCarousel(venues, session),

                    // 4. WINNER OVERLAY
                    if (session.status == OutingStatus.completed)
                      _buildWinnerOverlay(session),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildWinnerOverlay(OutingSessionModel session) {
    final winner = session.winner;
    if (winner == null) return const SizedBox();

    if (!_showWinnerDetails) {
      // MINI BAR (Tracking Mode Active)
      return Positioned(
        bottom: 40,
        left: 20,
        right: 20,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 10),
              )
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.teal.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.celebration_rounded, color: AppColors.teal, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      winner['name'] ?? "Destination",
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkSlate,
                      ),
                    ),
                    Text(
                      "Everyone is on the road!",
                      style: GoogleFonts.inter(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.expand_less_rounded),
                onPressed: () => setState(() => _showWinnerDetails = true),
              ),
            ],
          ),
        ).animate().slideY(begin: 1, duration: 400.ms),
      );
    }

    // FULL SCREEN WINNER PAGE
    final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'];
    final photoRef = winner['photoReference'];
    final imageUrl = photoRef != null
        ? "https://places.googleapis.com/v1/$photoRef/media?key=$apiKey&maxHeightPx=800"
        : null;

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // 1. HEADER
          Container(
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
            color: AppColors.darkSlate,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.teal.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  "THE WINNER",
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 2. HERO IMAGE
                  ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Stack(
                      children: [
                        if (imageUrl != null)
                          CachedNetworkImage(
                            imageUrl: imageUrl,
                            height: 240,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          )
                        else
                          Container(
                            height: 240,
                            width: double.infinity,
                            color: Colors.grey.shade100,
                            child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey),
                          ),
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.7),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 20,
                          left: 20,
                          right: 20,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                winner['name'] ?? "Unknown",
                                style: GoogleFonts.outfit(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                "Winning Destination",
                                style: GoogleFonts.inter(
                                  color: AppColors.teal,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // 3. FRIENDS' PROGRESS (Leaderboard Style)
                  Text(
                    "FRIENDS' PROGRESS",
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: Colors.grey.shade400,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    itemCount: session.participants.length,
                    itemBuilder: (context, index) {
                      final p = session.participants[index];
                      if (p.location == null) return const SizedBox();
                      
                      final vLat = winner['location']['latitude'] as double;
                      final vLng = winner['location']['longitude'] as double;
                      final dist = double.parse(_calculateDistance(
                          p.location!.latitude, p.location!.longitude, vLat, vLng));
                      final time = _estimateTime(dist);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey.shade100),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: index == 0 ? Colors.amber : Colors.grey.shade200,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  "${index + 1}",
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold,
                                    color: index == 0 ? Colors.white : Colors.grey.shade600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.name,
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.darkSlate,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      const Icon(Icons.near_me_rounded, color: AppColors.teal, size: 12),
                                      const SizedBox(width: 4),
                                      Text(
                                        "$dist km",
                                        style: GoogleFonts.inter(fontSize: 11, color: Colors.grey),
                                      ),
                                      const SizedBox(width: 12),
                                      const Icon(Icons.access_time_filled_rounded, color: Colors.amber, size: 12),
                                      const SizedBox(width: 4),
                                      Text(
                                        "$time min",
                                        style: GoogleFonts.inter(fontSize: 11, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 100), // Space for buttons
                ],
              ),
            ),
          ),

          // 4. ACTION BUTTONS
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.person_pin_circle_outlined, size: 18),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OutingTrackingScreen(
                            groupId: widget.groupId,
                            sessionId: widget.sessionId,
                          ),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.teal,
                      side: const BorderSide(color: AppColors.teal, width: 2),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    label: Text(
                      "TRACK FRIENDS' JOURNEY",
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.navigation_rounded, size: 18),
                    onPressed: () async {
                      final lat = winner['location']?['latitude'];
                      final lng = winner['location']?['longitude'];
                      if (lat != null && lng != null) {
                        final url = Uri.parse("https://www.google.com/maps/search/?api=1&query=$lat,$lng");
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url);
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    label: Text(
                      "GET DIRECTIONS",
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "EXIT DISCOVERY",
                    style: GoogleFonts.inter(color: Colors.grey, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildHeader(OutingSessionModel session) {
    final isFixed = session.calculationMode == 'Fixed';
    return Positioned(
      top: 60,
      right: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.darkSlate.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Icon(isFixed ? Icons.lock_rounded : Icons.radar_rounded, color: AppColors.teal, size: 18),
            const SizedBox(width: 8),
            Text(
              isFixed ? "Locked Journey" : "Discovery Room",
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ).animate().fadeIn().slideX(begin: 0.2),
    );
  }

  Widget _buildVenueCarousel(List venues, OutingSessionModel session) {
    return Positioned(
      bottom: 30,
      left: 0,
      right: 0,
      height: 280, // Increased for travel data
      child: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() => _currentVenueIndex = index);
          final loc = venues[index]['location'];
          if (loc != null) {
            _moveCamera(LatLng(loc['latitude'], loc['longitude']));
          }
        },
        itemCount: venues.length,
        itemBuilder: (context, index) {
          final venue = venues[index];
          return _buildVenueCard(venue, session);
        },
      ),
    );
  }

  Widget _buildVenueCard(
      Map<String, dynamic> venue, OutingSessionModel session) {
    final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'];
    final photoRef = venue['photoReference'];
    final imageUrl = photoRef != null
        ? "https://places.googleapis.com/v1/$photoRef/media?key=$apiKey&maxHeightPx=400"
        : null;

    final votesCount = (venue['votes'] as List?)?.length ?? 0;
    final totalParticipants = session.participants.length;

    final vLat = venue['location']['latitude'] as double;
    final vLng = venue['location']['longitude'] as double;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  // Image
                  if (imageUrl != null)
                    CachedNetworkImage(
                      imageUrl: imageUrl,
                      width: 130,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    )
                  else
                    Container(
                      width: 130,
                      color: Colors.grey.shade100,
                      child: const Icon(Icons.image_not_supported_outlined,
                          color: Colors.grey),
                    ),

                  // Details
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  venue['name'] ?? "Unknown",
                                  style: GoogleFonts.outfit(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.darkSlate,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                _getPriceLevel(venue['priceLevel']),
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.teal,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.star_rounded,
                                  color: Colors.amber, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                "${venue['rating'] ?? 'N/A'} (${venue['userRatingCount'] ?? 0})",
                                style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Travel Data
                          Text(
                            "ARRIVALS",
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: Colors.grey.shade400,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Expanded(
                            child: ListView.builder(
                              padding: EdgeInsets.zero,
                              itemCount: session.participants.length,
                              itemBuilder: (context, i) {
                                final p = session.participants[i];
                                if (p.location == null) return const SizedBox();
                                final dist = double.parse(_calculateDistance(
                                    p.location!.latitude,
                                    p.location!.longitude,
                                    vLat,
                                    vLng));
                                final time = _estimateTime(dist);
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 2),
                                  child: Row(
                                    children: [
                                      Text(
                                        p.name.isNotEmpty ? p.name.split(' ')[0] : 'User',
                                        style: GoogleFonts.inter(
                                            fontSize: 11,
                                            color: AppColors.darkSlate,
                                            fontWeight: FontWeight.w600),
                                      ),
                                      const Spacer(),
                                      Text(
                                        "$time min ($dist km)",
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          color: AppColors.teal,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Bottom Vote Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border(top: BorderSide(color: Colors.grey.shade100)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "$votesCount / $totalParticipants Votes",
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.teal,
                    ),
                  ),
                  _buildVoteButton(venue, session),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoteButton(Map<String, dynamic> venue, OutingSessionModel session) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final hasVoted = (venue['votes'] as List?)?.contains(uid) ?? false;

    return GestureDetector(
      onTap: () => _outingService.voteForVenue(
        groupId: widget.groupId,
        sessionId: widget.sessionId,
        venueId: venue['id'],
        uid: uid,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: hasVoted ? AppColors.teal.withOpacity(0.1) : AppColors.teal,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.teal),
        ),
        child: Text(
          hasVoted ? "VOTED" : "VOTE",
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: hasVoted ? AppColors.teal : Colors.white,
          ),
        ),
      ),
    );
  }
}
