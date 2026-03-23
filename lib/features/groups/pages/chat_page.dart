import 'package:flutter/material.dart';
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
import '../../../core/theme/colors.dart';
import '../data/models/group_model.dart';
import '../data/models/message_model.dart';
import '../data/services/chat_service.dart';
import '../widgets/group_share_sheet.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'group_settings_page.dart';

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
  final Map<String, String> _memberPhotos = {};
  final Map<String, String> _memberNames = {};
  bool _isFetchingMembers = false;
  late Stream<List<MessageModel>> _messagesStream;
  OverlayEntry? _attachmentMenuEntry;
  final LayerLink _attachmentMenuLink = LayerLink();
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _messagesStream = _chatService.getMessagesStream(widget.group.id);
    _fetchMemberDetails();
  }

  Future<void> _fetchMemberDetails() async {
    if (_isFetchingMembers) return;
    setState(() => _isFetchingMembers = true);
    
    final Map<String, String> newPhotos = {};
    final Map<String, String> newNames = {};

    try {
      final futures = widget.group.memberIds.map((uid) async {
        final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          final photoUrl = data['photoUrl'] ?? data['profilePic'];
          final name = data['name'] ?? data['fullName'] ?? "User";
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

  MessageModel? _editingMessage;
  final currentUser = FirebaseAuth.instance.currentUser;

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    if (_editingMessage != null) {
      _chatService.editMessage(
        widget.group.id,
        _editingMessage!.id,
        _messageController.text.trim(),
      );
      setState(() {
        _editingMessage = null;
        _messageController.clear();
      });
    } else {
      // Use the latest cached name/photo if available, fallback to Auth profile
      final displayName = _memberNames[currentUser?.uid] ?? currentUser?.displayName ?? 'User';
      final photoUrl = _memberPhotos[currentUser?.uid] ?? currentUser?.photoURL;

      _chatService.sendMessage(
        groupId: widget.group.id,
        senderId: currentUser?.uid ?? '',
        senderName: displayName,
        senderPhotoUrl: photoUrl,
        text: _messageController.text.trim(),
      );
      _messageController.clear();
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    }
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
            _chatService.removeReaction(widget.group.id, message.id, myId, emoji);
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
            await _chatService.deleteMessage(widget.group.id, message.id, forEveryone: forEveryone);
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(e.toString())),
              );
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
      builder: (context) => _MessageInfoSheet(message: message, group: widget.group),
    );
  }

  @override
  void dispose() {
    _closeAttachmentMenu();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _closeAttachmentMenu() {
    _attachmentMenuEntry?.remove();
    _attachmentMenuEntry = null;
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
              offset: const Offset(0, -320), // Positioned with perfect breathing room
              child: Material(
                color: Colors.transparent,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                          ),
                        ],
                      ),
                      child: Directionality(
                        textDirection: TextDirection.ltr,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(height: 12),
                            _buildMenuItem(
                              icon: Icons.camera_alt_rounded,
                              label: "Camera",
                              color: Colors.teal,
                              onTap: () {
                                _closeAttachmentMenu();
                                _handleImageSelection(ImageSource.camera);
                              },
                            ),
                            _buildMenuItem(
                              icon: Icons.image_rounded,
                              label: "Gallery",
                              color: Colors.indigo,
                              onTap: () {
                                _closeAttachmentMenu();
                                _handleImageSelection(ImageSource.gallery);
                              },
                            ),
                            _buildMenuItem(
                              icon: Icons.location_on_rounded,
                              label: "Location",
                              color: Colors.amber.shade700,
                              onTap: () {
                                _closeAttachmentMenu();
                                _handleLocationSharing();
                              },
                            ),
                            const SizedBox(height: 16),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    _closeAttachmentMenu();
                                    // TODO: Implement Start Outing Session
                                  },
                                  icon: const Icon(Icons.flash_on_rounded, size: 18, color: Colors.white),
                                  label: const Text("Start Outing Session", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    minimumSize: const Size(double.infinity, 50),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
              ).animate().fadeIn(duration: 250.ms).scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack).slideY(begin: 0.1, end: 0),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_attachmentMenuEntry!);
  }

  Future<void> _handleImageSelection(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 70);

    if (pickedFile != null && mounted) {
      setState(() => _isUploading = true);
      try {
        final imageUrl = await _chatService.uploadImage(File(pickedFile.path), widget.group.id);
        await _chatService.sendMessage(
          groupId: widget.group.id,
          senderId: currentUser?.uid ?? '',
          senderName: currentUser?.displayName ?? 'User',
          senderPhotoUrl: currentUser?.photoURL,
          text: imageUrl,
          type: 'image',
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to send image: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _isUploading = false);
      }
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
          const SnackBar(content: Text('Location permissions are permanently denied.')),
        );
      }
      return;
    }

    setState(() => _isUploading = true);
    try {
      final position = await Geolocator.getCurrentPosition();
      await _chatService.sendMessage(
        groupId: widget.group.id,
        senderId: currentUser?.uid ?? '',
        senderName: currentUser?.displayName ?? 'User',
        senderPhotoUrl: currentUser?.photoURL,
        text: 'geo:${position.latitude},${position.longitude}',
        type: 'location',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to get location: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
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
                color: color.withValues(alpha: 0.1),
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
                color: AppColors.darkSlate.withValues(alpha: 0.9),
              ),
            ),
            const Spacer(),
            Icon(Icons.chevron_right_rounded, color: Colors.grey.withValues(alpha: 0.4), size: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5), 
      body: Stack(
        children: [
          Positioned.fill(
            child: Column(
              children: [
                _buildHeader(context),
          
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: _messagesStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.teal));
                }

                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.red)));
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return _buildEmptyChat();
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == currentUser?.uid;
                    
                    // Mark as read if not me and not already read
                    if (!isMe && !message.readBy.contains(currentUser?.uid)) {
                      _chatService.markAsRead(widget.group.id, message.id, currentUser?.uid ?? '');
                    }

                    return _MessageBubble(
                      message: message, 
                      isMe: isMe,
                      onLongPress: () => _onMessageLongPress(message),
                      memberPhotos: _memberPhotos,
                      memberNames: _memberNames,
                    );
                  },
                );
              },
            ),
          ),
          
          if (_editingMessage != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.teal.withValues(alpha: 0.1),
              child: Row(
                children: [
                  const Icon(Icons.edit, size: 16, color: AppColors.teal),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Editing: ${_editingMessage!.text}",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.teal),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16, color: AppColors.teal),
                    onPressed: () => setState(() {
                      _editingMessage = null;
                      _messageController.clear();
                    }),
                  ),
                ],
              ),
            ),
          
                _buildInputBar(),
              ],
            ),
          ),
          if (_isUploading)
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                child: Container(
                  color: Colors.white.withValues(alpha: 0.3),
                  child: const Center(
                    child: CircularProgressIndicator(color: AppColors.teal),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 8, bottom: 12, left: 8, right: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.1), width: 1.5),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 22, color: AppColors.darkSlate),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 4),
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.teal.withValues(alpha: 0.08),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
              image: widget.group.photoUrl != null
                  ? DecorationImage(image: NetworkImage(widget.group.photoUrl!), fit: BoxFit.cover)
                  : null,
            ),
            child: widget.group.photoUrl == null
                ? const Icon(Icons.groups_rounded, color: AppColors.teal, size: 26)
                : null,
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
                          color: AppColors.darkSlate,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        "${widget.group.memberIds.length} members",
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.share_rounded, color: AppColors.teal, size: 22),
                  onPressed: () => _showShareSheet(context),
                  tooltip: "Invite Members",
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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24), // Extra bottom padding for safe area
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.withValues(alpha: 0.1), width: 1.5),
        ),
      ),
      child: SafeArea(
        top: false,
        bottom: false,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              CompositedTransformTarget(
                link: _attachmentMenuLink,
                child: GestureDetector(
                  onTap: _showAttachmentMenu,
                  child: Container(
                    width: 44,
                    height: 44,
                    margin: const EdgeInsets.only(bottom: 2, right: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.add, color: Colors.grey.shade600, size: 28),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(minHeight: 48, maxHeight: 120),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: TextField(
                    controller: _messageController,
                    maxLines: null,
                    textInputAction: TextInputAction.newline,
                    decoration: InputDecoration(
                      hintText: "Type a message...",
                      hintStyle: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 15),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: _sendMessage,
                child: Container(
                  width: 48,
                  height: 48,
                  margin: const EdgeInsets.only(bottom: 2),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: AppColors.tealGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.teal.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.send_rounded, color: Colors.white, size: 22),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyChat() {
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
                BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20),
              ],
            ),
            child: const Icon(Icons.forum_outlined, size: 60, color: AppColors.teal),
          ),
          const SizedBox(height: 16),
          Text(
            "No messages yet",
            style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.darkSlate),
          ),
          const SizedBox(height: 8),
          Text(
            "Say hello to start the conversation!",
            style: GoogleFonts.inter(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final VoidCallback onLongPress;
  final Map<String, String> memberPhotos;
  final Map<String, String> memberNames;

  const _MessageBubble({
    required this.message, 
    required this.isMe,
    required this.onLongPress,
    required this.memberPhotos,
    required this.memberNames,
  });

  @override
  Widget build(BuildContext context) {
    if (message.isDeleted) {
      return _buildDeletedMessage();
    }

    // Capture the ambient directionality (e.g. Arabic RTL or English LTR)
    final ambientDirection = Directionality.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: Directionality(
        // Force the layout to be LTR so Me=Right, Others=Left regardless of app language
        textDirection: TextDirection.ltr,
        child: Row(
          mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Avatar for others
            if (!isMe) ...[
              _buildAvatar(),
              const SizedBox(width: 8),
            ],
            
            Flexible(
              child: GestureDetector(
                onLongPress: onLongPress,
                child: Column(
                  crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    // Message Bubble
                    Container(
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                      decoration: BoxDecoration(
                        color: isMe ? null : Colors.white,
                        gradient: isMe ? const LinearGradient(
                          colors: AppColors.tealGradient,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ) : null,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(16),
                          topRight: const Radius.circular(16),
                          bottomLeft: Radius.circular(isMe ? 16 : 0),
                          bottomRight: Radius.circular(isMe ? 0 : 16),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: Directionality(
                        // Restore the original directionality for the text content
                        textDirection: ambientDirection,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!isMe) ...[
                              Text(
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
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: CachedNetworkImage(
                                  imageUrl: message.text,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    height: 200,
                                    width: double.infinity,
                                    color: Colors.grey.shade100,
                                    child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.teal)),
                                  ),
                                  errorWidget: (context, url, error) => const Icon(Icons.error_outline),
                                ),
                              ),
                              const SizedBox(height: 8),
                            ] else if (message.type == 'location') ...[
                              _buildLocationBubble(),
                              const SizedBox(height: 8),
                            ] else ...[
                              Text(
                                message.text,
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  color: isMe ? Colors.white : AppColors.darkSlate,
                                  height: 1.4,
                                ),
                              ),
                            ],
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (message.isEdited)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 4),
                                    child: Text(
                                      "edited",
                                      style: GoogleFonts.inter(
                                        fontSize: 9,
                                        fontStyle: FontStyle.italic,
                                        color: isMe ? Colors.white70 : Colors.grey.shade400,
                                      ),
                                    ),
                                  ),
                                Text(
                                  intl.DateFormat('hh:mm a').format(message.timestamp),
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    color: isMe ? Colors.white70 : Colors.grey.shade400,
                                  ),
                                ),
                                if (isMe) ...[
                                  const SizedBox(width: 4),
                                  Icon(
                                    message.readBy.length > 1 ? Icons.done_all_rounded : Icons.done_rounded, 
                                    size: 14, 
                                    color: message.readBy.length > 1 ? Colors.white : Colors.white70,
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Reactions
                    if (message.reactions.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
                        child: Directionality(
                          textDirection: ambientDirection,
                          child: Wrap(
                            spacing: 4,
                            children: message.reactions.entries.map((entry) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
                                  boxShadow: [
                                    BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(entry.key, style: const TextStyle(fontSize: 12)),
                                    if (entry.value.length > 1)
                                      Padding(
                                        padding: const EdgeInsets.only(left: 2),
                                        child: Text(
                                          "${entry.value.length}",
                                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    // Try to get the latest photo from our local cache, fallback to the one stored in message
    final photoUrl = memberPhotos[message.senderId] ?? message.senderPhotoUrl;
    
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: photoUrl != null && photoUrl.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: photoUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => _buildInitialsAvatar(isLoading: true),
                errorWidget: (context, url, error) => _buildInitialsAvatar(),
              )
            : _buildInitialsAvatar(),
      ),
    );
  }

  Widget _buildInitialsAvatar({bool isLoading = false}) {
    // Try to get latest name from cache
    final displayName = memberNames[message.senderId] ?? message.senderName;
    final initials = displayName.isNotEmpty 
        ? displayName.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase()
        : '?';
    
    return Container(
      color: AppColors.teal.withValues(alpha: isLoading ? 0.04 : 0.08),
      alignment: Alignment.center,
      child: isLoading 
        ? const SizedBox(
            width: 14, 
            height: 14, 
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.teal)
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

  Widget _buildLocationBubble() {
    final geo = message.text.replaceFirst('geo:', '').split(',');
    final lat = geo[0];
    final long = geo[1];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isMe ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.teal.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.location_on_rounded, color: AppColors.teal, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Shared Location",
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isMe ? Colors.white : AppColors.darkSlate,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () async {
                final url = 'https://www.google.com/maps/search/?api=1&query=$lat,$long';
                if (await canLaunchUrl(Uri.parse(url))) {
                  await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                }
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: isMe ? Colors.white.withValues(alpha: 0.5) : AppColors.teal.withValues(alpha: 0.3)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                foregroundColor: isMe ? Colors.white : AppColors.teal,
              ),
              child: const Text("View on Map"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeletedMessage() {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12, top: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.block, size: 14, color: Colors.grey.shade400),
            const SizedBox(width: 8),
            Text(
              isMe ? "You deleted this message" : "This message was deleted",
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
    final List<String> popularEmojis = [
      "❤️", "👍", "😂", "😮", "😢", "🔥", 
      "👏", "🙌", "🎉", "✨", "💯", "🙏",
      "🤩", "🤔", "👀", "🚀", "💡", "✅"
    ];
    final now = DateTime.now();
    final canDeleteForEveryone = isMe && now.difference(message.timestamp).inHours < 1;

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
            color: Colors.white.withValues(alpha: 0.8),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
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
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                // Reactions Grid
                SizedBox(
                  height: 120,
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 6,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                    ),
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: popularEmojis.length,
                    itemBuilder: (context, index) {
                      final emoji = popularEmojis[index];
                      final isSelected = message.reactions[emoji]?.contains(FirebaseAuth.instance.currentUser?.uid) ?? false;
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          onReaction(emoji);
                        },
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.teal.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? AppColors.teal.withValues(alpha: 0.3) : Colors.transparent,
                            ),
                          ),
                          child: Text(emoji, style: const TextStyle(fontSize: 22)),
                        ),
                      ).animate().scale(delay: (index * 20).ms, duration: 200.ms, curve: Curves.easeOutBack);
                    },
                  ),
                ),
                
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Divider(height: 1),
                ),
                
                // Actions
                Column(
                  children: [
                    if (isMe)
                      _buildActionItem(
                        icon: Icons.edit_rounded,
                        title: "Edit Message",
                        onTap: onEdit,
                      ),
                    _buildActionItem(
                      icon: Icons.info_rounded,
                      title: "Message Info",
                      onTap: onInfo,
                    ),
                    if (isMe)
                      _buildActionItem(
                        icon: Icons.delete_sweep_rounded,
                        title: "Delete for everyone",
                        color: canDeleteForEveryone ? Colors.redAccent : Colors.grey,
                        onTap: canDeleteForEveryone ? () => onDelete(true) : null,
                        subtitle: canDeleteForEveryone ? "Permanent removal" : "Timed out (1h)",
                      ),
                    _buildActionItem(
                      icon: Icons.delete_outline_rounded,
                      title: "Delete for me",
                      color: Colors.redAccent,
                      onTap: () => onDelete(false),
                    ),
                  ].animate(interval: 50.ms).fadeIn(duration: 300.ms).slideX(begin: 0.1, end: 0),
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
      subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(fontSize: 10)) : null,
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      enabled: onTap != null,
    );
  }
}

class _MessageInfoSheet extends StatelessWidget {
  final MessageModel message;
  final GroupModel group;

  const _MessageInfoSheet({required this.message, required this.group});

  @override
  Widget build(BuildContext context) {
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
            color: Colors.white.withValues(alpha: 0.85),
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
                      "Message Info",
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
                    color: AppColors.teal.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.teal.withValues(alpha: 0.1)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.done_all_rounded, color: AppColors.teal, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Read by",
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.teal,
                              ),
                            ),
                            Text(
                              "${message.readBy.length} members",
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
                        "No one has read this yet", 
                        style: GoogleFonts.inter(color: Colors.grey, fontStyle: FontStyle.italic),
                      ),
                    ),
                  )
                else
                  ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.3),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: message.readBy.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final uid = message.readBy[index];
                        final isMe = uid == FirebaseAuth.instance.currentUser?.uid;
                        return Row(
                          children: [
                            CircleAvatar(
                              radius: 18, 
                              backgroundColor: isMe ? AppColors.teal.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.1),
                              child: Icon(
                                isMe ? Icons.person_rounded : Icons.person_outline_rounded, 
                                size: 20, 
                                color: isMe ? AppColors.teal : Colors.grey,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              isMe ? "You" : "Member ($uid)", 
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
                                color: AppColors.darkSlate,
                              ),
                            ),
                            const Spacer(),
                            const Icon(Icons.done_all_rounded, size: 16, color: AppColors.teal),
                          ],
                        ).animate(delay: (index * 50).ms).fadeIn().slideX(begin: 0.1, end: 0);
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
