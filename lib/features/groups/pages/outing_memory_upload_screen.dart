import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/colors.dart';
import '../data/models/outing_session_model.dart';
import '../data/services/outing_service.dart';

class OutingMemoryUploadScreen extends StatefulWidget {
  final OutingSessionModel session;

  const OutingMemoryUploadScreen({
    super.key,
    required this.session,
  });

  @override
  State<OutingMemoryUploadScreen> createState() => _OutingMemoryUploadScreenState();
}

class _OutingMemoryUploadScreenState extends State<OutingMemoryUploadScreen> {
  final List<File> _selectedImages = [];
  bool _isUploading = false;
  final int _maxImages = 15;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImages() async {
    if (_selectedImages.length >= _maxImages) return;

    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage(
        imageQuality: 70, // Pre-compress the images cleanly
        maxWidth: 1200,
      );

      if (pickedFiles.isNotEmpty) {
        setState(() {
          int remaining = _maxImages - _selectedImages.length;
          for (int i = 0; i < pickedFiles.length && i < remaining; i++) {
            _selectedImages.add(File(pickedFiles[i].path));
          }
        });
      }
    } catch (e) {
      debugPrint("Error picking images: \$e");
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _finishAndSave() async {
    if (_isUploading) return;
    
    // Allow closing without photos if that's what the user wants
    if (_selectedImages.isEmpty) {
      setState(() => _isUploading = true);
      await OutingService().finalizeAndArchive(widget.session);
      if (mounted) Navigator.pop(context);
      return;
    }

    setState(() => _isUploading = true);

    try {
      await OutingService().uploadMemories(
        session: widget.session,
        photos: _selectedImages,
      );
      
      // Auto-finalize to show in history immediately
      await OutingService().finalizeAndArchive(widget.session);

      if (mounted) {
        Navigator.pop(context); // Go back to Group room
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Memories saved to History!')),
        );
      }
    } catch (e) {
      setState(() => _isUploading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving memory: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final venueName = widget.session.winner?['name'] ?? widget.session.category;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: const SizedBox.shrink(), // No back button physically hiding, forced to finish
        title: Text(
          "Save the Memory",
          style: GoogleFonts.outfit(
            color: AppColors.darkSlate,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Capture the Vibes!",
                      style: GoogleFonts.outfit(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: AppColors.darkSlate,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Everyone in the squad has 24 hours to add photos to this session! After that, our AI will piece together the 'Roast & Hype' recap for the group history.",
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Beautiful photo grid
                    if (_selectedImages.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Your Contributions (\${_selectedImages.length}/$_maxImages)",
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.darkSlate,
                            ),
                          ),
                          if (_selectedImages.length < _maxImages)
                            TextButton.icon(
                              onPressed: _pickImages,
                              icon: const Icon(Icons.add_a_photo_rounded, size: 16, color: AppColors.teal),
                              label: Text("Add More", style: GoogleFonts.inter(color: AppColors.teal, fontWeight: FontWeight.bold)),
                            )
                        ],
                      ),
                      const SizedBox(height: 12),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 1,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: _selectedImages.length,
                        itemBuilder: (context, index) {
                          return Stack(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  image: DecorationImage(
                                    image: FileImage(_selectedImages[index]),
                                    fit: BoxFit.cover,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    )
                                  ],
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () => _removeImage(index),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.5),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close, size: 14, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ).animate().scale(delay: (index * 50).ms, duration: 200.ms, curve: Curves.easeOutBack);
                        },
                      ),
                    ] else ...[
                      // Big placeholder upload button
                      GestureDetector(
                        onTap: _pickImages,
                        child: Container(
                          width: double.infinity,
                          height: 200,
                          decoration: BoxDecoration(
                            color: AppColors.teal.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: AppColors.teal.withOpacity(0.3), width: 2, style: BorderStyle.solid),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.teal.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.add_photo_alternate_rounded, size: 48, color: AppColors.teal),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "Tap to add up to 15 photos",
                                style: GoogleFonts.outfit(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.teal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
                    ]
                  ],
                ),
              ),
            ),
            
            // Bottom Action Bar
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: _isUploading ? null : _finishAndSave,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                        ),
                        child: Text(
                          "Skip & Close",
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _isUploading ? null : _finishAndSave,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.teal,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          shadowColor: AppColors.teal.withOpacity(0.4),
                          elevation: 8,
                        ),
                        child: _isUploading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : Text(
                                _selectedImages.isEmpty ? "Close Details" : "Upload & AI Recap",
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
