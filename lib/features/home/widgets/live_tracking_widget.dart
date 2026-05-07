import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;
import '../../../core/theme/colors.dart';
import '../../groups/data/models/outing_session_model.dart';
import 'package:laween/l10n/app_localizations.dart';
import '../../groups/pages/outing_tracking_screen.dart';

class LiveTrackingDashboardWidget extends StatelessWidget {
  const LiveTrackingDashboardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) return const SizedBox.shrink();

        final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
        final bool isActive = userData?['isTrackingActive'] ?? false;
        final String gId = userData?['activeGroupId'] ?? '';
        final String sId = userData?['activeSessionId'] ?? '';

        if (!isActive || gId.isEmpty || sId.isEmpty) {
          return const SizedBox.shrink();
        }

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

            return _buildModernTrackingCard(context, session);
          },
        );
      },
    );
  }

  Widget _buildModernTrackingCard(
    BuildContext context,
    OutingSessionModel session,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final winner = session.winner;
    if (winner == null) return const SizedBox.shrink();

    final dest = winner['location'];
    final dLat = (dest['latitude'] as num).toDouble();
    final dLng = (dest['longitude'] as num).toDouble();

    // Prepare participants with their individual progress
    final List<Map<String, dynamic>> participantProgress = [];
    int arrivedCount = 0;

    for (var p in session.participants) {
      double pProgress = 0.0;
      if (p.arrived) {
        pProgress = 1.0;
        arrivedCount++;
      } else if (p.location != null && p.startLocation != null) {
        final startDist = _calculateDistance(
          p.startLocation!.latitude,
          p.startLocation!.longitude,
          dLat,
          dLng,
        );
        final currentDist = _calculateDistance(
          p.location!.latitude,
          p.location!.longitude,
          dLat,
          dLng,
        );
        if (startDist > 0.01) {
          pProgress = (1.0 - (currentDist / startDist)).clamp(0.0, 1.0);
        }
      }
      
      participantProgress.add({
        'participant': p,
        'progress': pProgress,
      });
    }

    // Hide widget if everyone has arrived
    if (arrivedCount == session.participants.length && arrivedCount > 0) {
      return const SizedBox.shrink();
    }

    // Sort by progress so they layer correctly
    participantProgress.sort((a, b) => (a['progress'] as double).compareTo(b['progress'] as double));

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
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.getSurfaceElevated(context),
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: AppColors.getShadow(context).withValues(alpha: 0.06),
              blurRadius: 30,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.teal.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.gps_fixed_rounded, color: AppColors.teal, size: 20)
                      .animate(onPlay: (c) => c.repeat())
                      .shimmer(duration: 2000.ms),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            l10n.liveTracking.toUpperCase(),
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: AppColors.teal,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                          ).animate(onPlay: (c) => c.repeat()).fadeIn(duration: 800.ms).fadeOut(delay: 800.ms),
                        ],
                      ),
                      Text(
                        winner['name'] ?? l10n.destination,
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.getTextPrimary(context),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey.shade300, size: 14),
              ],
            ),
            
            const SizedBox(height: 32),

            // Journey Line with Avatars
            LayoutBuilder(
              builder: (context, constraints) {
                final trackWidth = constraints.maxWidth - 28; // Account for avatar size
                final isRtl = Directionality.of(context) == TextDirection.rtl;
                
                return Stack(
                  clipBehavior: Clip.none,
                  alignment: isRtl ? Alignment.centerRight : Alignment.centerLeft,
                  children: [
                    // Background Track
                    Container(
                      height: 4,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.getBorder(context),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    
                    // Destination Marker
                    Positioned(
                      left: isRtl ? -4 : null,
                      right: isRtl ? null : -4,
                      child: const Icon(Icons.flag_rounded, color: AppColors.teal, size: 24),
                    ),

                    // Individual Avatars
                    ...participantProgress.map((item) {
                      final p = item['participant'] as OutingParticipant;
                      final progress = item['progress'] as double;
                      
                      return AnimatedPositioned(
                        duration: const Duration(seconds: 2),
                        curve: Curves.easeInOut,
                        left: isRtl ? null : trackWidth * progress,
                        right: isRtl ? trackWidth * progress : null,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: AppColors.getSurface(context),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.getShadow(context).withValues(alpha: 0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              )
                            ],
                            border: Border.all(
                              color: p.arrived ? AppColors.teal : AppColors.getSurface(context),
                              width: 2,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 12,
                            backgroundColor: AppColors.getUserColor(p.uid).withOpacity(0.2),
                            backgroundImage: p.photoUrl != null && p.photoUrl!.isNotEmpty
                                ? CachedNetworkImageProvider(p.photoUrl!)
                                : null,
                            child: p.photoUrl == null || p.photoUrl!.isEmpty
                                ? Text(
                                    p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.getUserColor(p.uid),
                                    ),
                                  )
                                : null,
                          ),
                        ),
                      );
                    }),
                  ],
                );
              },
            ),

            const SizedBox(height: 32),

            // Status Text
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  arrivedCount == session.participants.length
                      ? l10n.everyoneArrived
                      : l10n.arrivedStatusLabel(arrivedCount, session.participants.length),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.getTextSecondary(context),
                  ),
                ),
                Text(
                  l10n.viewDetails,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.teal,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  double _calculateDistance(
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
    return 12742 * math.asin(math.sqrt(a));
  }
}
