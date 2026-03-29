import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:laween/features/auth/data/services/auth_service.dart';
import '../../../core/theme/colors.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:laween/features/auth/pages/onboarding_page.dart';
import 'package:laween/features/profile/pages/language_page.dart';
import 'package:laween/features/profile/pages/edit_profile_page.dart';
import 'package:laween/features/profile/pages/favorites_page.dart';
import 'package:laween/features/profile/pages/settings_page.dart';
import 'package:laween/features/profile/pages/about_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Future<void> _handleLogout(BuildContext context) async {
    await AuthService().signOut();
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const OnboardingPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = FirebaseAuth.instance.currentUser;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.grey.shade50, // Slightly off-white for premium card contrast
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
        builder: (context, snapshot) {
          String displayName = "User Name";
          String? photoUrl = user?.photoURL;

          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>;
            displayName = data['name'] ?? data['fullName'] ?? user?.displayName ?? "User Name";
            photoUrl = data['photoUrl'] ?? data['profilePic'] ?? photoUrl;
          }

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                // --- 1. Header Section ---
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    // Premium Gradient Curved Background
                    ClipPath(
                      clipper: ProfileHeaderClipper(),
                      child: Container(
                        height: screenHeight * 0.28,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: AppColors.tealGradient),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.teal.withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            )
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: SafeArea(
                          child: Column(
                            children: [
                              const SizedBox(height: 10),
                              Text(
                                l10n.profile,
                                style: GoogleFonts.inter(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    // Profile Avatar with Dual Border & Camera Badge
                    Positioned(
                      bottom: -55,
                      child: Stack(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 15,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 55,
                              backgroundColor: AppColors.teal.withValues(alpha: 0.1),
                              backgroundImage: (photoUrl != null && photoUrl.startsWith('http')) ? NetworkImage(photoUrl) : null,
                              child: (photoUrl?.startsWith('http') != true)
                                  ? Icon(
                                      Icons.person,
                                      size: 70,
                                      color: AppColors.teal.withValues(alpha: 0.5),
                                    )
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 70),
                
                // --- 2. User Info ---
                Text(
                  displayName,
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2D3748),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    user?.email ?? "email@example.com",
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // --- 3. Grouped Settings Menu ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
                        child: Text(
                          l10n.isAr ? "حسابي" : "Account",
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade500,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 10,
                              spreadRadius: 0,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _buildPremiumMenuItem(
                              icon: Icons.person_outline,
                              iconBgColor: Colors.blue.withValues(alpha: 0.15),
                              iconColor: Colors.blue.shade700,
                              title: l10n.editProfile,
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfilePage())),
                            ),
                            const Divider(height: 1, indent: 64, color: Color(0xFFEDF2F7)),
                            _buildPremiumMenuItem(
                              icon: Icons.favorite_border,
                              iconBgColor: Colors.pink.withValues(alpha: 0.15),
                              iconColor: Colors.pink.shade600,
                              title: l10n.myFavorites,
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const FavoritesPage())),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
                        child: Text(
                          l10n.isAr ? "التفضيلات" : "Preferences",
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade500,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 10,
                              spreadRadius: 0,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _buildPremiumMenuItem(
                              icon: Icons.language,
                              iconBgColor: AppColors.teal.withValues(alpha: 0.15),
                              iconColor: AppColors.teal,
                              title: l10n.language,
                              trailingText: l10n.isAr ? "العربية" : "English",
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const LanguagePage())),
                            ),
                            const Divider(height: 1, indent: 64, color: Color(0xFFEDF2F7)),
                            _buildPremiumMenuItem(
                              icon: Icons.settings_outlined,
                              iconBgColor: Colors.purple.withValues(alpha: 0.15),
                              iconColor: Colors.purple.shade600,
                              title: l10n.settings,
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsPage())),
                            ),
                            const Divider(height: 1, indent: 64, color: Color(0xFFEDF2F7)),
                            _buildPremiumMenuItem(
                              icon: Icons.info_outline,
                              iconBgColor: Colors.orange.withValues(alpha: 0.15),
                              iconColor: Colors.orange.shade700,
                              title: l10n.aboutLaween,
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AboutPage())),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),
                      
                      // --- 4. Standalone Logout Action ---
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.red.withValues(alpha: 0.1)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withValues(alpha: 0.05),
                              blurRadius: 10,
                              spreadRadius: 0,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: _buildPremiumMenuItem(
                          icon: Icons.logout,
                          iconBgColor: Colors.red.withValues(alpha: 0.1),
                          iconColor: Colors.red.shade600,
                          title: l10n.logout,
                          textColor: Colors.red.shade600,
                          onTap: () => _handleLogout(context),
                          isDestructive: true,
                        ),
                      ),
                      
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPremiumMenuItem({
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
    String? trailingText,
    bool isDestructive = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: isDestructive ? FontWeight.w600 : FontWeight.w500,
                    color: textColor ?? const Color(0xFF2D3748),
                  ),
                ),
              ),
              if (trailingText != null) ...[
                Text(
                  trailingText,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.teal,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: isDestructive ? Colors.red.withValues(alpha: 0.3) : Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProfileHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 40);
    path.quadraticBezierTo(size.width * 0.5, size.height + 30, size.width, size.height - 40);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
