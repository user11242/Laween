// lib/features/groups/widgets/outing_message_bubble.dart

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/colors.dart';
import '../../../core/services/location_service.dart';
import '../data/models/message_model.dart';
import '../data/models/outing_session_model.dart';
import '../data/services/outing_service.dart';
import 'outing_waiting_room_sheet.dart';
import 'outing_thinking_view.dart';
import 'outing_voting_view.dart';
import 'outing_winner_view.dart';
import '../pages/outing_map_screen.dart';
import '../pages/location_picker_screen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';

class OutingMessageBubble extends StatefulWidget {
  final MessageModel message;
  final String groupId;
  final bool isMe;

  const OutingMessageBubble({
    super.key,
    required this.message,
    required this.groupId,
    required this.isMe,
  });

  @override
  State<OutingMessageBubble> createState() => _OutingMessageBubbleState();
}

class _OutingMessageBubbleState extends State<OutingMessageBubble>
    with TickerProviderStateMixin {
  final OutingService _outingService = OutingService();
  final LocationService _locationService = LocationService();

  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late AnimationController _glowController;
  Timer? _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    _glowController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    if (d.isNegative) return "00:00:00";
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    return "${twoDigits(d.inHours)}:${twoDigits(d.inMinutes.remainder(60))}:${twoDigits(d.inSeconds.remainder(60))}";
  }

  IconData _categoryIcon(String cat) {
    switch (cat.toLowerCase()) {
      case 'restaurant':
        return Icons.restaurant_rounded;
      case 'cafe':
        return Icons.local_cafe_rounded;
      case 'park':
        return Icons.park_rounded;
      default:
        return Icons.place_rounded;
    }
  }

  void _joinAndShowRoom(BuildContext context, OutingSessionModel session,
      bool hasJoined) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (!hasJoined) {
      try {
        final LatLng? pickedLocation = await Navigator.push<LatLng>(
          context,
          MaterialPageRoute(builder: (_) => const LocationPickerScreen()),
        );

        if (pickedLocation == null) return; // User cancelled

        await _outingService.joinSession(
          groupId: widget.groupId,
          sessionId: session.id,
          uid: user.uid,
          name: user.displayName ?? "User",
          photoUrl: user.photoURL,
          location: GeoPoint(pickedLocation.latitude, pickedLocation.longitude),
        );
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error joining: $e")),
          );
        }
        return;
      }
    }

    if (mounted) {
      if (session.status == OutingStatus.waiting) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => OutingWaitingRoomSheet(
            groupId: widget.groupId,
            sessionId: session.id,
          ),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OutingMapScreen(
              groupId: widget.groupId,
              sessionId: session.id,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<OutingSessionModel?>(
      stream: _outingService.streamSession(
          widget.groupId, widget.message.outingSessionId ?? ''),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return _buildLoadingSkeleton();
        }

        final session = snapshot.data!;
        _remaining = session.expiresAt.difference(DateTime.now());
        final isExpired =
            _remaining.isNegative || session.status != OutingStatus.waiting;
        final hasJoined = session.participants
            .any((p) => p.uid == FirebaseAuth.instance.currentUser?.uid);

        // Special states go full-bleed into their own views
        if (session.status == OutingStatus.thinking) {
          return _wrapCard(OutingThinkingView(
              category: session.category, isMe: widget.isMe));
        }
        if (session.status == OutingStatus.voting) {
          return _wrapCard(OutingVotingView(
              groupId: widget.groupId, session: session, isMe: widget.isMe));
        }
        if (session.status == OutingStatus.completed) {
          return _wrapCard(
              OutingWinnerView(session: session, isMe: widget.isMe));
        }

        return _buildPremiumCard(session, isExpired, hasJoined);
      },
    );
  }

  Widget _buildLoadingSkeleton() {
    return Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [
            const Color(0xFF0D2137),
            const Color(0xFF0A3040),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          color: AppColors.teal,
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _wrapCard(Widget child) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF0D2137), Color(0xFF0A3040)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.teal.withValues(alpha: 0.25),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: child,
      ),
    );
  }

  Widget _buildPremiumCard(
      OutingSessionModel session, bool isExpired, bool hasJoined) {
    return AnimatedBuilder(
      animation: Listenable.merge([_glowController, _rotateController]),
      builder: (context, _) {
        final glowOpacity = 0.15 + _glowController.value * 0.12;

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              colors: [Color(0xFF0D2137), Color(0xFF0A3040)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: AppColors.teal.withValues(alpha: 0.35),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.teal.withValues(alpha: glowOpacity),
                blurRadius: 30,
                spreadRadius: 2,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26.5),
            child: Stack(
              children: [
                // === AURORA GLOW BACKDROP ===
                Positioned(
                  top: -40,
                  left: -40,
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.teal.withValues(alpha: 0.22),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -30,
                  right: -30,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF00F5C4).withValues(alpha: 0.12),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                // === ROTATING GRID WATERMARK ===
                Positioned(
                  right: -20,
                  top: 20,
                  child: Transform.rotate(
                    angle: _rotateController.value * 2 * math.pi,
                    child: Icon(
                      Icons.my_location_rounded,
                      size: 90,
                      color: Colors.white.withValues(alpha: 0.04),
                    ),
                  ),
                ),

                // === TOP LIVE OUTING STRIP ===
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.teal.withValues(alpha: 0.30),
                          Colors.transparent,
                        ],
                        stops: const [0, 1],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            // Pulsing dot
                            ScaleTransition(
                              scale: Tween(begin: 0.7, end: 1.3).animate(
                                CurvedAnimation(
                                    parent: _pulseController,
                                    curve: Curves.easeInOut),
                              ),
                              child: Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4DFFD2),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF4DFFD2)
                                          .withValues(alpha: 0.7),
                                      blurRadius: 6,
                                      spreadRadius: 2,
                                    )
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "LIVE  •  OUTING",
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF4DFFD2),
                                letterSpacing: 2.5,
                              ),
                            ),
                          ],
                        ),
                        // Countdown
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.teal.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            _formatDuration(_remaining),
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // === MAIN CONTENT ===
                GestureDetector(
                  onTap: () => _joinAndShowRoom(context, session, hasJoined),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Big glowing pin + title row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Glowing icon
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF00C9A7),
                                    Color(0xFF0097A7),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.teal.withValues(alpha: 0.5),
                                    blurRadius: 18,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Icon(
                                _categoryIcon(session.category),
                                size: 26,
                                color: Colors.white,
                              ),
                            ).animate().scale(curve: Curves.elasticOut, duration: 600.ms),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Find Your\nMiddle Ground",
                                    style: GoogleFonts.outfit(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      height: 1.15,
                                    ),
                                  ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.1),
                                const SizedBox(height: 6),
                                // Category pill
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.teal
                                        .withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: AppColors.teal
                                          .withValues(alpha: 0.4),
                                    ),
                                  ),
                                  child: Text(
                                    session.category,
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF4DFFD2),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ).animate().fadeIn(delay: 200.ms),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Divider
                      Container(
                        height: 1,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.teal.withValues(alpha: 0.5),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Participants + Count
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              SizedBox(
                                height: 34,
                                width: session.participants.isEmpty
                                    ? 34
                                    : (math.min(session.participants.length, 5) *
                                            20.0 + 14),
                                child: Stack(
                                  children: session.participants.isEmpty
                                      ? [
                                          _buildEmptyAvatar(),
                                        ]
                                      : List.generate(
                                          math.min(
                                              session.participants.length, 5),
                                          (i) => Positioned(
                                            left: i * 20.0,
                                            child: _buildAvatar(
                                                session.participants[i].name,
                                                i),
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                session.participants.isEmpty
                                    ? "No one yet"
                                    : "${session.participants.length} friend${session.participants.length == 1 ? '' : 's'} joined",
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                          if (!isExpired)
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 14,
                              color: AppColors.teal.withValues(alpha: 0.7),
                            ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // === CTA BUTTON ===
                      _buildActionButton(session, isExpired, hasJoined),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyAvatar() {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.06),
        border: Border.all(color: AppColors.teal.withValues(alpha: 0.3)),
      ),
      child: const Icon(Icons.person_outline_rounded,
          size: 16, color: Colors.white38),
    );
  }

  Widget _buildAvatar(String name, int index) {
    final colors = [
      const Color(0xFF00C9A7),
      const Color(0xFF0097A7),
      const Color(0xFF00B4CC),
      const Color(0xFF009688),
      const Color(0xFF26A69A),
    ];
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colors[index % colors.length],
        border: Border.all(color: const Color(0xFF0A3040), width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.teal.withValues(alpha: 0.3),
            blurRadius: 6,
          ),
        ],
      ),
      child: Center(
        child: Text(
          name[0].toUpperCase(),
          style: const TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  Widget _buildActionButton(
      OutingSessionModel session, bool isExpired, bool hasJoined) {
    final label = isExpired
        ? "SESSION ENDED"
        : (hasJoined ? "✦  MANAGE SESSION" : "✦  JOIN SESSION");

    if (isExpired) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white.withValues(alpha: 0.06),
          border: Border.all(color: Colors.white12),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              letterSpacing: 1.5,
              color: Colors.white38,
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () => _joinAndShowRoom(context, session, hasJoined),
      child: AnimatedBuilder(
        animation: _glowController,
        builder: (context, _) {
          return Container(
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                colors: [Color(0xFF00C9A7), Color(0xFF0097A7)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.teal.withValues(
                      alpha: 0.35 + _glowController.value * 0.2),
                  blurRadius: 20,
                  spreadRadius: 1,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Center(
              child: Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          );
        },
      ),
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.3);
  }
}
