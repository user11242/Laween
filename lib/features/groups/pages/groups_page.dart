import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../widgets/create_join_dialog.dart';
import '../data/models/group_model.dart';
import './chat_page.dart';

class GroupsPage extends StatefulWidget {
  const GroupsPage({super.key});

  @override
  State<GroupsPage> createState() => _GroupsPageState();
}

class _GroupsPageState extends State<GroupsPage> {
  bool _showMenu = false;
  final currentUser = FirebaseAuth.instance.currentUser;

  void _toggleMenu() {
    setState(() {
      _showMenu = !_showMenu;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Stack(
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('groups')
                .where('memberIds', arrayContains: currentUser?.uid)
                // .orderBy('createdAt', descending: true) // Requires composite index!
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return CustomScrollView(
                  slivers: [
                    const SliverAppBar(pinned: true, backgroundColor: AppColors.teal, title: Text("Error")),
                    SliverFillRemaining(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Center(
                          child: Text(
                            "Firestore Error: ${snapshot.error}\n\nPlease check your debug console for the index creation link.",
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }

              final groups = snapshot.hasData
                  ? snapshot.data!.docs
                      .map((doc) => GroupModel.fromMap(doc.data() as Map<String, dynamic>))
                      .toList()
                  : <GroupModel>[];

              return CustomScrollView(
                slivers: [
                  // Modern SliverAppBar with Gradient
                  SliverAppBar(
                    expandedHeight: 120.0,
                    floating: false,
                    pinned: true,
                    backgroundColor: AppColors.teal,
                    elevation: 0,
                    flexibleSpace: FlexibleSpaceBar(
                      centerTitle: false,
                      titlePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      title: Text(
                        l10n.groups,
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      background: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: AppColors.tealGradient,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              right: -50,
                              top: -50,
                              child: Container(
                                width: 200,
                                height: 200,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Search Bar Section
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: l10n.search,
                            hintStyle: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 14),
                            prefixIcon: const Icon(Icons.search, color: AppColors.teal, size: 22),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                          ),
                        ),
                      ),
                    ),
                  ),

                  if (snapshot.connectionState == ConnectionState.waiting)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: CircularProgressIndicator(color: AppColors.teal)),
                    )
                  else if (groups.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _buildEmptyState(l10n),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            if (index.isOdd) {
                              return Padding(
                                padding: const EdgeInsets.only(left: 88, right: 24),
                                child: Divider(height: 1, color: Colors.grey.shade100),
                              );
                            }
                            final groupIndex = index ~/ 2;
                            return _GroupCard(group: groups[groupIndex]);
                          },
                          childCount: groups.length * 2 - 1,
                        ),
                      ),
                    ),

                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              );
            },
          ),
          
          // Floating Action Menu Overlay Dimming
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _showMenu
                ? GestureDetector(
                    key: const ValueKey('overlay_dim'),
                    onTap: _toggleMenu,
                    child: Container(color: Colors.black45),
                  )
                : const SizedBox.shrink(key: ValueKey('overlay_empty')),
          ),
          
          // The Dialog that pops up
          Positioned(
            bottom: 110,
            left: 24,
            right: 24,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutBack,
                        reverseCurve: Curves.easeInQuint,
                      ),
                    ),
                    alignment: Alignment.bottomRight, // Originates towards the FAB
                    child: child,
                  ),
                );
              },
              child: _showMenu
                  ? Hero(
                      key: const ValueKey('dialog_card'),
                      tag: 'group_menu',
                      child: Material(
                        color: Colors.transparent,
                        child: CreateJoinDialog(
                          onClose: _toggleMenu,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(key: ValueKey('dialog_empty')),
            ),
          ),
        ],
      ),
      floatingActionButton: AnimatedScale(
        scale: _showMenu ? 1.05 : 1.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutBack,
        child: FloatingActionButton(
          onPressed: _toggleMenu,
          backgroundColor: _showMenu ? AppColors.darkSlate : AppColors.teal,
          elevation: _showMenu ? 8 : 4,
          child: AnimatedRotation(
            duration: const Duration(milliseconds: 400),
            curve: Curves.elasticOut,
            turns: _showMenu ? 0.375 : 0, // spins 135 degrees into an 'x'
            child: const Icon(Icons.add, color: Colors.white, size: 32),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppColors.teal.withValues(alpha: 0.05),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.groups_outlined,
            size: 80,
            color: AppColors.teal,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          l10n.isAr ? "لا توجد مجموعات بعد" : "No groups joined yet",
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.darkSlate,
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48),
          child: Text(
            l10n.isAr 
                ? "ابدأ بإنشاء مجموعة جديدة أو انضم إلى المجموعات المتاحة" 
                : "Start by creating a new group or join existing ones",
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ),
      ],
    );
  }
}

class _GroupCard extends StatelessWidget {
  final GroupModel group;

  const _GroupCard({required this.group});

  String _formatTime(DateTime? time) {
    if (time == null) return "";
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inDays == 0) return DateFormat('hh:mm a').format(time);
    if (diff.inDays == 1) return "Yesterday";
    return DateFormat('dd/MM/yy').format(time);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isAr = l10n.isAr;
    final currentUser = FirebaseAuth.instance.currentUser;
    final unreadCount = group.unreadCounts[currentUser?.uid] ?? 0;

    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ChatPage(group: group)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            children: [
              // Premium Avatar
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.teal.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: group.photoUrl != null
                      ? CachedNetworkImage(
                          imageUrl: group.photoUrl!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Colors.grey.shade100,
                            child: const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.teal),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => 
                            const Icon(Icons.groups, color: AppColors.teal, size: 28),
                        )
                      : const Icon(Icons.groups, color: AppColors.teal, size: 28),
                ),
              ),
              const SizedBox(width: 16),
              
              // Group Info
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
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.darkSlate,
                            ),
                          ),
                        ),
                        if (group.lastMessageTime != null)
                          Text(
                            _formatTime(group.lastMessageTime),
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: unreadCount > 0 ? AppColors.teal : Colors.grey.shade500,
                              fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: RichText(
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            text: TextSpan(
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                              children: [
                                if (group.lastMessageSender != null)
                                  TextSpan(
                                    text: "${group.lastMessageSender == currentUser?.displayName || group.lastMessageSender == currentUser?.uid ? (isAr ? "أنت" : "You") : group.lastMessageSender}: ",
                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                TextSpan(
                                  text: group.lastMessage ?? (isAr ? "انضم للمحادثة..." : "Start chatting..."),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (unreadCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                            decoration: const BoxDecoration(
                              color: AppColors.teal,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              "$unreadCount",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
