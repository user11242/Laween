import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../core/theme/colors.dart';
import '../data/services/group_service.dart';
import 'chat_page.dart';
import 'create_group_page.dart';

class JoinGroupPage extends StatefulWidget {
  const JoinGroupPage({super.key});

  @override
  State<JoinGroupPage> createState() => _JoinGroupPageState();
}

class _JoinGroupPageState extends State<JoinGroupPage> {
  final List<TextEditingController> _pinControllers = List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  final GroupService _groupService = GroupService();
  final MobileScannerController _scannerController = MobileScannerController();
  bool _isLoading = false;
  bool _isScanMode = true;

  void _onPinChanged(String value, int index) {
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    
    // Auto-join if all fields are filled
    final code = _pinControllers.map((c) => c.text).join();
    if (code.length == 6) {
      _joinGroup(code);
    }
  }

  Future<void> _joinGroup(String code) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      final joinedGroup = await _groupService.joinGroupWithCode(code, userId);
      
      if (mounted && joinedGroup != null) {
        // Redirect to chat page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ChatPage(group: joinedGroup),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _scannerController.dispose();
    for (var controller in _pinControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          // --- Fixed Header (Pinnned) ---
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
                        l10n.joinGroup,
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
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  
                  // Toggle Mode Switcher
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildToggleButton(
                            label: l10n.scanQr,
                            isActive: _isScanMode,
                            icon: Icons.qr_code_scanner_rounded,
                            onTap: () {
                              if (!_isScanMode) {
                                setState(() => _isScanMode = true);
                              }
                            },
                          ),
                        ),
                        Expanded(
                          child: _buildToggleButton(
                            label: l10n.enterCode,
                            isActive: !_isScanMode,
                            icon: Icons.password_rounded,
                            onTap: () {
                              if (_isScanMode) {
                                setState(() => _isScanMode = false);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Content Area
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _isScanMode ? _buildScanView(l10n) : _buildCodeView(l10n),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton({
    required String label,
    required bool isActive,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: isActive ? const LinearGradient(
            colors: AppColors.tealGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ) : null,
          color: isActive ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isActive ? [
             BoxShadow(
              color: AppColors.teal.withValues(alpha: 0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ] : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isActive ? Colors.white : Colors.grey.shade400, size: 20),
            const SizedBox(width: 10),
            Text(
              label,
              style: GoogleFonts.outfit(
                color: isActive ? Colors.white : Colors.grey.shade400,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanView(AppLocalizations l10n) {
    return Column(
      key: const ValueKey("scan_view"),
      children: [
        // QR Scanner Container
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(38),
                child: MobileScanner(
                  controller: _scannerController,
                  onDetect: (capture) {
                    final List<Barcode> barcodes = capture.barcodes;
                    for (final barcode in barcodes) {
                      final String? rawValue = barcode.rawValue;
                      if (rawValue != null && rawValue.contains("laween.app/join/")) {
                        final code = rawValue.split("/").last;
                        if (code.length == 6) {
                          _scannerController.stop();
                          _joinGroup(code);
                          break;
                        }
                      }
                    }
                  },
                ),
              ),
            ),
            // Custom Scoping Overlay
            _buildCorner(top: 15, left: 15, isTop: true, isLeft: true),
            _buildCorner(top: 15, right: 15, isTop: true, isLeft: false),
            _buildCorner(bottom: 15, left: 15, isTop: false, isLeft: true),
            _buildCorner(bottom: 15, right: 15, isTop: false, isLeft: false),
            
            // Scanner Line Animation (Static for UI design)
            Container(
              width: 240,
              height: 2,
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: AppColors.teal.withValues(alpha: 0.5),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
                gradient: LinearGradient(
                  colors: [
                    AppColors.teal.withValues(alpha: 0.01),
                    AppColors.teal,
                    AppColors.teal.withValues(alpha: 0.01),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        Text(
          l10n.scanToJoin,
          style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.darkSlate),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.pointCameraDesc,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade500, height: 1.5),
        ),
        const SizedBox(height: 40),
        
        // Flashlight Button
        Container(
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey.shade200),
            color: Colors.white,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _scannerController.toggleTorch(),
              borderRadius: BorderRadius.circular(18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.flashlight_on_rounded, color: AppColors.teal, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    "Toggle Flashlight",
                    style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.teal),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 100), // Safe area at bottom
      ],
    );
  }

  Widget _buildCorner({double? top, double? bottom, double? left, double? right, required bool isTop, required bool isLeft}) {
    return Positioned(
      top: top, bottom: bottom, left: left, right: right,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          border: Border(
            top: isTop ? const BorderSide(color: AppColors.teal, width: 4) : BorderSide.none,
            bottom: !isTop ? const BorderSide(color: AppColors.teal, width: 4) : BorderSide.none,
            left: isLeft ? const BorderSide(color: AppColors.teal, width: 4) : BorderSide.none,
            right: !isLeft ? const BorderSide(color: AppColors.teal, width: 4) : BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildCodeView(AppLocalizations l10n) {
    return Column(
      key: const ValueKey("code_view"),
      children: [
        Container(
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            color: AppColors.teal.withValues(alpha: 0.08),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.teal.withValues(alpha: 0.1)),
          ),
          child: const Icon(Icons.keyboard_command_key_rounded, size: 40, color: AppColors.teal),
        ),
        const SizedBox(height: 32),
        Text(
          l10n.enterGroupCode,
          style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.darkSlate),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.type6DigitCodeDesc,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade500, height: 1.5),
        ),
        const SizedBox(height: 40),
        
        Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(6, (index) => _buildPinField(index)),
          ),
        ),
        
        const SizedBox(height: 48),
        
        // Join Button
        SizedBox(
          width: double.infinity,
          height: 58,
          child: ElevatedButton(
            onPressed: _isLoading ? null : () => _joinGroup(_pinControllers.map((c) => c.text).join()),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
            child: Ink(
              decoration: BoxDecoration(
                gradient: _isLoading ? null : const LinearGradient(
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
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          l10n.joinGroup,
                          style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.3),
                        ),
                        const SizedBox(width: 10),
                        const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                      ],
                    ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildPinField(int index) {
    return Container(
      width: 48,
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _pinControllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.darkSlate),
        decoration: InputDecoration(
          counterText: "",
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.teal, width: 2),
          ),
        ),
        onChanged: (value) => _onPinChanged(value, index),
      ),
    );
  }
}
