import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/utils/numeric_utils.dart';
import '../../../core/theme/colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../data/services/group_service.dart';
import '../../../core/message/app_messenger.dart';
import 'package:url_launcher/url_launcher.dart';

class CreateGroupPage extends StatefulWidget {
  const CreateGroupPage({super.key});

  @override
  State<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends State<CreateGroupPage> {
  final TextEditingController _nameController = TextEditingController();
  File? _image;
  final List<Contact> _selectedContacts = [];
  bool _isLoading = false;
  final GroupService _groupService = GroupService();

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _image = File(pickedFile.path));
    }
  }

  Future<void> _pickContacts() async {
    // Use the package's built-in permission request for better compatibility
    if (await FlutterContacts.requestPermission()) {
      final contacts = await FlutterContacts.getContacts(withProperties: true);
      if (!mounted) return;

      final result = await showModalBottomSheet<List<Contact>>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => _ContactPickerSheet(
          contacts: contacts,
          initiallySelected: _selectedContacts,
        ),
      );

      if (result != null) {
        setState(() {
          _selectedContacts.clear();
          _selectedContacts.addAll(result);
        });
      }
    } else {
      if (mounted) {
        // Only open settings if they really want to, otherwise show a clear message
        AppMessenger.showSnackBar(
          context,
          title: AppLocalizations.of(context)!.isAr ? "الصلاحية مطلوبة" : "Permission Required",
          message: AppLocalizations.of(context)!.isAr
              ? "يرجى منح صلاحية الوصول لجهات الاتصال من الإعدادات"
              : "Please grant contacts permission in settings to add friends",
          type: MessengerType.info,
        );
      }
    }
  }

  Future<void> _createGroup() async {
    if (_nameController.text.trim().isEmpty) {
      AppMessenger.showSnackBar(
        context,
        title: AppLocalizations.of(context)!.isAr ? "خطأ" : "Error",
        message: AppLocalizations.of(context)!.isAr
            ? "يرجى إدخال اسم المجموعة"
            : "Please enter a group name",
        type: MessengerType.error,
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await _groupService.createGroup(
      name: _nameController.text.trim(),
      memberPhoneNumbers: _selectedContacts
          .map((c) => c.phones.isNotEmpty ? c.phones.first.number : '')
          .where((p) => p.isNotEmpty)
          .toList(),
      imageFile: _image,
    );
    
    final error = result?['error'];
    final groupCode = result?['groupCode'];

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error == null) {
      final l10n = AppLocalizations.of(context, listen: false)!;
      // 🚀 SUCCESS: Trigger Invites if needed
      if (groupCode != null) {
        final invitees = _selectedContacts
            .map((c) => c.phones.isNotEmpty ? c.phones.first.number : '')
            .where((p) => p.isNotEmpty)
            .toList();
        
        if (invitees.isNotEmpty) {
          await _sendSMSInvites(invitees, groupCode);
        }
      }

      AppMessenger.showSnackBar(
        context,
        title: l10n.isAr ? "نجاح" : "Success",
        message: l10n.isAr
            ? "تم إنشاء المجموعة بنجاح"
            : "Group created successfully",
        type: MessengerType.success,
      );
      Navigator.pop(context);
    } else {
      final l10n = AppLocalizations.of(context, listen: false)!;
      AppMessenger.showSnackBar(
        context,
        title: l10n.isAr ? "خطأ" : "Error",
        message: error,
        type: MessengerType.error,
      );
    }
  }

  Future<void> _sendSMSInvites(List<String> phones, String code) async {
    final isAr = AppLocalizations.of(context)!.isAr;
    final message = isAr
        ? "أهلاً! انضم إلى مجموعتي في تطبيق لاوين (Laween) لتنسيق طلعاتنا. استخدم هذا الكود للانضمام: [$code]"
        : "Hey! Join my group on Laween to coordinate our outings. Use this code to join: [$code]";

    // Encode spaces as %20 instead of + to avoid the '+' issue in SMS apps
    final encodedMessage = Uri.encodeComponent(message).replaceAll('+', '%20');
    final String recipients = phones.join(',');
    
    // On iOS/Android, the separator and query param can vary, but this is the most compatible way
    final Uri smsUri = Uri.parse('sms:$recipients?body=$encodedMessage');

    try {
      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
      }
    } catch (e) {
      debugPrint("Could not launch SMS: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      // Prevent the keyboard from resizing the layout above
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          // --- Fixed Header (never scrolls) ---
          ClipPath(
            clipper: CreateGroupHeaderClipper(),
            child: Container(
              height: screenHeight * 0.22,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: AppColors.tealGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      InkWell(
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(50),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Transform.flip(
                            flipX: l10n.isAr,
                            child: const Icon(
                              Icons.arrow_back_ios_new,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        l10n.createGroup,
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // --- Scrollable Form Content ---
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 28),

                  // Group Photo Picker
                  Center(
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              gradient: _image == null
                                  ? LinearGradient(
                                      colors: [
                                        AppColors.teal.withOpacity(0.08),
                                        AppColors.teal.withOpacity(0.15),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : null,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.teal.withOpacity(0.3),
                                width: 2,
                              ),
                              image: _image != null
                                  ? DecorationImage(
                                      image: FileImage(_image!),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: _image == null
                                ? const Icon(
                                    Icons.camera_alt_outlined,
                                    size: 38,
                                    color: AppColors.teal,
                                  )
                                : null,
                          ),
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: const BoxDecoration(
                              color: AppColors.teal,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.edit,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),
                  Center(
                    child: Text(
                      l10n.createANewGroup,
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.getTextPrimary(context),
                      ),
                    ),
                  ),
                  Center(
                    child: Text(
                      l10n.isAr
                          ? "اختر صورة واسمًا لمجموعتك"
                          : "Set a photo and name for your group",
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.getTextSecondary(context),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Group Name Field
                  Text(
                    l10n.groupName,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.getTextSecondary(context),
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.getSurfaceElevated(context),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.getBorder(context)),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.getShadow(
                            context,
                          ).withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _nameController,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: AppColors.getTextPrimary(context),
                      ),
                      decoration: InputDecoration(
                        hintText: l10n.isAr
                            ? "مثال: فريق التطوير"
                            : "e.g. Design Team",
                        hintStyle: GoogleFonts.inter(
                          color: AppColors.getTextMuted(context),
                          fontSize: 14,
                        ),
                        prefixIcon: const Icon(
                          Icons.group_rounded,
                          color: AppColors.teal,
                          size: 22,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 16,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Members Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.members,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.getTextSecondary(context),
                          letterSpacing: 0.3,
                        ),
                      ),
                      if (_selectedContacts.isNotEmpty)
                        Text(
                          "${_selectedContacts.length} ${l10n.isAr ? 'مختار' : 'selected'}",
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.teal,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Add Members Button
                  GestureDetector(
                    onTap: _pickContacts,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      decoration: BoxDecoration(
                        color: AppColors.getSurfaceElevated(context),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.teal.withOpacity(0.4),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.getShadow(
                              context,
                            ).withValues(alpha: 0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: AppColors.teal.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.person_add_rounded,
                              color: AppColors.teal,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            l10n.addMembers,
                            style: GoogleFonts.inter(
                              color: AppColors.teal,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Selected Contacts Chips
                  if (_selectedContacts.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _selectedContacts.asMap().entries.map((entry) {
                        final contact = entry.value;
                        final idx = entry.key;
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.teal.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.teal.withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 10,
                                backgroundColor: AppColors.teal,
                                child: Text(
                                  contact.displayName.isNotEmpty
                                      ? contact.displayName[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                contact.displayName,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: AppColors.getTextPrimary(context),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: () => setState(
                                  () => _selectedContacts.removeAt(idx),
                                ),
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 15,
                                  color: AppColors.getTextMuted(context),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],

                  const SizedBox(height: 40),

                  // Continue Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _createGroup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: _isLoading
                              ? null
                              : const LinearGradient(
                                  colors: AppColors.tealGradient,
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                          color: _isLoading ? Colors.grey.shade300 : null,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.teal.withOpacity(0.25),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Container(
                          alignment: Alignment.center,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      l10n.continueText,
                                      style: GoogleFonts.outfit(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Transform.flip(
                                      flipX: l10n.isAr,
                                      child: const Icon(
                                        Icons.arrow_forward_rounded,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactPickerSheet extends StatefulWidget {
  final List<Contact> contacts;
  final List<Contact> initiallySelected;

  const _ContactPickerSheet({
    required this.contacts,
    required this.initiallySelected,
  });

  @override
  State<_ContactPickerSheet> createState() => _ContactPickerSheetState();
}

class _ContactPickerSheetState extends State<_ContactPickerSheet> {
  late List<Contact> _tempSelected;
  String _searchQuery = "";
  final Map<String, bool> _appUserStatus = {}; // phone -> isUser
  bool _isCheckingUsers = true;

  @override
  void initState() {
    super.initState();
    _tempSelected = List.from(widget.initiallySelected);
    _checkAppUsers();
  }

  Future<void> _checkAppUsers() async {
    final phones = widget.contacts
        .expand((c) => c.phones)
        .map((p) => NumericUtils.normalize(p.number, clean: true))
        .where((p) => p.isNotEmpty)
        .toSet()
        .toList();

    if (phones.isEmpty) {
      if (mounted) setState(() => _isCheckingUsers = false);
      return;
    }

    try {
      // Chunked lookup
      const int chunkSize = 30;
      for (var i = 0; i < phones.length; i += chunkSize) {
        final end = (i + chunkSize < phones.length)
            ? i + chunkSize
            : phones.length;
        final chunk = phones.sublist(i, end);

        final query = await FirebaseFirestore.instance
            .collection('users')
            .where('phone', whereIn: chunk)
            .get();

        final foundPhones = query.docs
            .map((d) => d.data()['phone'] as String)
            .toList();
        for (var p in chunk) {
          _appUserStatus[p] = foundPhones.contains(p);
        }
      }
    } catch (e) {
      debugPrint("Error checking app users: $e");
    }

    if (mounted) {
      setState(() => _isCheckingUsers = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredContacts = widget.contacts
        .where(
          (c) =>
              c.displayName.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: AppColors.getSurfaceElevated(context),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: AppColors.getShadow(context).withValues(alpha: 0.2),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.addMembers,
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_isCheckingUsers)
                      Text(
                        AppLocalizations.of(context)!.isAr ? "جاري البحث عن أصدقاء..." : "Finding friends...",
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.getTextMuted(context),
                        ),
                      )
                    else
                      Text(
                        AppLocalizations.of(context)!.isAr ? "تم اختيار ${_tempSelected.length}" : "${_tempSelected.length} chosen",
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.teal,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, _tempSelected),
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.teal.withOpacity(0.1),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.continueText,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.teal,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.all(20),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.getSurface(context),
                borderRadius: BorderRadius.circular(16),
              ),
              child: TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.isAr ? "ابحث بالاسم أو الرقم..." : "Search name or phone...",
                  hintStyle: GoogleFonts.inter(
                    color: AppColors.getTextMuted(context),
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: AppColors.getTextMuted(context),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
          ),

          // Contacts List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 40),
              itemCount: filteredContacts.length,
              itemBuilder: (context, index) {
                final contact = filteredContacts[index];
                final isSelected = _tempSelected.any((c) => c.id == contact.id);
                final phone = contact.phones.isNotEmpty
                    ? contact.phones.first.number
                    : '';
                final cleanPhone = NumericUtils.normalize(phone, clean: true);
                final isOnApp = _appUserStatus[cleanPhone] == true;

                return InkWell(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _tempSelected.removeWhere((c) => c.id == contact.id);
                      } else {
                        _tempSelected.add(contact);
                      }
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: isOnApp
                                  ? AppColors.teal.withValues(alpha: 0.1)
                                  : AppColors.getSurface(context),
                              child: Text(
                                contact.displayName.isNotEmpty
                                    ? contact.displayName[0].toUpperCase()
                                    : '?',
                                style: GoogleFonts.outfit(
                                  color: isOnApp
                                      ? AppColors.teal
                                      : AppColors.getTextMuted(context),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            if (isOnApp)
                              Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check_circle,
                                  size: 16,
                                  color: AppColors.teal,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                contact.displayName,
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                  color: AppColors.getTextPrimary(context),
                                ),
                              ),
                              Text(
                                phone,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!isOnApp && !_isCheckingUsers)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              AppLocalizations.of(context)!.isAr ? "دعوة" : "INVITE",
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                        const SizedBox(width: 12),
                        Checkbox(
                          value: isSelected,
                          activeColor: AppColors.teal,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                _tempSelected.add(contact);
                              } else {
                                _tempSelected.removeWhere(
                                  (c) => c.id == contact.id,
                                );
                              }
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class CreateGroupHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height);
    path.quadraticBezierTo(
      size.width * 0.7,
      size.height,
      size.width,
      size.height - 60,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
