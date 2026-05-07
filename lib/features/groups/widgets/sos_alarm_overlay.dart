import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:laween/l10n/app_localizations.dart';

class SosAlarmOverlay extends StatefulWidget {
  final String userName;
  final VoidCallback onStopAlarm;
  final VoidCallback onSeeMap;

  const SosAlarmOverlay({
    super.key,
    required this.userName,
    required this.onStopAlarm,
    required this.onSeeMap,
  });

  @override
  State<SosAlarmOverlay> createState() => _SosAlarmOverlayState();
}

class _SosAlarmOverlayState extends State<SosAlarmOverlay> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _startAlarm();
  }

  void _startAlarm() async {
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.setVolume(1.0);
      // Using the local asset for maximum reliability
      await _audioPlayer.play(AssetSource("sounds/mixkit-sci-fi-ship-siren-alert-1653.wav"));
    } catch (e) {
      debugPrint("ALARM ERROR: $e");
    }
  }

  @override
  void dispose() {
    _audioPlayer.stop();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _handleStop() {
    _audioPlayer.stop();
    widget.onStopAlarm();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Flashing Background
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.red.shade900,
                  Colors.red.shade600,
                  Colors.red.shade900,
                ],
              ),
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true))
           .tint(color: Colors.red.shade400, duration: 600.ms),

          // Content
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                // Pulsing SOS Icon
                Container(
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                    border: Border.all(color: Colors.white.withOpacity(0.2), width: 2),
                  ),
                  child: const Icon(
                    Icons.emergency_rounded,
                    color: Colors.white,
                    size: 120,
                  ),
                )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(duration: 600.ms, begin: const Offset(1, 1), end: const Offset(1.2, 1.2))
                .shimmer(duration: 1200.ms, color: Colors.white54),

                const SizedBox(height: 48),

                Text(
                  l10n.sosActiveLabel,
                  style: GoogleFonts.outfit(
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ).animate(onPlay: (c) => c.repeat(reverse: true))
                 .shake(duration: 500.ms, hz: 4),

                const SizedBox(height: 16),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    "${widget.userName}${l10n.needsHelpSuffix}",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ),

                const Spacer(),

                // Action Buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                  child: Column(
                    children: [
                      // Stop Alarm Button (Like a timer stop button)
                      GestureDetector(
                        onTap: _handleStop,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              )
                            ],
                          ),
                          child: Center(
                            child: Text(
                              l10n.stopAlarm,
                              style: GoogleFonts.outfit(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: Colors.red.shade700,
                              ),
                            ),
                          ),
                        ),
                      ).animate().slideY(begin: 0.5, duration: 600.ms, curve: Curves.easeOutQuart),

                      const SizedBox(height: 20),

                      // See on Map Button
                      TextButton.icon(
                        onPressed: widget.onSeeMap,
                        icon: const Icon(Icons.location_on_rounded, color: Colors.white),
                        label: Text(
                          l10n.seeOnMap,
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                          backgroundColor: Colors.white.withOpacity(0.15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: const BorderSide(color: Colors.white24),
                          ),
                        ),
                      ).animate().slideY(begin: 0.8, duration: 800.ms, curve: Curves.easeOutQuart),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms);
  }
}
