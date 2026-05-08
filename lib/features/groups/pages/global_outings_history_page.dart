import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/colors.dart';
import '../data/models/outing_session_model.dart';
import 'package:laween/l10n/app_localizations.dart';
import 'history_detail_page.dart';
import 'package:laween/core/services/google_maps_service.dart';
import 'package:laween/core/services/favorite_service.dart';

class GlobalOutingsHistoryPage extends StatefulWidget {
  final bool showFavoritesOnly;
  final bool isEmbedded;
  const GlobalOutingsHistoryPage({
    super.key, 
    this.showFavoritesOnly = false,
    this.isEmbedded = false,
  });

  @override
  State<GlobalOutingsHistoryPage> createState() => _GlobalOutingsHistoryPageState();
}

class _GlobalOutingsHistoryPageState extends State<GlobalOutingsHistoryPage> {
  final String myUid = FirebaseAuth.instance.currentUser?.uid ?? '';
  bool _isLoading = true;
  bool _showOnlyFavorites = false;
  List<_GlobalOutingItem> _allOutings = [];
  List<_GlobalOutingItem> _filteredOutings = [];

  @override
  void initState() {
    super.initState();
    _showOnlyFavorites = widget.showFavoritesOnly;
    _loadAllOutings();
  }

  Future<void> _loadAllOutings() async {
    if (myUid.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final groupsSnapshot = await FirebaseFirestore.instance
          .collection('groups')
          .where('memberIds', arrayContains: myUid)
          .get();

      List<_GlobalOutingItem> allItems = [];

      for (var groupDoc in groupsSnapshot.docs) {
        final groupData = groupDoc.data();
        final groupName = groupData['name'] ?? 'Group';

        final outingsSnapshot = await groupDoc.reference
            .collection('outings')
            .where('status', isEqualTo: OutingStatus.archived.name)
            .get();

        for (var outingDoc in outingsSnapshot.docs) {
          final outingData = outingDoc.data();
          final session = OutingSessionModel.fromMap(outingData);
          allItems.add(_GlobalOutingItem(
            session: session,
            groupName: groupName,
            groupId: groupDoc.id,
            totalGroupMembers: (groupData['memberIds'] as List?)?.length ?? 0,
          ));
        }
      }

      allItems.sort((a, b) => b.session.createdAt.compareTo(a.session.createdAt));

      if (mounted) {
        setState(() {
          _allOutings = allItems;
          _applyFilter();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _applyFilter() {
    setState(() {
      if (_showOnlyFavorites) {
        _filteredOutings = _allOutings.where((item) => item.session.favoritedBy.contains(myUid)).toList();
      } else {
        _filteredOutings = List.from(_allOutings);
      }
    });
  }

  Future<void> _toggleFavorite(OutingSessionModel session, String groupId) async {
    final sessionRef = FirebaseFirestore.instance
        .collection('groups')
        .doc(groupId)
        .collection('outings')
        .doc(session.id);

    final bool isFav = session.favoritedBy.contains(myUid);
    if (isFav) {
      await sessionRef.update({
        'favoritedBy': FieldValue.arrayRemove([myUid])
      });
      session.favoritedBy.remove(myUid);
      
      // Also remove from central favorites if it matches
      if (session.winner != null && session.winner!['id'] != null) {
        await FavoriteService().removeFavoritePlace(session.winner!['id'].toString());
      }
    } else {
      await sessionRef.update({
        'favoritedBy': FieldValue.arrayUnion([myUid])
      });
      session.favoritedBy.add(myUid);
      
      // Also add to central favorites
      if (session.winner != null && session.winner!['id'] != null) {
        final winner = session.winner!;
        await FavoriteService().addFavoritePlace(
          place: {
            'id': winner['id'].toString(),
            'name': winner['name'],
            'address': winner['address'],
            'location': winner['location'],
            'photoReference': winner['photoReference'],
            'rating': winner['rating'],
            'userRatingCount': winner['userRatingCount'],
          },
          source: "outing_history",
          visited: true,
          sourceOutingId: session.id,
        );
      }
    }

    _applyFilter();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    if (widget.isEmbedded) {
      return _buildContent(l10n);
    }

    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AppBar(
        backgroundColor: AppColors.getSurfaceElevated(context),
        elevation: 0,
        centerTitle: true,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppColors.getTextPrimary(context),
                ),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: Text(
          l10n.outingsHistory,
          style: GoogleFonts.outfit(
            color: AppColors.getTextPrimary(context),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: _buildContent(l10n),
    );
  }

  Widget _buildContent(AppLocalizations l10n) {
    return Column(
      children: [
        // Filter Chips
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: [
              _buildFilterChip(l10n.allLabel, !_showOnlyFavorites),
              const SizedBox(width: 12),
              _buildFilterChip(l10n.favoritesLabel, _showOnlyFavorites),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.teal))
              : _filteredOutings.isEmpty
                  ? _buildEmptyState(l10n)
                  : RefreshIndicator(
                      onRefresh: _loadAllOutings,
                      color: AppColors.teal,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        itemCount: _filteredOutings.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 32),
                        itemBuilder: (context, index) {
                          final item = _filteredOutings[index];
                          return _buildHistoryCard(item, index);
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, bool active) {
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: () {
        setState(() => _showOnlyFavorites = label == l10n.favoritesLabel);
        _applyFilter();
      },
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

  Widget _buildHistoryCard(_GlobalOutingItem item, int index) {
    final l10n = AppLocalizations.of(context)!;
    final session = item.session;
    final bool isFavorite = session.favoritedBy.contains(myUid);
    final String venueName = session.winner?['name'] ?? l10n.epicOutingLabel;
    
    // Fetch venue image from photoReference if available
    final String? venuePhotoRef = session.winner?['photoReference'];
    final String? venuePhotoUrl = GoogleMapsService().getPlacePhotoUrl(venuePhotoRef);

    final int joinedCount = session.participants.length;
    final int totalCount = item.totalGroupMembers;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => HistoryDetailPage(session: session)),
      ),
      child: Container(
        height: 120,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.getSurfaceElevated(context),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.getShadow(context).withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: Row(
          children: [
            // 1. Image (Venue Image first, then cover photo)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: 96,
                height: 96,
                color: AppColors.getInputBackground(context),
                child: venuePhotoUrl != null
                    ? CachedNetworkImage(
                        imageUrl: venuePhotoUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : session.coverPhotoUrl != null
                        ? CachedNetworkImage(
                            imageUrl: session.coverPhotoUrl!,
                            fit: BoxFit.cover,
                          )
                        : Icon(
                            Icons.location_on_rounded,
                            color: AppColors.getTextMuted(context),
                          ),
              ),
            ),
            const SizedBox(width: 16),
            // 2. Info
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.groupName.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: AppColors.teal,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    venueName,
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.getTextPrimary(context),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.people_alt_rounded,
                        size: 14,
                        color: AppColors.getTextMuted(context),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        l10n.participantCount(joinedCount, totalCount),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.getTextSecondary(context),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // 3. Actions & Date
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => _toggleFavorite(session, item.groupId),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    isFavorite
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: isFavorite
                        ? Colors.redAccent
                        : AppColors.getShadow(context),
                    size: 22,
                  ),
                ),
                Text(
                  "${session.createdAt.day}/${session.createdAt.month}/${session.createdAt.year}",
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: AppColors.getTextMuted(context),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms, delay: (index * 80).ms).slideX(
      begin: 0.1,
      end: 0,
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
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

class _GlobalOutingItem {
  final OutingSessionModel session;
  final String groupName;
  final String groupId;
  final int totalGroupMembers;

  _GlobalOutingItem({
    required this.session,
    required this.groupName,
    required this.groupId,
    required this.totalGroupMembers,
  });
}
