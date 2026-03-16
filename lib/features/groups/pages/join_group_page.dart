import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:laween/l10n/app_localizations.dart';
import 'create_group_page.dart'; // To reuse the clipper

class JoinGroupPage extends StatefulWidget {
  const JoinGroupPage({super.key});

  @override
  State<JoinGroupPage> createState() => _JoinGroupPageState();
}

class _JoinGroupPageState extends State<JoinGroupPage> {
  bool _isScanMode = true;
  final List<TextEditingController> _pinControllers = List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());

  @override
  void dispose() {
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
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            ClipPath(
              clipper: CreateGroupHeaderClipper(),
              child: Container(
                height: screenHeight * 0.22,
                width: double.infinity,
                color: const Color(0xFF006D77),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SafeArea(
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Transform.flip(
                            flipX: l10n.isAr,
                            child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Text(
                        l10n.joinGroup,
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  
                  // Toggle Buttons
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildToggleButton(
                            label: l10n.scanQr,
                            isActive: _isScanMode,
                            icon: Icons.camera_alt,
                            onTap: () => setState(() => _isScanMode = true),
                          ),
                        ),
                        Expanded(
                          child: _buildToggleButton(
                            label: l10n.enterCode,
                            isActive: !_isScanMode,
                            icon: Icons.auto_awesome,
                            onTap: () => setState(() => _isScanMode = false),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Content based on mode
                  _isScanMode ? _buildScanView(l10n) : _buildCodeView(l10n),
                ],
              ),
            ),
          ],
        ),
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
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF006D77) : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
          boxShadow: isActive ? [
             BoxShadow(
              color: const Color(0xFF006D77).withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ] : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isActive ? Colors.white : Colors.grey, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                color: isActive ? Colors.white : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanView(AppLocalizations l10n) {
    return Column(
      children: [
        // QR Placeholder
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Icon(Icons.qr_code_2, size: 100, color: Color(0xFF2D3748)),
            ),
            // Corner markers (simulated)
            _buildCorner(top: 0, left: 0),
            _buildCorner(top: 0, right: 0),
            _buildCorner(bottom: 0, left: 0),
            _buildCorner(bottom: 0, right: 0),
          ],
        ),
        const SizedBox(height: 40),
        Text(
          l10n.scanToJoin,
          style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF2D3748)),
        ),
        const SizedBox(height: 12),
        Text(
          l10n.pointCameraDesc,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade500, height: 1.5),
        ),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.camera_alt, color: Colors.white),
            label: Text(
              l10n.openCamera,
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF006D77),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              elevation: 4,
              shadowColor: const Color(0xFF006D77).withValues(alpha: 0.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCorner({double? top, double? bottom, double? left, double? right}) {
    return Positioned(
      top: top, bottom: bottom, left: left, right: right,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          border: Border(
            top: top != null ? const BorderSide(color: Color(0xFF006D77), width: 4) : BorderSide.none,
            bottom: bottom != null ? const BorderSide(color: Color(0xFF006D77), width: 4) : BorderSide.none,
            left: left != null ? const BorderSide(color: Color(0xFF006D77), width: 4) : BorderSide.none,
            right: right != null ? const BorderSide(color: Color(0xFF006D77), width: 4) : BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildCodeView(AppLocalizations l10n) {
    return Column(
      children: [
        // Star Graphic
        Container(
          width: 160,
          height: 160,
          decoration: BoxDecoration(
            color: const Color(0xFF006D77).withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.auto_awesome, size: 60, color: Color(0xFF006D77)),
        ),
        const SizedBox(height: 40),
        Text(
          l10n.enterGroupCode,
          style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF2D3748)),
        ),
        const SizedBox(height: 12),
        Text(
          l10n.type6DigitCodeDesc,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade500, height: 1.5),
        ),
        const SizedBox(height: 40),
        
        // PIN Fields
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (index) => _buildPinField(index)),
        ),
        
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF006D77),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              elevation: 4,
              shadowColor: const Color(0xFF006D77).withValues(alpha: 0.5),
            ),
            child: Text(
              l10n.joinGroup,
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPinField(int index) {
    return SizedBox(
      width: 45,
      height: 60,
      child: TextField(
        controller: _pinControllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.text,
        textCapitalization: TextCapitalization.characters,
        maxLength: 1,
        decoration: InputDecoration(
          counterText: "",
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Color(0xFF006D77), width: 2),
          ),
        ),
        onChanged: (value) {
          if (value.isNotEmpty && index < 5) {
            _focusNodes[index + 1].requestFocus();
          } else if (value.isEmpty && index > 0) {
            _focusNodes[index - 1].requestFocus();
          }
        },
      ),
    );
  }
}
