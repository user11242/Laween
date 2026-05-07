// lib/features/groups/widgets/outing_waiting_room_sheet.dart

import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/outing_session_model.dart';
import '../data/services/outing_service.dart';
import '../pages/outing_map_screen.dart';
import 'package:laween/l10n/app_localizations.dart';

class OutingWaitingRoomSheet extends StatefulWidget {
  final String groupId;
  final String sessionId;

  const OutingWaitingRoomSheet({
    super.key,
    required this.groupId,
    required this.sessionId,
  });

  @override
  State<OutingWaitingRoomSheet> createState() => _OutingWaitingRoomSheetState();
}

class _OutingWaitingRoomSheetState extends State<OutingWaitingRoomSheet> {
  bool get isAr => AppLocalizations.of(context)?.isAr ?? false;
  final OutingService _outingService = OutingService();
  int _totalGroupMembers = 1;
  Timer? _timer;
  String? _errorMessage;
  Timer? _errorTimer;

  void _showError(String msg) {
    if (_errorTimer?.isActive ?? false) _errorTimer?.cancel();
    setState(() => _errorMessage = msg);
    _errorTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _errorMessage = null);
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchGroupMemberCount();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  void _fetchGroupMemberCount() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .get();
      if (doc.exists && mounted) {
        final List memberIds = doc.data()?['memberIds'] ?? [];
        setState(() => _totalGroupMembers = memberIds.length);
      }
    } catch (e) {
      debugPrint("Error fetching member count: $e");
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _errorTimer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    if (d.isNegative) return "00:00:00";
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    return "${twoDigits(d.inHours)}:${twoDigits(d.inMinutes.remainder(60))}:${twoDigits(d.inSeconds.remainder(60))}";
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
          border: Border.all(
            color: Colors.white.withOpacity(0.5),
            width: 1.5,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: StreamBuilder<OutingSessionModel?>(
          stream: _outingService.streamSession(
            widget.groupId,
            widget.sessionId,
          ),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data == null) {
              return const SizedBox(
                height: 400,
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.teal),
                ),
              );
            }

            final session = snapshot.data!;

            final currentUser = FirebaseAuth.instance.currentUser;

            // REDIRECTION: Jump to Discovery Room if session starts
            if (session.status == OutingStatus.thinking ||
                session.status == OutingStatus.voting) {
              final isParticipant = session.participants.any(
                (p) => p.uid == currentUser?.uid,
              );
              if (isParticipant) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (Navigator.canPop(context)) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => OutingMapScreen(
                          groupId: widget.groupId,
                          sessionId: session.id,
                        ),
                      ),
                    );
                  }
                });
              }
              return const SizedBox();
            }

            // REDIRECTION: Close and show message if cancelled
            if (session.status == OutingStatus.cancelled) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && _errorMessage == null) {
                  _showError(AppLocalizations.of(context)?.sessionCancelledNoParticipants ?? "Session cancelled: Not enough participants joined.");
                  // Delay closure so user can read the message
                  Future.delayed(const Duration(seconds: 3), () {
                    if (context.mounted && Navigator.canPop(context)) {
                      Navigator.pop(context);
                    }
                  });
                }
              });
              return const SizedBox();
            }

            final now = DateTime.now();
            final remaining = session.expiresAt.difference(now);
            final isCreator = session.creatorId == currentUser?.uid;

            // AUTO-CANCEL: If time's up and only 1 person joined
            if (remaining.isNegative &&
                session.participants.length < 2 &&
                session.status == OutingStatus.waiting &&
                isCreator) {
              _outingService.updateStatus(
                widget.groupId,
                widget.sessionId,
                OutingStatus.cancelled,
              );
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Container(
                  width: 45,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),

                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header
                Row(
                  children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                          )
                              .animate(onPlay: (c) => c.repeat())
                              .scale(
                                duration: 1.5.seconds,
                                begin: const Offset(1, 1),
                                end: const Offset(2.5, 2.5),
                                curve: Curves.easeOut,
                              )
                              .fadeOut(),
                          Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: Colors.redAccent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)?.outingWaitingRoom ?? "Outing Waiting Room",
                            style: GoogleFonts.outfit(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.darkSlate,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  AppLocalizations.of(context)?.live ?? "LIVE",
                                  style: GoogleFonts.inter(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.redAccent,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "${AppLocalizations.of(context)?.sessionNumber ?? 'Session #'} ${widget.sessionId.substring(0, 4).toUpperCase()}",
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: Colors.grey.shade400,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Timer Visualization (Glassmorphic)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 32,
                      horizontal: 24,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(36),
                      border: Border.all(
                        color: Colors.black.withOpacity(0.05),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 30,
                          offset: const Offset(0, 15),
                        ),
                        BoxShadow(
                          color: AppColors.teal.withOpacity(0.03),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            // Subtle pulse ring
                            Container(
                              width: 160,
                              height: 160,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.teal.withOpacity(0.02),
                              ),
                            )
                                .animate(onPlay: (c) => c.repeat())
                                .scale(
                                  duration: 2.seconds,
                                  begin: const Offset(0.8, 0.8),
                                  end: const Offset(1.2, 1.2),
                                )
                                .fadeOut(),
                            Column(
                              children: [
                                Text(
                                  _formatDuration(remaining),
                                  style: GoogleFonts.outfit(
                                    fontSize: 62,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.darkSlate,
                                    letterSpacing: -3,
                                    shadows: [
                                      Shadow(
                                        color: AppColors.teal.withValues(
                                          alpha: 0.15,
                                        ),
                                        blurRadius: 20,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.teal.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.people_alt_rounded,
                                        size: 14,
                                        color: AppColors.teal,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        "${session.participants.length} / $_totalGroupMembers ${AppLocalizations.of(context)?.membersJoined ?? 'Members Joined'}",
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.teal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  if (session.calculationMode == 'Fixed')
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: AppColors.teal.withOpacity(0.3),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.teal.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.location_on_rounded,
                              color: AppColors.teal,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppLocalizations.of(context)?.targetDestination ?? "TARGET DESTINATION",
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    color: Colors.grey.shade400,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  session.winner?['name'] ?? "Selected Venue",
                                  style: GoogleFonts.outfit(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.darkSlate,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildActionTile(
                          context,
                          AppLocalizations.of(context)?.outingMode ?? "Outing Mode",
                          _getLocalizedValue(session.calculationMode, context),
                          Icons.timer_outlined,
                          ['Time', 'KM'],
                          AppColors.teal,
                          (val) => _outingService.updateSessionDetails(
                            groupId: widget.groupId,
                            sessionId: widget.sessionId,
                            calculationMode: val,
                          ),
                        ),
                        const SizedBox(width: 16),
                        _buildActionTile(
                          context,
                          AppLocalizations.of(context)?.discovering ?? "Discovering",
                          _getLocalizedValue(session.category, context),
                          Icons.explore_outlined,
                          [
                            'Restaurant',
                            'Cafe',
                            'Park',
                            'Mall',
                            'Sporty',
                            'Cinema',
                          ],
                          Colors.orangeAccent,
                          (val) => _outingService.updateSessionDetails(
                            groupId: widget.groupId,
                            sessionId: widget.sessionId,
                            category: val,
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 24),

                  // Participants List Header
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      AppLocalizations.of(context)?.participantsLabel ?? "PARTICIPANTS",
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade400,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Participant Grid/Row
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: session.participants.length,
                      itemBuilder: (context, index) {
                        final p = session.participants[index];
                        final isMe = p.uid == currentUser?.uid;
                        final isHost = p.uid == session.creatorId;
                        final userColor = AppColors.getUserColor(p.uid);
                        
                        return Padding(
                              padding: const EdgeInsets.only(right: 24),
                              child: Column(
                                children: [
                                  Stack(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(3),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: userColor,
                                            width: 2.5,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: userColor.withOpacity(0.15),
                                              blurRadius: 12,
                                              spreadRadius: 2,
                                            ),
                                          ],
                                        ),
                                        child: CircleAvatar(
                                          radius: 28,
                                          backgroundColor:
                                              userColor.withOpacity(0.12),
                                          backgroundImage: p.photoUrl != null &&
                                                  p.photoUrl!.isNotEmpty
                                              ? NetworkImage(p.photoUrl!)
                                              : null,
                                          child: p.photoUrl == null ||
                                                  p.photoUrl!.isEmpty
                                              ? Text(
                                                  p.name.isNotEmpty
                                                      ? p.name[0].toUpperCase()
                                                      : '?',
                                                  style: TextStyle(
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.bold,
                                                    color: userColor,
                                                  ),
                                                )
                                              : null,
                                        ),
                                      ),
                                      if (isMe)
                                        Positioned(
                                          right: -2,
                                          bottom: 2,
                                          child: _buildBadge(
                                            Icons.person,
                                            AppColors.teal,
                                          ),
                                        ),
                                      if (isHost)
                                        Positioned(
                                          left: -2,
                                          top: -2,
                                          child: _buildBadge(
                                            Icons.workspace_premium_rounded,
                                            Colors.orangeAccent,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    isMe
                                        ? (AppLocalizations.of(context)?.youLabel ?? "You")
                                        : (p.name.isNotEmpty
                                            ? p.name.split(' ')[0]
                                            : 'User'),
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: isMe
                                          ? FontWeight.bold
                                          : FontWeight.w600,
                                      color: AppColors.darkSlate,
                                    ),
                                  ),
                                ],
                              ),
                            )
                            .animate()
                            .fadeIn(delay: (index * 150).ms)
                            .scale(begin: const Offset(0.8, 0.8));
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          // BOTTOM ALERT (Local)
          if (_errorMessage != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.redAccent.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => setState(() => _errorMessage = null),
                            child: const Icon(
                              Icons.close_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                    )
                        .animate()
                        .slideY(begin: 0.2, end: 0, curve: Curves.easeOutBack)
                        .fadeIn()
                        .shimmer(delay: 400.ms, duration: 1.seconds),

                  // Action Buttons Row
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => _outingService.leaveSession(
                            widget.groupId,
                            widget.sessionId,
                            currentUser!.uid,
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            foregroundColor: Colors.redAccent,
                          ),
                          child: Text(
                            AppLocalizations.of(context)?.leaveSession ?? "Leave Session",
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      if (isCreator) ...[
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: AppColors.tealGradient,
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.teal.withOpacity(0.3),
                                  blurRadius: 15,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: () {
                                if (session.participants.length < 2) {
                                  _showError(AppLocalizations.of(context)?.needAtLeast2People ?? "You need at least 2 people to start an outing!");
                                  return;
                                }
                                _outingService.updateStatus(
                                  widget.groupId,
                                  widget.sessionId,
                                  OutingStatus.thinking,
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(vertical: 20),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    AppLocalizations.of(context)?.startJourneyNow ?? "Start Journey Now",
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: Colors.white,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  const Icon(
                                    Icons.arrow_forward_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              );
            },
          ),
        ),
      );
  }

  Widget _buildBadge(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: 10,
      ),
    );
  }

  


  Widget _buildActionTile(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    List<String> options,
    Color accentColor,
    Function(String) onSelected,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            isScrollControlled: true,
            builder: (context) => BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(40),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 45,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      isAr ? "اختر $label" : "Select $label",
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkSlate,
                      ),
                    ),
                    const SizedBox(height: 32),
                    ...options.map((opt) {
                      final isSelected = value.toLowerCase() == opt.toLowerCase();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GestureDetector(
                          onTap: () {
                            onSelected(opt);
                            Navigator.pop(context);
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            decoration: BoxDecoration(
                              color: isSelected ? accentColor : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected ? Colors.transparent : Colors.grey.shade200,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                _getLocalizedValue(opt, context),
                                style: GoogleFonts.outfit(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? Colors.white : AppColors.darkSlate,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.black.withOpacity(0.05)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 18, color: accentColor),
              ),
              const SizedBox(height: 16),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: Colors.grey.shade400,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value.toUpperCase(),
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkSlate,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getLocalizedValue(String value, BuildContext context) {
    final l10n = AppLocalizations.of(context);
    switch (value) {
      case 'Time':
        return l10n?.timeLabel ?? value;
      case 'KM':
        return l10n?.kmLabel ?? value;
      case 'Restaurant':
        return l10n?.restaurant ?? value;
      case 'Cafe':
        return l10n?.cafe ?? value;
      case 'Park':
        return l10n?.park ?? value;
      case 'Mall':
        return l10n?.mall ?? value;
      case 'Sporty':
        return l10n?.sporty ?? value;
      case 'Cinema':
        return l10n?.cinema ?? value;
      default:
        return value;
    }
  }
}
