import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../groups/data/models/group_model.dart';
import '../../groups/pages/chat_page.dart';

class RecentGroupCard extends StatelessWidget {
  final GroupModel group;

  const RecentGroupCard({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ChatPage(group: group)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.getSurface(context),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.getDivider(context), width: 1),
          boxShadow: [
            BoxShadow(
              color: AppColors.getShadow(context).withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            _buildGroupAvatar(context),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          group.name,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.getTextPrimary(context),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (group.lastMessageTime != null)
                        Text(
                          _formatTime(context, group.lastMessageTime!),
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.getTextSecondary(context),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          group.lastMessage ?? "No messages yet",
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.getTextSecondary(context),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _buildMemberAvatars(context),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupAvatar(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.teal.withValues(alpha: 0.15),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.getSurface(context), width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.teal.withValues(alpha: 0.2),
            blurRadius: 8,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: (group.photoUrl != null && group.photoUrl!.startsWith('http'))
            ? CachedNetworkImage(
                imageUrl: group.photoUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => _buildPlaceholderAvatar(),
                errorWidget: (context, url, error) => _buildPlaceholderAvatar(),
              )
            : _buildPlaceholderAvatar(),
      ),
    );
  }

  Widget _buildPlaceholderAvatar() {
    String firstChar = "G";
    if (group.name.isNotEmpty) {
      // Using .characters to safely extract the first grapheme cluster without splitting emojis!
      firstChar = group.name.characters.first.toUpperCase();
    }

    return Center(
      child: Text(
        firstChar,
        style: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.teal.withValues(alpha: 0.8),
        ),
      ),
    );
  }

  Widget _buildMemberAvatars(BuildContext context) {
    return SizedBox(
      height: 20,
      width: 45,
      child: Stack(
        children: List.generate(
          math.min(group.memberIds.length, 3),
          (index) => Positioned(
            left: index * 12.0,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: AppColors.getSurfaceElevated(context),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.getSurface(context),
                  width: 1.5,
                ),
              ),
              child: Icon(
                Icons.person,
                size: 10,
                color: AppColors.getTextSecondary(context),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(BuildContext context, DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    final isAr = AppLocalizations.of(context)?.isAr == true;

    if (diff.inDays == 0) {
      final formattedTime = DateFormat('hh:mm a').format(date);
      if (isAr) {
        return formattedTime.replaceAll('AM', 'ص').replaceAll('PM', 'م');
      }
      return formattedTime;
    }
    if (diff.inDays < 7) {
      return DateFormat('EEE', isAr ? 'ar' : 'en').format(date);
    }
    return DateFormat('MMM d', isAr ? 'ar' : 'en').format(date);
  }
}
