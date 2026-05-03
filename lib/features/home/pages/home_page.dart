import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/colors.dart';
import 'package:laween/l10n/app_localizations.dart';
import 'package:laween/features/groups/pages/groups_page.dart';
import 'package:laween/features/profile/pages/profile_page.dart';
import 'package:laween/features/groups/data/models/group_model.dart';
import '../widgets/live_tracking_widget.dart';
import '../widgets/recent_group_card.dart';
import '../../groups/pages/create_group_page.dart';
import '../../groups/pages/join_group_page.dart';
import '../../groups/pages/global_outings_history_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  late Stream<int> _totalUnreadStream;
  final _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _initUnreadStream();
  }

  void _initUnreadStream() {
    final user = _auth.currentUser;
    if (user == null) {
      _totalUnreadStream = Stream.value(0);
      return;
    }
    
    _totalUnreadStream = FirebaseFirestore.instance
        .collection('groups')
        .where('memberIds', arrayContains: user.uid)
        .snapshots()
        .map((snapshot) {
          int total = 0;
          for (var doc in snapshot.docs) {
            final unreadCounts =
                doc.data()['unreadCounts'] as Map<String, dynamic>?;
            if (unreadCounts != null) {
              total += (unreadCounts[user.uid] as num? ?? 0).toInt();
            }
          }
          return total;
        });
  }

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

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
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
          backgroundColor: isDark ? const Color(0xFF1F1F1F) : Colors.white,
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
              icon: StreamBuilder<int>(
                stream: _totalUnreadStream,
                builder: (context, snapshot) {
                  final count = snapshot.data ?? 0;
                  return Badge(
                    label: Text(count.toString()),
                    isLabelVisible: count > 0,
                    backgroundColor: Colors.redAccent,
                    child: Icon(
                      _currentIndex == 1 ? Icons.people : Icons.people_outline,
                    ),
                  );
                },
              ),
              label: l10n.groups,
            ),
            BottomNavigationBarItem(
              icon: Icon(
                _currentIndex == 2 ? Icons.favorite : Icons.favorite_border,
              ),
              label: l10n.favorite,
            ),
            BottomNavigationBarItem(
              icon: Icon(
                _currentIndex == 3 ? Icons.person : Icons.person_outline,
              ),
              label: l10n.profile,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeContent(User? user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
      ),
      child: Stack(
        children: [
          // 1. BLURRY ACCENT BLOBS (Premium "WOW")
          Positioned(
                top: -50,
                right: -50,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF6366F1).withValues(alpha: 0.08),
                  ),
                ),
              )
              .animate()
              .fadeIn(duration: 2.seconds)
              .scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack),

          Positioned(
            top: 150,
            left: -80,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.teal.withValues(alpha: 0.05),
              ),
            ),
          ).animate().fadeIn(delay: 500.ms, duration: 2.seconds),

          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  // 2. MODERN HEADER (White text for dark mode)
                  _buildModernHeader(user),

                  const SizedBox(height: 32),

                  // 3. LIVE TRACKING DISCOVERY (Careem Style)
                  const LiveTrackingDashboardWidget(),

                  // 4. QUICK ACTIONS GRID (2x2)
                  Text(
                    l10n.isAr ? "الإجراءات السريعة" : "Quick Actions",
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.primary,
                    ),
                  ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1),

                  const SizedBox(height: 16),
                  _buildQuickActionsGrid(),

                  const SizedBox(height: 32),

                  // 5. RECENTLY ACTIVE GROUPS
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.isAr ? "النشطة مؤخراً" : "Recently Active",
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.primary,
                        ),
                      ),
                      TextButton(
                        onPressed: () => setState(() => _currentIndex = 1),
                        child: Text(
                          l10n.isAr ? "عرض الكل" : "See All",
                          style: GoogleFonts.inter(
                            color: AppColors.teal.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.05),

                  const SizedBox(height: 8),
                  _buildRecentlyActive(user),

                  const SizedBox(height: 120),
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
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        String name = "User";
        String? photoUrl;
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          name = data['name'] ?? data['fullName'] ?? user?.displayName ?? "Me";
          photoUrl = data['photoUrl'] ?? data['profilePic'];
        }

        final l10n = AppLocalizations.of(context)!;
        return Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getGreeting(l10n),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.slate,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  "$name 👋",
                  style: GoogleFonts.inter(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ).animate().fadeIn(duration: 800.ms).slideX(begin: -0.1),
            const Spacer(),
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.slate.withValues(alpha: 0.1),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: GestureDetector(
                onTap: () => setState(() => _currentIndex = 3),
                child: CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.lightSlate,
                  backgroundImage:
                      (photoUrl != null && photoUrl.startsWith('http'))
                      ? CachedNetworkImageProvider(photoUrl)
                      : null,
                  child: (photoUrl == null || !photoUrl.startsWith('http'))
                      ? const Icon(
                          Icons.person,
                          color: AppColors.slate,
                          size: 30,
                        )
                      : null,
                ),
              ),
            ).animate().scale(delay: 200.ms),
          ],
        );
      },
    );
  }

  String _getGreeting(AppLocalizations l10n) {
    final hour = DateTime.now().hour;
    if (hour < 12) return l10n.isAr ? "صباح الخير" : "Good Morning";
    if (hour < 17) return l10n.isAr ? "مساء الخير" : "Good Afternoon";
    return l10n.isAr ? "مساء الخير" : "Good Evening";
  }

  Widget _buildQuickActionsGrid() {
    final l10n = AppLocalizations.of(context)!;
    final List<Map<String, dynamic>> actions = [
      {
        "title": l10n.isAr ? "إنشاء مجموعة" : "Create Group",
        "icon": Icons.add_circle_outline_rounded,
        "color": const Color(0xFF6366F1), // Indigo
        "onTap": () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateGroupPage()),
          );
        },
      },
      {
        "title": l10n.isAr ? "الانضمام لمجموعة" : "Join Group",
        "icon": Icons.qr_code_scanner_rounded,
        "color": AppColors.teal,
        "onTap": () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const JoinGroupPage()),
          );
        },
      },
      {
        "title": l10n.isAr ? "سجل الخرجات" : "Outings History",
        "icon": Icons.history_rounded,
        "color": const Color(0xFFF59E0B),
        "onTap": () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const GlobalOutingsHistoryPage()),
          );
        },
      },
      {
        "title": l10n.isAr ? "البحث العام" : "Global Search",
        "icon": Icons.search_rounded,
        "color": const Color(0xFFEC4899),
        "onTap": () {},
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.4,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return GestureDetector(
          onTap: action['onTap'],
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.slate.withValues(alpha: 0.1),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (action['color'] as Color).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    action['icon'] as IconData,
                    color: action['color'] as Color,
                    size: 22,
                  ),
                ),
                Text(
                  action['title'] as String,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ).animate().fadeIn(delay: (300 + (index * 50)).ms).slideY(begin: 0.1);
      },
    );
  }

  Widget _buildRecentlyActive(User? user) {
    if (user == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('groups')
          .where('memberIds', arrayContains: user.uid)
          .orderBy('lastMessageTime', descending: true)
          .limit(3)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 40),
            alignment: Alignment.center,
            child: Column(
              children: [
                Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 48,
                  color: AppColors.slate.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 12),
                Text(
                  "No recent activity",
                  style: GoogleFonts.inter(color: AppColors.slate),
                ),
              ],
            ),
          );
        }

        final groups = snapshot.data!.docs;
        return Column(
          children: groups.map((doc) {
            final group = GroupModel.fromMap(
              doc.data() as Map<String, dynamic>,
            );
            return RecentGroupCard(group: group);
          }).toList(),
        ).animate().fadeIn(delay: 500.ms);
      },
    );
  }
}
