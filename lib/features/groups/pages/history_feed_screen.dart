import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/colors.dart';
import '../data/models/outing_session_model.dart';

class HistoryFeedScreen extends StatefulWidget {
  final String groupId;

  const HistoryFeedScreen({super.key, required this.groupId});

  @override
  State<HistoryFeedScreen> createState() => _HistoryFeedScreenState();
}

class _HistoryFeedScreenState extends State<HistoryFeedScreen> {
  final String myUid = FirebaseAuth.instance.currentUser?.uid ?? '';

  Future<void> _toggleFavorite(OutingSessionModel session) async {
    final sessionRef = FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId)
        .collection('outings')
        .doc(session.id);

    if (session.favoritedBy.contains(myUid)) {
      await sessionRef.update({
        'favoritedBy': FieldValue.arrayRemove([myUid]),
      });
    } else {
      await sessionRef.update({
        'favoritedBy': FieldValue.arrayUnion([myUid]),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AppBar(
        backgroundColor: AppColors.getSurfaceElevated(context),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.darkSlate),
        title: Text(
          "Memories",
          style: GoogleFonts.outfit(
            color: AppColors.darkSlate,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('groups')
            .doc(widget.groupId)
            .collection('outings')
            .where('status', isEqualTo: OutingStatus.archived.name)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.teal),
            );
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
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
                    "No memories yet",
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkSlate,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Finish an outing to save it here!",
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.getTextSecondary(context),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 24),
            itemBuilder: (context, index) {
              final session = OutingSessionModel.fromMap(
                docs[index].data() as Map<String, dynamic>,
              );
              final bool isFavorite = session.favoritedBy.contains(myUid);
              final String title =
                  session.memoryTitle ??
                  "Outing at \${session.winner?['name'] ?? session.category}";
              final String recap = session.memoryRecap ?? "No recap generated.";

              // Formatting the date nicely
              final month = session.createdAt.month;
              final day = session.createdAt.day;
              final year = session.createdAt.year;

              return Container(
                    decoration: BoxDecoration(
                      color: AppColors.getSurfaceElevated(context),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.getShadow(
                            context,
                          ).withValues(alpha: 0.05),
                          blurRadius: 15,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Cover Photo Area
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(24),
                              ),
                              child: Container(
                                height: 200,
                                color: AppColors.getSurface(context),
                                width: double.infinity,
                                child: session.coverPhotoUrl != null
                                    ? CachedNetworkImage(
                                        imageUrl: session.coverPhotoUrl!,
                                        fit: BoxFit.cover,
                                      )
                                    : Icon(
                                        Icons.restaurant_rounded,
                                        size: 48,
                                        color: AppColors.getTextMuted(context),
                                      ),
                              ),
                            ),
                            // Date Badge
                            Positioned(
                              top: 16,
                              left: 16,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  "\$month/\$day/\$year",
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                            // Favorite Heart Button
                            Positioned(
                              top: 12,
                              right: 12,
                              child: GestureDetector(
                                onTap: () => _toggleFavorite(session),
                                child:
                                    Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: AppColors.getSurfaceElevated(
                                              context,
                                            ).withValues(alpha: 0.9),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            isFavorite
                                                ? Icons.favorite_rounded
                                                : Icons.favorite_border_rounded,
                                            color: isFavorite
                                                ? Colors.redAccent
                                                : AppColors.getTextMuted(
                                                    context,
                                                  ),
                                            size: 20,
                                          ),
                                        )
                                        .animate(target: isFavorite ? 1 : 0)
                                        .scaleXY(end: 1.1, duration: 150.ms),
                              ),
                            ),
                            // Picture Count Badge
                            if ((session.memoryPhotos?.length ?? 0) > 1)
                              Positioned(
                                bottom: 12,
                                right: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.6),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.photo_library_rounded,
                                        size: 12,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        "\${session.memoryPhotos!.length}",
                                        style: GoogleFonts.inter(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                        // Content Area (AI Roast & Recap)
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: GoogleFonts.outfit(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.darkSlate,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.teal.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.teal.withValues(
                                      alpha: 0.1,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "🤖 ",
                                      style: TextStyle(fontSize: 16),
                                    ),
                                    Expanded(
                                      child: Text(
                                        recap,
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          color: AppColors.darkSlate,
                                          height: 1.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Participants icons below
                              const SizedBox(height: 16),
                              Row(
                                children: session.participants.take(5).map((p) {
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 6),
                                    child: CircleAvatar(
                                      radius: 12,
                                      backgroundColor: AppColors.getUserColor(
                                        p.uid,
                                      ).withValues(alpha: 0.2),
                                      backgroundImage:
                                          p.photoUrl != null &&
                                              p.photoUrl!.isNotEmpty
                                          ? CachedNetworkImageProvider(
                                              p.photoUrl!,
                                            )
                                          : null,
                                      child:
                                          p.photoUrl == null ||
                                              p.photoUrl!.isEmpty
                                          ? Text(
                                              p.name.isNotEmpty
                                                  ? p.name[0].toUpperCase()
                                                  : '?',
                                              style: GoogleFonts.outfit(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.getUserColor(
                                                  p.uid,
                                                ),
                                              ),
                                            )
                                          : null,
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 400.ms, delay: (index * 100).ms)
                  .slideY(begin: 0.1);
            },
          );
        },
      ),
    );
  }
}
