import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/colors.dart';
import '../../../core/services/location_service.dart';

class TrackingControlCard extends StatelessWidget {
  const TrackingControlCard({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists)
          return const SizedBox.shrink();

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final bool isTrackingActive = data['isTrackingActive'] ?? false;
        final bool isGhostMode = data['isGhostMode'] ?? false;

        return Container(
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              // --- Header ---
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Row(
                  children: [
                    Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color:
                                (isTrackingActive
                                        ? const Color(0xFF10B981)
                                        : Colors.grey)
                                    .withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isTrackingActive
                                ? Icons.radar
                                : Icons.radar_outlined,
                            color: isTrackingActive
                                ? const Color(0xFF10B981)
                                : Colors.grey,
                            size: 20,
                          ),
                        )
                        .animate(target: isTrackingActive ? 1 : 0)
                        .shimmer(duration: 2.seconds, color: Colors.white24)
                        .scale(begin: const Offset(0.9, 0.9)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "LIVE TRACKING",
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white38,
                              letterSpacing: 1.2,
                            ),
                          ),
                          Text(
                            isTrackingActive
                                ? "Signal Active"
                                : "Signal Offline",
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildPrivacyToggle(user.uid, isGhostMode),
                  ],
                ),
              ),

              // --- Main Toggle Button ---
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                child: _buildMainActionButton(
                  context,
                  user.uid,
                  isTrackingActive,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPrivacyToggle(String userId, bool isGhostMode) {
    return GestureDetector(
      onTap: () => LocationService().updatePrivacy(userId, !isGhostMode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isGhostMode
              ? const Color(0xFF6366F1).withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isGhostMode
                ? const Color(0xFF6366F1).withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isGhostMode ? Icons.security_rounded : Icons.public_rounded,
              size: 14,
              color: isGhostMode ? const Color(0xFF818CF8) : Colors.white38,
            ),
            const SizedBox(width: 6),
            Text(
              isGhostMode ? "Ghost" : "Public",
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isGhostMode ? const Color(0xFF818CF8) : Colors.white38,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainActionButton(
    BuildContext context,
    String userId,
    bool isActive,
  ) {
    return GestureDetector(
      onTap: () {
        if (isActive) {
          LocationService().stopTracking(userId);
        } else {
          LocationService().startTracking(userId);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: isActive
              ? const LinearGradient(
                  colors: [Color(0xFFEF4444), Color(0xFFB91C1C)],
                )
              : LinearGradient(
                  colors: [
                    AppColors.teal,
                    AppColors.teal.withValues(alpha: 0.7),
                  ],
                ),
          boxShadow: [
            BoxShadow(
              color: (isActive ? const Color(0xFFEF4444) : AppColors.teal)
                  .withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isActive ? Icons.stop_rounded : Icons.play_arrow_rounded,
                color: Colors.white,
              ),
              const SizedBox(width: 10),
              Text(
                isActive ? "Stop Tracking" : "Start Live Tracking",
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
