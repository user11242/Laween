// lib/features/groups/widgets/outing_voting_view.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/colors.dart';
import '../data/models/outing_session_model.dart';
import '../data/services/outing_service.dart';

class OutingVotingView extends StatelessWidget {
  final String groupId;
  final OutingSessionModel session;
  final bool isMe;

  OutingVotingView({
    super.key,
    required this.groupId,
    required this.session,
    required this.isMe,
  });

  final OutingService _outingService = OutingService();

  @override
  Widget build(BuildContext context) {
    // TopVenues is stored in session.finalLocation['topVenues']
    final List venues = session.finalLocation?['topVenues'] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Top 3 Results",
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isMe ? Colors.white : AppColors.darkSlate,
          ),
        ),
        const SizedBox(height: 16),
        ...venues.asMap().entries.map((entry) {
          final index = entry.key;
          final venue = entry.value;
          return _buildVenueCard(venue, index)
              .animate()
              .fadeIn(delay: (index * 150).milliseconds)
              .slideX(begin: 0.1);
        }),
        const SizedBox(height: 12),
        Center(
          child: Text(
            "Voting closes in ${_formatDuration(session.expiresAt.difference(DateTime.now()))}",
            style: GoogleFonts.inter(
              fontSize: 11,
              color: isMe ? Colors.white60 : Colors.grey,
            ),
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration d) {
    if (d.isNegative) return "00:00";
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    return "${twoDigits(d.inMinutes.remainder(60))}:${twoDigits(d.inSeconds.remainder(60))}";
  }

  Widget _buildVenueCard(Map<String, dynamic> venue, int index) {
    final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'];
    final photoRef = venue['photoReference'];
    final imageUrl = photoRef != null
        ? "https://places.googleapis.com/v1/$photoRef/media?key=$apiKey&maxHeightPx=400"
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isMe ? Colors.white.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isMe
              ? Colors.white.withOpacity(0.2)
              : Colors.black.withOpacity(0.05),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            if (imageUrl != null)
              CachedNetworkImage(
                imageUrl: imageUrl,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                    Container(color: Colors.grey.shade100),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey.shade100,
                  child: const Icon(Icons.error),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          venue['name'] ?? "Unknown Venue",
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isMe ? Colors.white : AppColors.darkSlate,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: Colors.amber,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "${venue['rating'] ?? 'N/A'} (${venue['userRatingCount'] ?? 0}) • ${session.calculationMode == 'Time' ? '~${venue['averageEtaMinutes'] ?? '?'} min drive' : '~${venue['averageRouteDistanceMeters'] != null ? (venue['averageRouteDistanceMeters'] / 1000).toStringAsFixed(1) : '?'} km'}",
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: isMe
                                    ? Colors.white70
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                        if (venue['isFavorite'] == true) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.teal.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.teal.withOpacity(0.2)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.favorite_rounded, color: AppColors.teal, size: 10),
                                const SizedBox(width: 6),
                                Text(
                                  "GROUP FAVORITE",
                                  style: GoogleFonts.inter(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.teal,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () => _outingService.voteForVenue(
                      groupId: groupId,
                      sessionId: session.id,
                      venueId: venue['id'],
                      uid: FirebaseAuth.instance.currentUser?.uid ?? '',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.teal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: const Text(
                      "Vote",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
