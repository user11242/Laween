// lib/features/groups/pages/outing_tracking_screen.dart

import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/colors.dart';
import 'package:live_activities/live_activities.dart';
import '../data/models/outing_session_model.dart';
import '../data/services/outing_service.dart';

class OutingTrackingScreen extends StatefulWidget {
  final String groupId;
  final String sessionId;

  const OutingTrackingScreen({
    super.key,
    required this.groupId,
    required this.sessionId,
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

  final _liveActivitiesPlugin = LiveActivities();
  String? _activityId;
  String? _lastParticipantsJson;
  final Map<String, double> _startDistances = {};

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      _outingService.startLiveTracking(widget.groupId, widget.sessionId, uid);
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _outingService.stopLiveTracking(); 
    if (_activityId != null) {
      _liveActivitiesPlugin.endActivity(_activityId!);
    }
    super.dispose();
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

    final glowPaint = Paint()
      ..color = AppColors.teal.withValues(alpha: 0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(const Offset(radius, radius), radius - 10, glowPaint);

    final paint = Paint()..color = color;
    canvas.drawCircle(const Offset(radius, radius), radius - 15, paint);

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawCircle(const Offset(radius, radius), radius - 15, borderPaint);

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
    final double dist = 12742 * math.asin(math.sqrt(a)); 
    return dist.toStringAsFixed(1);
  }

  String _estimateTime(double distanceKm) {
    // Basic city estimation algorithm: 40km/h average -> 1.5 mins per km + 2 mins traffic pad.
    final mins = (distanceKm * 1.5) + 2;
    return mins.toInt().toString();
  }

  Future<void> _updateMarkers(OutingSessionModel session) async {
    if (_isDisposed || !mounted) return;

    final Set<Marker> newMarkers = {};
    final winner = session.winner;
    
    // 1. Destination Marker
    if (winner != null && winner['location'] != null) {
      final loc = winner['location'];
      newMarkers.add(
        Marker(
          markerId: const MarkerId('v_winner'),
          position: LatLng((loc['latitude'] as num).toDouble(), (loc['longitude'] as num).toDouble()),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
          infoWindow: InfoWindow(title: winner['name'] ?? "Destination"),
        ),
      );
    }

    // 2. Participant Live Avatars
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
            anchor: const Offset(0.5, 0.5),
          ),
        );
      }
    }

    if (_isDisposed || !mounted) return;

    // Trigger update if hardware coordinates changed for anyone
    if (newMarkers.length != _markers.length || !_markers.containsAll(newMarkers)) {
      setState(() => _markers = newMarkers);
      // Only auto-fit once or if 'follow' is enabled
      if (!_hasInitialFit || _shouldFollow) {
        _fitBounds();
        _hasInitialFit = true;
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
      backgroundColor: AppColors.background,
      body: StreamBuilder<OutingSessionModel?>(
        stream: _outingService.streamSession(widget.groupId, widget.sessionId),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: CircularProgressIndicator(color: AppColors.teal));
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
                initialCameraPosition: const CameraPosition(
                  target: LatLng(25.2048, 55.2708), // Fallback map init
                  zoom: 12,
                ),
                myLocationEnabled: false,
                compassEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                markers: _markers,
                onMapCreated: (controller) {
                  if (!_controller.isCompleted) _controller.complete(controller);
                },
              ),

              // --- 2. HEADER & NAVIGATION ---
              Positioned(
                top: 55,
                left: 20,
                right: 20,
                child: Row(
                  children: [
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.darkSlate.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.darkSlate.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 5)),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  "LIVE TRACKING",
                                  style: GoogleFonts.inter(fontSize: 10, color: AppColors.teal, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                                ),
                                const Spacer(),
                                if (_shouldFollow)
                                  const Icon(Icons.auto_fix_high_rounded, color: AppColors.teal, size: 12),
                              ],
                            ),
                            Text(
                              winner?['name'] ?? "Destination",
                              style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // --- MAP CONTROLS ---
              Positioned(
                bottom: 340, // Above ETA sheet
                right: 20,
                child: Column(
                  children: [
                    _buildMapControl(
                      icon: _shouldFollow ? Icons.gps_fixed_rounded : Icons.gps_not_fixed_rounded,
                      color: _shouldFollow ? AppColors.teal : AppColors.darkSlate,
                      onTap: () {
                        setState(() => _shouldFollow = !_shouldFollow);
                        if (_shouldFollow) _fitBounds();
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildMapControl(
                      icon: Icons.layers_rounded,
                      onTap: () {
                        // Toggle map style or just zoom out
                        _fitBounds();
                      },
                    ),
                  ],
                ),
              ),

              // --- 3. DYNAMIC ETA BOARD ---
              _buildETASheet(session, winner),
            ],
          );
        },
      ),
    );
  }

  Widget _buildETASheet(OutingSessionModel session, Map<String, dynamic>? winner) {
    if (winner == null || winner['location'] == null) return const SizedBox.shrink();
    final vLat = winner['location']['latitude'] as double;
    final vLng = winner['location']['longitude'] as double;

    // Distill mathematically sorted participants matrix
    final sortedP = List<OutingParticipant>.from(session.participants);
    sortedP.sort((a, b) {
      if (a.location == null && b.location != null) return 1;
      if (a.location != null && b.location == null) return -1;
      if (a.location == null && b.location == null) return 0;
      final distA = double.parse(_calculateDistance(a.location!.latitude, a.location!.longitude, vLat, vLng));
      final distB = double.parse(_calculateDistance(b.location!.latitude, b.location!.longitude, vLat, vLng));
      return distA.compareTo(distB);
    });

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        padding: const EdgeInsets.only(top: 24, left: 24, right: 24, bottom: 40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 30, offset: const Offset(0, -10)),
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
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Icon(Icons.people_alt_rounded, color: AppColors.darkSlate, size: 20),
                const SizedBox(width: 8),
                Text(
                  "Friends Arrival Times",
                  style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.darkSlate),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sortedP.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
              itemBuilder: (context, i) {
                final p = sortedP[i];
                if (p.location == null) return const SizedBox.shrink();

                final dist = double.parse(_calculateDistance(p.location!.latitude, p.location!.longitude, vLat, vLng));
                final time = _estimateTime(dist);
                final bool isArrived = dist <= 0.1; // Less than 100 meters

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: isArrived ? AppColors.teal : Colors.grey.shade200,
                        radius: 18,
                        child: isArrived 
                          ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                          : Text("${i + 1}", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.name, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.darkSlate)),
                            Text("$dist km away", style: GoogleFonts.inter(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                      ),
                      if (isArrived)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: AppColors.teal.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                          child: Text("ARRIVED", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.teal, letterSpacing: 1)),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                          child: Row(
                            children: [
                              Text(time, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.amber.shade700)),
                              const SizedBox(width: 4),
                              Text("min", style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 11, color: Colors.amber.shade700)),
                            ],
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ).animate().slideY(begin: 1, duration: 600.ms, curve: Curves.easeOutQuart),
    );
  }

  void _syncLiveActivity(OutingSessionModel session, Map<String, dynamic>? winner) async {
    if (winner == null || winner['location'] == null) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    if (session.participants.isEmpty) return;

    // 1. Calculate all participant stats
    int maxEta = 0;
    final participantsList = session.participants.where((p) => p.location != null).map((p) {
      final pDistStr = _calculateDistance(
        p.location!.latitude,
        p.location!.longitude,
        (winner['location']['latitude'] as num).toDouble(),
        (winner['location']['longitude'] as num).toDouble(),
      );
      final pDist = double.tryParse(pDistStr) ?? 0.0;
      final isMe = p.uid == uid;
      
      final pEtaInt = int.tryParse(_estimateTime(pDist)) ?? 0;
      if (pEtaInt > maxEta) maxEta = pEtaInt;

      // Relative progress: 0.0 at start, 1.0 at destination
      _startDistances.putIfAbsent(p.uid, () => pDist);
      final startDist = _startDistances[p.uid]!;
      double progress = 0.0;
      if (startDist > 0.05) { // 50 meters min journey for slider movement
        progress = (1.0 - (pDist / startDist)).clamp(0.0, 1.0);
      } else {
        progress = 1.0;
      }

      return {
        'name': isMe ? "You" : p.name,
        'initial': (p.name.isNotEmpty ? p.name[0] : "?").toUpperCase(),
        'photoUrl': p.photoUrl ?? "",
        'eta': pEtaInt.toString(),
        'dist': "$pDistStr km",
        'progress': progress,
        'isMe': isMe,
      };
    }).toList();

    // 2. Sort and take top 3 by proximity
    participantsList.sort((a, b) => (b['progress'] as double).compareTo(a['progress'] as double));
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
      'destinationName': winner['name'] ?? 'Destination'
    };

    if (_activityId == null) {
      try {
        _liveActivitiesPlugin.init(appGroupId: "group.laween");
        _activityId = await _liveActivitiesPlugin.createActivity("laween_tracking", payload);
        debugPrint("Live Activity Created: $_activityId");
      } catch (e) {
        debugPrint("Live Activity Creation Error: $e");
      }
    } else {
      try {
        await _liveActivitiesPlugin.updateActivity(_activityId!, payload);
        debugPrint("Live Activity Updated");
      } catch (e) {
        debugPrint("Live Activity Update Error: $e");
      }
    }
  }

  Widget _buildMapControl({required IconData icon, Color color = AppColors.darkSlate, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 10, offset: const Offset(0, 5)),
          ],
        ),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }
}
