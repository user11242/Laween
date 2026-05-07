import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ArFriendCompassPage extends StatefulWidget {
  final double friendLat;
  final double friendLng;
  final String friendName;
  final String? friendImageUrl;
  final double? friendAccuracy;
  final DateTime? friendLastUpdate;

  const ArFriendCompassPage({
    super.key,
    required this.friendLat,
    required this.friendLng,
    required this.friendName,
    this.friendImageUrl,
    this.friendAccuracy,
    this.friendLastUpdate,
  });

  @override
  State<ArFriendCompassPage> createState() => _ArFriendCompassPageState();
}

class _ArFriendCompassPageState extends State<ArFriendCompassPage> {
  CameraController? _cameraController;
  bool _isCameraReady = false;

  double? _rawHeading;
  double? _cameraHeading;
  double? _userHeading;
  double? _headingAccuracy;

  Position? _userPosition;
  StreamSubscription? _compassSubscription;
  StreamSubscription? _positionSubscription;

  // Debug mode toggle
  final bool _showDebugOverlay =
      const bool.fromEnvironment('dart.vm.product') == false;
  final double _cameraHeadingOffset = 0.0; // Configurable constant for testing

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
      _userPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
      );
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint("Geolocator position error: $e");
    }

    // 3. Track location updates
    _positionSubscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.bestForNavigation,
            distanceFilter: 0,
          ),
        ).listen((pos) {
          if (mounted) setState(() => _userPosition = pos);
        });

    // 4. Track compass updates
    _compassSubscription = FlutterCompass.events!.listen((event) {
      if (mounted && event.heading != null) {
        setState(() {
          _rawHeading = event.heading;
          _cameraHeading = event.headingForCameraMode;
          _headingAccuracy = event.accuracy;

          double newHeading = _rawHeading!;
          if (_cameraHeading != null && _cameraHeading != 0.0) {
            newHeading = _cameraHeading!;
          }

          if (_userHeading == null) {
            _userHeading = newHeading;
          } else {
            _userHeading = _smoothAngle(_userHeading!, newHeading, 0.20);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _compassSubscription?.cancel();
    _positionSubscription?.cancel();
    super.dispose();
  }

  double _normalizeTo360(double angle) {
    return (angle % 360.0 + 360.0) % 360.0;
  }

  double _normalizeTo180(double angle) {
    double normalized = _normalizeTo360(angle);
    return normalized > 180.0 ? normalized - 360.0 : normalized;
  }

  double _smoothAngle(double oldAngle, double newAngle, double alpha) {
    double diff = _normalizeTo180(newAngle - oldAngle);
    return _normalizeTo360(oldAngle + alpha * diff);
  }

  double _calculateBearing() {
    if (_userPosition == null) return 0.0;
    final bearing = Geolocator.bearingBetween(
      _userPosition!.latitude,
      _userPosition!.longitude,
      widget.friendLat,
      widget.friendLng,
    );
    return _normalizeTo360(bearing);
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

  String _formatDistance(double distance) {
    if (distance >= 100) {
      return "${(distance / 5).round() * 5}m";
    }
    return "${distance.round()}m";
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

    // Calculate Relative Bearing: 0 = straight ahead, + = right, - = left
    double relativeBearing = _normalizeTo180(
      bearing - _userHeading! - _cameraHeadingOffset,
    );

    // Screen Mapping logic
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    double horizontalFov = 65.0;
    if (distance <= 15 ||
        (_userPosition != null && _userPosition!.accuracy > 15)) {
      horizontalFov = 150.0;
    } else if (distance <= 35) {
      horizontalFov = 90.0;
    }
    bool isOnScreen = relativeBearing.abs() <= horizontalFov / 2;

    const double safeMargin = 80.0;
    final double usableHalfWidth = (screenWidth / 2) - safeMargin;

    double screenX =
        (screenWidth / 2) +
        (relativeBearing / (horizontalFov / 2)) * usableHalfWidth;
    // Final safety clamp just in case
    screenX = screenX.clamp(safeMargin, screenWidth - safeMargin);

    // Accuracy and freshness logic
    String? warningMessage;

    if (widget.friendLastUpdate != null) {
      final age = DateTime.now().difference(widget.friendLastUpdate!);
      if (age.inMinutes >= 2) {
        warningMessage = "Waiting for updated friend location.";
      } else if (age.inSeconds >= 30) {
        warningMessage = "Friend location may be outdated.";
      }
    }

    if (warningMessage == null &&
        _headingAccuracy != null &&
        _headingAccuracy! > 30) {
      warningMessage = "Move phone in a figure-8 to calibrate compass.";
    }

    if (warningMessage == null && widget.friendAccuracy != null) {
      double combinedAccuracy = math.sqrt(
        math.pow(_userPosition!.accuracy, 2) +
            math.pow(widget.friendAccuracy!, 2),
      );
      if (combinedAccuracy > distance || combinedAccuracy > 15) {
        warningMessage = "Location accuracy is weak indoors.";
      }
    }

    if (warningMessage == null && distance < 12) {
      warningMessage = "Nearby — GPS may be inaccurate indoors.";
    }

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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                        ),
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
                      const SizedBox(
                        width: 48,
                      ), // Balancing width for back button
                    ],
                  ),
                ),

                // Distance display card
                Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white12, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.navigation_rounded,
                        color: Colors.amber,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _formatDistance(distance),
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

                if (warningMessage != null)
                  Container(
                    margin: const EdgeInsets.only(top: 8, left: 24, right: 24),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      warningMessage,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // 4. Central AR Target / Guidance Indicators
          if (isOnScreen)
            Positioned(
              left: screenX - 80, // Center the 160px wide widget
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
                            child:
                                widget.friendImageUrl != null &&
                                    widget.friendImageUrl!.isNotEmpty
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
                                    child: const Icon(
                                      Icons.person,
                                      size: 40,
                                      color: Colors.grey,
                                    ),
                                  ),
                          ),
                        )
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .scale(
                          duration: 800.ms,
                          begin: const Offset(1, 1),
                          end: const Offset(1.08, 1.08),
                        ),

                    const SizedBox(height: 12),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
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
          else ...[
            if (distance <= 35) ...[
              Positioned(
                top: screenHeight / 2 - 40,
                left: 24,
                child:
                    Container(
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
                          child: const Icon(
                            Icons.arrow_back_rounded,
                            color: Colors.amber,
                            size: 44,
                          ),
                        )
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .scale(
                          duration: 500.ms,
                          begin: const Offset(1, 1),
                          end: const Offset(1.15, 1.15),
                        ),
              ),
              Positioned(
                top: screenHeight / 2 - 40,
                right: 24,
                child:
                    Container(
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
                          child: const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.amber,
                            size: 44,
                          ),
                        )
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .scale(
                          duration: 500.ms,
                          begin: const Offset(1, 1),
                          end: const Offset(1.15, 1.15),
                        ),
              ),
            ] else ...[
              Positioned(
                top: screenHeight / 2 - 40,
                left: relativeBearing < 0 ? 24 : null,
                right: relativeBearing > 0 ? 24 : null,
                child:
                    Container(
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
                            relativeBearing < 0
                                ? Icons.arrow_back_rounded
                                : Icons.arrow_forward_rounded,
                            color: Colors.amber,
                            size: 44,
                          ),
                        )
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .scale(
                          duration: 500.ms,
                          begin: const Offset(1, 1),
                          end: const Offset(1.15, 1.15),
                        ),
              ),
            ],
          ],

          // 5. Bottom Instructions Hint
          Positioned(
            bottom: _showDebugOverlay ? 220 : 40,
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
                    ? "✨ Point directly at ${widget.friendName}."
                    : relativeBearing.abs() > 135
                    ? "🔄 ${widget.friendName} is behind you. Turn around."
                    : relativeBearing > 0
                    ? "🔄 Turn right to find ${widget.friendName}."
                    : "🔄 Turn left to find ${widget.friendName}.",
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  color: isOnScreen
                      ? Colors.green.shade300
                      : Colors.amber.shade300,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          // 6. Dev Debug Overlay
          if (_showDebugOverlay)
            Positioned(
              bottom: 20,
              left: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.all(8),
                color: Colors.black.withOpacity(0.8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "DEBUG MODE",
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "U_Lat: ${_userPosition?.latitude.toStringAsFixed(6)} | U_Lng: ${_userPosition?.longitude.toStringAsFixed(6)}",
                      style: TextStyle(color: Colors.white70, fontSize: 10),
                    ),
                    Text(
                      "F_Lat: ${widget.friendLat.toStringAsFixed(6)} | F_Lng: ${widget.friendLng.toStringAsFixed(6)}",
                      style: TextStyle(color: Colors.white70, fontSize: 10),
                    ),
                    Text(
                      "Raw Dist: ${distance.toStringAsFixed(2)}m | U_Acc: ${_userPosition?.accuracy.toStringAsFixed(1)} | F_Acc: ${widget.friendAccuracy?.toStringAsFixed(1) ?? 'N/A'}",
                      style: TextStyle(color: Colors.white70, fontSize: 10),
                    ),
                    Text(
                      "Bearing: ${bearing.toStringAsFixed(2)}° | Rel Bear: ${relativeBearing.toStringAsFixed(2)}°",
                      style: TextStyle(color: Colors.white70, fontSize: 10),
                    ),
                    Text(
                      "Raw Hd: ${_rawHeading?.toStringAsFixed(2)} | Cam Hd: ${_cameraHeading?.toStringAsFixed(2)}",
                      style: TextStyle(color: Colors.white70, fontSize: 10),
                    ),
                    Text(
                      "Final Hd: ${_userHeading?.toStringAsFixed(2)} | Hd Acc: ${_headingAccuracy?.toStringAsFixed(1)}",
                      style: TextStyle(color: Colors.white70, fontSize: 10),
                    ),
                    Text(
                      "FOV: $horizontalFov | Screen: $isOnScreen | x: ${screenX.toStringAsFixed(1)}",
                      style: TextStyle(color: Colors.white70, fontSize: 10),
                    ),
                    Text(
                      "F_Age: ${widget.friendLastUpdate != null ? DateTime.now().difference(widget.friendLastUpdate!).inSeconds.toString() + 's' : 'N/A'}",
                      style: TextStyle(color: Colors.white70, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
