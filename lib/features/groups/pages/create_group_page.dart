import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/theme/colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../data/services/group_service.dart';
import '../../../core/message/app_messenger.dart';

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
    final status = await Permission.contacts.request();
    if (status.isPermanentlyDenied) {
      openAppSettings();
      return;
    }
    
    if (status.isGranted) {
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
        AppMessenger.showSnackBar(
          context,
          title: "Error",
          message: "Contact permission denied",
          type: MessengerType.error,
        );
      }
    }
  }

  Future<void> _createGroup() async {
    if (_nameController.text.trim().isEmpty) {
      AppMessenger.showSnackBar(
        context,
        title: AppLocalizations.of(context)!.isAr ? "خطأ" : "Error",
        message: AppLocalizations.of(context)!.isAr ? "يرجى إدخال اسم المجموعة" : "Please enter a group name",
        type: MessengerType.error,
      );
      return;
    }

    setState(() => _isLoading = true);

    final error = await _groupService.createGroup(
      name: _nameController.text.trim(),
      memberPhoneNumbers: _selectedContacts
          .map((c) => c.phones.isNotEmpty ? c.phones.first.number : '')
          .where((p) => p.isNotEmpty)
          .toList(),
      imageFile: _image,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error == null) {
      AppMessenger.showSnackBar(
        context,
        title: AppLocalizations.of(context)!.isAr ? "نجاح" : "Success",
        message: AppLocalizations.of(context)!.isAr ? "تم إنشاء المجموعة بنجاح" : "Group created successfully",
        type: MessengerType.success,
      );
      Navigator.pop(context);
    } else {
      AppMessenger.showSnackBar(
        context,
        title: AppLocalizations.of(context)!.isAr ? "خطأ" : "Error",
        message: error,
        type: MessengerType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
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
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      InkWell(
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(50),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Transform.flip(
                            flipX: l10n.isAr,
                            child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
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
                                        AppColors.teal.withValues(alpha: 0.08),
                                        AppColors.teal.withValues(alpha: 0.15),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : null,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.teal.withValues(alpha: 0.3),
                                width: 2,
                              ),
                              image: _image != null
                                  ? DecorationImage(image: FileImage(_image!), fit: BoxFit.cover)
                                  : null,
                            ),
                            child: _image == null
                                ? const Icon(Icons.camera_alt_outlined, size: 38, color: AppColors.teal)
                                : null,
                          ),
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: const BoxDecoration(
                              color: AppColors.teal,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.edit, size: 14, color: Colors.white),
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
                        color: AppColors.darkSlate,
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
                        color: Colors.grey.shade500,
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
                      color: Colors.grey.shade600,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _nameController,
                      style: GoogleFonts.inter(fontSize: 15, color: AppColors.darkSlate),
                      decoration: InputDecoration(
                        hintText: l10n.isAr ? "مثال: فريق التطوير" : "e.g. Design Team",
                        hintStyle: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 14),
                        prefixIcon: const Icon(Icons.group_rounded, color: AppColors.teal, size: 22),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
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
                          color: Colors.grey.shade600,
                          letterSpacing: 0.3,
                        ),
                      ),
                      if (_selectedContacts.isNotEmpty)
                        Text(
                          "${_selectedContacts.length} ${l10n.isAr ? 'مختار' : 'selected'}",
                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.teal, fontWeight: FontWeight.w600),
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
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.teal.withValues(alpha: 0.4), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
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
                              color: AppColors.teal.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.person_add_rounded, color: AppColors.teal, size: 18),
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
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: AppColors.teal.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.teal.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 10,
                                backgroundColor: AppColors.teal,
                                child: Text(
                                  contact.displayName.isNotEmpty ? contact.displayName[0].toUpperCase() : '?',
                                  style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                contact.displayName,
                                style: GoogleFonts.inter(fontSize: 13, color: AppColors.darkSlate, fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: () => setState(() => _selectedContacts.removeAt(idx)),
                                child: Icon(Icons.close_rounded, size: 15, color: Colors.grey.shade500),
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
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
                              color: AppColors.teal.withValues(alpha: 0.25),
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
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
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
                                      child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
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

  const _ContactPickerSheet({required this.contacts, required this.initiallySelected});

  @override
  State<_ContactPickerSheet> createState() => _ContactPickerSheetState();
}

class _ContactPickerSheetState extends State<_ContactPickerSheet> {
  late List<Contact> _tempSelected;
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _tempSelected = List.from(widget.initiallySelected);
  }

  @override
  Widget build(BuildContext context) {
    final filteredContacts = widget.contacts
        .where((c) => c.displayName.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.addMembers,
                style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, _tempSelected),
                child: Text(AppLocalizations.of(context)!.continueText),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            onChanged: (val) => setState(() => _searchQuery = val),
            decoration: InputDecoration(
              hintText: "Search contacts...",
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: filteredContacts.length,
              itemBuilder: (context, index) {
                final contact = filteredContacts[index];
                final isSelected = _tempSelected.any((c) => c.id == contact.id);
                return ListTile(
                  leading: CircleAvatar(child: Text(contact.displayName.isNotEmpty ? contact.displayName[0] : '?')),
                  title: Text(contact.displayName),
                  subtitle: Text(contact.phones.isNotEmpty ? contact.phones.first.number : ''),
                  trailing: Checkbox(
                    value: isSelected,
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _tempSelected.add(contact);
                        } else {
                          _tempSelected.removeWhere((c) => c.id == contact.id);
                        }
                      });
                    },
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
    path.quadraticBezierTo(size.width * 0.7, size.height, size.width, size.height - 60);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
