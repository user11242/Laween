// lib/features/groups/widgets/outing_winner_view.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/colors.dart';
import '../data/models/outing_session_model.dart';

class OutingWinnerView extends StatelessWidget {
  final OutingSessionModel session;
  final bool isMe;

  const OutingWinnerView({
    super.key,
    required this.session,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    final winner = session.winner;
    if (winner == null) return const SizedBox.shrink();

    final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'];
    final photoRef = winner['photoReference'];
    final imageUrl = photoRef != null 
        ? "https://places.googleapis.com/v1/$photoRef/media?key=$apiKey&maxHeightPx=600"
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "THE WINNER! 🎉",
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isMe ? Colors.white : AppColors.teal,
                letterSpacing: 1.5,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.people_alt_rounded, color: Colors.amber, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    "${(winner['votes'] as List?)?.length ?? 0} Votes",
                    style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amber),
                  ),
                ],
              ),
            ),
          ],
        ).animate().fadeIn().slideY(begin: -0.2),
        const SizedBox(height: 16),
        
        // Winner Card
        Container(
          decoration: BoxDecoration(
            color: isMe ? Colors.white.withValues(alpha: 0.15) : Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: isMe ? Colors.white.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.05),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.teal.withValues(alpha: 0.1),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: Column(
            children: [
              if (imageUrl != null)
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
                      child: CachedNetworkImage(
                        imageUrl: imageUrl,
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              "${winner['rating'] ?? 'N/A'}",
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      winner['name'] ?? "Unknown",
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isMe ? Colors.white : AppColors.darkSlate,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      winner['address'] ?? "",
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: isMe ? Colors.white70 : Colors.grey.shade600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _openInMaps(winner['location']),
                            icon: const Icon(Icons.directions_rounded, size: 18),
                            label: const Text("Get Directions"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.teal,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ).animate().scale(delay: 200.milliseconds, curve: Curves.easeOutBack),
      ],
    );
  }

  Future<void> _openInMaps(Map<String, dynamic> location) async {
    final lat = location['latitude'];
    final lng = location['longitude'];
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }
}
