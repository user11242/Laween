import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:laween/core/theme/colors.dart';
import '../providers/wallpaper_provider.dart';

class ChatWallpaperPage extends StatelessWidget {
  final String groupId;

  const ChatWallpaperPage({super.key, required this.groupId});

  // A carefully selected palette of premium, pleasing wallpaper colors
  static const List<Color> presetColors = [
    Color(0xFFE5DDD5), // Standard WhatsApp Tan
    Color(0xFFECE5DD), // Lighter Tan
    Color(0xFFD3E0D8), // Soft Mint
    Color(0xFFE2DED0), // Ash Grey
    Color(0xFFDED6E0), // Soft Lavender
    Color(0xFFCCDFD4), // Muted Green
    Color(0xFFE8DBE5), // Soft Pink
    Color(0xFFD0DCE5), // Soft Blue
    Color(0xFF232D36), // WhatsApp Dark Slate
    Color(0xFF1E2831), // Deep Dark Blue
    Color(0xFF2C3136), // Charcoal
    Color(0xFFF0F2F5), // Light Default
  ];

  Future<void> _pickImage(BuildContext context) async {
    final picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80, // good quality but not massive
      );
      if (image != null && context.mounted) {
        // Save the absolute file path
        await context.read<WallpaperProvider>().setWallpaper(
          groupId,
          'file://${image.path}',
        );
        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Custom wallpaper applied!')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
      }
    }
  }

  void _setColor(BuildContext context, Color color) {
    // Convert Color to hexadecimal string e.g. #FF123456
    final hexString =
        '#${color.value.toRadixString(16).padLeft(8, '0').toUpperCase()}';
    context.read<WallpaperProvider>().setWallpaper(groupId, hexString);
    Navigator.pop(context);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Wallpaper updated!')));
  }

  void _resetWallpaper(BuildContext context) {
    context.read<WallpaperProvider>().clearWallpaper(groupId);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Wallpaper reset to default.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "Custom Wallpaper",
          style: GoogleFonts.outfit(
            color: AppColors.darkSlate,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.darkSlate),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Custom Options",
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkSlate,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildOptionCard(
                    icon: Icons.photo_library_rounded,
                    title: "Pick from Gallery",
                    subtitle: "Choose a custom photo from your device",
                    color: AppColors.teal,
                    onTap: () => _pickImage(context),
                  ),
                  const SizedBox(height: 12),
                  _buildOptionCard(
                    icon: Icons.layers_clear_rounded,
                    title: "Remove Wallpaper",
                    subtitle: "Restore the default light grey background",
                    color: Colors.red.shade400,
                    onTap: () => _resetWallpaper(context),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    "Solid Colors",
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkSlate,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.8,
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                final color = presetColors[index];
                return GestureDetector(
                  onTap: () => _setColor(context, color),
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.black.withValues(alpha: 0.1),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                );
              }, childCount: presetColors.length),
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
        ],
      ),
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkSlate,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: color),
          ],
        ),
      ),
    );
  }
}
