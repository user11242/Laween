import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/colors.dart';

class ArFriendCompassPage extends StatefulWidget {
  final double friendLat;
  final double friendLng;
  final String friendName;
  final String? friendImageUrl;

  const ArFriendCompassPage({
    super.key,
    required this.friendLat,
    required this.friendLng,
    required this.friendName,
    this.friendImageUrl,
  });

  @override
  State<ArFriendCompassPage> createState() => _ArFriendCompassPageState();
}

class _ArFriendCompassPageState extends State<ArFriendCompassPage> {
  CameraController? _cameraController;
  bool _isCameraReady = false;
  double? _userHeading;
  Position? _userPosition;
  StreamSubscription? _compassSubscription;
  StreamSubscription? _positionSubscription;

  @override
  void initState() {
    super.initState();
    _initArFeature();
  }

  Future<void> _initArFeature() async {
    // 1. Initialize camera
    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        final backCam = cameras.firstWhere(
          (cam) => cam.lensDirection == CameraLensDirection.back,
          orElse: () => cameras.first,
        );
        _cameraController = CameraController(
          backCam,
          ResolutionPreset.medium,
          enableAudio: false,
        );
        await _cameraController!.initialize();
        if (mounted) setState(() => _isCameraReady = true);
      }
    } catch (e) {
      debugPrint("Camera initialization error: $e");
    }

    // 2. Initial position
    try {
      _userPosition = await Geolocator.getCurrentPosition();
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint("Geolocator position error: $e");
    }

    // 3. Track location updates
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((pos) {
      if (mounted) setState(() => _userPosition = pos);
    });

    // 4. Track compass updates
    _compassSubscription = FlutterCompass.events!.listen((event) {
      if (mounted) setState(() => _userHeading = event.heading);
    });
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _compassSubscription?.cancel();
    _positionSubscription?.cancel();
    super.dispose();
  }

  double _calculateBearing() {
    if (_userPosition == null) return 0.0;

    final startLat = _userPosition!.latitude * pi / 180.0;
    final startLng = _userPosition!.longitude * pi / 180.0;
    final endLat = widget.friendLat * pi / 180.0;
    final endLng = widget.friendLng * pi / 180.0;

    final dLng = endLng - startLng;
    final y = sin(dLng) * cos(endLat);
    final x = cos(startLat) * sin(endLat) - sin(startLat) * cos(endLat) * cos(dLng);

    final bearing = atan2(y, x) * 180.0 / pi;
    return (bearing + 360.0) % 360.0;
  }

  double _calculateDistance() {
    if (_userPosition == null) return 0.0;
    return Geolocator.distanceBetween(
      _userPosition!.latitude,
      _userPosition!.longitude,
      widget.friendLat,
      widget.friendLng,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraReady || _userPosition == null || _userHeading == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Colors.white),
              const SizedBox(height: 16),
              Text(
                "Initializing AR Friend Compass...",
                style: GoogleFonts.outfit(color: Colors.white70, fontSize: 16),
              ),
            ],
          ).animate().fadeIn(duration: 500.ms),
        ),
      );
    }

    final bearing = _calculateBearing();
    final distance = _calculateDistance();
    
    // Relative heading = bearing - heading.
    // Wrap to -180 to 180
    final relativeBearing = ((bearing - _userHeading! + 540) % 360) - 180;

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // We define a Field of View (FOV) of 60 degrees.
    // Any target within -30 to +30 degrees is on screen.
    final bool isOnScreen = relativeBearing.abs() <= 30.0;

    // Horizontal position mapped from -1.0 to 1.0
    final double normalizedX = relativeBearing / 30.0;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Camera Live View
          CameraPreview(_cameraController!),

          // 2. Translucent dark overlay
          Container(color: Colors.black.withOpacity(0.15)),

          // 3. Top Status / App Bar
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Text(
                          "AR FRIEND COMPASS",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48), // Spacer to balance
                    ],
                  ),
                ),

                // Distance display card
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white12, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.navigation_rounded, color: Colors.amber, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        "${distance.toStringAsFixed(0)}m",
                        style: GoogleFonts.outfit(
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "away from ${widget.friendName}",
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 4. Central AR Target / Guidance Indicators
          if (isOnScreen)
            Positioned(
              left: (screenWidth / 2) + (normalizedX * (screenWidth / 2)) - 80,
              top: screenHeight / 2 - 80,
              child: SizedBox(
                width: 160,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Glow animation circle
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.2),
                        border: Border.all(color: Colors.amber, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.amber.withOpacity(0.4),
                            blurRadius: 25,
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: widget.friendImageUrl != null && widget.friendImageUrl!.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: widget.friendImageUrl!,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                width: 80,
                                height: 80,
                                color: Colors.grey.shade300,
                                child: const Icon(Icons.person, size: 40, color: Colors.grey),
                              ),
                      ),
                    ).animate(onPlay: (c) => c.repeat(reverse: true))
                     .scale(duration: 800.ms, begin: const Offset(1, 1), end: const Offset(1.08, 1.08)),

                    const SizedBox(height: 12),

                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.75),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Text(
                        widget.friendName,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            // Arrow indicators directing where to rotate
            Positioned(
              top: screenHeight / 2 - 40,
              left: relativeBearing < 0 ? 24 : null,
              right: relativeBearing > 0 ? 24 : null,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withOpacity(0.8),
                  border: Border.all(color: Colors.amber, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withOpacity(0.3),
                      blurRadius: 15,
                    ),
                  ],
                ),
                child: Icon(
                  relativeBearing < 0 ? Icons.arrow_back_rounded : Icons.arrow_forward_rounded,
                  color: Colors.amber,
                  size: 44,
                ),
              ).animate(onPlay: (c) => c.repeat(reverse: true))
               .scale(duration: 500.ms, begin: const Offset(1, 1), end: const Offset(1.15, 1.15)),
            ),

          // 5. Bottom Instructions Hint
          Positioned(
            bottom: 40,
            left: 24,
            right: 24,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.65),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Text(
                isOnScreen
                    ? "✨ Match centered! Point directly at ${widget.friendName}."
                    : "🔄 Rotate your phone to follow the glowing arrow.",
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  color: isOnScreen ? Colors.green.shade300 : Colors.amber.shade300,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
