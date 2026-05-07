// lib/features/groups/pages/history_detail_page.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/colors.dart';
import '../data/models/outing_session_model.dart';
import 'package:laween/l10n/app_localizations.dart';
import 'package:laween/core/services/google_maps_service.dart';
import 'outing_memories_page.dart';

class HistoryDetailPage extends StatefulWidget {
  final OutingSessionModel session;

  const HistoryDetailPage({super.key, required this.session});

  @override
  State<HistoryDetailPage> createState() => _HistoryDetailPageState();
}

class _HistoryDetailPageState extends State<HistoryDetailPage> {
  final String myUid = FirebaseAuth.instance.currentUser?.uid ?? '';
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.session.favoritedBy.contains(myUid);
  }

  Future<void> _toggleFavorite() async {
    final sessionRef = FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.session.groupId)
        .collection('outings')
        .doc(widget.session.id);

    setState(() => _isFavorite = !_isFavorite);

    if (_isFavorite) {
      await sessionRef.update({
        'favoritedBy': FieldValue.arrayUnion([myUid])
      });
    } else {
      await sessionRef.update({
        'favoritedBy': FieldValue.arrayRemove([myUid])
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Use coverPhotoUrl (Best Memory) for the Hero image as requested by AI context
    // Venue image can be a smaller thumbnail or used elsewhere if needed
    final String? venuePhotoRef = widget.session.winner?['photoReference'];
    final String? venuePhotoUrl = GoogleMapsService().getPlacePhotoUrl(venuePhotoRef, maxWidth: 400);

    final venueName = widget.session.winner?['name'] ?? l10n.epicOutingLabel;
    final photos = widget.session.memoryPhotos ?? [];
    final int joinedCount = widget.session.participants.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.darkSlate, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: _isFavorite ? Colors.redAccent : AppColors.darkSlate,
              size: 24,
            ),
            onPressed: _toggleFavorite,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // 1. Venue Info Card
            Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              venueName,
                              style: GoogleFonts.outfit(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: AppColors.darkSlate,
                                height: 1.1,
                              ),
                            ),
                            if (widget.session.winner?['address'] != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                widget.session.winner!['address'],
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: Colors.grey.shade500,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (venuePhotoUrl != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: CachedNetworkImage(
                            imageUrl: venuePhotoUrl,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Divider(height: 1),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatBadge(
                        icon: Icons.star_rounded,
                        label: "${widget.session.winner?['rating'] ?? '?.?'} (${widget.session.winner?['userRatingCount'] ?? 0})",
                        color: Colors.orange,
                      ),
                      _buildStatBadge(
                        icon: Icons.calendar_today_rounded,
                        label: "${widget.session.createdAt.day}/${widget.session.createdAt.month}/${widget.session.createdAt.year}",
                        color: Colors.blueGrey,
                      ),
                      _buildStatBadge(
                        icon: Icons.local_activity_rounded,
                        label: widget.session.category.toUpperCase(),
                        color: AppColors.teal,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 3. Participants & Memories
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.membersCount(joinedCount),
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkSlate,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildParticipantsStack(widget.session.participants),
                  const SizedBox(height: 40),
                  
                  if (photos.isNotEmpty)
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.darkSlate.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          )
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => OutingMemoriesPage(session: widget.session)),
                        ),
                        icon: const Icon(Icons.photo_library_rounded, size: 20),
                        label: Text(
                          l10n.sessionMemories,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.darkSlate,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipantsStack(List<OutingParticipant> participants) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: participants.map((p) => Column(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.teal.withOpacity(0.1),
            backgroundImage: p.photoUrl != null ? CachedNetworkImageProvider(p.photoUrl!) : null,
            child: p.photoUrl == null ? Text(p.name[0].toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)) : null,
          ),
          const SizedBox(height: 4),
          Text(
            p.name.split(' ')[0],
            style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
          ),
        ],
      )).toList(),
    );
  }

  Widget _buildStatBadge({required IconData icon, required String label, required Color color}) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }
}
