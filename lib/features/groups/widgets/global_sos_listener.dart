import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:laween/features/groups/widgets/sos_alarm_overlay.dart';
import 'package:laween/features/groups/data/models/outing_session_model.dart';
import 'package:laween/features/groups/pages/chat_page.dart';
import 'package:laween/features/groups/data/models/group_model.dart';
import 'package:laween/main.dart';

class GlobalSosListener extends StatefulWidget {
  final Widget child;

  const GlobalSosListener({super.key, required this.child});

  @override
  State<GlobalSosListener> createState() => _GlobalSosListenerState();
}

class _GlobalSosListenerState extends State<GlobalSosListener> {
  final Set<String> _dismissedSosUids = {};
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (mounted) {
        setState(() => _currentUserId = user?.uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null) return widget.child;

    return Stack(
      children: [
        widget.child,
        StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(_currentUserId)
              .snapshots(),
          builder: (context, userSnapshot) {
            // Even if loading, we want to keep the child visible
            if (!userSnapshot.hasData) return const SizedBox();

            final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
            final groupId = userData?['activeGroupId'] as String?;
            final sessionId = userData?['activeSessionId'] as String?;

            if (groupId == null || sessionId == null || groupId.isEmpty || sessionId.isEmpty) {
              return const SizedBox();
            }

            return StreamBuilder<DocumentSnapshot>(
              key: ValueKey('$groupId-$sessionId'), // 🔥 FORCE REBUILD WHEN EXACT SESSION CHANGES
              stream: FirebaseFirestore.instance
                  .collection('groups')
                  .doc(groupId)
                  .collection('outings')
                  .doc(sessionId)
                  .snapshots(),
              builder: (context, sessionSnapshot) {
                if (!sessionSnapshot.hasData || !sessionSnapshot.data!.exists) {
                  return const SizedBox();
                }

                final session = OutingSessionModel.fromFirestore(sessionSnapshot.data! as DocumentSnapshot<Map<String, dynamic>>);
                
                // 🧹 CLEAN UP MEMORY: If someone cancelled their SOS, forget that we dismissed it
                for (var p in session.participants) {
                  if (p.isSosActive == false && _dismissedSosUids.contains(p.uid)) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        setState(() {
                          _dismissedSosUids.remove(p.uid);
                        });
                      }
                    });
                  }
                }

                // Find first active SOS that isn't me and hasn't been dismissed
                final activeSosUser = session.participants.where((p) => 
                  p.uid != _currentUserId && 
                  p.isSosActive == true && 
                  !_dismissedSosUids.contains(p.uid)
                ).firstOrNull;

                if (activeSosUser == null) {
                  return const SizedBox();
                }

                return SosAlarmOverlay(
                  userName: activeSosUser.name,
                  onStopAlarm: () {
                    setState(() {
                      _dismissedSosUids.add(activeSosUser.uid);
                    });
                  },
                  onSeeMap: () async {
                    setState(() {
                      _dismissedSosUids.add(activeSosUser.uid);
                    });
                    
                    try {
                      final groupDoc = await FirebaseFirestore.instance
                          .collection('groups')
                          .doc(groupId)
                          .get();
                      
                      if (groupDoc.exists && mounted) {
                        final data = groupDoc.data()!;
                        data['id'] = groupDoc.id;
                        final group = GroupModel.fromMap(data);
                        
                        navigatorKey.currentState?.push(
                          MaterialPageRoute(builder: (context) => ChatPage(group: group)),
                        );
                      }
                    } catch (e) {
                      debugPrint("Error navigating to SOS: $e");
                    }
                  },
                );
              },
            );
          },
        ),
      ],
    );
  }
}
