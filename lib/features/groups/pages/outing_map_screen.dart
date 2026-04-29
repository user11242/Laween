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
import '../../../core/theme/colors.dart';
import '../data/models/outing_session_model.dart';
import 'outing_tracking_screen.dart';
import '../data/services/outing_service.dart';
import '../../../core/services/location_service.dart';

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
    _pageController.dispose();
    super.dispose();
  }

  void _startLiveTracking() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      LocationService().setActiveSession(widget.groupId, widget.sessionId);
      LocationService().startTracking(uid);
    }
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
      ..color = AppColors.teal.withValues(alpha: 0.5)
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
                _pageController.animateToPage(
                  i,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              }
            },
            icon: BitmapDescriptor.defaultMarkerWithHue(
              i == _currentVenueIndex
                  ? BitmapDescriptor.hueRose
                  : BitmapDescriptor.hueRed,
            ),
          ),
        );
      }
    }

    if (_isDisposed || !mounted) return;

    if (!_markers.containsAll(newMarkers) ||
        _markers.length != newMarkers.length) {
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

    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: position, zoom: 16.5, tilt: 45, bearing: 30),
      ),
    );
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
                WidgetsBinding.instance.addPostFrameCallback(
                  (_) => _updateMarkers(session),
                );

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
                          Future.delayed(
                            const Duration(milliseconds: 500),
                            () => _fitBounds(),
                          );
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
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.teal.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.celebration_rounded,
                  color: AppColors.teal,
                  size: 20,
                ),
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
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.grey,
                      ),
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
                    color: AppColors.teal.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.emoji_events_rounded,
                    color: Colors.amber,
                    size: 24,
                  ),
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
                            child: const Icon(
                              Icons.image_not_supported_outlined,
                              color: Colors.grey,
                            ),
                          ),
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.7),
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
                      final dist = double.parse(
                        _calculateDistance(
                          p.location!.latitude,
                          p.location!.longitude,
                          vLat,
                          vLng,
                        ),
                      );
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
                              color: Colors.black.withValues(alpha: 0.05),
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
                                color: index == 0
                                    ? Colors.amber
                                    : Colors.grey.shade200,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  "${index + 1}",
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold,
                                    color: index == 0
                                        ? Colors.white
                                        : Colors.grey.shade600,
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
                                      const Icon(
                                        Icons.near_me_rounded,
                                        color: AppColors.teal,
                                        size: 12,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        "$dist km",
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      const Icon(
                                        Icons.access_time_filled_rounded,
                                        color: Colors.amber,
                                        size: 12,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        "$time min",
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          color: Colors.grey,
                                        ),
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
                  color: Colors.black.withValues(alpha: 0.1),
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
                  // 5. TRACK FRIENDS BUTTON
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OutingTrackingScreen(
                            groupId: widget.groupId,
                            sessionId: widget.sessionId,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.location_history_rounded, size: 18),
                    label: Text(
                      "LOCATE FRIENDS",
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.teal,
                      side: const BorderSide(color: AppColors.teal, width: 2),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
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
                        final url = Uri.parse(
                          "https://www.google.com/maps/search/?api=1&query=$lat,$lng",
                        );
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url);
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
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
                    style: GoogleFonts.inter(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
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
          color: AppColors.darkSlate.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          boxShadow: [
            BoxShadow(
              color: AppColors.teal.withValues(alpha: 0.2),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: AppColors.teal,
                    shape: BoxShape.circle,
                  ),
                ).animate(onPlay: (controller) => controller.repeat())
                 .scale(begin: const Offset(1, 1), end: const Offset(2.5, 2.5), duration: 1500.ms)
                 .fadeOut(duration: 1500.ms),
                const Icon(
                  Icons.radar_rounded,
                  color: AppColors.teal,
                  size: 16,
                ),
              ],
            ),
            const SizedBox(width: 10),
            Text(
              isFixed ? "Locked Journey" : "Discovery Room",
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
                letterSpacing: 0.5,
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
      height: 440, // Increased height for vertical-style cards
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
    Map<String, dynamic> venue,
    OutingSessionModel session,
  ) {
    final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'];
    final photoRef = venue['photoReference'];
    final imageUrl = photoRef != null
        ? "https://places.googleapis.com/v1/$photoRef/media?key=$apiKey&maxHeightPx=800"
        : null;

    final votesCount = (venue['votes'] as List?)?.length ?? 0;
    final totalParticipants = session.participants.length;

    final vLat = venue['location']['latitude'] as double;
    final vLng = venue['location']['longitude'] as double;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Column(
          children: [
            // 1. Hero Content (Image with info overlay)
            Expanded(
              flex: 5,
              child: Stack(
                children: [
                  // Image
                  Positioned.fill(
                    child: imageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            color: Colors.grey.shade100,
                            child: const Icon(
                              Icons.restaurant_rounded,
                              color: Colors.grey,
                              size: 48,
                            ),
                          ),
                  ),
                  // Gradient Overlay
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.8),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Floating Rating Badge
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: BackdropFilter(
                          filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                color: Colors.amber,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "${venue['rating'] ?? 'N/A'}",
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Price Level & Name (Bottom Left on image)
                  Positioned(
                    bottom: 16,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.teal,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _getPriceLevel(venue['priceLevel']),
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "${venue['userRatingCount'] ?? 0} Reviews",
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: Colors.white.withValues(alpha: 0.7),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          venue['name'] ?? "Unknown",
                          style: GoogleFonts.outfit(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // 2. Arrivals Section (Horizontal scrolling profile bubbles)
            Container(
              height: 100, // Fixed height to avoid overflow
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      "WHO'S ARRIVING",
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: Colors.grey.shade400,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: session.participants.length,
                      itemBuilder: (context, i) {
                        final p = session.participants[i];
                        if (p.location == null) return const SizedBox();
                        final dist = double.parse(
                          _calculateDistance(
                            p.location!.latitude,
                            p.location!.longitude,
                            vLat,
                            vLng,
                          ),
                        );
                        final time = _estimateTime(dist);
                        final userColor = _getUserColor(p.uid);

                        return Container(
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.fromLTRB(6, 6, 12, 6),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.grey.shade100),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: userColor.withValues(alpha: 0.1),
                                backgroundImage: p.photoUrl != null && p.photoUrl!.isNotEmpty
                                    ? NetworkImage(p.photoUrl!)
                                    : null,
                                child: p.photoUrl == null || p.photoUrl!.isEmpty
                                    ? Text(
                                        p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: userColor,
                                        ),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 8),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.name.split(' ')[0],
                                    style: GoogleFonts.inter(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.darkSlate,
                                    ),
                                  ),
                                  Text(
                                    "$time min ($dist km)",
                                    style: GoogleFonts.inter(
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.teal,
                                    ),
                                  ),
                                ],
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
            // 3. Action Bar (Vote & Total)
            Container(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "$votesCount / $totalParticipants",
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: AppColors.darkSlate,
                          ),
                        ),
                        Text(
                          "Total Votes",
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: _buildVoteButton(venue, session),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoteButton(
    Map<String, dynamic> venue,
    OutingSessionModel session,
  ) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final hasVoted = (venue['votes'] as List?)?.contains(uid) ?? false;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _outingService.voteForVenue(
          groupId: widget.groupId,
          sessionId: widget.sessionId,
          venueId: venue['id'],
          uid: uid,
        ),
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: hasVoted
                ? null
                : const LinearGradient(
                    colors: [AppColors.teal, Color(0xFF00B4CC)],
                  ),
            color: hasVoted ? Colors.grey.shade100 : null,
            borderRadius: BorderRadius.circular(16),
            boxShadow: hasVoted
                ? []
                : [
                    BoxShadow(
                      color: AppColors.teal.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  hasVoted ? Icons.check_circle_rounded : Icons.how_to_vote_rounded,
                  size: 16,
                  color: hasVoted ? Colors.grey : Colors.white,
                ),
                const SizedBox(width: 8),
                Text(
                  hasVoted ? "VOTED" : "CAST VOTE",
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: hasVoted ? Colors.grey : Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getUserColor(String uid) {
    final List<Color> colors = [
      AppColors.teal,
      Colors.blueAccent,
      Colors.purpleAccent,
      Colors.pinkAccent,
      Colors.orangeAccent,
      Colors.indigoAccent,
      Colors.cyan,
      Colors.tealAccent.shade700,
    ];
    return colors[uid.hashCode % colors.length];
  }
}
