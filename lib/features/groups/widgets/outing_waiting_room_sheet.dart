// lib/features/groups/widgets/outing_waiting_room_sheet.dart

import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/colors.dart';
import '../data/models/outing_session_model.dart';
import '../data/services/outing_service.dart';
import '../pages/outing_map_screen.dart';

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
  final OutingService _outingService = OutingService();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
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
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
          border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1.5),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: StreamBuilder<OutingSessionModel?>(
          stream: _outingService.streamSession(widget.groupId, widget.sessionId),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data == null) {
              return const SizedBox(
                height: 400,
                child: Center(child: CircularProgressIndicator(color: AppColors.teal)),
              );
            }

            final session = snapshot.data!;
            
            final currentUser = FirebaseAuth.instance.currentUser;
            
            // AUTOMATIC REDIRECTION: Jump to Discovery Room if session starts
            if (session.status == OutingStatus.thinking || session.status == OutingStatus.voting) {
              final isParticipant = session.participants.any((p) => p.uid == currentUser?.uid);
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

            final now = DateTime.now();
            final remaining = session.expiresAt.difference(now);
            final isCreator = session.creatorId == currentUser?.uid;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Container(
                  width: 45,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(height: 32),
                
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.radio_button_checked_rounded, color: Colors.redAccent, size: 20),
                    ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1.seconds),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Outing Waiting Room",
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkSlate,
                          ),
                        ),
                        Text(
                          "Session #${widget.sessionId.substring(0, 4).toUpperCase()}",
                          style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
                
                const SizedBox(height: 40),
                
                // Timer Visualization
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        _formatDuration(remaining),
                        style: GoogleFonts.outfit(
                          fontSize: 54,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkSlate,
                          letterSpacing: -2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.people_alt_rounded, size: 16, color: AppColors.teal),
                          const SizedBox(width: 8),
                          Text(
                            "${session.participants.length} / 8 Friends Joined",
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.teal,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildInteractiveChip(
                      context,
                      "Mode",
                      session.calculationMode,
                      Icons.settings_rounded,
                      ['Time', 'KM'],
                      (val) => _outingService.updateSessionDetails(
                        groupId: widget.groupId,
                        sessionId: widget.sessionId,
                        calculationMode: val,
                      ),
                    ),
                    _buildInteractiveChip(
                      context,
                      "Category",
                      session.category,
                      Icons.restaurant_rounded,
                      ['Restaurant', 'Cafe', 'Park', 'Mall', 'Sporty', 'Cinema'],
                      (val) => _outingService.updateSessionDetails(
                        groupId: widget.groupId,
                        sessionId: widget.sessionId,
                        category: val,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 40),
                
                // Participants List Header
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "PARTICIPANTS",
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade400,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Participant Grid/Row
                SizedBox(
                  height: 90,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: session.participants.length,
                    itemBuilder: (context, index) {
                      final p = session.participants[index];
                      final isMe = p.uid == currentUser?.uid;
                      return Padding(
                        padding: const EdgeInsets.only(right: 20),
                        child: Column(
                          children: [
                            Stack(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isMe ? AppColors.teal : Colors.grey.shade200,
                                      width: 2,
                                    ),
                                  ),
                                  child: CircleAvatar(
                                    radius: 24,
                                    backgroundColor: AppColors.teal.withValues(alpha: 0.1),
                                    child: Text(
                                      p.name[0].toUpperCase(),
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.teal),
                                    ),
                                  ),
                                ),
                                if (isMe)
                                  Positioned(
                                    right: 0,
                                    bottom: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(color: AppColors.teal, shape: BoxShape.circle),
                                      child: const Icon(Icons.person, color: Colors.white, size: 10),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              isMe ? "You" : p.name.split(' ')[0],
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: isMe ? FontWeight.bold : FontWeight.w500,
                                color: AppColors.darkSlate,
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: (index * 100).milliseconds).slideX(begin: 0.2);
                    },
                  ),
                ),
                
                const SizedBox(height: 48),
                
                // Action Buttons Row
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => _outingService.leaveSession(widget.groupId, widget.sessionId, currentUser!.uid),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          foregroundColor: Colors.redAccent,
                        ),
                        child: Text(
                          "Leave Session",
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
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
                                color: AppColors.teal.withValues(alpha: 0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: () => _outingService.updateStatus(widget.groupId, widget.sessionId, OutingStatus.thinking),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                            child: Text(
                              "Start Now",
                              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 20),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildInteractiveChip(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    List<String> options,
    Function(String) onSelected,
  ) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent, // Fully transparent for glass effect
          isScrollControlled: true,
          builder: (context) => BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
                border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1.5),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle
                  Container(
                    width: 45,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  Text(
                    "Select $label",
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkSlate,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Customize your outing experience",
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  Column(
                    children: options.map((opt) {
                      final isSelected = value.toLowerCase() == opt.toLowerCase();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GestureDetector(
                          onTap: () {
                            onSelected(opt);
                            Navigator.pop(context);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            decoration: BoxDecoration(
                              gradient: isSelected 
                                  ? const LinearGradient(colors: AppColors.tealGradient) 
                                  : null,
                              color: isSelected ? null : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: isSelected ? Colors.transparent : Colors.grey.shade200,
                                  width: 1.5,
                              ),
                              boxShadow: isSelected ? [
                                  BoxShadow(
                                    color: AppColors.teal.withValues(alpha: 0.25),
                                    blurRadius: 15,
                                    offset: const Offset(0, 8),
                                  )
                              ] : [],
                            ),
                            child: Center(
                              child: Text(
                                opt,
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
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.teal.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppColors.teal),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(fontSize: 10, color: Colors.grey.shade400, fontWeight: FontWeight.bold),
                ),
                Text(
                  value.toUpperCase(),
                  style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.darkSlate),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
