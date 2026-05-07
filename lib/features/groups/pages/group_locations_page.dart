import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/colors.dart';
import '../data/services/group_service.dart';
import 'package:laween/l10n/app_localizations.dart';

class GroupLocationsPage extends StatelessWidget {
  final String groupId;
  final GroupService _groupService = GroupService();

  GroupLocationsPage({super.key, required this.groupId});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AppBar(
        title: Text(
          l10n?.sharedLocationsTitle ?? 'Shared Locations',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: AppColors.getTextPrimary(context),
          ),
        ),
        backgroundColor: AppColors.getSurface(context),
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.getTextPrimary(context)),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _groupService.getGroupLocations(groupId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.teal),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.location_off_outlined,
                    size: 64,
                    color: AppColors.getDivider(context),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n?.noLocationsYet ?? 'No locations shared yet',
                    style: GoogleFonts.inter(
                      color: AppColors.getTextSecondary(context),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          final locations = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: locations.length,
            itemBuilder: (context, index) {
              final msg = locations[index];
              final geo = msg['text']
                  .toString()
                  .replaceFirst('geo:', '')
                  .split(',');
              final lat = geo[0];
              final long = geo[1];
              final date = (msg['timestamp'] as Timestamp).toDate();

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.getSurfaceElevated(context),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.getShadow(context).withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.teal.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.location_on_rounded,
                      color: AppColors.teal,
                    ),
                  ),
                  title: Text(
                    l10n?.isAr == true
                        ? 'بواسطة ${msg['senderName'] ?? 'شخص غير معروف'}'
                        : 'Shared by ${msg['senderName'] ?? 'Unknown'}',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      color: AppColors.getTextPrimary(context),
                    ),
                  ),
                  subtitle: Text(
                    DateFormat('MMM dd, hh:mm a', l10n?.isAr == true ? 'ar' : 'en').format(date),
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.getTextMuted(context)),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.map_rounded, color: AppColors.teal),
                    onPressed: () async {
                      final url =
                          'https://www.google.com/maps/search/?api=1&query=$lat,$long';
                      if (await canLaunchUrl(Uri.parse(url))) {
                        await launchUrl(
                          Uri.parse(url),
                          mode: LaunchMode.externalApplication,
                        );
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
