import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:ui';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as intl;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../../core/theme/colors.dart';
import '../data/models/group_model.dart';
import '../data/models/message_model.dart';
import '../data/models/outing_session_model.dart';
import '../../auth/data/services/fcm_service.dart';
import '../data/services/chat_service.dart';
import '../widgets/group_share_sheet.dart';
import '../widgets/outing_message_bubble.dart';
import '../widgets/create_outing_sheet.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'group_settings_page.dart';
import '../widgets/voice_message_bubble.dart';
import '../data/services/outing_service.dart';
import 'outing_memory_upload_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import '../providers/wallpaper_provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'location_picker_page.dart';
import 'package:laween/l10n/app_localizations.dart';

class ChatPage extends StatefulWidget {
  final GroupModel group;

  const ChatPage({super.key, required this.group});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatService _chatService = ChatService();
  final LayerLink _attachmentMenuLink = LayerLink();

  // Recording
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  DateTime? _recordStartTime;
  bool _isCanceling = false;
  bool _isLocked = false;
  Timer? _amplitudeTimer;
  List<double> _amplitudes = List.generate(12, (_) => 0.0);
  String _elapsedTime = "00:00";
  Offset? _recordingStartPos;
  static const _soundChannel = MethodChannel('com.laween.app/system_sound');
  bool _isStartingRecorder = false;
  bool _shouldStopImmediately = false;
  final Map<String, String> _memberPhotos = {};
  final Map<String, String> _memberNames = {};
  List<MessageModel> _allMessages = [];
  bool _isFetchingMembers = false;
  int _messageLimit = 30;
  bool _isLoadingMore = false;
  late Stream<List<MessageModel>> _messagesStream;
  late Stream<DocumentSnapshot> _groupStream;
  OverlayEntry? _attachmentMenuEntry;
  bool _isUploading = false;
  final currentUser = FirebaseAuth.instance.currentUser;
  String? _currentUserDisplayName;
  final Map<String, GlobalKey> _messageKeys = {};
  int _initialUnreadCount = 0;
  String? _highlightedMessageId;
  Timer? _highlightTimer;
  Timer? _typingTimer;
  bool _isTyping = false;
  final Set<String> _markingReadIds = {}; // Tracking currently marking as read

  // Audio Coordination
  final ValueNotifier<String?> _activeAudioId = ValueNotifier(null);
  final List<File> _selectedImages = [];

  // Finished Outings (24h window)
  late Stream<QuerySnapshot> _finishedOutingsStream;

  bool _isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  String _getDateString(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);
    final isAr = AppLocalizations.of(context)?.isAr == true;

    if (messageDate == today) return isAr ? "اليوم" : "Today";
    if (messageDate == yesterday) return isAr ? "أمس" : "Yesterday";
    return intl.DateFormat('MMMM d, yyyy', isAr ? 'ar' : 'en').format(date);
  }

  String _formatTime(DateTime time) {
    final isAr = AppLocalizations.of(context)?.isAr == true;
    final formattedTime = intl.DateFormat('hh:mm a').format(time);
    if (isAr) {
      return formattedTime.replaceAll('AM', 'ص').replaceAll('PM', 'م');
    }
    return formattedTime;
  }

  @override
  void initState() {
    super.initState();
    _initialUnreadCount = widget.group.unreadCounts[currentUser?.uid] ?? 0;
    _scrollController.addListener(_scrollListener);
    _messagesStream = _chatService.getMessagesStream(
      widget.group.id,
      limit: _messageLimit,
    );
    _groupStream = FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.group.id)
        .snapshots();
    _chatService.resetUnreadCount(widget.group.id, currentUser?.uid ?? '');
    _fetchMemberDetails();
    _fetchCurrentUserInfo();
    FcmService.instance.activeGroupId = widget.group.id;
    _messageController.addListener(_onTypingChanged);

    _finishedOutingsStream = FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.group.id)
        .collection('outings')
        .where('status', isEqualTo: OutingStatus.finished.name)
        .orderBy('finishedAt', descending: true)
        .limit(1)
        .snapshots();

    // 🛡️ Periodic rebuild for typing indicator TTL
    _rebuildTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted && _hasActiveTypers()) {
        setState(() {});
      }
    });
  }

  void _scrollListener() {
    if (_scrollController.hasClients &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore) {
        setState(() {
          _isLoadingMore = true;
          _messageLimit += 30;
          _messagesStream = _chatService.getMessagesStream(
            widget.group.id,
            limit: _messageLimit,
          );
        });
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) setState(() => _isLoadingMore = false);
        });
      }
    }
  }

  Timer? _rebuildTimer;

  bool _hasActiveTypers() {
    // This method is called by the timer to see if we should rebuild
    // Returning true ensures we always check for stale indicators every 3 seconds
    return true;
  }

  @override
  void dispose() {
    _messageController.removeListener(_onTypingChanged);
    // 🛡️ Clear typing status before leaving
    if (_isTyping && currentUser != null) {
      _chatService.setTypingStatus(widget.group.id, currentUser!.uid, false);
    }
    _rebuildTimer?.cancel();
    _typingTimer?.cancel();
    _highlightTimer?.cancel();
    _closeAttachmentMenu();
    _messageController.dispose();
    _scrollController.dispose();
    _audioRecorder.dispose();
    _amplitudeTimer?.cancel();
    FcmService.instance.activeGroupId = null;
    super.dispose();
  }

  void _throttledMarkAsRead(List<String> messageIds) {
    if (currentUser == null) return;

    // Filter out IDs that are already being processed
    final newIds = messageIds
        .where((id) => !_markingReadIds.contains(id))
        .toList();
    if (newIds.isEmpty) return;

    _markingReadIds.addAll(newIds);

    Future.microtask(() async {
      try {
        await _chatService.markMessagesAsRead(
          widget.group.id,
          newIds,
          currentUser!.uid,
        );
      } catch (e) {
        debugPrint("Error marking messages as read: $e");
        // Remove from tracking so we can retry later if needed
        for (var id in newIds) {
          _markingReadIds.remove(id);
        }
      }
    });
  }

  void _onTypingChanged() {
    if (currentUser == null) return;

    final text = _messageController.text;
    debugPrint(
      "⌨️ [Typing] Text changed: '$text' | Current _isTyping: $_isTyping",
    );

    if (text.trim().isNotEmpty) {
      if (!_isTyping) {
        setState(() => _isTyping = true);
        final displayName =
            _currentUserDisplayName ?? currentUser?.displayName ?? "Someone";
        _chatService.setTypingStatus(
          widget.group.id,
          currentUser!.uid,
          true,
          userName: displayName,
        );
      }

      _typingTimer?.cancel();
      _typingTimer = Timer(const Duration(seconds: 2), () {
        debugPrint("⌨️ [Typing] Timer expired, stopping...");
        if (mounted && _isTyping) {
          setState(() => _isTyping = false);
          _chatService.setTypingStatus(
            widget.group.id,
            currentUser!.uid,
            false,
          );
        }
      });
    } else {
      if (_isTyping) {
        debugPrint("⌨️ [Typing] Text cleared, stopping...");
        setState(() => _isTyping = false);
        _typingTimer?.cancel();
        _chatService.setTypingStatus(widget.group.id, currentUser!.uid, false);
      }
    }
  }

  void _playNextVoice(String currentId) {
    // Find message index (0 is newest)
    final index = _allMessages.indexWhere((m) => m.id == currentId);
    if (index == -1) return;

    // Search for the next NEWER voice message (lower index)
    for (int i = index - 1; i >= 0; i--) {
      final nextMsg = _allMessages[i];
      if (nextMsg.type == 'audio') {
        debugPrint("🎵 [Audio] Auto-playing next message: ${nextMsg.id}");
        _activeAudioId.value = nextMsg.id;
        break;
      }
    }
  }

  Future<void> _fetchMemberDetails() async {
    if (_isFetchingMembers) return;
    setState(() => _isFetchingMembers = true);

    final Map<String, String> newPhotos = {};
    final Map<String, String> newNames = {};

    try {
      final futures = widget.group.memberIds.map((uid) async {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get();
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          final photoUrl = data['photoUrl'] ?? data['profilePic'];
          final name = data['name'] ?? data['fullName'] ?? "Friend";
          if (photoUrl != null) newPhotos[uid] = photoUrl;
          newNames[uid] = name;
        }
      });

      await Future.wait(futures);

      if (mounted) {
        setState(() {
          _memberPhotos.addAll(newPhotos);
          _memberNames.addAll(newNames);
        });
      }
    } catch (e) {
      debugPrint("Error fetching member details: $e");
    } finally {
      if (mounted) setState(() => _isFetchingMembers = false);
    }
  }

  Future<void> _fetchCurrentUserInfo() async {
    if (currentUser == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            _currentUserDisplayName =
                data['name'] ?? data['fullName'] ?? currentUser?.displayName;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching current user info: $e");
    }
  }

  MessageModel? _editingMessage;
  MessageModel? _replyingTo;

  Future<void> _playNativeSound(int soundId) async {
    try {
      await _soundChannel.invokeMethod('playSystemSound', {'soundId': soundId});
    } catch (e) {
      debugPrint("Error playing native sound: $e");
      // Fallback for Android or errors
      SystemSound.play(SystemSoundType.click);
    }
  }

  void _onReply(MessageModel message) {
    setState(() {
      _replyingTo = message;
      _editingMessage = null;
    });
    HapticFeedback.lightImpact();
  }

  Future<void> _startRecording() async {
    try {
      debugPrint("🎤 Starting voice recording sequence...");
      if (!await _audioRecorder.hasPermission()) {
        debugPrint("❌ Microphone permission not granted");
        return;
      }
      final tempDir = await getTemporaryDirectory();
      final filePath = p.join(
        tempDir.path,
        'voice_note_${DateTime.now().millisecondsSinceEpoch}.m4a',
      );

      _isStartingRecorder = true;
      _shouldStopImmediately = false;

      setState(() {
        _isRecording = true;
        _recordStartTime = DateTime.now();
        _isCanceling = false;
        _isLocked = false;
        _amplitudes = List.generate(12, (_) => 0.0);
        _elapsedTime = "00:00";
      });

      debugPrint("🎙️ Initializing recorder...");
      await _audioRecorder.start(const RecordConfig(), path: filePath);
      debugPrint("✅ Recorder started successfully");
      _isStartingRecorder = false;

      // User released button before recorder was ready — stop immediately
      if (_shouldStopImmediately) {
        debugPrint("🛑 User released early, stopping recorder immediately.");
        await _stopRecording();
        return;
      }

      _amplitudeTimer = Timer.periodic(const Duration(milliseconds: 80), (
        timer,
      ) async {
        if (!_isRecording) return;
        final amp = await _audioRecorder.getAmplitude();
        if (mounted) {
          setState(() {
            // Waveform
            double normalized = ((amp.current + 60) / 60).clamp(0.0, 1.0);
            _amplitudes.removeAt(0);
            _amplitudes.add(normalized);

            // Duration
            final duration = DateTime.now().difference(
              _recordStartTime ?? DateTime.now(),
            );
            final minutes = duration.inMinutes.toString().padLeft(2, '0');
            final seconds = (duration.inSeconds % 60).toString().padLeft(
              2,
              '0',
            );
            _elapsedTime = "$minutes:$seconds";
          });
        }
      });

      _playNativeSound(1113); // iOS Begin Record
      HapticFeedback.heavyImpact();
    } catch (e) {
      debugPrint("Error starting recording: $e");
      _isStartingRecorder = false;
      if (mounted) {
        setState(() {
          _isRecording = false;
        });
      }
    }
  }

  Future<void> _stopRecording() async {
    // If recorder hasn't started yet, flag it so _startRecording handles the stop
    if (_isStartingRecorder) {
      _shouldStopImmediately = true;
      return;
    }
    if (!_isRecording) return;

    // Capture cancel state BEFORE resetting it
    final wasCanceling = _isCanceling;

    _amplitudeTimer?.cancel();
    _amplitudeTimer = null;

    final path = await _audioRecorder.stop();

    setState(() {
      _isRecording = false;
      _isCanceling = false;
      _isLocked = false;
      _amplitudes = List.generate(12, (_) => 0.0);
    });

    if (wasCanceling || path == null) {
      _playNativeSound(1101); // iOS Discard/Delete
      HapticFeedback.lightImpact();
      return;
    }

    _playNativeSound(1114); // iOS End Record
    HapticFeedback.mediumImpact();

    final duration = DateTime.now().difference(
      _recordStartTime ?? DateTime.now(),
    );
    if (duration.inMilliseconds < 500) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hold to record a voice note'),
            duration: Duration(seconds: 1),
          ),
        );
      }
      return;
    }

    _sendVoiceNote(path, duration);
  }

  Future<void> _sendVoiceNote(String path, Duration duration) async {
    try {
      final url = await _chatService.uploadAudio(File(path), widget.group.id);

      // Format duration for preview text: Voice Note (00:03)
      String twoDigits(int n) => n.toString().padLeft(2, "0");
      final minutes = twoDigits(duration.inMinutes.remainder(60));
      final seconds = twoDigits(duration.inSeconds.remainder(60));
      final durationStr = "($minutes:$seconds)";

      await _chatService.sendMessage(
        groupId: widget.group.id,
        senderId: currentUser?.uid ?? '',
        senderName: _currentUserDisplayName ?? currentUser?.displayName ?? "Me",
        senderPhotoUrl: currentUser?.photoURL,
        text: "Voice Note $durationStr",
        type: 'audio',
        mediaUrls: [url],
      );
    } catch (e) {
      debugPrint("Error sending voice note: $e");
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty && _selectedImages.isEmpty) return;

    setState(() => _isUploading = true);
    try {
      List<String> imageUrls = [];
      if (_selectedImages.isNotEmpty) {
        final uploadTasks = _selectedImages.map(
          (file) => _chatService.uploadImage(file, widget.group.id),
        );
        imageUrls = await Future.wait(uploadTasks);
      }

      if (_editingMessage != null) {
        _chatService.editMessage(widget.group.id, _editingMessage!.id, text);
        setState(() {
          _editingMessage = null;
          _messageController.clear();
          _selectedImages.clear();
        });
      } else {
        final displayName =
            _currentUserDisplayName ?? currentUser?.displayName ?? 'Me';
        final photoUrl =
            _memberPhotos[currentUser?.uid] ?? currentUser?.photoURL;

        if (text.isNotEmpty || imageUrls.isNotEmpty) {
          await _chatService.sendMessage(
            groupId: widget.group.id,
            senderId: currentUser?.uid ?? '',
            senderName: displayName,
            senderPhotoUrl: photoUrl,
            text: text.isNotEmpty
                ? text
                : (imageUrls.isNotEmpty ? imageUrls.first : ''),
            mediaUrls: imageUrls,
            type: imageUrls.isNotEmpty ? 'image' : 'text',
            replyToId: _replyingTo?.id,
            replyToText: _replyingTo?.text,
            replyToSenderId: _replyingTo?.senderId,
            replyToSenderName:
                _memberNames[_replyingTo?.senderId] ?? _replyingTo?.senderName,
          );
          setState(() {
            _replyingTo = null;
            _messageController.clear();
            _selectedImages.clear();
          });
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to send: $e')));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _scrollToMessage(String messageId) {
    final key = _messageKeys[messageId];
    if (key != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (key.currentContext != null) {
          final renderBox =
              key.currentContext!.findRenderObject() as RenderBox?;
          if (renderBox != null && renderBox.attached && renderBox.hasSize) {
            Scrollable.ensureVisible(
              key.currentContext!,
              alignment: 0.5,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOutQuart,
            );
          }
        }
      });
    } else {
      // Fallback for messages not currently in view: jump to approximate position
      final index = _allMessages.indexWhere((m) => m.id == messageId);
      if (index != -1 && _scrollController.hasClients) {
        _scrollController
            .animateTo(
              index * 120.0, // Approximate height per bubble
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutQuart,
            )
            .then((_) {
              // After scrolling, the item should be built, try ensureVisible again
              WidgetsBinding.instance.addPostFrameCallback((_) {
                final newKey = _messageKeys[messageId];
                if (newKey != null && newKey.currentContext != null) {
                  final newRenderBox =
                      newKey.currentContext!.findRenderObject() as RenderBox?;
                  if (newRenderBox != null &&
                      newRenderBox.attached &&
                      newRenderBox.hasSize) {
                    Scrollable.ensureVisible(
                      newKey.currentContext!,
                      alignment: 0.5,
                      duration: const Duration(milliseconds: 300),
                    );
                  }
                }
              });
            });
      }
    }

    // Trigger highlight animation
    setState(() {
      _highlightedMessageId = messageId;
    });

    // Clear highlight after delay
    _highlightTimer?.cancel();
    _highlightTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _highlightedMessageId = null;
        });
      }
    });
  }

  Widget _buildBubble(MessageModel message) {
    final isMe = message.senderId == currentUser?.uid;
    final key = _messageKeys.putIfAbsent(message.id, () => GlobalKey());

    return _MessageBubble(
      message: message,
      groupId: widget.group.id,
      isMe: isMe,
      onLongPress: () => _onMessageLongPress(message),
      onReplyTap: (replyId) => _scrollToMessage(replyId),
      isHighlighted: _highlightedMessageId == message.id,
      memberPhotos: _memberPhotos,
      memberNames: _memberNames,
      totalMembers: widget.group.memberIds.length,
      activeAudioIdNotifier: _activeAudioId,
      onPlayNextVoice: _playNextVoice,
      onReactionTap: () => _showReactionDetails(message),
    );
  }

  void _showReactionDetails(MessageModel message) {
    if (message.reactions.isEmpty) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        // Flatten reactions into a list of (uid, emoji)
        final List<MapEntry<String, String>> reactors = [];
        message.reactions.forEach((emoji, uids) {
          for (var uid in uids) {
            reactors.add(MapEntry(uid.toString(), emoji));
          }
        });

        return Container(
          height: MediaQuery.of(context).size.height * 0.5,
          decoration: BoxDecoration(
            color: AppColors.getSurfaceElevated(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handlebar
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Text(
                  l10n.reactionsLabel,
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.getTextPrimary(context),
                  ),
                ),
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  itemCount: reactors.length,
                  itemBuilder: (context, index) {
                    final uid = reactors[index].key;
                    final emoji = reactors[index].value;
                    final photoUrl = _memberPhotos[uid];
                    final name = _memberNames[uid] ?? "Friend";

                    return ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.teal.withOpacity(0.1),
                          shape: BoxShape.circle,
                          image: photoUrl != null
                              ? DecorationImage(
                                  image: CachedNetworkImageProvider(photoUrl),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: photoUrl == null
                            ? const Icon(Icons.person, color: AppColors.teal)
                            : null,
                      ),
                      title: Text(
                        name,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: AppColors.getTextPrimary(context),
                        ),
                      ),
                      trailing: Text(
                        emoji,
                        style: const TextStyle(fontSize: 24),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTypingIndicator(Map<String, dynamic> typingUsers) {
    final List<String> typingUids = [];
    final now = DateTime.now();
    typingUsers.forEach((uid, data) {
      if (uid != currentUser?.uid && data is Map) {
        final isTyping = data['isTyping'] == true;
        final Timestamp? ts = data['timestamp'] as Timestamp?;

        // 🛡️ TTL: Only show if updated in the last 6 seconds
        bool isFresh = true;
        if (ts != null) {
          final diff = now.difference(ts.toDate()).inSeconds;
          if (diff > 6) isFresh = false;
        }

        if (isTyping && isFresh) {
          typingUids.add(uid);
        }
      } else if (uid != currentUser?.uid && data == true) {
        // Fallback for legacy simple boolean data
        typingUids.add(uid);
      }
    });

    if (typingUids.isEmpty) return const SizedBox.shrink();

    // TEXT LOGIC
    String text;
    if (typingUids.length == 1) {
      text = "${_memberNames[typingUids[0]] ?? "Someone"} is typing";
    } else if (typingUids.length == 2) {
      final n1 = _memberNames[typingUids[0]] ?? "Someone";
      final n2 = _memberNames[typingUids[1]] ?? "Someone";
      text = "$n1 and $n2 are typing";
    } else {
      final n1 = _memberNames[typingUids[0]] ?? "Someone";
      text = "$n1 and ${typingUids.length - 1} others are typing";
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Dynamic Avatar Stack
              SizedBox(
                width: typingUids.length == 1
                    ? 32
                    : (32 + (typingUids.length.clamp(1, 3) - 1) * 12)
                          .toDouble(),
                height: 32,
                child: Stack(
                  children: List.generate(typingUids.length.clamp(1, 3), (
                    index,
                  ) {
                    final uid = typingUids[index];
                    final pUrl = _memberPhotos[uid];
                    return Positioned(
                      left: index * 12.0,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.getSurface(context),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.getSurface(context),
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
                        child: ClipOval(
                          child: (pUrl != null && pUrl.startsWith('http'))
                              ? CachedNetworkImage(
                                  imageUrl: pUrl,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) =>
                                      Container(color: Colors.grey.shade200),
                                  errorWidget: (context, url, error) =>
                                      Container(
                                        color: AppColors.teal.withOpacity(0.1),
                                        child: const Icon(
                                          Icons.person,
                                          size: 20,
                                          color: AppColors.teal,
                                        ),
                                      ),
                                )
                              : Container(
                                  color: AppColors.teal.withOpacity(0.1),
                                  child: const Icon(
                                    Icons.person,
                                    size: 20,
                                    color: AppColors.teal,
                                  ),
                                ),
                        ),
                      ),
                    );
                  }).reversed.toList(), // Reversed to show first avatar on top
                ),
              ),
              const SizedBox(width: 8),

              // Typing Bubble
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 4),
                    child: Text(
                      text,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.getSurface(context),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                        bottomLeft: Radius.circular(0),
                        bottomRight: Radius.circular(16),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.getShadow(
                            context,
                          ).withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(3, (index) {
                        return Container(
                              width: 5,
                              height: 5,
                              margin: const EdgeInsets.symmetric(
                                horizontal: 2.5,
                              ),
                              decoration: const BoxDecoration(
                                color: AppColors.teal,
                                shape: BoxShape.circle,
                              ),
                            )
                            .animate(onPlay: (c) => c.repeat())
                            .scale(
                              begin: const Offset(1, 1),
                              end: const Offset(1.4, 1.4),
                              duration: 400.ms,
                              delay: (index * 150).ms,
                              curve: Curves.easeInOut,
                            )
                            .fadeIn(duration: 400.ms)
                            .then()
                            .scale(
                              begin: const Offset(1.4, 1.4),
                              end: const Offset(1, 1),
                              duration: 400.ms,
                            )
                            .fadeOut(duration: 400.ms);
                      }),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.2, end: 0);
  }

  void _onMessageLongPress(MessageModel message) {
    if (message.isDeleted) return;

    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _MessageOptionsSheet(
        message: message,
        isMe: message.senderId == currentUser?.uid,
        onReaction: (emoji) {
          final myId = currentUser?.uid ?? '';
          if (message.reactions[emoji]?.contains(myId) ?? false) {
            _chatService.removeReaction(
              widget.group.id,
              message.id,
              myId,
              emoji,
            );
          } else {
            _chatService.addReaction(widget.group.id, message.id, myId, emoji);
          }
          Navigator.pop(context);
        },
        onEdit: () {
          Navigator.pop(context);
          setState(() {
            _editingMessage = message;
            _messageController.text = message.text;
          });
        },
        onDelete: (forEveryone) async {
          Navigator.pop(context);
          try {
            await _chatService.deleteMessage(
              widget.group.id,
              message.id,
              forEveryone: forEveryone,
              uid: currentUser?.uid,
            );
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(e.toString())));
            }
          }
        },
        onInfo: () {
          Navigator.pop(context);
          _showMessageInfo(message);
        },
      ),
    );
  }

  void _showMessageInfo(MessageModel message) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _MessageInfoSheet(
        message: message,
        group: widget.group,
        memberNames: _memberNames,
        memberPhotos: _memberPhotos,
      ),
    );
  }

  void _closeAttachmentMenu() {
    _attachmentMenuEntry?.remove();
    _attachmentMenuEntry = null;
  }

  void _showCreateOutingSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppLocalizations.of(context)?.isAr == true
                  ? "بدء خرجة"
                  : "Start Outing",
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.darkSlate,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)?.isAr == true
                  ? "كيف ترغب في التخطيط لليوم؟"
                  : "How would you like to plan today?",
              style: GoogleFonts.inter(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 32),
            _buildSelectionOption(
              title: AppLocalizations.of(context)?.isAr == true
                  ? "البحث عن نقطة المنتصف"
                  : "Find Midpoint",
              subtitle: AppLocalizations.of(context)?.isAr == true
                  ? "المكان الأكثر عدلاً للجميع"
                  : "The fairest spot for everyone",
              icon: Icons.auto_awesome_rounded,
              color: AppColors.teal,
              onTap: () {
                Navigator.pop(context);
                _openCreationSheet(isDirect: false);
              },
            ),
            const SizedBox(height: 16),
            _buildSelectionOption(
              title: AppLocalizations.of(context)?.isAr == true
                  ? "مكان محدد"
                  : "Specific Place",
              subtitle: AppLocalizations.of(context)?.isAr == true
                  ? "أعرف إلى أين نحن ذاهبون"
                  : "I know where we're going",
              icon: Icons.location_on_rounded,
              color: Colors.orange,
              onTap: () {
                Navigator.pop(context);
                _openCreationSheet(isDirect: true);
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkSlate,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 16, color: color),
          ],
        ),
      ),
    );
  }

  void _openCreationSheet({required bool isDirect}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateOutingSheet(
        groupId: widget.group.id,
        initialDirectMode: isDirect,
      ),
    );
  }

  void _showAttachmentMenu() {
    if (_attachmentMenuEntry != null) {
      _closeAttachmentMenu();
      return;
    }

    _attachmentMenuEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          GestureDetector(
            onTap: _closeAttachmentMenu,
            behavior: HitTestBehavior.opaque,
            child: Container(color: Colors.transparent),
          ),
          Positioned(
            width: 260, // Slightly wider for better text layout
            child: CompositedTransformFollower(
              link: _attachmentMenuLink,
              showWhenUnlinked: false,
              offset: const Offset(
                0,
                -320,
              ), // Positioned with perfect breathing room
              child:
                  Material(
                        color: Colors.transparent,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.getSurfaceElevated(
                                  context,
                                ).withValues(alpha: 0.85),
                                borderRadius: BorderRadius.circular(28),
                                border: Border.all(
                                  color: AppColors.getBorder(context),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.getShadow(
                                      context,
                                    ).withValues(alpha: 0.1),
                                    blurRadius: 30,
                                    offset: const Offset(0, 15),
                                  ),
                                ],
                              ),
                              child: Directionality(
                                textDirection:
                                    AppLocalizations.of(context)?.isAr == true
                                    ? TextDirection.rtl
                                    : TextDirection.ltr,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const SizedBox(height: 12),
                                    _buildMenuItem(
                                      icon: Icons.camera_alt_rounded,
                                      label:
                                          AppLocalizations.of(context)?.isAr ==
                                              true
                                          ? "الكاميرا"
                                          : "Camera",
                                      color: Colors.teal,
                                      onTap: () {
                                        _closeAttachmentMenu();
                                        _handleImageSelection(
                                          ImageSource.camera,
                                        );
                                      },
                                    ),
                                    _buildMenuItem(
                                      icon: Icons.image_rounded,
                                      label:
                                          AppLocalizations.of(context)?.isAr ==
                                              true
                                          ? "المعرض"
                                          : "Gallery",
                                      color: Colors.indigo,
                                      onTap: () {
                                        _closeAttachmentMenu();
                                        _handleImageSelection(
                                          ImageSource.gallery,
                                        );
                                      },
                                    ),
                                    _buildMenuItem(
                                      icon: Icons.location_on_rounded,
                                      label:
                                          AppLocalizations.of(context)?.isAr ==
                                              true
                                          ? "الموقع"
                                          : "Location",
                                      color: Colors.amber.shade700,
                                      onTap: () {
                                        _closeAttachmentMenu();
                                        _handleLocationSharing();
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        16,
                                        0,
                                        16,
                                        16,
                                      ),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: AppColors.tealGradient,
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppColors.teal.withValues(
                                                alpha: 0.3,
                                              ),
                                              blurRadius: 10,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: ElevatedButton.icon(
                                          onPressed: () {
                                            _closeAttachmentMenu();
                                            _showCreateOutingSheet();
                                          },
                                          icon: const Icon(
                                            Icons.flash_on_rounded,
                                            size: 18,
                                            color: Colors.white,
                                          ),
                                          label: Text(
                                            AppLocalizations.of(
                                                      context,
                                                    )?.isAr ==
                                                    true
                                                ? "بدء جلسة خرجة"
                                                : "Start Outing Session",
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.transparent,
                                            shadowColor: Colors.transparent,
                                            minimumSize: const Size(
                                              double.infinity,
                                              50,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 250.ms)
                      .scale(
                        begin: const Offset(0.8, 0.8),
                        curve: Curves.easeOutBack,
                      )
                      .slideY(begin: 0.1, end: 0),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_attachmentMenuEntry!);
  }

  Future<void> _handleImageSelection(ImageSource source) async {
    final picker = ImagePicker();
    List<XFile> pickedFiles = [];

    try {
      if (source == ImageSource.camera) {
        final file = await picker.pickImage(source: source, imageQuality: 70);
        if (file != null) pickedFiles.add(file);
      } else {
        pickedFiles = await picker.pickMultiImage(imageQuality: 70, limit: 5);
        if (pickedFiles.length > 5) pickedFiles = pickedFiles.sublist(0, 5);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to pick images: $e')));
      }
      return;
    }

    if (pickedFiles.isNotEmpty && mounted) {
      setState(() {
        _selectedImages.addAll(pickedFiles.map((x) => File(x.path)));
      });
    }
  }

  Future<void> _handleLocationSharing() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location services are disabled.')),
        );
      }
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are denied')),
          );
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permissions are permanently denied.'),
          ),
        );
      }
      return;
    }

    setState(() => _isUploading = true);
    try {
      final position = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() => _isUploading = false);
        await _showLocationModeSheet(position);
      }
      return;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to get location: $e')));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _showLocationModeSheet(Position position) async {
    final userPos = gmaps.LatLng(position.latitude, position.longitude);
    final l10n = AppLocalizations.of(context, listen: false)!;
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  l10n.shareLocation,
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkSlate,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Real Google Map preview
              SizedBox(
                height: 200,
                child: Stack(
                  children: [
                    IgnorePointer(
                      child: gmaps.GoogleMap(
                        initialCameraPosition: gmaps.CameraPosition(
                          target: userPos,
                          zoom: 15,
                        ),
                        markers: {
                          gmaps.Marker(
                            markerId: const gmaps.MarkerId('user'),
                            position: userPos,
                          ),
                        },
                        zoomControlsEnabled: false,
                        myLocationButtonEnabled: false,
                        mapToolbarEnabled: false,
                        compassEnabled: false,
                        tiltGesturesEnabled: false,
                        rotateGesturesEnabled: false,
                        scrollGesturesEnabled: false,
                        zoomGesturesEnabled: false,
                      ),
                    ),
                    // "Your location" pill overlay
                    Positioned(
                      top: 10,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.my_location,
                              color: AppColors.teal,
                              size: 13,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              l10n.yourLocation,
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.darkSlate,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Options
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    InkWell(
                      onTap: () => Navigator.pop(context, 'live'),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppColors.teal.withOpacity(0.3),
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          color: AppColors.teal.withOpacity(0.04),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.teal.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.my_location,
                                color: AppColors.teal,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.shareLiveLocation,
                                    style: GoogleFonts.outfit(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.darkSlate,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    l10n.shareLiveDesc,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () => Navigator.pop(context, 'custom'),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.grey.withOpacity(0.2),
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          color: Colors.grey.shade50,
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.map_outlined,
                                color: Colors.grey,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.chooseOnMap,
                                    style: GoogleFonts.outfit(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.darkSlate,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    l10n.chooseOnMapDesc,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );

    if (result == null) return;

    if (result == 'live') {
      // Send current GPS position
      final lat = position.latitude;
      final lng = position.longitude;
      final senderName =
          _currentUserDisplayName ?? currentUser?.displayName ?? "Me";
      await _chatService.sendMessage(
        groupId: widget.group.id,
        senderId: currentUser?.uid ?? '',
        senderName: senderName,
        senderPhotoUrl: currentUser?.photoURL,
        text: 'geo:$lat,$lng',
        type: 'location',
      );
    } else if (result == 'custom') {
      // Open the full-screen map picker
      if (!mounted) return;
      final picked = await Navigator.push<gmaps.LatLng>(
        context,
        MaterialPageRoute(
          builder: (context) => LocationPickerPage(initialPosition: position),
        ),
      );
      if (picked == null) return;
      final senderName =
          _currentUserDisplayName ?? currentUser?.displayName ?? "Me";
      await _chatService.sendMessage(
        groupId: widget.group.id,
        senderId: currentUser?.uid ?? '',
        senderName: senderName,
        senderPhotoUrl: currentUser?.photoURL,
        text: 'geo:${picked.latitude},${picked.longitude}',
        type: 'location',
      );
    }
  }

  Widget _buildSelectedImagesPreview() {
    return Container(
      height: 90,
      margin: const EdgeInsets.only(bottom: 8, top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _selectedImages.length,
        itemBuilder: (context, index) {
          return Stack(
            children: [
              Container(
                margin: const EdgeInsets.only(right: 8, top: 4, bottom: 4),
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withOpacity(0.2)),
                  image: DecorationImage(
                    image: FileImage(_selectedImages[index]),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                top: 0,
                right: 4,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedImages.removeAt(index);
                    });
                  },
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(4),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.getTextPrimary(context).withValues(alpha: 0.9),
              ),
            ),
            const Spacer(),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.grey.withOpacity(0.4),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wallpaperProvider = Provider.of<WallpaperProvider>(context);
    final wallpaperStr = wallpaperProvider.getWallpaper(widget.group.id);

    Color backgroundColor = AppColors.getBackground(context);
    DecorationImage? bgImage;
    LinearGradient? bgGradient;

    if (wallpaperStr != null) {
      if (wallpaperStr.startsWith('gradient://')) {
        final colorsStr = wallpaperStr.substring(11).split(',');
        if (colorsStr.length == 2) {
          final c1 = Color(int.parse(colorsStr[0].substring(1), radix: 16));
          final c2 = Color(int.parse(colorsStr[1].substring(1), radix: 16));
          bgGradient = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [c1, c2],
          );
        }
      } else if (wallpaperStr.startsWith('#')) {
        // Hex color
        final hexStr = wallpaperStr.substring(1);
        if (hexStr.length == 8) {
          final color = Color(int.parse(hexStr, radix: 16));
          backgroundColor = color;
        }
      } else if (wallpaperStr.startsWith('file://')) {
        // Local file image
        final filePath = wallpaperStr.substring(7);
        bgImage = DecorationImage(
          image: FileImage(File(filePath)),
          fit: BoxFit.cover,
        );
      }
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Container(
        decoration: BoxDecoration(image: bgImage, gradient: bgGradient),
        child: Stack(
          children: [
            Positioned.fill(
              key: const ValueKey('chat_main_column'),
              child: Column(
                children: [
                  _buildHeader(context),
                  _buildMemoryPrompt(),

                  Expanded(
                    child: StreamBuilder<List<MessageModel>>(
                      stream: _messagesStream,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                                ConnectionState.waiting &&
                            !snapshot.hasData) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const CircularProgressIndicator(
                                  color: AppColors.teal,
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  "Loading messages...",
                                  style: GoogleFonts.inter(
                                    color: Colors.grey.shade600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Text(
                                "Error: ${snapshot.error}",
                                style: const TextStyle(color: Colors.red),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          );
                        }

                        final rawMessages = (snapshot.data ?? [])
                            .where(
                              (m) => !m.deletedFor.contains(currentUser?.uid),
                            )
                            .toList();

                        // Track messages for deep-scrolling
                        _allMessages = rawMessages;

                        // ⚡ BATCh MARK AS READ (Asynchronous)
                        // Prevents layout freezing when processing hundreds of messages
                        if (currentUser != null) {
                          final unreadMessageIds = rawMessages
                              .where(
                                (m) =>
                                    m.senderId != currentUser!.uid &&
                                    !m.readBy.contains(currentUser!.uid),
                              )
                              .map((m) => m.id)
                              .take(500)
                              .toList();

                          if (unreadMessageIds.isNotEmpty) {
                            // Debounce / throttle marking as read to avoid stream loops
                            _throttledMarkAsRead(unreadMessageIds);
                          }
                        }

                        if (rawMessages.isEmpty) {
                          return _buildEmptyChat();
                        }

                        // Process messages into chat items (messages + date dividers)
                        final List<dynamic> chatItems = [];
                        for (int i = 0; i < rawMessages.length; i++) {
                          final message = rawMessages[i];
                          chatItems.add(message);

                          // Add date divider if this is the last message or date changes
                          if (i == rawMessages.length - 1) {
                            chatItems.add(_getDateString(message.timestamp));
                          } else {
                            final olderMessage = rawMessages[i + 1];
                            if (!_isSameDay(
                              message.timestamp,
                              olderMessage.timestamp,
                            )) {
                              chatItems.add(_getDateString(message.timestamp));
                            }
                          }
                        }

                        // Inject Unread Divider if needed
                        if (_initialUnreadCount > 0 &&
                            _initialUnreadCount <= rawMessages.length) {
                          // Find the position in chatItems corresponding to the unread boundary
                          final targetMessageId =
                              rawMessages[_initialUnreadCount - 1].id;
                          final indexInItems = chatItems.indexWhere(
                            (item) =>
                                item is MessageModel &&
                                item.id == targetMessageId,
                          );
                          if (indexInItems != -1) {
                            chatItems.insert(
                              indexInItems + 1,
                              "UNREAD_DIVIDER",
                            );
                          }
                        }

                        return ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 20,
                          ),
                          reverse: true,
                          itemCount:
                              chatItems.length + (_isLoadingMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (_isLoadingMore && index == chatItems.length) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 20),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: AppColors.teal,
                                  ),
                                ),
                              );
                            }

                            final item = chatItems[index];
                            if (item is String) {
                              if (item == "UNREAD_DIVIDER") {
                                return const _UnreadDivider();
                              }
                              return _DateDivider(dateLabel: item);
                            }
                            return _buildBubble(item as MessageModel);
                          },
                        );
                      },
                    ),
                  ),

                  if (_editingMessage != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      color: AppColors.teal.withOpacity(0.1),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.edit,
                            size: 16,
                            color: AppColors.teal,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Editing: ${_editingMessage!.text}",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.teal,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              size: 16,
                              color: AppColors.teal,
                            ),
                            onPressed: () => setState(() {
                              _editingMessage = null;
                              _messageController.clear();
                            }),
                          ),
                        ],
                      ),
                    ),

                  if (_replyingTo != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          top: BorderSide(color: Colors.grey.withOpacity(0.1)),
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border(
                            left: BorderSide(color: AppColors.teal, width: 4),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _memberNames[_replyingTo!.senderId] ??
                                        _replyingTo!.senderName,
                                    style: GoogleFonts.outfit(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.teal,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _replyingTo!.type == 'image'
                                        ? "📷 Photo"
                                        : _replyingTo!.text,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.close,
                                size: 18,
                                color: Colors.grey,
                              ),
                              onPressed: () =>
                                  setState(() => _replyingTo = null),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ),
                    ),

                  StreamBuilder<DocumentSnapshot>(
                    stream: _groupStream,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || !snapshot.data!.exists) {
                        return const SizedBox.shrink();
                      }
                      final data =
                          snapshot.data!.data() as Map<String, dynamic>;
                      final Map<String, dynamic> typingUsers =
                          data['typing_users'] // Check both names just in case
                          ??
                          data['typingUsers'] as Map<String, dynamic>? ??
                          {};

                      return _buildTypingIndicator(typingUsers);
                    },
                  ),
                  _buildInputBar(),
                  const SizedBox(height: 12), // Extra space for floating look
                ],
              ),
            ),
            if (_isUploading)
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                  child: Container(
                    color: Colors.white.withOpacity(0.3),
                    child: const Center(
                      child: CircularProgressIndicator(color: AppColors.teal),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        bottom: 12,
        left: 8,
        right: 8,
      ),
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        border: Border(
          bottom: BorderSide(color: AppColors.getBorder(context), width: 1.5),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              size: 22,
              color: AppColors.darkSlate,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 4),
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.teal.withOpacity(0.08),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.withOpacity(0.1)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(23),
              child: widget.group.photoUrl != null
                  ? CachedNetworkImage(
                      imageUrl: widget.group.photoUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.teal,
                          ),
                      errorWidget: (context, url, error) => const Icon(
                        Icons.groups_rounded,
                        color: AppColors.teal,
                        size: 26,
                      ),
                    )
                  : const Icon(
                      Icons.groups_rounded,
                      color: AppColors.teal,
                      size: 26,
                    ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.group.name,
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.getTextPrimary(context),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  AppLocalizations.of(context)?.isAr == true
                      ? "${widget.group.memberIds.length} أعضاء"
                      : "${widget.group.memberIds.length} members",
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.getTextSecondary(context),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.share_rounded,
              color: AppColors.teal,
              size: 22,
            ),
            onPressed: () => _showShareSheet(context),
            tooltip: AppLocalizations.of(context)?.isAr == true
                ? "دعوة أعضاء"
                : "Invite Members",
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.info_outline, color: AppColors.teal),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GroupSettingsPage(group: widget.group),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMemoryPrompt() {
    return StreamBuilder<QuerySnapshot>(
      stream: _finishedOutingsStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        final doc = snapshot.data!.docs.first;
        final session = OutingSessionModel.fromFirestore(
          doc as DocumentSnapshot<Map<String, dynamic>>,
        );

        if (session.finishedAt == null) return const SizedBox.shrink();

        final diff = DateTime.now().difference(session.finishedAt!);
        if (diff.inHours >= 24) {
          // Trigger finalization if needed (lazy cleanup)
          OutingService().finalizeAndArchive(session);
          return const SizedBox.shrink();
        }

        final hoursLeft = 24 - diff.inHours;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.teal, AppColors.tealLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.teal.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Add Memories! 📸",
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      "Ends in $hoursLeft hours",
                      style: GoogleFonts.inter(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          OutingMemoryUploadScreen(session: session),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.teal,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                child: Text(
                  "Upload",
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ).animate().fadeIn().slideY(begin: -0.2);
      },
    );
  }

  void _showShareSheet(BuildContext context) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => GroupShareSheet(group: widget.group),
    );
  }

  Widget _buildInputBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.getSurfaceElevated(context),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppColors.getShadow(context).withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_selectedImages.isNotEmpty) _buildSelectedImagesPreview(),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (!_isRecording) ...[
                    CompositedTransformTarget(
                      link: _attachmentMenuLink,
                      child: IconButton(
                        onPressed: _showAttachmentMenu,
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.teal.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.add_rounded,
                            color: AppColors.teal,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        constraints: const BoxConstraints(
                          minHeight: 40,
                          maxHeight: 120,
                        ),
                        child: TextField(
                          controller: _messageController,
                          textAlign: AppLocalizations.of(context)?.isAr == true
                              ? TextAlign.right
                              : TextAlign.left,
                          maxLines: null,
                          textInputAction: TextInputAction.newline,
                          onChanged: (val) => setState(() {}),
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            color: AppColors.darkSlate,
                          ),
                          decoration: InputDecoration(
                            hintText: AppLocalizations.of(context)?.isAr == true
                                ? "...اكتب رسالة"
                                : "Type a message...",
                            hintStyle: GoogleFonts.inter(
                              color: Colors.grey.shade400,
                              fontSize: 15,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 8,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    // Recording State UI
                    Expanded(
                      child: Container(
                        height: 44,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            // Blinking Dot
                            Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                )
                                .animate(onPlay: (c) => c.repeat(reverse: true))
                                .scale(
                                  begin: const Offset(0.8, 0.8),
                                  end: const Offset(1.2, 1.2),
                                  duration: 600.ms,
                                )
                                .fadeOut(duration: 600.ms),
                            const SizedBox(width: 8),
                            Text(
                              _elapsedTime,
                              style: GoogleFonts.inter(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Waveform
                            Flexible(child: _buildWaveform()),
                            const SizedBox(width: 8),
                            if (_isLocked)
                              TextButton(
                                onPressed: () {
                                  HapticFeedback.mediumImpact();
                                  setState(() => _isCanceling = true);
                                  _stopRecording();
                                },
                                child: Text(
                                  "Discard",
                                  style: GoogleFonts.inter(
                                    color: Colors.red,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              )
                            else ...[
                              Text(
                                _isCanceling
                                    ? "Release to cancel"
                                    : "Slide to cancel",
                                style: GoogleFonts.inter(
                                  color: Colors.grey,
                                  fontSize: 13,
                                ),
                              ).animate().fadeIn().shimmer(duration: 2.seconds),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.chevron_left,
                                color: Colors.grey,
                                size: 16,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(width: 12),

                  // Send / Record Button
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      GestureDetector(
                        onLongPressDown: (details) {
                          _recordingStartPos = details.globalPosition;
                        },
                        onLongPressStart: (_) {
                          if (_messageController.text.trim().isEmpty) {
                            _startRecording();
                          }
                        },
                        onLongPressEnd: (_) {
                          if (_isRecording && !_isLocked) {
                            _stopRecording();
                          }
                        },
                        onLongPressMoveUpdate: (details) {
                          if (_isRecording &&
                              !_isLocked &&
                              _recordingStartPos != null) {
                            final deltaX =
                                details.globalPosition.dx -
                                _recordingStartPos!.dx;
                            final deltaY =
                                details.globalPosition.dy -
                                _recordingStartPos!.dy;

                            // Slide to Cancel (Horizontal - Left)
                            if (deltaX < -100) {
                              if (!_isCanceling) {
                                setState(() => _isCanceling = true);
                                HapticFeedback.heavyImpact();
                              }
                            } else {
                              if (_isCanceling) {
                                setState(() => _isCanceling = false);
                              }
                            }

                            // Slide to Lock (Vertical - Up)
                            final duration = DateTime.now().difference(
                              _recordStartTime ?? DateTime.now(),
                            );
                            if (duration.inMilliseconds > 600 &&
                                deltaY < -100 &&
                                deltaX.abs() < 50) {
                              setState(() => _isLocked = true);
                              HapticFeedback.heavyImpact();
                              debugPrint("🔒 Voice Recording Locked");
                            }
                          }
                        },
                        onTap: () {
                          if (_messageController.text.trim().isNotEmpty ||
                              _selectedImages.isNotEmpty) {
                            _sendMessage();
                          } else if (_isLocked) {
                            HapticFeedback.mediumImpact();
                            _stopRecording();
                          }
                        },
                        child: Container(
                          width: 48,
                          height: 48,
                          margin: const EdgeInsets.only(bottom: 2),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: _isCanceling
                                  ? [Colors.red.shade400, Colors.red.shade700]
                                  : AppColors.tealGradient,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color:
                                    (_isCanceling ? Colors.red : AppColors.teal)
                                        .withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            (_messageController.text.trim().isNotEmpty ||
                                    _selectedImages.isNotEmpty)
                                ? Icons.send_rounded
                                : (_isLocked
                                      ? Icons.send_rounded
                                      : Icons.mic_rounded),
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                      if (_isRecording && !_isLocked && !_isCanceling)
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 60,
                          child: Column(
                            children: [
                              const Icon(
                                    Icons.lock_outline_rounded,
                                    color: Colors.grey,
                                    size: 20,
                                  )
                                  .animate(onPlay: (c) => c.repeat())
                                  .moveY(
                                    begin: 0,
                                    end: -10,
                                    duration: 1.seconds,
                                    curve: Curves.easeInOut,
                                  )
                                  .fadeIn(duration: 500.ms)
                                  .then()
                                  .fadeOut(duration: 500.ms),
                              const SizedBox(height: 4),
                              const Icon(
                                Icons.keyboard_arrow_up_rounded,
                                color: Colors.grey,
                                size: 16,
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
      ),
    );
  }

  Widget _buildWaveform() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_amplitudes.length, (index) {
        final amp = _amplitudes[index];
        return AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          width: 3,
          height: 4 + (amp * 30), // Min height 4, max 34
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.6),
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }

  Widget _buildEmptyChat() {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 20,
                ),
              ],
            ),
            child: const Icon(
              Icons.forum_outlined,
              size: 60,
              color: AppColors.teal,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.noMessagesYet,
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.darkSlate,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.sayHello,
            style: GoogleFonts.inter(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  final String groupId;
  final bool isMe;
  final VoidCallback onLongPress;
  final Function(String) onReplyTap;
  final bool isHighlighted;
  final Map<String, String> memberPhotos;
  final Map<String, String> memberNames;
  final int totalMembers;
  final ValueNotifier<String?> activeAudioIdNotifier;
  final Function(String) onPlayNextVoice;
  final VoidCallback onReactionTap;

  const _MessageBubble({
    required this.message,
    required this.groupId,
    required this.isMe,
    required this.onLongPress,
    required this.onReplyTap,
    this.isHighlighted = false,
    required this.memberPhotos,
    required this.memberNames,
    required this.totalMembers,
    required this.activeAudioIdNotifier,
    required this.onPlayNextVoice,
    required this.onReactionTap,
  });

  String _formatTime(BuildContext context, DateTime time) {
    final isAr = AppLocalizations.of(context)?.isAr == true;
    final formattedTime = intl.DateFormat('hh:mm a').format(time);
    if (isAr) {
      return formattedTime.replaceAll('AM', 'ص').replaceAll('PM', 'م');
    }
    return formattedTime;
  }

  @override
  Widget build(BuildContext context) {
    if (message.isDeleted) {
      return _buildDeletedMessage(context);
    }

    final ambientDirection = Directionality.of(context);

    Widget messageContent = Dismissible(
      key: Key("reply-${message.id}"),
      direction: DismissDirection.startToEnd,
      confirmDismiss: (direction) async {
        final state = context.findAncestorStateOfType<_ChatPageState>();
        if (state != null) {
          state._onReply(message);
        }
        return false;
      },
      background: Container(
        padding: const EdgeInsets.only(left: 20),
        alignment: Alignment.centerLeft,
        child: const Icon(Icons.reply_rounded, color: AppColors.teal, size: 24),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            mainAxisAlignment: isMe
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isMe) ...[_buildAvatar(), const SizedBox(width: 8)],
              Flexible(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    GestureDetector(
                      onLongPress: onLongPress,
                      child: Column(
                        crossAxisAlignment: isMe
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        children: [
                          Container(
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.7,
                            ),
                            decoration: message.type == 'outing'
                                ? null
                                : BoxDecoration(
                                    color: isMe
                                        ? null
                                        : AppColors.getChatBubbleOther(context),
                                    gradient: isMe
                                        ? const LinearGradient(
                                            colors: AppColors.tealGradient,
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          )
                                        : null,
                                    borderRadius: BorderRadius.only(
                                      topLeft: const Radius.circular(16),
                                      topRight: const Radius.circular(16),
                                      bottomLeft: Radius.circular(
                                        isMe ? 16 : 0,
                                      ),
                                      bottomRight: Radius.circular(
                                        isMe ? 0 : 16,
                                      ),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.04,
                                        ),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                            padding: message.type == 'outing'
                                ? EdgeInsets.zero
                                : message.type == 'image'
                                ? const EdgeInsets.all(2)
                                : const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                            child: Directionality(
                              textDirection: ambientDirection,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (message.replyToId != null) ...[
                                    GestureDetector(
                                      onTap: () =>
                                          onReplyTap(message.replyToId!),
                                      child: Container(
                                        margin: const EdgeInsets.only(
                                          bottom: 8,
                                        ),
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: isMe
                                              ? Colors.white.withValues(
                                                  alpha: 0.1,
                                                )
                                              : AppColors.getSurface(context),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border(
                                            left: BorderSide(
                                              color: isMe
                                                  ? Colors.white
                                                  : AppColors.teal,
                                              width: 3,
                                            ),
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              memberNames[message
                                                      .replyToSenderId] ??
                                                  message.replyToSenderName ??
                                                  "Friend",
                                              style: GoogleFonts.outfit(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: isMe
                                                    ? Colors.white
                                                    : AppColors.teal,
                                              ),
                                            ),
                                            Text(
                                              message.replyToText ?? "",
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.inter(
                                                fontSize: 11,
                                                color: isMe
                                                    ? Colors.white70
                                                    : AppColors.getTextSecondary(
                                                        context,
                                                      ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                  if (!isMe) ...[
                                    Text(
                                      memberNames[message.senderId] ??
                                          message.senderName,
                                      style: GoogleFonts.outfit(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.teal,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                  ],
                                  if (message.type == 'image') ...[
                                    _buildWhatsAppImage(context, message, isMe),
                                  ] else if (message.type == 'location') ...[
                                    _buildLocationBubble(),
                                    const SizedBox(height: 8),
                                  ] else if (message.type == 'outing') ...[
                                    OutingMessageBubble(
                                      message: message,
                                      groupId: groupId,
                                      isMe: isMe,
                                    ),
                                    const SizedBox(height: 8),
                                  ] else if (message.type == 'audio') ...[
                                    VoiceMessageBubble(
                                      message: message,
                                      isMe: isMe,
                                      activeAudioIdNotifier:
                                          activeAudioIdNotifier,
                                      onComplete: () =>
                                          onPlayNextVoice(message.id),
                                    ),
                                  ] else if (message.text.contains("SOS!") ||
                                      message.text.contains(
                                        "Location: https://",
                                      ) ||
                                      (message.senderName ==
                                          "🚨 EMERGENCY")) ...[
                                    _buildSosLocationBubble(context, message),
                                  ] else ...[
                                    Text(
                                      message.text,
                                      style: GoogleFonts.inter(
                                        fontSize: 15,
                                        color: isMe
                                            ? Colors.white
                                            : AppColors.getTextPrimary(context),
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                  if (message.type != 'image')
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (message.isEdited)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              right: 4,
                                            ),
                                            child: Text(
                                              "edited",
                                              style: GoogleFonts.inter(
                                                fontSize: 9,
                                                fontStyle: FontStyle.italic,
                                                color:
                                                    (isMe &&
                                                        message.type !=
                                                            'outing')
                                                    ? Colors.white70
                                                    : AppColors.getTextMuted(
                                                        context,
                                                      ),
                                              ),
                                            ),
                                          ),
                                        Text(
                                          _formatTime(
                                            context,
                                            message.timestamp,
                                          ),
                                          style: GoogleFonts.inter(
                                            fontSize: 10,
                                            color:
                                                (isMe &&
                                                    message.type != 'outing')
                                                ? Colors.white70
                                                : AppColors.getTextMuted(
                                                    context,
                                                  ),
                                          ),
                                        ),
                                        if (isMe) ...[
                                          const SizedBox(width: 4),
                                          _buildTicks(message),
                                        ],
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 🛡️ WhatsApp Style Overlapping Reactions
                    if (message.reactions.isNotEmpty)
                      Positioned(
                        bottom: -14, // Lowered for better overlap
                        right: isMe ? 4 : null,
                        left: !isMe ? 4 : null,
                        child: GestureDetector(
                          onTap: onReactionTap,
                          child: Directionality(
                            textDirection: ambientDirection,
                            child: Wrap(
                              spacing: 2,
                              children: message.reactions.entries.map((entry) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFFF0F2F5,
                                    ), // Light gray background
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.1,
                                        ),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        entry.key,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                      if (entry.value.length > 1)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            left: 2,
                                          ),
                                          child: Text(
                                            "${entry.value.length}",
                                            style: GoogleFonts.inter(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey.shade700,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (isHighlighted) {
      return messageContent.animate().shimmer(
        color: AppColors.teal.withOpacity(0.3),
        duration: 1000.ms,
      );
    }

    return messageContent;
  }

  bool _isValidImageUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    return url.startsWith('http');
  }

  Widget _buildWhatsAppImage(
    BuildContext context,
    MessageModel message,
    bool isMe,
  ) {
    final urls = message.mediaUrls.isNotEmpty
        ? message.mediaUrls
        : [message.text];

    final bool hasCaption =
        message.text.isNotEmpty &&
        !message.text.startsWith('http') &&
        urls.contains(message.text) == false;

    return Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: 1, // Constant square aspect ratio
                      child: _buildMediaGrid(context, urls),
                    ),
                    if (!hasCaption) ...[
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.3),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 8,
                        right: 12,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _formatTime(context, message.timestamp),
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                            if (isMe) ...[
                              const SizedBox(width: 4),
                              _buildTicks(message, color: Colors.white),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (hasCaption) ...[
                Padding(
                  padding: const EdgeInsets.only(
                    left: 12,
                    right: 12,
                    top: 8,
                    bottom: 4,
                  ),
                  child: Text(
                    message.text,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: isMe ? Colors.white : AppColors.darkSlate,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 12, bottom: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        _formatTime(context, message.timestamp),
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: isMe ? Colors.white70 : Colors.grey.shade600,
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        _buildTicks(
                          message,
                          color: isMe ? Colors.white70 : Colors.grey.shade600,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        )
        .animate()
        .scale(
          begin: const Offset(0.8, 0.8),
          end: const Offset(1.0, 1.0),
          duration: 400.ms,
          curve: Curves.easeOutBack,
        )
        .fadeIn(duration: 400.ms);
  }

  Widget _buildMediaGrid(BuildContext context, List<String> urls) {
    if (urls.length == 1) {
      return _buildImageItem(context, urls[0], index: 0, total: 1);
    }

    if (urls.length == 2) {
      return Row(
        children: [
          Expanded(
            child: _buildImageItem(context, urls[0], index: 0, total: 2),
          ),
          const SizedBox(width: 2),
          Expanded(
            child: _buildImageItem(context, urls[1], index: 1, total: 2),
          ),
        ],
      );
    }

    if (urls.length == 3) {
      return Row(
        children: [
          Expanded(
            child: _buildImageItem(context, urls[0], index: 0, total: 3),
          ),
          const SizedBox(width: 2),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: _buildImageItem(context, urls[1], index: 1, total: 3),
                ),
                const SizedBox(height: 2),
                Expanded(
                  child: _buildImageItem(context, urls[2], index: 2, total: 3),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // Standard WhatsApp-style 2-column grid
    return GridView.builder(
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
        childAspectRatio: 1,
      ),
      itemCount: urls.length > 4 ? 4 : urls.length,
      itemBuilder: (context, index) {
        if (index == 3 && urls.length > 4) {
          return Stack(
            fit: StackFit.expand,
            children: [
              _buildImageItem(
                context,
                urls[index],
                index: index,
                total: urls.length,
              ),
              Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: Text(
                    "+${urls.length - 3}",
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          );
        }
        return _buildImageItem(
          context,
          urls[index],
          index: index,
          total: urls.length,
        );
      },
    );
  }

  Widget _buildImageItem(
    BuildContext context,
    String url, {
    required int index,
    required int total,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FullScreenImagePage(
              imageUrl: url,
              allImages: message.mediaUrls.isNotEmpty
                  ? message.mediaUrls
                  : [message.text],
              initialIndex: index,
              senderName: message.senderName,
              timestamp: message.timestamp,
            ),
          ),
        );
      },
      child: _isValidImageUrl(url)
          ? CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              placeholder: (context, url) => Container(
                color: Colors.grey.shade100,
                child: const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.teal,
                  ),
                ),
              ),
              errorWidget: (context, url, error) => _buildImageError(),
            )
          : _buildImageError(),
    );
  }

  Widget _buildTicks(MessageModel message, {Color? color}) {
    final isReadByAll =
        message.readBy.length >= (totalMembers - 1) && totalMembers > 1;
    final isAnyRead = message.readBy.isNotEmpty;
    final bool onTeal = isMe && message.type != 'outing';

    if (color != null) {
      return Icon(
        isAnyRead ? Icons.done_all_rounded : Icons.done_rounded,
        size: 14,
        color: color,
      );
    }

    if (isReadByAll) {
      return const Icon(Icons.done_all_rounded, size: 14, color: Colors.blue);
    } else if (isAnyRead) {
      return Icon(
        Icons.done_all_rounded,
        size: 14,
        color: onTeal ? Colors.white70 : Colors.grey.shade400,
      );
    } else {
      return Icon(
        Icons.done_rounded,
        size: 14,
        color: onTeal ? Colors.white70 : Colors.grey.shade400,
      );
    }
  }

  Widget _buildAvatar() {
    final photoUrl = memberPhotos[message.senderId] ?? message.senderPhotoUrl;

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: _isValidImageUrl(photoUrl)
            ? CachedNetworkImage(
                imageUrl: photoUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                    _buildInitialsAvatar(isLoading: true),
                errorWidget: (context, url, error) => _buildInitialsAvatar(),
              )
            : _buildInitialsAvatar(),
      ),
    );
  }

  Widget _buildImageError() {
    return Container(
      height: 200,
      width: double.infinity,
      color: Colors.grey.shade100,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported_outlined,
            color: Colors.grey.shade400,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            "Image not ready",
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialsAvatar({bool isLoading = false}) {
    final displayName = memberNames[message.senderId] ?? message.senderName;
    final initials = displayName.trim().isNotEmpty
        ? displayName
              .trim()
              .split(' ')
              .where((e) => e.isNotEmpty)
              .map((e) => e[0])
              .take(2)
              .join()
              .toUpperCase()
        : '?';

    return Container(
      color: AppColors.teal.withOpacity(isLoading ? 0.04 : 0.08),
      alignment: Alignment.center,
      child: isLoading
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.teal,
              ),
            )
          : Text(
              initials,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.teal,
              ),
            ),
    );
  }

  Widget _buildSosLocationBubble(BuildContext context, MessageModel message) {
    final l10n = AppLocalizations.of(context)!;
    // 🚨 Intercept SOS / Google Maps links to create a gorgeous map/SOS card
    final hasSos =
        message.text.contains("SOS!") || (message.senderName == "🚨 EMERGENCY");
    final urlRegex = RegExp(r'(https?://[^\s]+)');
    final match = urlRegex.firstMatch(message.text);
    final link = match?.group(0);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: hasSos
            ? (AppColors.isDark(context)
                  ? Colors.red.withValues(alpha: 0.15)
                  : Colors.red.shade50)
            : (AppColors.isDark(context)
                  ? Colors.blue.withValues(alpha: 0.15)
                  : Colors.blue.shade50),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasSos
              ? (AppColors.isDark(context)
                    ? Colors.red.shade800
                    : Colors.red.shade300)
              : (AppColors.isDark(context)
                    ? Colors.blue.shade800
                    : Colors.blue.shade300),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasSos ? Icons.emergency_rounded : Icons.location_on_rounded,
                color: hasSos ? Colors.red : Colors.blue,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  hasSos ? l10n.emergencyLabel : l10n.sharedLocationLabel,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: hasSos
                        ? (AppColors.isDark(context)
                              ? Colors.red.shade200
                              : Colors.red.shade900)
                        : (AppColors.isDark(context)
                              ? Colors.blue.shade200
                              : Colors.blue.shade900),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            message.text.replaceAll(link ?? '', '').trim(),
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.getTextPrimary(context),
              height: 1.3,
            ),
          ),
          if (link != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final uri = Uri.parse(link);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                icon: const Icon(
                  Icons.map_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                label: Text(
                  l10n.openInGoogleMaps,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: hasSos
                      ? Colors.red.shade700
                      : Colors.blue.shade700,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLocationBubble() {
    final geo = message.text.replaceFirst('geo:', '').split(',');
    final latVal = double.tryParse(geo.isNotEmpty ? geo[0] : '0') ?? 0.0;
    final lngVal = double.tryParse(geo.length > 1 ? geo[1] : '0') ?? 0.0;
    final lat = geo.isNotEmpty ? geo[0] : '0.0';
    final long = geo.length > 1 ? geo[1] : '0.0';
    final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
    final target = gmaps.LatLng(latVal, lngVal);

    return FutureBuilder<String>(
      future: _getAddress(lat, long, apiKey),
      builder: (context, snapshot) {
        final address = snapshot.data ?? "Shared Location";

        return GestureDetector(
          onTap: () => _openMap(lat, long),
          child: Container(
            width: 260,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: AppColors.getSurfaceElevated(context),
              boxShadow: [
                BoxShadow(
                  color: AppColors.getShadow(context).withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Real Google Map preview
                  SizedBox(
                    height: 150,
                    child: IgnorePointer(
                      child: gmaps.GoogleMap(
                        initialCameraPosition: gmaps.CameraPosition(
                          target: target,
                          zoom: 15,
                        ),
                        markers: {
                          gmaps.Marker(
                            markerId: const gmaps.MarkerId('loc'),
                            position: target,
                          ),
                        },
                        zoomControlsEnabled: false,
                        myLocationButtonEnabled: false,
                        mapToolbarEnabled: false,
                        compassEnabled: false,
                        tiltGesturesEnabled: false,
                        rotateGesturesEnabled: false,
                        scrollGesturesEnabled: false,
                        zoomGesturesEnabled: false,
                      ),
                    ),
                  ),
                  // Divider line
                  Container(height: 1, color: AppColors.getDivider(context)),
                  // Address footer
                  Container(
                    color: AppColors.getSurfaceElevated(context),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: Colors.redAccent,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                address,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.getTextPrimary(context),
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                AppLocalizations.of(context)?.tapToOpenInMaps ??
                                    'Tap to open in Maps',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: AppColors.getTextSecondary(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          color: Colors.grey,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<String> _getAddress(String lat, String long, String apiKey) async {
    try {
      final url =
          "https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$long&key=$apiKey";
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          return data['results'][0]['formatted_address'];
        }
      }
      return "Location at $lat, $long";
    } catch (_) {
      return "Location Details";
    }
  }

  void _openMap(String lat, String long) async {
    final url = 'https://www.google.com/maps/search/?api=1&query=$lat,$long';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildDeletedMessage(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12, top: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.withOpacity(0.15)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.block, size: 14, color: Colors.grey.shade400),
            const SizedBox(width: 8),
            Text(
              AppLocalizations.of(context)?.isAr == true
                  ? (isMe ? "لقد قمت بحذف هذه الرسالة" : "تم حذف هذه الرسالة")
                  : (isMe
                        ? "You deleted this message"
                        : "This message was deleted"),
              style: GoogleFonts.inter(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageOptionsSheet extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final Function(String) onReaction;
  final VoidCallback onEdit;
  final Function(bool) onDelete;
  final VoidCallback onInfo;

  const _MessageOptionsSheet({
    required this.message,
    required this.isMe,
    required this.onReaction,
    required this.onEdit,
    required this.onDelete,
    required this.onInfo,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final List<String> popularEmojis = [
      "❤️",
      "👍",
      "😂",
      "😮",
      "😢",
      "🔥",
      "👏",
      "🙌",
      "🎉",
      "✨",
      "💯",
      "🙏",
      "🤩",
      "🤔",
      "👀",
      "🚀",
      "💡",
      "✅",
    ];
    final now = DateTime.now();
    final canDeleteForEveryone =
        isMe && now.difference(message.timestamp).inHours < 1;

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(30),
        topRight: Radius.circular(30),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.8),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Reactions Grid
                SizedBox(
                  height: 120,
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 6,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                        ),
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: popularEmojis.length,
                    itemBuilder: (context, index) {
                      final emoji = popularEmojis[index];
                      final isSelected =
                          message.reactions[emoji]?.contains(
                            FirebaseAuth.instance.currentUser?.uid,
                          ) ??
                          false;
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          onReaction(emoji);
                        },
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.teal.withOpacity(0.15)
                                : Colors.white.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.teal.withOpacity(0.3)
                                  : Colors.transparent,
                            ),
                          ),
                          child: Text(
                            emoji,
                            style: const TextStyle(fontSize: 22),
                          ),
                        ),
                      ).animate().scale(
                        delay: (index * 20).ms,
                        duration: 200.ms,
                        curve: Curves.easeOutBack,
                      );
                    },
                  ),
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Divider(height: 1),
                ),

                // Actions
                Column(
                  children:
                      [
                            if (isMe)
                              _buildActionItem(
                                icon: Icons.edit_rounded,
                                title: l10n.editMessage,
                                onTap: onEdit,
                              ),
                            if (isMe)
                              _buildActionItem(
                                icon: Icons.info_rounded,
                                title: l10n.messageInfo,
                                onTap: onInfo,
                              ),
                            if (isMe)
                              _buildActionItem(
                                icon: Icons.delete_sweep_rounded,
                                title: l10n.deleteForEveryone,
                                color: canDeleteForEveryone
                                    ? Colors.redAccent
                                    : Colors.grey,
                                onTap: canDeleteForEveryone
                                    ? () async {
                                        final bool?
                                        confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            title: Text(
                                              l10n.deleteForEveryoneTitle,
                                              style: GoogleFonts.outfit(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            content: Text(
                                              l10n.deleteForEveryoneContent,
                                              style: GoogleFonts.inter(),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(ctx, false),
                                                child: Text(
                                                  l10n.cancel,
                                                  style: GoogleFonts.inter(
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                              ),
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(ctx, true),
                                                child: Text(
                                                  l10n.deleteAction,
                                                  style: GoogleFonts.inter(
                                                    color: Colors.redAccent,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (confirm == true) {
                                          onDelete(true);
                                        }
                                      }
                                    : null,
                                subtitle: canDeleteForEveryone
                                    ? l10n.permanentRemoval
                                    : (AppLocalizations.of(context)?.isAr ==
                                              true
                                          ? "انتهى الوقت (ساعة واحدة)"
                                          : "Timed out (1h)"),
                              ),
                            _buildActionItem(
                              icon: Icons.delete_outline_rounded,
                              title: l10n.deleteForMe,
                              color: Colors.redAccent,
                              onTap: () => onDelete(false),
                            ),
                          ]
                          .animate(interval: 50.ms)
                          .fadeIn(duration: 300.ms)
                          .slideX(begin: 0.1, end: 0),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required String title,
    required VoidCallback? onTap,
    Color? color,
    String? subtitle,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppColors.darkSlate),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w500,
          color: color ?? AppColors.darkSlate,
        ),
      ),
      subtitle: subtitle != null
          ? Text(subtitle, style: const TextStyle(fontSize: 10))
          : null,
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      enabled: onTap != null,
    );
  }
}

class _MessageInfoSheet extends StatelessWidget {
  final MessageModel message;
  final GroupModel group;
  final Map<String, String> memberNames;
  final Map<String, String> memberPhotos;

  const _MessageInfoSheet({
    required this.message,
    required this.group,
    required this.memberNames,
    required this.memberPhotos,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(30),
        topRight: Radius.circular(30),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.85),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.messageInfo,
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkSlate,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.grey),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.teal.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.teal.withOpacity(0.1)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.done_all_rounded,
                        color: AppColors.teal,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.readBy,
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.teal,
                              ),
                            ),
                            Text(
                              "${message.readBy.length} ${l10n.membersLabel}",
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn().slideY(begin: 0.2, end: 0),
                const SizedBox(height: 20),
                if (message.readBy.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text(
                        l10n.noOneReadYet,
                        style: GoogleFonts.inter(
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  )
                else
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.3,
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: message.readBy.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final uid = message.readBy[index];
                        final isMe =
                            uid == FirebaseAuth.instance.currentUser?.uid;
                        final photoUrl = memberPhotos[uid];

                        return Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.grey.withOpacity(0.1),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(18),
                                    child:
                                        photoUrl != null &&
                                            photoUrl.startsWith('http')
                                        ? CachedNetworkImage(
                                            imageUrl: photoUrl,
                                            fit: BoxFit.cover,
                                            placeholder: (context, url) =>
                                                const Icon(
                                                  Icons.person_outline_rounded,
                                                  size: 20,
                                                  color: Colors.grey,
                                                ),
                                            errorWidget:
                                                (
                                                  context,
                                                  url,
                                                  error,
                                                ) => const Icon(
                                                  Icons.person_outline_rounded,
                                                  size: 20,
                                                  color: Colors.grey,
                                                ),
                                          )
                                        : Icon(
                                            isMe
                                                ? Icons.person_rounded
                                                : Icons.person_outline_rounded,
                                            size: 20,
                                            color: isMe
                                                ? AppColors.teal
                                                : Colors.grey,
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    isMe
                                        ? "You"
                                        : (memberNames[uid] ?? "Member ($uid)"),
                                    style: GoogleFonts.inter(
                                      fontSize: 15,
                                      fontWeight: isMe
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: AppColors.darkSlate,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.done_all_rounded,
                                  size: 16,
                                  color: AppColors.teal,
                                ),
                              ],
                            )
                            .animate(delay: (index * 50).ms)
                            .fadeIn()
                            .slideX(begin: 0.1, end: 0);
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DateDivider extends StatelessWidget {
  final String dateLabel;

  const _DateDivider({required this.dateLabel});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 24),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.getSurface(context),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: AppColors.getShadow(context).withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          dateLabel,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.getTextSecondary(context),
          ),
        ),
      ),
    );
  }
}

class _UnreadDivider extends StatelessWidget {
  const _UnreadDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        children: [
          const Expanded(child: Divider(color: Colors.black12, thickness: 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.getSurface(context),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.getShadow(context).withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                "Unread Messages",
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.teal,
                ),
              ),
            ),
          ),
          const Expanded(child: Divider(color: Colors.black12, thickness: 1)),
        ],
      ),
    );
  }
}

class FullScreenImagePage extends StatefulWidget {
  final String imageUrl;
  final List<String> allImages;
  final List<Map<String, dynamic>>?
  allMetadata; // Optional: metadata for each image
  final int initialIndex;
  final String senderName;
  final DateTime timestamp;

  const FullScreenImagePage({
    super.key,
    required this.imageUrl,
    this.allImages = const [],
    this.allMetadata,
    this.initialIndex = 0,
    required this.senderName,
    required this.timestamp,
  });

  @override
  State<FullScreenImagePage> createState() => _FullScreenImagePageState();
}

class _FullScreenImagePageState extends State<FullScreenImagePage> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.allImages.isNotEmpty ? widget.initialIndex : 0;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.allImages.isNotEmpty
        ? widget.allImages
        : [widget.imageUrl];

    // Determine dynamic metadata if available
    String currentSender = widget.senderName;
    DateTime currentTime = widget.timestamp;

    if (widget.allMetadata != null &&
        _currentIndex < widget.allMetadata!.length) {
      final meta = widget.allMetadata![_currentIndex];
      currentSender = meta['senderName'] ?? currentSender;
      currentTime = (meta['timestamp'] as Timestamp).toDate();
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.8),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              currentSender,
              style: GoogleFonts.outfit(color: Colors.white, fontSize: 16),
            ),
            Text(
              intl.DateFormat('MMM d, hh:mm a').format(currentTime),
              style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
        actions: [
          if (images.length > 1)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text(
                  "${_currentIndex + 1} / ${images.length}",
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: images.length,
        onPageChanged: (index) => setState(() => _currentIndex = index),
        itemBuilder: (context, index) {
          return Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: CachedNetworkImage(
                imageUrl: images[index],
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(color: AppColors.teal),
                ),
                errorWidget: (context, url, error) =>
                    const Icon(Icons.error, color: Colors.white),
              ),
            ),
          );
        },
      ),
    );
  }
}
