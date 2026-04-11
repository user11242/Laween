import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/colors.dart';
import 'package:laween/l10n/app_localizations.dart';
import 'package:laween/features/groups/pages/groups_page.dart';
import 'package:laween/features/profile/pages/profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0; // Set back to 0 (Home) by default

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final l10n = AppLocalizations.of(context)!;

    final List<Widget> pages = [
      _buildHomeContent(user),
      const GroupsPage(),
      _buildHomeContent(user), // Placeholder for Favorite
      const ProfilePage(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.teal,
          unselectedItemColor: const Color(0xFF94A3B8),
          selectedLabelStyle: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
          elevation: 0,
          items: [
            BottomNavigationBarItem(
              icon: Icon(_currentIndex == 0 ? Icons.home : Icons.home_outlined),
              label: l10n.home,
            ),
            BottomNavigationBarItem(
              icon: Icon(_currentIndex == 1 ? Icons.people : Icons.people_outline),
              label: l10n.groups,
            ),
            BottomNavigationBarItem(
              icon: Icon(_currentIndex == 2 ? Icons.favorite : Icons.favorite_border),
              label: l10n.favorite,
            ),
            BottomNavigationBarItem(
              icon: Icon(_currentIndex == 3 ? Icons.person : Icons.person_outline),
              label: l10n.profile,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeContent(User? user) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFF1F5F9), // Slate 50
            const Color(0xFFF8FAFC), // Slate 100
            Colors.white,
          ],
        ),
      ),
      child: Stack(
        children: [
          // Subtle accent bloobs/patterns
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.teal.withValues(alpha: 0.05),
              ),
            ),
          ).animate().fadeIn(duration: 2.seconds),
          
          SafeArea(
            child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              
              // 1. DYNAMIC HEADER
              _buildModernHeader(user),
              
              const SizedBox(height: 25),
              
              // 2. GLASSMORPHIC SEARCH
              _buildPremiumSearch(),
              
              const SizedBox(height: 32),
              
              // 3. QUICK ACTIONS CAROUSEL
              Text(
                "Quick Actions",
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkSlate,
                ),
              ).animate().fadeIn(delay: 450.ms, duration: 600.ms).slideX(begin: -0.1, curve: Curves.easeOutCubic),
              
              const SizedBox(height: 16),
              _buildActionCarousel(),
              
              const SizedBox(height: 32),
              
              // 4. LIVE ACTIVITY / FRIENDS SECTION
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Friends Activity",
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkSlate,
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      "See All",
                      style: GoogleFonts.inter(
                        color: AppColors.teal,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 700.ms, duration: 600.ms).slideX(begin: -0.05, curve: Curves.easeOutCubic),
              
              const SizedBox(height: 8),
              _buildFriendsActivityList(user),
              
              const SizedBox(height: 120), // Space for bottom bar
            ],
          ),
        ),
      ),
    ],
    ),
    );
  }

  Widget _buildModernHeader(User? user) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
      builder: (context, snapshot) {
        String name = "User";
        String? photoUrl;
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          name = data['name'] ?? data['fullName'] ?? user?.displayName ?? "User";
          photoUrl = data['photoUrl'] ?? data['profilePic'];
        }
        
        return Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getGreeting(),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  "$name 👋",
                  style: GoogleFonts.inter(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.darkSlate,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ).animate().fadeIn(duration: 800.ms).slideX(begin: -0.1),
            const Spacer(),
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.teal.withValues(alpha: 0.1), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.teal.withValues(alpha: 0.1),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 26,
                backgroundColor: Colors.white,
                backgroundImage: (photoUrl != null && photoUrl.startsWith('http')) ? NetworkImage(photoUrl) : null,
                child: (photoUrl == null || !photoUrl.startsWith('http'))
                    ? Icon(Icons.person, color: AppColors.teal.withValues(alpha: 0.5), size: 30)
                    : null,
              ),
            ).animate().scale(delay: 200.ms),
          ],
        );
      },
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Good Morning";
    if (hour < 17) return "Good Afternoon";
    return "Good Evening";
  }

  Widget _buildPremiumSearch() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: AppColors.teal.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: "Search for friends or groups...",
          hintStyle: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 14),
          prefixIcon: Icon(Icons.search_rounded, color: AppColors.teal.withValues(alpha: 0.6)),
          suffixIcon: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.teal.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.tune_rounded, color: AppColors.teal, size: 18),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
        ),
      ),
    ).animate().fadeIn(delay: 300.ms, duration: 600.ms).slideY(begin: 0.2, curve: Curves.easeOutCubic);
  }

  Widget _buildActionCarousel() {
    final List<Map<String, dynamic>> actions = [
      {
        "title": "Find Midpoint",
        "icon": Icons.location_on_rounded,
        "color": AppColors.teal,
        "desc": "Meet halfway fairly",
      },
      {
        "title": "Groups",
        "icon": Icons.groups_rounded,
        "color": const Color(0xFF6366F1),
        "desc": "3 active sessions",
      },
      {
        "title": "Radar",
        "icon": Icons.radar_rounded,
        "color": const Color(0xFFF59E0B),
        "desc": "Friends nearby",
      },
    ];

    return SizedBox(
      height: 160,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: actions.length,
        itemBuilder: (context, index) {
          final action = actions[index];
          return Container(
            width: 140,
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: (action['color'] as Color).withValues(alpha: 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (action['color'] as Color).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(action['icon'] as IconData, color: action['color'] as Color, size: 24),
                ),
                const Spacer(),
                Text(
                  action['title'] as String,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppColors.darkSlate,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  action['desc'] as String,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: (500 + (index * 100)).ms).slideX(begin: 0.2);
        },
      ),
    );
  }

  Widget _buildFriendsActivityList(User? user) {
    // Dummy stream for now to simulate real activity
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').limit(5).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        final friends = snapshot.data!.docs;
        
        return Column(
          children: friends.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            if (doc.id == user?.uid) return const SizedBox();
            
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundImage: (data['photoUrl'] != null) ? NetworkImage(data['photoUrl']) : null,
                    radius: 20,
                    backgroundColor: AppColors.teal.withValues(alpha: 0.1),
                    child: data['photoUrl'] == null ? const Icon(Icons.person, size: 20) : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['name'] ?? "Friend",
                          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Text(
                          "Active in 'Coffee Run'",
                          style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ),
                  const _PulsingStatusDot(),
                ],
              ),
            ).animate().fadeIn(delay: (800 + (friends.indexOf(doc) * 100)).ms).slideY(begin: 0.1);
          }).toList(),
        );
      },
    );
  }
}

class _PulsingStatusDot extends StatefulWidget {
  const _PulsingStatusDot();

  @override
  State<_PulsingStatusDot> createState() => _PulsingStatusDotState();
}

class _PulsingStatusDotState extends State<_PulsingStatusDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 20,
          height: 20,
          alignment: Alignment.center,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 8 + (12 * _controller.value),
                height: 8 + (12 * _controller.value),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 1 - _controller.value),
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF10B981),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
