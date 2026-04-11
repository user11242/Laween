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
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error joining: $e")),
        );
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
          builder: (_) => OutingMapScreen(
            groupId: widget.groupId,
            sessionId: session.id,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<OutingSessionModel?>(
      stream: _outingService.streamSession(
          widget.groupId, widget.message.outingSessionId ?? ''),
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
        final hasJoined = session.participants
            .any((p) => p.uid == FirebaseAuth.instance.currentUser?.uid);

        return _buildCompactBubble(session, isWaiting, isCompleted, hasJoined);
      },
    );
  }

  Widget _buildCompactBubble(OutingSessionModel session, bool isWaiting, bool isCompleted, bool hasJoined) {
    final bool canAccess = !isCompleted || hasJoined;
    
    return GestureDetector(
      onTap: () {
        if (!canAccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Session closed. Only participants can view details.")),
          );
          return;
        }
        _joinAndShowRoom(context, session, hasJoined);
      },
      child: Container(
        width: 260,
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFE6E6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.location_on_rounded,
                    size: 24,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Outing Session",
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                if (isWaiting && !_remaining.isNegative) ...[
                  Text(
                    "Live",
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF4CAF50),
                    ),
                  ),
                  Text(
                    "  •  ",
                    style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "${_remaining.inMinutes}:${(_remaining.inSeconds % 60).toString().padLeft(2, '0')} min remaining",
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ] else if (isCompleted) ...[
                   Text(
                    "Destination Locked",
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.teal,
                    ),
                  ),
                ] else ...[
                   Text(
                    "Expired",
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Divider(height: 1, color: Colors.grey.shade200),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
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
                  backgroundColor: AppColors.teal,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: Text(
                  isCompleted ? "Winner" : "Join",
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.9, 0.9));
  }
}
