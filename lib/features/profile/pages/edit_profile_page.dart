import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/colors.dart';
import 'package:laween/l10n/app_localizations.dart';
import '../../../../core/services/storage_service.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _picker = ImagePicker();
  final _storageService = StorageService();
  File? _imageFile;
  bool _isLoading = false;
  bool _isInitialLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        _nameController.text = data['name'] ?? data['fullName'] ?? "";
        _phoneController.text = data['phone'] ?? "";
      }
    }
    if (mounted) {
      setState(() {
        _isInitialLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    final l10n = AppLocalizations.of(context)!;

    try {
      String? photoUrl;
      if (_imageFile != null) {
        photoUrl = await _storageService.uploadFile(
          file: _imageFile!,
          path: 'profile_pics/${user?.uid}.jpg',
        );
      }

      final updates = {
        'name': _nameController.text.trim(),
        'fullName': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
      };
      if (photoUrl != null) {
        updates['photoUrl'] = photoUrl;
        updates['profilePic'] = photoUrl;
      }

      await FirebaseFirestore.instance.collection('users').doc(user?.uid).update(updates);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.successUpdate),
            backgroundColor: AppColors.teal,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.grey.shade50,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.editProfile,
          style: GoogleFonts.inter(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: _isInitialLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.teal))
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Premium Avatar Section
                    Center(
                      child: Stack(
                        children: [
                          GestureDetector(
                            onTap: _pickImage,
                            child: StreamBuilder<DocumentSnapshot>(
                              stream: FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser?.uid).snapshots(),
                              builder: (context, snapshot) {
                                String? photoUrl;
                                if (snapshot.hasData && snapshot.data!.exists) {
                                  final data = snapshot.data!.data() as Map<String, dynamic>;
                                  photoUrl = data['photoUrl'] ?? data['profilePic'];
                                }
                                return Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.08),
                                        blurRadius: 15,
                                        spreadRadius: 2,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: CircleAvatar(
                                    radius: 55,
                                    backgroundColor: AppColors.teal.withValues(alpha: 0.1),
                                    backgroundImage: _imageFile != null
                                        ? FileImage(_imageFile!)
                                        : (photoUrl != null && photoUrl.startsWith('http'))
                                            ? NetworkImage(photoUrl)
                                            : null,
                                    child: (_imageFile == null && photoUrl?.startsWith('http') != true)
                                        ? Icon(
                                            Icons.person,
                                            size: 70,
                                            color: AppColors.teal.withValues(alpha: 0.5),
                                          )
                                        : null,
                                  ),
                                );
                              },
                            ),
                          ),
                          Positioned(
                            bottom: 5,
                            right: 5,
                            child: GestureDetector(
                              onTap: _pickImage,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 3),
                                ),
                                child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Name Field
                    _buildPremiumTextField(
                      controller: _nameController,
                      label: l10n.fullName,
                      icon: Icons.person_outline,
                      validator: (v) => v == null || v.isEmpty ? "Required" : null,
                    ),
                    const SizedBox(height: 20),

                    // Email Field (Locked)
                    _buildPremiumTextField(
                      controller: TextEditingController(text: FirebaseAuth.instance.currentUser?.email ?? ""),
                      label: l10n.email,
                      icon: Icons.email_outlined,
                      readOnly: true,
                      enabled: false,
                    ),
                    const SizedBox(height: 20),

                    // Phone Field
                    _buildPremiumTextField(
                      controller: _phoneController,
                      label: l10n.phone,
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 40),

                    // Save Button
                    Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: AppColors.tealGradient),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.teal.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : Text(
                                l10n.save,
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPremiumTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    bool readOnly = false,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: enabled ? Colors.white : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              if (enabled)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            validator: validator,
            keyboardType: keyboardType,
            readOnly: readOnly,
            enabled: enabled,
            style: GoogleFonts.inter(
              fontSize: 16,
              color: enabled ? Colors.black : Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: label,
              prefixIcon: Icon(icon, color: AppColors.teal, size: 22),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            ),
          ),
        ),
      ],
    );
  }
}
