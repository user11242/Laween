import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:laween/core/theme/colors.dart';
import '../providers/wallpaper_provider.dart';
import 'package:laween/l10n/app_localizations.dart';

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

  static const List<LinearGradient> presetGradients = [
    LinearGradient(
      colors: [Color(0xFFE2D1C3), Color(0xFFFDFCFB)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ), // Warm Peach
    LinearGradient(
      colors: [Color(0xFFa18cd1), Color(0xFFfbc2eb)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ), // Soft purple-pink
    LinearGradient(
      colors: [Color(0xFFff9a9e), Color(0xFFfecfef)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ), // Cherry blossom
    LinearGradient(
      colors: [Color(0xFF8fd3f4), Color(0xFF84fab0)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ), // Aqua mint
    LinearGradient(
      colors: [Color(0xFFe0c3fc), Color(0xFF8ec5fc)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ), // Soft lavender blue
    LinearGradient(
      colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ), // Bright blue
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
            const SnackBar(content: Text('Custom frosted glass applied!')),
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

  void _setGradient(BuildContext context, LinearGradient gradient) {
    final colors = gradient.colors;
    final hex1 =
        '#${colors[0].value.toRadixString(16).padLeft(8, '0').toUpperCase()}';
    final hex2 =
        '#${colors[1].value.toRadixString(16).padLeft(8, '0').toUpperCase()}';

    // Store as gradient://#color1,#color2
    context.read<WallpaperProvider>().setWallpaper(
      groupId,
      'gradient://$hex1,$hex2',
    );
    Navigator.pop(context);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Premium gradient applied!')));
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
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AppBar(
        title: Text(
          l10n?.customWallpaper ?? "Custom Wallpaper",
          style: GoogleFonts.outfit(
            color: AppColors.getTextPrimary(context),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.getBackground(context),
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.getTextPrimary(context)),
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
                    l10n?.customOptions ?? "Custom Options",
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.getTextPrimary(context),
                    ),
                  ),
                  _buildOptionCard(
                    context: context,
                    icon: Icons.photo_library_rounded,
                    title: l10n?.pickFromGallery ?? "Pick from Gallery",
                    subtitle:
                        l10n?.frostedGlassBlurDesc ??
                        "Will apply a stunning frosted-glass blur",
                    color: AppColors.teal,
                    onTap: () => _pickImage(context),
                  ),
                  const SizedBox(height: 12),
                  _buildOptionCard(
                    context: context,
                    icon: Icons.layers_clear_rounded,
                    title: l10n?.removeWallpaper ?? "Remove Wallpaper",
                    subtitle:
                        l10n?.restoreDefaultWallpaperDesc ??
                        "Restore the default light grey background",
                    color: Colors.red.shade400,
                    onTap: () => _resetWallpaper(context),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    l10n?.premiumGradients ?? "Premium Gradients",
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.getTextPrimary(context),
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
                final gradient = presetGradients[index];

                // Construct string to check if it's active
                final colors = gradient.colors;
                final hex1 =
                    '#${colors[0].value.toRadixString(16).padLeft(8, '0').toUpperCase()}';
                final hex2 =
                    '#${colors[1].value.toRadixString(16).padLeft(8, '0').toUpperCase()}';
                final isActiveStr = 'gradient://$hex1,$hex2';

                final currentWallpaper = context
                    .watch<WallpaperProvider>()
                    .getWallpaper(groupId);
                final isActive = currentWallpaper == isActiveStr;

                return GestureDetector(
                  onTap: () => _setGradient(context, gradient),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: gradient,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isActive
                            ? AppColors.teal
                            : AppColors.getShadow(
                                context,
                              ).withValues(alpha: 0.1),
                        width: isActive ? 3 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: gradient.colors.first.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: isActive
                        ? const Center(
                            child: Icon(
                              Icons.check_circle_rounded,
                              color: Colors.white,
                              size: 36,
                            ),
                          )
                        : null,
                  ),
                );
              }, childCount: presetGradients.length),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(
                left: 20,
                right: 20,
                top: 32,
                bottom: 16,
              ),
              child: Text(
                l10n?.solidColors ?? "Solid Colors",
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.getTextPrimary(context),
                ),
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

                final hexString =
                    '#${color.value.toRadixString(16).padLeft(8, '0').toUpperCase()}';
                final currentWallpaper = context
                    .watch<WallpaperProvider>()
                    .getWallpaper(groupId);
                final isActive = currentWallpaper == hexString;

                return GestureDetector(
                  onTap: () => _setColor(context, color),
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isActive
                            ? AppColors.teal
                            : AppColors.getShadow(
                                context,
                              ).withValues(alpha: 0.1),
                        width: isActive ? 3 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: isActive
                        ? const Center(
                            child: Icon(
                              Icons.check_circle_rounded,
                              color: Colors.white,
                              size: 36,
                            ),
                          )
                        : null,
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
    required BuildContext context,
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
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
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
                      color: AppColors.getTextPrimary(context),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.getTextSecondary(context),
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
