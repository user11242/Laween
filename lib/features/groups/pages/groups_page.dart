import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:laween/l10n/app_localizations.dart';
import '../widgets/create_join_dialog.dart';

class GroupsPage extends StatefulWidget {
  const GroupsPage({super.key});

  @override
  State<GroupsPage> createState() => _GroupsPageState();
}

class _GroupsPageState extends State<GroupsPage> {
  bool _showMenu = false;

  void _toggleMenu() {
    setState(() {
      _showMenu = !_showMenu;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Teal Header Background
          Container(
            height: screenHeight * 0.3,
            width: double.infinity,
            color: const Color(0xFF006D77),
            padding: const EdgeInsets.symmetric(horizontal: 40),
            alignment: l10n.isAr ? Alignment.centerRight : Alignment.centerLeft,
            child:SafeArea(
              child: Text(
                l10n.groups,
                style: GoogleFonts.inter(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          
          // White Body with Curved Top
          Positioned(
            top: screenHeight * 0.22,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(60),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
              child: Column(
                children: [
                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9), 
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: l10n.search,
                        hintStyle: GoogleFonts.inter(color: Colors.grey.shade500),
                        prefixIcon: const Icon(Icons.search, color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                    ),
                  ),
                  
                  const Expanded(
                    child: Center(
                      child: SizedBox.shrink(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Floating Action Menu Overlay
          if (_showMenu)
            GestureDetector(
              onTap: _toggleMenu,
              child: Container(
                color: Colors.black26, // Dim background
              ),
            ),
          
          if (_showMenu)
            Positioned(
              bottom: 100, // Above FAB
              left: 24,
              right: 24,
              child: Hero(
                tag: 'group_menu',
                child: Material(
                  color: Colors.transparent,
                  child: CreateJoinDialog(
                    onClose: _toggleMenu,
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _toggleMenu,
        backgroundColor: const Color(0xFF94A3B8), 
        child: AnimatedRotation(
          duration: const Duration(milliseconds: 300),
          turns: _showMenu ? 0.125 : 0, // Rotates 45 deg to look like 'x'
          child: const Icon(Icons.add, color: Colors.white, size: 30),
        ),
      ),
    );
  }
}
