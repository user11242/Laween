// lib/features/groups/widgets/outing_message_bubble.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/colors.dart';
import '../data/models/message_model.dart';
import '../data/models/outing_session_model.dart';
import '../data/services/outing_service.dart';
import 'outing_waiting_room_sheet.dart';
import '../pages/outing_map_screen.dart';
import '../pages/location_picker_screen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../pages/outing_memory_upload_screen.dart';
import '../pages/history_detail_page.dart';
import 'package:laween/l10n/app_localizations.dart';

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
  String? _cachedUserName;

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
    _fetchUserInfo();
  }

  void _fetchUserInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            _cachedUserName =
                data['name'] ?? data['fullName'] ?? user.displayName;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching user info in bubble: $e");
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    _glowController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _joinAndShowRoom(
    BuildContext context,
    OutingSessionModel session,
    bool hasJoined,
  ) async {
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
          name: _cachedUserName ?? user.displayName ?? "Me",
          photoUrl: user.photoURL,
          location: GeoPoint(pickedLocation.latitude, pickedLocation.longitude),
        );
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error joining: $e")));
        return;
      }
    }

    if (!context.mounted) return;

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
    } else if (session.status == OutingStatus.completed) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              OutingMapScreen(groupId: widget.groupId, sessionId: session.id),
        ),
      );
    } else if (session.status == OutingStatus.finished) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              OutingMemoryUploadScreen(session: session),
        ),
      );
    } else if (session.status == OutingStatus.archived) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              HistoryDetailPage(session: session),
        ),
      );
    }
  }

  bool _isProcessingTimeout = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<OutingSessionModel?>(
      stream: _outingService.streamSession(
        widget.groupId,
        widget.message.outingSessionId ?? '',
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return const SizedBox(
            height: 60,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }

        final session = snapshot.data!;
        _remaining = session.expiresAt.difference(DateTime.now());
        final isWaiting = session.status == OutingStatus.waiting;
        final isCompleted = session.status == OutingStatus.completed;
        final hasJoined = session.participants.any(
          (p) => p.uid == FirebaseAuth.instance.currentUser?.uid,
        );

        // ROOT AUTO-START: If the timer hits zero while the user is staring at the chat page
        final isCreator = session.creatorId == FirebaseAuth.instance.currentUser?.uid;
        if (_remaining.isNegative && isWaiting && isCreator && !_isProcessingTimeout) {
           _isProcessingTimeout = true;
           WidgetsBinding.instance.addPostFrameCallback((_) {
              if (session.participants.length >= 2) {
                 _outingService.updateStatus(widget.groupId, session.id, OutingStatus.thinking).then((_) {
                   if (mounted) setState(() => _isProcessingTimeout = false);
                 });
              } else {
                 _outingService.updateStatus(widget.groupId, session.id, OutingStatus.cancelled).then((_) {
                   if (mounted) setState(() => _isProcessingTimeout = false);
                 });
              }
           });
        }

        return _buildCompactBubble(session, isWaiting, isCompleted, hasJoined);
      },
    );
  }

  Widget _buildCompactBubble(
    OutingSessionModel session,
    bool isWaiting,
    bool isCompleted,
    bool hasJoined,
  ) {
    final bool isAr = AppLocalizations.of(context)?.isAr ?? false;
    final bool canAccess = !isCompleted || hasJoined;
    final bool isCelebration = session.firstArrivedUid != null;
    final bool isExpired = _remaining.isNegative && session.status != OutingStatus.archived && session.status != OutingStatus.finished;
    
    // Define UI properties based on status
    Color statusColor;
    IconData statusIcon;
    String statusTitle;
    Widget? statusAnimation;
    
    switch (session.status) {
      case OutingStatus.waiting:
        statusColor = const Color(0xFF4CAF50); // Green
        statusIcon = Icons.group_add_rounded;
        statusTitle = AppLocalizations.of(context)!.liveLabel;
        statusAnimation = LiquidFillIcon(icon: Icons.group_rounded, color: statusColor, size: 14);
        break;
      case OutingStatus.thinking:
        statusColor = const Color(0xFF9C27B0); // Purple
        statusIcon = Icons.psychology_rounded;
        statusTitle = isAr ? "جاري التفكير..." : "Thinking...";
        statusAnimation = LiquidFillIcon(icon: Icons.psychology_rounded, color: statusColor, size: 14);
        break;
      case OutingStatus.voting:
        statusColor = const Color(0xFFFF9800); // Orange
        statusIcon = Icons.how_to_vote_rounded;
        statusTitle = isAr ? "جاري التصويت" : "Voting Phase";
        statusAnimation = LiquidFillIcon(icon: Icons.how_to_vote_rounded, color: statusColor, size: 14);
        break;
      case OutingStatus.completed:
        statusColor = AppColors.teal;
        statusIcon = Icons.stars_rounded;
        statusTitle = AppLocalizations.of(context)!.destinationLocked;
        statusAnimation = const Icon(Icons.auto_awesome, size: 14, color: AppColors.teal)
            .animate(onPlay: (c) => c.repeat()).shimmer(duration: 2.seconds).scale(begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2), duration: 1.seconds);
        break;
      case OutingStatus.finished:
        statusColor = const Color(0xFFE91E63); // Pink
        statusIcon = Icons.camera_enhance_rounded;
        statusTitle = AppLocalizations.of(context)!.collectingMemories;
        break;
      case OutingStatus.archived:
        statusColor = Colors.blueGrey;
        statusIcon = Icons.history_edu_rounded;
        statusTitle = AppLocalizations.of(context)!.savedInHistory;
        break;
      case OutingStatus.cancelled:
        statusColor = Colors.red;
        statusIcon = Icons.cancel_rounded;
        statusTitle = isAr ? "ملغاة" : "Cancelled";
        break;
    }

    if (isExpired) {
       statusColor = Colors.grey;
       statusIcon = Icons.timer_off_rounded;
       statusTitle = AppLocalizations.of(context)!.expired;
       statusAnimation = null;
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Pulsing Golden Glow for Celebration
        if (isCelebration)
          Positioned.fill(
            child:
                Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFD700).withOpacity(0.3),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                    )
                    .animate(onPlay: (controller) => controller.repeat(reverse: true))
                    .scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05), duration: 1500.ms)
                    .fadeIn(duration: 1500.ms),
          ),

        GestureDetector(
          onTap: () {
            if (!canAccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(AppLocalizations.of(context)!.onlyParticipantsDetails)),
              );
              return;
            }
            _joinAndShowRoom(context, session, hasJoined);
          },
          child: Container(
            width: 270,
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.getSurfaceElevated(context),
              borderRadius: BorderRadius.circular(32),
              border: isCelebration
                  ? Border.all(color: const Color(0xFFFFD700), width: 2)
                  : Border.all(color: AppColors.getBorder(context).withOpacity(0.5)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.getShadow(context).withValues(alpha: 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header Area
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(statusIcon, size: 22, color: statusColor),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.outingSession,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.getTextSecondary(context),
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                statusTitle,
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: statusColor,
                                  letterSpacing: -0.4,
                                ),
                              ),
                              const SizedBox(width: 6),
                              if (statusAnimation != null) statusAnimation,
                              if (session.status == OutingStatus.waiting || 
                                  session.status == OutingStatus.thinking || 
                                  session.status == OutingStatus.voting) ...[
                                const SizedBox(width: 4),
                                Text(
                                  "${session.participants.length}",
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: statusColor.withOpacity(0.8),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 18),
                
                // Status Info Row
                if (!isExpired && session.status == OutingStatus.waiting) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.getSurface(context),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.getBorder(context).withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.timer_outlined, size: 14, color: AppColors.getTextSecondary(context)),
                        const SizedBox(width: 6),
                        Text(
                          AppLocalizations.of(context)!.minRemaining(_remaining.inMinutes),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.getTextSecondary(context),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                Divider(height: 1, color: AppColors.getBorder(context).withOpacity(0.5)),
                const SizedBox(height: 18),
                
                // Action Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      if (!canAccess) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Only participants can view details.")),
                        );
                        return;
                      }
                      _joinAndShowRoom(context, session, hasJoined);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: statusColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shadowColor: statusColor.withOpacity(0.4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: Text(
                      isCelebration
                          ? AppLocalizations.of(context)!.celebrateLabel
                          : (isCompleted
                              ? AppLocalizations.of(context)!.winnerLabel
                              : (session.status == OutingStatus.finished
                                  ? AppLocalizations.of(context)!.memoriesLabel
                                  : (session.status == OutingStatus.archived
                                      ? AppLocalizations.of(context)!.recapLabel
                                          : (session.status == OutingStatus.voting
                                              ? (isAr ? "صوّت الآن" : "Vote Now")
                                              : (hasJoined 
                                                  ? (isAr ? "انضممت" : "Joined")
                                                  : AppLocalizations.of(context)!.joinLabel))))),
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ).animate(onPlay: (c) => isCelebration ? c.repeat() : c.stop()).shimmer(duration: 1500.ms, color: Colors.white.withOpacity(0.3)),
                ),
              ],
            ),
          ),
        ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.95, 0.95)),

        // Winner Crown Badge
        if (isCelebration)
          Positioned(
            top: -5,
            right: -5,
            child:
                Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD700),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Text("👑", style: TextStyle(fontSize: 18)),
                    )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scale(
                      begin: const Offset(0.9, 0.9),
                      end: const Offset(1.2, 1.2),
                      duration: 800.ms,
                    ),
          ),
      ],
    );
  }
}

class LiquidFillIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;

  const LiquidFillIcon({
    super.key,
    required this.icon,
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Animate(
      onPlay: (c) => c.repeat(),
      effects: [
        CustomEffect(
          duration: 2.seconds,
          builder: (context, value, child) {
            return ShaderMask(
              shaderCallback: (rect) {
                return LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  stops: [value, value],
                  colors: [color, color.withOpacity(0.15)],
                ).createShader(rect);
              },
              child: Icon(icon, size: size, color: Colors.white),
            );
          },
        ),
      ],
    );
  }
}
