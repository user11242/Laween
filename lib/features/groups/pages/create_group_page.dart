import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:laween/l10n/app_localizations.dart';

class CreateGroupPage extends StatelessWidget {
  const CreateGroupPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header with Back Button
            ClipPath(
              clipper: CreateGroupHeaderClipper(),
              child: Container(
                height: screenHeight * 0.22,
                width: double.infinity,
                color: const Color(0xFF006D77),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SafeArea(
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Transform.flip(
                            flipX: l10n.isAr,
                            child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Text(
                        l10n.createGroup,
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  // Group Photo Placeholder
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          color: const Color(0xFF006D77).withValues(alpha: 0.05),
                          shape: BoxShape.circle,
                        ),
                      ),
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: const Color(0xFF94A3B8).withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt_outlined, size: 40, color: Color(0xFF94A3B8)),
                      ),
                      // Decorative dots around
                      Positioned(
                        top: 20, left: 20,
                        child: _buildDecorativeDots(const Color(0xFF006D77)),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  Text(
                    l10n.createANewGroup,
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2D3748),
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Group Name Input
                  Align(
                    alignment: l10n.isAr ? Alignment.centerRight : Alignment.centerLeft,
                    child: Text(
                      l10n.groupName,
                      style: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade600),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Members / Add Members
                  Align(
                    alignment: l10n.isAr ? Alignment.centerRight : Alignment.centerLeft,
                    child: Text(
                      l10n.members,
                      style: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade600),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.add_circle, color: Color(0xFF006D77)),
                      label: Text(
                        l10n.addMembers,
                        style: GoogleFonts.inter(color: const Color(0xFF2D3748), fontWeight: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF006D77)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 60),
                  
                  // Continue Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF006D77),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        elevation: 0,
                      ),
                      child: Text(
                        l10n.continueText,
                        style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDecorativeDots(Color color) {
    return Column(
      children: [
        Row(
          children: [
            Container(width: 4, height: 4, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Container(width: 4, height: 4, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          ],
        ),
        const SizedBox(height: 6),
        Container(width: 4, height: 4, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      ],
    );
  }
}

class CreateGroupHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height);
    path.quadraticBezierTo(size.width * 0.7, size.height, size.width, size.height - 60);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
