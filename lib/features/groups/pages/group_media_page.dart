import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/colors.dart';
import '../data/services/group_service.dart';
import './chat_page.dart';

class GroupMediaPage extends StatelessWidget {
  final String groupId;
  final GroupService _groupService = GroupService();

  GroupMediaPage({super.key, required this.groupId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Media',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.darkSlate),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.darkSlate),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _groupService.getGroupMedia(groupId), // I should probably add an 'all' version without limit
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.teal));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Icon(Icons.photo_library_outlined, size: 64, color: Colors.grey.shade300),
                   const SizedBox(height: 16),
                   Text(
                    'No media shared yet',
                    style: GoogleFonts.inter(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          final media = snapshot.data!;
          // Flatten mediaUrls from all messages
          final List<String> imageList = [];
          final List<Map<String, dynamic>> imageMeta = [];
          
          for (var msg in media) {
            final List<String> urls = (msg['mediaUrls'] as List?)?.cast<String>() ?? [msg['text']];
            for (var url in urls) {
              imageList.add(url);
              imageMeta.add(msg);
            }
          }

          return GridView.builder(
            padding: const EdgeInsets.all(2),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 2,
              mainAxisSpacing: 2,
            ),
            itemCount: imageList.length,
            itemBuilder: (context, index) {
              final url = imageList[index];
              final msg = imageMeta[index];

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FullScreenImagePage(
                        imageUrl: url,
                        allImages: imageList,
                        allMetadata: imageMeta, // Pass the full metadata list
                        initialIndex: index,
                        senderName: msg['senderName'] ?? 'Shared Image',
                        timestamp: (msg['timestamp'] as Timestamp).toDate(),
                      ),
                    ),
                  );
                },
                child: CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(color: Colors.grey.shade100),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
