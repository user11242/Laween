import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math' as math;
import '../../../core/theme/colors.dart';
import '../../groups/data/models/outing_session_model.dart';
import '../../groups/pages/outing_tracking_screen.dart';

class LiveTrackingDashboardWidget extends StatelessWidget {
  const LiveTrackingDashboardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) return const SizedBox.shrink();

        final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
        final bool isActive = userData?['isTrackingActive'] ?? false;
        final String gId = userData?['activeGroupId'] ?? '';
        final String sId = userData?['activeSessionId'] ?? '';

        if (!isActive || gId.isEmpty || sId.isEmpty) {
          return const SizedBox.shrink();
        }

        // Direct stream to the specific active session
        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('groups')
              .doc(gId)
              .collection('outings')
              .doc(sId)
              .snapshots(),
          builder: (context, sessionSnapshot) {
            if (!sessionSnapshot.hasData || !sessionSnapshot.data!.exists) {
              return const SizedBox.shrink();
            }

            final session = OutingSessionModel.fromMap(
              sessionSnapshot.data!.data() as Map<String, dynamic>,
            );
            
            return _buildCareemStyleWidget(context, session);
          },
        );
      },
    );
  }

  Widget _buildCareemStyleWidget(BuildContext context, OutingSessionModel session) {
    final winner = session.winner;
    if (winner == null) return const SizedBox.shrink();

    // Calculate overall team progress
    // Progress = (StartDist - CurrentDist) / StartDist
    double totalProgress = 0;
    int participantCount = 0;

    for (var p in session.participants) {
      if (p.location != null && p.startLocation != null && winner['location'] != null) {
        final dest = winner['location'];
        final dLat = (dest['latitude'] as num).toDouble();
        final dLng = (dest['longitude'] as num).toDouble();

        final startDist = _calculateDistance(p.startLocation!.latitude, p.startLocation!.longitude, dLat, dLng);
        final currentDist = _calculateDistance(p.location!.latitude, p.location!.longitude, dLat, dLng);

        if (startDist > 0) {
          final pProgress = (startDist - currentDist) / startDist;
          totalProgress += pProgress.clamp(0.0, 1.0);
          participantCount++;
        }
      }
    }

    final displayProgress = participantCount > 0 ? (totalProgress / participantCount) : 0.0;
    final percentage = (displayProgress * 100).toInt();

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OutingTrackingScreen(
              groupId: session.groupId,
              sessionId: session.id,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.slate.withValues(alpha: 0.1), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.teal.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.navigation_rounded, color: AppColors.teal, size: 20),
                ),
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
                          color: AppColors.teal,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Text(
                        winner['name'] ?? "Destination",
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.teal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "$percentage%",
                    style: GoogleFonts.inter(
                      color: AppColors.teal,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Stack(
              children: [
                Container(
                  height: 6,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.slate.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(seconds: 1),
                  height: 6,
                  width: (MediaQuery.of(context).size.width - 88) * displayProgress,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: AppColors.tealGradient),
                    borderRadius: BorderRadius.circular(3),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.teal.withValues(alpha: 0.5),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "${session.participants.length} friends moving",
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.slate,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      "On my way",
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.teal,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.teal, size: 10),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295;
    final a = 0.5 -
        math.cos((lat2 - lat1) * p) / 2 +
        math.cos(lat1 * p) *
            math.cos(lat2 * p) *
            (1 - math.cos((lon2 - lon1) * p)) /
            2;
    return 12742 * math.asin(math.sqrt(a));
  }
}
