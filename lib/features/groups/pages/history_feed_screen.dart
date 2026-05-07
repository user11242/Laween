import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/colors.dart';
import '../data/models/outing_session_model.dart';
import 'history_detail_page.dart';
import 'package:laween/l10n/app_localizations.dart';

class HistoryFeedScreen extends StatefulWidget {
  final String groupId;

  const HistoryFeedScreen({super.key, required this.groupId});

  @override
  State<HistoryFeedScreen> createState() => _HistoryFeedScreenState();
}

class _HistoryFeedScreenState extends State<HistoryFeedScreen> {
  final String myUid = FirebaseAuth.instance.currentUser?.uid ?? '';
  bool _showOnlyFavorites = false;

  Future<void> _toggleFavorite(OutingSessionModel session) async {
    final sessionRef = FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId)
        .collection('outings')
        .doc(session.id);

    if (session.favoritedBy.contains(myUid)) {
      await sessionRef.update({
        'favoritedBy': FieldValue.arrayRemove([myUid])
      });
    } else {
      await sessionRef.update({
        'favoritedBy': FieldValue.arrayUnion([myUid])
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AppBar(
        backgroundColor: AppColors.getSurfaceElevated(context),
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.getTextPrimary(context)),
        title: Text(
          l10n.squadHistory,
          style: GoogleFonts.outfit(
            color: AppColors.getTextPrimary(context),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: Column(
        children: [
          // --- FILTER TOGGLE ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              children: [
                _buildFilterChip(l10n.allLabel, !_showOnlyFavorites),
                const SizedBox(width: 12),
                _buildFilterChip(l10n.favoritesLabel, _showOnlyFavorites),
              ],
            ),
          ),
          
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.teal));
                }

                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 32),
                  itemBuilder: (context, index) {
                    final session = OutingSessionModel.fromMap(docs[index].data() as Map<String, dynamic>);
                    return _buildHistoryCard(session, index);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Stream<QuerySnapshot> _getStream() {
    var query = FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId)
        .collection('outings')
        .where('status', isEqualTo: OutingStatus.archived.name);

    if (_showOnlyFavorites) {
      query = query.where('favoritedBy', arrayContains: myUid);
    }

    return query.orderBy('createdAt', descending: true).snapshots();
  }

  Widget _buildFilterChip(String label, bool active) {
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: () => setState(() => _showOnlyFavorites = label == l10n.favoritesLabel),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active
              ? AppColors.getTextPrimary(context)
              : AppColors.getInputBackground(context),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: active
                ? AppColors.getBackground(context)
                : AppColors.getTextSecondary(context),
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryCard(OutingSessionModel session, int index) {
    final l10n = AppLocalizations.of(context)!;
    final bool isFavorite = session.favoritedBy.contains(myUid);
    final String title = session.memoryTitle ?? l10n.epicOutingLabel;
    
    return GestureDetector(
      onTap: () => Navigator.push(
        context, 
        MaterialPageRoute(builder: (_) => HistoryDetailPage(session: session))
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.getSurfaceElevated(context),
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: AppColors.getShadow(context).withValues(alpha: 0.05),
              blurRadius: 30,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cover Photo
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                  child: Container(
                    height: 220,
                    width: double.infinity,
                    color: AppColors.getInputBackground(context),
                    child: session.coverPhotoUrl != null
                        ? CachedNetworkImage(
                            imageUrl: session.coverPhotoUrl!,
                            fit: BoxFit.cover,
                          )
                        : Icon(
                            Icons.photo_library_rounded,
                            size: 48,
                            color: AppColors.getTextMuted(context),
                          ),
                  ),
                ),
                // Favorite Button
                Positioned(
                  top: 20,
                  right: 20,
                  child: GestureDetector(
                    onTap: () => _toggleFavorite(session),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.getSurfaceElevated(context).withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.getShadow(context).withValues(alpha: 0.1),
                            blurRadius: 10,
                          )
                        ]
                      ),
                      child: Icon(
                        isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        color: isFavorite
                            ? Colors.redAccent
                            : AppColors.getTextMuted(context),
                        size: 22,
                      ),
                    ),
                  ),
                ),
                // Photo Count
                if ((session.memoryPhotos?.length ?? 0) > 0)
                  Positioned(
                    bottom: 16,
                    left: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.photo_library_rounded, size: 14, color: Colors.white),
                          const SizedBox(width: 6),
                          Text(
                            l10n.photosLabel(session.memoryPhotos!.length),
                            style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${session.createdAt.day}/${session.createdAt.month}/${session.createdAt.year}",
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: AppColors.teal,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.getTextPrimary(context),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  if (session.memoryRecap != null)
                    Text(
                      session.memoryRecap!,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.getTextSecondary(context),
                        height: 1.5,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms, delay: (index * 100).ms).slideY(begin: 0.1);
  }

  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_rounded,
            size: 64,
            color: AppColors.getInputBackground(context),
          ),
          const SizedBox(height: 16),
          Text(
            _showOnlyFavorites ? l10n.noFavoritesYet : l10n.noMemoriesYetLabel,
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.getTextPrimary(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _showOnlyFavorites ? l10n.tapHeartToSave : l10n.finishOutingToSaveMemories,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.getTextMuted(context),
            ),
          ),
        ],
      ),
    );
  }
}
