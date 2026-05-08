// lib/features/profile/pages/favorites_page.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:laween/l10n/app_localizations.dart';
import '../../../core/theme/colors.dart';
import '../../../core/services/favorite_service.dart';
import '../../../core/services/google_maps_service.dart';
import '../../groups/pages/global_outings_history_page.dart';

class FavoritesPage extends StatefulWidget {
  final int initialIndex;
  const FavoritesPage({super.key, this.initialIndex = 0});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2, 
      vsync: this, 
      initialIndex: widget.initialIndex
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AppBar(
        backgroundColor: AppColors.getSurfaceElevated(context),
        elevation: 0,
        title: Text(
          l10n.favorite,
          style: GoogleFonts.outfit(
            color: AppColors.getTextPrimary(context),
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.teal,
          indicatorWeight: 3,
          labelColor: AppColors.teal,
          unselectedLabelColor: AppColors.getTextSecondary(context),
          labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: [
            Tab(text: l10n.savedPlaces),
            Tab(text: l10n.outingsHistory),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const SavedPlacesList(),
          const GlobalOutingsHistoryPage(isEmbedded: true),
        ],
      ),
    );
  }
}

class SavedPlacesList extends StatelessWidget {
  const SavedPlacesList({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isAr = l10n.isAr;

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: FavoriteService().getUserFavoritePlacesStream(), // I'll add this stream to service
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.teal));
        }

        final favorites = snapshot.data ?? [];

        if (favorites.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.favorite_border_rounded, size: 80, color: AppColors.getTextMuted(context).withOpacity(0.3)),
                const SizedBox(height: 16),
                Text(
                  l10n.noFavoritesYet,
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.getTextPrimary(context),
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    isAr ? "اضغط على القلب في أي مكان لحفظه هنا." : "Tap the heart on any place to save it here.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.getTextMuted(context),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(24),
          itemCount: favorites.length,
          separatorBuilder: (_, __) => const SizedBox(height: 20),
          itemBuilder: (context, index) {
            final p = favorites[index];
            return FavoritePlaceCard(place: p);
          },
        );
      },
    );
  }
}

class FavoritePlaceCard extends StatelessWidget {
  final Map<String, dynamic> place;
  const FavoritePlaceCard({super.key, required this.place});

  @override
  Widget build(BuildContext context) {
    final String? photoRef = place['imageUrl'];
    final String? imageUrl = photoRef != null && !photoRef.startsWith('http') 
        ? GoogleMapsService().getPlacePhotoUrl(photoRef)
        : photoRef;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.getSurfaceElevated(context),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.getShadow(context).withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: imageUrl != null
                ? CachedNetworkImage(
                    imageUrl: imageUrl,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: 80,
                    height: 80,
                    color: AppColors.getInputBackground(context),
                    child: const Icon(Icons.location_on_rounded, color: AppColors.teal),
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  place['placeName'] ?? "",
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.getTextPrimary(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                if (place['rating'] != null)
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        "${place['rating']} (${place['userRatingCount'] ?? 0})",
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.getTextSecondary(context),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 4),
                Text(
                  place['address'] ?? place['category'] ?? "",
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.getTextMuted(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.favorite_rounded, color: Colors.redAccent),
            onPressed: () => FavoriteService().removeFavoritePlace(place['placeId']),
          ),
        ],
      ),
    );
  }
}

// Extension to FavoriteService to support list stream
extension FavoriteServiceStream on FavoriteService {
  Stream<List<Map<String, dynamic>>> getUserFavoritePlacesStream() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return Stream.value([]);
    
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('favorites')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }
}
