import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/colors.dart';
import '../data/models/outing_session_model.dart';
import 'package:laween/l10n/app_localizations.dart';

class GlobalOutingsHistoryPage extends StatefulWidget {
  const GlobalOutingsHistoryPage({super.key});

  @override
  State<GlobalOutingsHistoryPage> createState() =>
      _GlobalOutingsHistoryPageState();
}

class _GlobalOutingsHistoryPageState extends State<GlobalOutingsHistoryPage> {
  final String myUid = FirebaseAuth.instance.currentUser?.uid ?? '';
  bool _isLoading = true;
  List<_GlobalOutingItem> _outings = [];

  @override
  void initState() {
    super.initState();
    _loadAllOutings();
  }

  Future<void> _loadAllOutings() async {
    if (myUid.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      // 1. Fetch user groups
      final groupsSnapshot = await FirebaseFirestore.instance
          .collection('groups')
          .where('memberIds', arrayContains: myUid)
          .get();

      List<_GlobalOutingItem> allOutings = [];

      // 2. Fetch all archived outings for each group
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
          allOutings.add(
            _GlobalOutingItem(
              session: session,
              groupName: groupName,
              groupId: groupDoc.id,
            ),
          );
        }
      }

      // 3. Sort by createdAt descending
      allOutings.sort(
        (a, b) => b.session.createdAt.compareTo(a.session.createdAt),
      );

      if (mounted) {
        setState(() {
          _outings = allOutings;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleFavorite(
    OutingSessionModel session,
    String groupId,
  ) async {
    final sessionRef = FirebaseFirestore.instance
        .collection('groups')
        .doc(groupId)
        .collection('outings')
        .doc(session.id);

    final bool isFav = session.favoritedBy.contains(myUid);
    if (isFav) {
      await sessionRef.update({
        'favoritedBy': FieldValue.arrayRemove([myUid]),
      });
    } else {
      await sessionRef.update({
        'favoritedBy': FieldValue.arrayUnion([myUid]),
      });
    }

    // Live update local state
    setState(() {
      if (isFav) {
        session.favoritedBy.remove(myUid);
      } else {
        session.favoritedBy.add(myUid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AppBar(
        backgroundColor: AppColors.getSurfaceElevated(context),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.getTextPrimary(context)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.outingsHistory,
          style: GoogleFonts.outfit(
            color: AppColors.getTextPrimary(context),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.teal),
            )
          : _outings.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history_rounded,
                    size: 64,
                    color: AppColors.getTextMuted(context),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.noMemoriesYet,
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.getTextPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.finishOutingToSave,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.getTextSecondary(context),
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadAllOutings,
              color: AppColors.teal,
              child: ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: _outings.length,
                separatorBuilder: (_, __) => const SizedBox(height: 20),
                itemBuilder: (context, index) {
                  final item = _outings[index];
                  final session = item.session;
                  final bool isFavorite = session.favoritedBy.contains(myUid);
                  final String title =
                      session.memoryTitle ??
                      "Outing at ${session.winner?['name'] ?? session.category}";
                  final String recap =
                      session.memoryRecap ?? "No recap recorded.";

                  // Date formatting
                  final month = session.createdAt.month;
                  final day = session.createdAt.day;
                  final year = session.createdAt.year;

                  return Container(
                        decoration: BoxDecoration(
                          color: AppColors.getSurfaceElevated(context),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.getShadow(
                                context,
                              ).withValues(alpha: 0.04),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Cover photo
                            Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(20),
                                  ),
                                  child: Container(
                                    height: 170,
                                    color: AppColors.getSurface(context),
                                    width: double.infinity,
                                    child: session.coverPhotoUrl != null
                                        ? CachedNetworkImage(
                                            imageUrl: session.coverPhotoUrl!,
                                            fit: BoxFit.cover,
                                          )
                                        : Icon(
                                            Icons.restaurant_rounded,
                                            size: 40,
                                            color: AppColors.getTextMuted(
                                              context,
                                            ),
                                          ),
                                  ),
                                ),
                                // Date badge
                                Positioned(
                                  top: 14,
                                  left: 14,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(
                                        alpha: 0.65,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      "$month/$day/$year",
                                      style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ),
                                // Group badge
                                Positioned(
                                  top: 14,
                                  right: 54,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.teal.withValues(
                                        alpha: 0.9,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      item.groupName,
                                      style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ),
                                // Favorite button
                                Positioned(
                                  top: 10,
                                  right: 10,
                                  child: GestureDetector(
                                    onTap: () =>
                                        _toggleFavorite(session, item.groupId),
                                    child:
                                        Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color:
                                                    AppColors.getSurfaceElevated(
                                                      context,
                                                    ).withValues(alpha: 0.9),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                isFavorite
                                                    ? Icons.favorite_rounded
                                                    : Icons
                                                          .favorite_border_rounded,
                                                color: isFavorite
                                                    ? Colors.redAccent
                                                    : AppColors.getTextMuted(
                                                        context,
                                                      ),
                                                size: 18,
                                              ),
                                            )
                                            .animate(target: isFavorite ? 1 : 0)
                                            .scaleXY(
                                              end: 1.1,
                                              duration: 150.ms,
                                            ),
                                  ),
                                ),
                              ],
                            ),
                            // Content
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: GoogleFonts.outfit(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.getTextPrimary(context),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppColors.teal.withValues(
                                        alpha: 0.04,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: AppColors.teal.withValues(
                                          alpha: 0.08,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          "🤖 ",
                                          style: TextStyle(fontSize: 14),
                                        ),
                                        Expanded(
                                          child: Text(
                                            recap,
                                            style: GoogleFonts.inter(
                                              fontSize: 13,
                                              color: AppColors.getTextPrimary(context),
                                              height: 1.4,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 400.ms, delay: (index * 80).ms)
                      .slideY(begin: 0.08);
                },
              ),
            ),
    );
  }
}

class _GlobalOutingItem {
  final OutingSessionModel session;
  final String groupName;
  final String groupId;

  _GlobalOutingItem({
    required this.session,
    required this.groupName,
    required this.groupId,
  });
}
