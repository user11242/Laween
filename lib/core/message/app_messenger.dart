import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:laween/core/theme/colors.dart';
import 'package:flutter_animate/flutter_animate.dart';

enum MessengerType { success, error, warning, info }

class AppMessenger {
  static OverlayEntry? _currentOverlay;

  static void showSnackBar(
    BuildContext context, {
    required String title,
    required String message,
    required MessengerType type,
  }) {
    Color primaryColor = AppColors.teal;
    IconData icon = Icons.info_outline;
    
    if (type == MessengerType.error) {
      primaryColor = Colors.redAccent;
      icon = Icons.error_outline;
    } else if (type == MessengerType.success) {
      primaryColor = Colors.green;
      icon = Icons.check_circle_outline;
    } else if (type == MessengerType.warning) {
      primaryColor = Colors.orangeAccent;
      icon = Icons.warning_amber_outlined;
    }

    _showOverlay(context, title, message, primaryColor, icon);
  }

  static void _showOverlay(
    BuildContext context,
    String title,
    String message,
    Color primaryColor,
    IconData icon,
  ) {
    _currentOverlay?.remove();
    _currentOverlay = null;

    final overlay = Overlay.of(context);
    
    _currentOverlay = OverlayEntry(
      builder: (context) => _MessengerOverlay(
        title: title,
        message: message,
        primaryColor: primaryColor,
        icon: icon,
        onDispose: () {
          _currentOverlay?.remove();
          _currentOverlay = null;
        },
      ),
    );

    overlay.insert(_currentOverlay!);
  }
}

class _MessengerOverlay extends StatefulWidget {
  final String title;
  final String message;
  final Color primaryColor;
  final IconData icon;
  final VoidCallback onDispose;

  const _MessengerOverlay({
    required this.title,
    required this.message,
    required this.primaryColor,
    required this.icon,
    required this.onDispose,
  });

  @override
  State<_MessengerOverlay> createState() => _MessengerOverlayState();
}

class _MessengerOverlayState extends State<_MessengerOverlay> {
  bool _isVisible = true;

  void _close() {
    if (!mounted) return;
    setState(() => _isVisible = false);
    // Wait for exit animation
    Future.delayed(400.ms, () => widget.onDispose());
  }

  @override
  void initState() {
    super.initState();
    // Auto-close after 5 seconds
    Future.delayed(5.seconds, () {
      if (mounted && _isVisible) _close();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;
    
    return Positioned(
      bottom: bottomPadding + keyboardInset + 20,
      left: 20,
      right: 20,
      child: Material(
        color: Colors.transparent,
        child: _isVisible 
          ? _buildContent()
              .animate()
              .scale(duration: 400.ms, curve: Curves.easeOutBack, begin: const Offset(0.8, 0.8))
              .moveY(begin: 50, end: 0, duration: 400.ms, curve: Curves.easeOutQuad)
              .fadeIn(duration: 400.ms)
          : _buildContent()
              .animate()
              .scale(duration: 300.ms, curve: Curves.easeInBack, end: const Offset(0.7, 0.7))
              .moveY(begin: 0, end: 60, duration: 300.ms, curve: Curves.easeIn)
              .fadeOut(duration: 200.ms),
      ),
    );
  }

  Widget _buildContent() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: widget.primaryColor.withValues(alpha: 0.2), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: widget.primaryColor.withValues(alpha: 0.08),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: widget.primaryColor.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(widget.icon, color: widget.primaryColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        color: widget.primaryColor,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.message,
                      style: GoogleFonts.inter(
                        color: Colors.black.withValues(alpha: 0.75),
                        fontSize: 13,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.close, color: Colors.grey.withValues(alpha: 0.5), size: 18),
                onPressed: _close,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
