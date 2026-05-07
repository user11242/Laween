// lib/features/groups/pages/outing_tracking_screen.dart

import 'dart:async';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/services/google_maps_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/colors.dart';
import '../data/models/outing_session_model.dart';
import '../data/services/outing_service.dart';
import '../../../core/services/location_service.dart';
import '../widgets/sos_alarm_overlay.dart';

class OutingTrackingScreen extends StatefulWidget {
  final String groupId;
  final String sessionId;
  final OutingSessionModel? initialSession;

  const OutingTrackingScreen({
    super.key,
    required this.groupId,
    required this.sessionId,
    this.initialSession,
  });

  @override
  State<OutingTrackingScreen> createState() => _OutingTrackingScreenState();
}

class _OutingTrackingScreenState extends State<OutingTrackingScreen> {
  final OutingService _outingService = OutingService();
  final Completer<GoogleMapController> _controller = Completer();

  Set<Marker> _markers = {};
  bool _isDisposed = false;
  final Map<String, BitmapDescriptor> _customMarkers = {};
  bool _hasInitialFit = false;
  bool _shouldFollow = true; // User can toggle this behavior
  String? _selectedParticipantUid;
  Set<Polyline> _polylines = {};
  final Map<String, List<LatLng>> _cachedRoutes = {};

  LatLng _getInitialTarget() {
    final session = widget.initialSession;
    if (session != null) {
      final winner = session.winner;
      if (winner != null && winner['location'] != null) {
        return LatLng(
          (winner['location']['latitude'] as num).toDouble(),
          (winner['location']['longitude'] as num).toDouble(),
        );
      }
      for (var p in session.participants) {
        if (p.location != null) {
          return LatLng(p.location!.latitude, p.location!.longitude);
        }
      }
    }
    return const LatLng(25.2048, 55.2708); // absolute fallback
  }

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      LocationService().setActiveSession(widget.groupId, widget.sessionId);
      LocationService().startTracking(uid);
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  Future<BitmapDescriptor> _getAvatarIcon(
    String name,
    String? photoUrl,
    Color color,
  ) async {
    final cacheKey = "avatar_${photoUrl ?? name}_${color.toARGB32()}";
    if (_customMarkers.containsKey(cacheKey)) return _customMarkers[cacheKey]!;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const size = 110.0;
    const radius = size / 2;

    // Outer glow ring (strong, colored)
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(Offset(radius, radius), radius - 8, glowPaint);

    // Colored border ring
    final ringPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;
    canvas.drawCircle(Offset(radius, radius), radius - 8, ringPaint);

    // White inner border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    if (photoUrl != null && photoUrl.isNotEmpty) {
      try {
        final Completer<ui.Image> completer = Completer();
        final imageStream = NetworkImage(
          photoUrl,
        ).resolve(ImageConfiguration.empty);
        imageStream.addListener(
          ImageStreamListener(
            (info, _) {
              if (!completer.isCompleted) completer.complete(info.image);
            },
            onError: (exception, stackTrace) {
              if (!completer.isCompleted) completer.completeError(exception);
            },
          ),
        );

        final ui.Image image = await completer.future.timeout(
          const Duration(seconds: 4),
        );

        canvas.save();
        Path path = Path()
          ..addOval(
            Rect.fromCircle(
              center: Offset(radius, radius),
              radius: radius - 16,
            ),
          );
        canvas.clipPath(path);

        paintImage(
          canvas: canvas,
          rect: Rect.fromCircle(
            center: Offset(radius, radius),
            radius: radius - 16,
          ),
          image: image,
          fit: BoxFit.cover,
        );
        canvas.restore();
        canvas.drawCircle(
          const Offset(radius, radius),
          radius - 16,
          borderPaint,
        );
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

  void _drawInitialMarker(
    Canvas canvas,
    double radius,
    Color color,
    String name,
    Paint borderPaint,
  ) {
    final paint = Paint()..color = color;
    canvas.drawCircle(Offset(radius, radius), radius - 16, paint);
    canvas.drawCircle(Offset(radius, radius), radius - 16, borderPaint);

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
    final double dist = 12742 * math.asin(math.sqrt(a));
    return dist.toStringAsFixed(1);
  }

  String _estimateTime(double distanceKm) {
    // Basic city estimation algorithm: 40km/h average -> 1.5 mins per km + 2 mins traffic pad.
    final mins = (distanceKm * 1.5) + 2;
    return mins.toInt().toString();
  }

  Future<void> _fitRouteBounds(
    double pLat,
    double pLng,
    dynamic winnerLoc,
  ) async {
    if (!_controller.isCompleted) return;
    final controller = await _controller.future;
    final vLat = (winnerLoc['latitude'] as num).toDouble();
    final vLng = (winnerLoc['longitude'] as num).toDouble();

    final minLat = math.min(pLat, vLat);
    final maxLat = math.max(pLat, vLat);
    final minLng = math.min(pLng, vLng);
    final maxLng = math.max(pLng, vLng);

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
    // Large padding to account for ETA sheet at the bottom
    controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 120.0));
  }

  Future<void> _updateMarkers(OutingSessionModel session) async {
    if (_isDisposed || !mounted) return;

    final Set<Marker> newMarkers = {};
    final Set<Polyline> newPolylines = {};
    final winner = session.winner;
    final winnerLoc = winner?['location'];

    // 1. Destination Marker
    if (winnerLoc != null) {
      newMarkers.add(
        Marker(
          markerId: const MarkerId('v_winner'),
          position: LatLng(
            (winnerLoc['latitude'] as num).toDouble(),
            (winnerLoc['longitude'] as num).toDouble(),
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueOrange,
          ),
          infoWindow: InfoWindow(title: winner?['name'] ?? "Destination"),
        ),
      );
    }

    // 2. Participant Live Avatars
    final List<Future<Marker?>> participantMarkerFutures = [];
    for (int i = 0; i < session.participants.length; i++) {
      final p = session.participants[i];
      if (p.location != null) {
        participantMarkerFutures.add(() async {
          final color = AppColors.getUserColor(p.uid);
          final icon = await _getAvatarIcon(p.name, p.photoUrl, color);
          if (_isDisposed || !mounted) return null;
          return Marker(
            markerId: MarkerId('p_${p.uid}'),
            position: LatLng(p.location!.latitude, p.location!.longitude),
            infoWindow: InfoWindow(title: p.name),
            icon: icon,
            anchor: const Offset(0.5, 0.5),
            onTap: () {
              setState(() {
                if (_selectedParticipantUid == p.uid) {
                  _selectedParticipantUid = null;
                } else {
                  _selectedParticipantUid = p.uid;
                }
              });
              _updateMarkers(session); // Re-trigger to update polylines
              if (_selectedParticipantUid != null && winnerLoc != null) {
                _shouldFollow =
                    false; // Stop auto-following when they inspect a route
                _fitRouteBounds(
                  p.location!.latitude,
                  p.location!.longitude,
                  winnerLoc,
                );
              }
            },
          );
        }());
      }
    }

    final results = await Future.wait(participantMarkerFutures);
    for (var m in results) {
      if (m != null) newMarkers.add(m);
    }

    // 3. Handle Selected Polyline
    if (_selectedParticipantUid != null && winnerLoc != null) {
      final selectedP = session.participants.firstWhere(
        (p) => p.uid == _selectedParticipantUid,
      );
      if (selectedP.location != null) {
        List<LatLng>? route = _cachedRoutes[_selectedParticipantUid!];
        if (route == null) {
          route = await GoogleMapsService().getRoutePolyline(
            originLat: selectedP.location!.latitude,
            originLng: selectedP.location!.longitude,
            destLat: (winnerLoc['latitude'] as num).toDouble(),
            destLng: (winnerLoc['longitude'] as num).toDouble(),
          );
          if (route != null) {
            _cachedRoutes[_selectedParticipantUid!] = route;
          }
        }

        if (route != null && mounted) {
          final color = AppColors.getUserColor(selectedP.uid);
          newPolylines.add(
            Polyline(
              polylineId: PolylineId('route_${_selectedParticipantUid}'),
              points: route,
              color: color,
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

    // Guard against infinite rebuild loops
    bool markersChanged = false;
    if (newMarkers.length != _markers.length) {
      markersChanged = true;
    } else {
      for (var newM in newMarkers) {
        final oldM = _markers
            .where((m) => m.markerId == newM.markerId)
            .firstOrNull;
        if (oldM == null || oldM.position != newM.position) {
          markersChanged = true;
          break;
        }
      }
    }
    bool polylinesChanged = newPolylines.length != _polylines.length;

    if (markersChanged || polylinesChanged) {
      if (mounted) {
        setState(() {
          _markers = newMarkers;
          _polylines = newPolylines;
        });
      }
      // Only auto-fit once or if 'follow' is enabled
      if (!_hasInitialFit || _shouldFollow) {
        _fitBounds();
        _hasInitialFit = true;
      }
    }

    // 4. Detect First Arrival
    if (session.firstArrivedUid == null) {
      final myUid = FirebaseAuth.instance.currentUser?.uid;
      final me = session.participants.firstWhere(
        (p) => p.uid == myUid,
        orElse: () => session.participants.first,
      ); // Fallback to avoid error

      if (me.location != null && winnerLoc != null) {
        final vLat = (winnerLoc['latitude'] as num).toDouble();
        final vLng = (winnerLoc['longitude'] as num).toDouble();

        final dist = double.parse(
          _calculateDistance(
            me.location!.latitude,
            me.location!.longitude,
            vLat,
            vLng,
          ),
        );

        if (dist <= 0.1) {
          // 100 meters
          _outingService.recordFirstArrival(
            widget.groupId,
            session.id,
            myUid ?? '',
          );
        }
      }
    }
  }

  Future<void> _animateToUser(String uid) async {
    if (!_controller.isCompleted) return;
    final controller = await _controller.future;

    // Find the participant's location
    final snapshot = await FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId)
        .collection('outings')
        .doc(widget.sessionId)
        .get();

    if (snapshot.exists) {
      final session = OutingSessionModel.fromFirestore(snapshot);
      final participant = session.participants
          .where((p) => p.uid == uid)
          .firstOrNull;
      if (participant != null && participant.location != null) {
        controller.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(
              participant.location!.latitude,
              participant.location!.longitude,
            ),
            16.0,
          ),
        );
      }
    }
  }

  Future<void> _fitBounds() async {
    if (_markers.isEmpty || !_controller.isCompleted) return;
    final controller = await _controller.future;

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
      // Give 150 offset specifically so the Bottom Sheet doesn't block the markers
      controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 150.0));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      body: StreamBuilder<OutingSessionModel?>(
        stream: _outingService.streamSession(widget.groupId, widget.sessionId),
        initialData: widget.initialSession,
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data == null) {
            return _buildSkeletonLoader();
          }

          final session = snapshot.data!;
          final winner = session.winner;

          WidgetsBinding.instance.addPostFrameCallback((_) {
            _updateMarkers(session);
            _syncLiveActivity(session, winner);
          });

          return Stack(
            children: [
              // --- 1. THE MAP ---
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _getInitialTarget(),
                  zoom: 12,
                ),
                myLocationEnabled: false,
                compassEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                markers: _markers,
                polylines: _polylines,
                onMapCreated: (controller) {
                  if (!_controller.isCompleted) {
                    _controller.complete(controller);
                  }
                  Future.delayed(const Duration(milliseconds: 300), () {
                    if (mounted) _fitBounds();
                  });
                },
                onCameraMoveStarted: () {
                  if (_shouldFollow) {
                    setState(() {
                      _shouldFollow = false;
                    });
                  }
                },
              ),

              // --- 2. PREMIUM GLASS HEADER ---
              Positioned(
                top: 55,
                left: 20,
                right: 20,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.darkSlate.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              margin: const EdgeInsets.all(4),
                              padding: const EdgeInsets.all(12),
                              decoration: const BoxDecoration(
                                color: Colors.white10,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                          width: 6,
                                          height: 6,
                                          decoration: const BoxDecoration(
                                            color: AppColors.teal,
                                            shape: BoxShape.circle,
                                          ),
                                        )
                                        .animate(onPlay: (c) => c.repeat())
                                        .scale(
                                          duration: 1000.ms,
                                          begin: const Offset(0.8, 0.8),
                                          end: const Offset(1.2, 1.2),
                                        )
                                        .then()
                                        .scale(
                                          duration: 1000.ms,
                                          begin: const Offset(1.2, 1.2),
                                          end: const Offset(0.8, 0.8),
                                        ),
                                    const SizedBox(width: 6),
                                    Text(
                                      "LIVE TRACKING",
                                      style: GoogleFonts.inter(
                                        fontSize: 9,
                                        color: Colors.white70,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  winner?['name'] ?? "Destination",
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          if (_shouldFollow)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: AppColors.teal.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.teal.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Text(
                                "FOLLOWING",
                                style: GoogleFonts.outfit(
                                  fontSize: 8,
                                  color: AppColors.teal,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2),

              // --- MAP CONTROLS ---
              Positioned(
                bottom: 350, // Above ETA sheet
                right: 20,
                child: Column(
                  children: [
                    _buildMapControl(
                      icon: _shouldFollow
                          ? Icons.gps_fixed_rounded
                          : Icons.gps_not_fixed_rounded,
                      active: _shouldFollow,
                      onTap: () {
                        setState(() => _shouldFollow = !_shouldFollow);
                        if (_shouldFollow) _fitBounds();
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildMapControl(
                      icon: Icons.layers_rounded,
                      onTap: () {
                        _fitBounds();
                      },
                    ),
                  ],
                ),
              ),

              // --- 3. DYNAMIC ETA BOARD ---
              _buildETASheet(session, winner),

              // --- 4. PRIVACY PILL ---
              _buildPrivacyPill(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildETASheet(
    OutingSessionModel session,
    Map<String, dynamic>? winner,
  ) {
    if (winner == null || winner['location'] == null) {
      return const SizedBox.shrink();
    }
    final vLat = (winner['location']['latitude'] as num).toDouble();
    final vLng = (winner['location']['longitude'] as num).toDouble();

    // Distill mathematically sorted participants matrix
    final sortedP = List<OutingParticipant>.from(session.participants);
    sortedP.sort((a, b) {
      if (a.location == null && b.location != null) return 1;
      if (a.location != null && b.location == null) return -1;
      if (a.location == null && b.location == null) return 0;
      final distA = double.parse(
        _calculateDistance(
          a.location!.latitude,
          a.location!.longitude,
          vLat,
          vLng,
        ),
      );
      final distB = double.parse(
        _calculateDistance(
          b.location!.latitude,
          b.location!.longitude,
          vLat,
          vLng,
        ),
      );
      return distA.compareTo(distB);
    });

    return Align(
      alignment: Alignment.bottomCenter,
      child:
          Container(
            padding: const EdgeInsets.only(
              top: 24,
              left: 24,
              right: 24,
              bottom: 40,
            ),
            decoration: BoxDecoration(
              color: AppColors.getSurfaceElevated(context),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(32),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.getShadow(context),
                  blurRadius: 30,
                  offset: const Offset(0, -10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.getDivider(context),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Icon(
                      Icons.people_alt_rounded,
                      color: AppColors.getTextPrimary(context),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Friends Arrival Times",
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.getTextPrimary(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ListView.separated(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: sortedP.length,
                  separatorBuilder: (_, __) =>
                      Divider(height: 1, color: AppColors.getDivider(context)),
                  itemBuilder: (context, i) {
                    final p = sortedP[i];
                    if (p.location == null) return const SizedBox.shrink();
                    final isMe =
                        p.uid == FirebaseAuth.instance.currentUser?.uid;

                    // Use real Google values from Firestore if available
                    final dist =
                        p.distanceKm ??
                        double.parse(
                          _calculateDistance(
                            p.location!.latitude,
                            p.location!.longitude,
                            vLat,
                            vLng,
                          ),
                        );
                    final timeMins =
                        p.etaMinutes ?? int.tryParse(_estimateTime(dist)) ?? 0;
                    final bool isArrived = dist <= 0.1;

                    return _buildParticipantTile(
                          p: p,
                          index: i,
                          isMe: isMe,
                          dist: dist,
                          timeMins: timeMins,
                          isArrived: isArrived,
                          vLat: vLat,
                          vLng: vLng,
                        )
                        .animate(delay: (i * 100).ms)
                        .fadeIn(duration: 400.ms)
                        .slideX(begin: 0.1);
                  },
                ),
              ],
            ),
          ).animate().slideY(
            begin: 1,
            duration: 600.ms,
            curve: Curves.easeOutQuart,
          ),
    );
  }

  Widget _buildParticipantTile({
    required OutingParticipant p,
    required int index,
    required bool isMe,
    required double dist,
    required int timeMins,
    required bool isArrived,
    required double vLat,
    required double vLng,
  }) {
    // Calculate Journey Progress
    double progress = 0.0;
    if (p.startLocation != null) {
      final totalDist =
          double.tryParse(
            _calculateDistance(
              p.startLocation!.latitude,
              p.startLocation!.longitude,
              vLat,
              vLng,
            ),
          ) ??
          0.0;
      if (totalDist > 0.05) {
        progress = (1.0 - (dist / totalDist)).clamp(0.0, 1.0);
      } else {
        progress = 1.0;
      }
    } else {
      progress = (1.0 - (dist / 10.0)).clamp(0.0, 1.0);
    }

    final isSelected = _selectedParticipantUid == p.uid;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: EdgeInsets.symmetric(
        vertical: 16,
        horizontal: isSelected ? 12 : 0,
      ),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.getUserColor(p.uid).withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // --- AVATAR ---
          Stack(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.getUserColor(p.uid),
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: p.photoUrl != null && p.photoUrl!.isNotEmpty
                      ? Image.network(p.photoUrl!, fit: BoxFit.cover)
                      : Container(
                          color: AppColors.getUserColor(p.uid),
                          child: Center(
                            child: Text(
                              p.name.isNotEmpty ? p.name[0].toUpperCase() : "?",
                              style: GoogleFonts.outfit(
                                color:
                                    Colors.white, // Keep white on Teal button
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                          ),
                        ),
                ),
              ),
              if (isArrived)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.white, // Keep white on Teal button
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.teal,
                      size: 18,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),

          // --- INFO & PROGRESS ---
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      p.name + (isMe ? " (You)" : ""),
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.getUserColor(p.uid),
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.getUserColor(
                            p.uid,
                          ).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          "ME",
                          style: GoogleFonts.inter(
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                            color: AppColors.getUserColor(p.uid),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                if (!isArrived) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: SizedBox(
                      height: 4,
                      width: 120,
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: AppColors.getUserColor(
                          p.uid,
                        ).withValues(alpha: 0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.getUserColor(p.uid),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                Text(
                  isArrived
                      ? "Joined the masterpiece"
                      : "${dist.toStringAsFixed(1)} km left",
                  style: GoogleFonts.inter(
                    color: AppColors.getTextSecondary(context),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // --- STATUS / ETA ---
          if (isArrived)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.teal.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                "ARRIVED",
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w900,
                  fontSize: 10,
                  color: AppColors.teal,
                  letterSpacing: 1,
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.amber.shade400, Colors.amber.shade600],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "$timeMins",
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      color: Colors.white, // Keep white on Teal button
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "min",
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white.withValues(
                        alpha: 0.9,
                      ), // Keep white on Teal button
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPrivacyPill() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox();

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();

        final data = snapshot.data!.data() as Map<String, dynamic>?;
        final isGhost = data?['isGhostMode'] ?? true;
        final isActive = data?['isTrackingActive'] ?? false;

        if (!isActive) return const SizedBox();

        return Positioned(
          top: 130, // Below the back button
          left: 20,
          child: GestureDetector(
            onTap: () => LocationService().updatePrivacy(uid, !isGhost),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isGhost
                    ? AppColors.darkSlate.withValues(alpha: 0.8)
                    : AppColors.teal.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: isGhost
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.white.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isGhost
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isGhost ? "PRIVATE (GHOST)" : "SHARING LOCATION",
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn().slideX(begin: -0.2),
        );
      },
    );
  }

  Widget _buildSkeletonLoader() {
    return Container(
      color: AppColors.getBackground(context),
      child: Stack(
        children: [
          // Shimmery Map Placeholder
          Opacity(
                opacity: 0.1,
                child: Container(color: AppColors.getSurface(context)),
              )
              .animate(onPlay: (controller) => controller.repeat())
              .shimmer(
                duration: 1500.ms,
                color: AppColors.getSurfaceElevated(
                  context,
                ).withValues(alpha: 0.1),
              ),

          // Header Skeleton
          Positioned(
            top: 55,
            left: 20,
            right: 20,
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Colors.white10,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn().shimmer(duration: 1500.ms),

          // Bottom Sheet Skeleton
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 380,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.getSurfaceElevated(context),
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Column(
                children: List.generate(
                  3,
                  (i) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.getSurfaceElevated(context),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 120,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: AppColors.getSurfaceElevated(context),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                width: 60,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: AppColors.getSurfaceElevated(context),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 60,
                          height: 30,
                          decoration: BoxDecoration(
                            color: AppColors.getSurfaceElevated(context),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ).animate().slideY(begin: 1, duration: 400.ms, curve: Curves.easeOut),
        ],
      ),
    );
  }

  void _syncLiveActivity(
    OutingSessionModel session,
    Map<String, dynamic>? winner,
  ) async {
    _outingService.syncLiveActivity(session);
  }

  Widget _buildMapControl({
    required IconData icon,
    bool active = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
          onTap: onTap,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(25),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: active
                      ? AppColors.teal.withValues(alpha: 0.8)
                      : AppColors.darkSlate.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: active
                        ? Colors.white.withValues(alpha: 0.5)
                        : Colors.white.withValues(alpha: 0.1),
                    width: 1,
                  ),
                  boxShadow: [
                    if (active)
                      BoxShadow(
                        color: AppColors.teal.withValues(alpha: 0.3),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                  ],
                ),
                child: Icon(
                  icon,
                  color: Colors.white, // Keep white on Teal button
                  size: 22,
                ),
              ),
            ),
          ),
        )
        .animate(target: active ? 1 : 0)
        .scale(
          begin: const Offset(1, 1),
          end: const Offset(1.05, 1.05),
          duration: 200.ms,
        );
  }
}
