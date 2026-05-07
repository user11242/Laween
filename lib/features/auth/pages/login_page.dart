import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:laween/l10n/app_localizations.dart';
import '../../../core/theme/colors.dart';
import '../widgets/login_form.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  late AnimationController _entranceController;
  late AnimationController _breatheController;
  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<double> _titleFade;
  late Animation<Offset> _titleSlide;
  late Animation<double> _formFade;
  late Animation<Offset> _formSlide;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _breatheController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    // Logo pops in first
    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.35, curve: Curves.elasticOut),
      ),
    );
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.25, curve: Curves.easeOut),
      ),
    );

    // Title slides up
    _titleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.2, 0.5, curve: Curves.easeOut),
      ),
    );
    _titleSlide = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: const Interval(0.2, 0.5, curve: Curves.easeOutCubic),
          ),
        );

    // Form fades up last
    _formFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.4, 0.8, curve: Curves.easeOut),
      ),
    );
    _formSlide = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: const Interval(0.4, 0.8, curve: Curves.easeOutCubic),
          ),
        );

    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _breatheController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context, listen: true)!;
    final screenH = MediaQuery.of(context).size.height;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // ── 1. Organic gradient blobs ──
          _AnimatedBlob(
            controller: _breatheController,
            top: -screenH * 0.12,
            right: -80,
            size: screenH * 0.42,
            color: AppColors.teal,
            baseOpacity: 0.08,
          ),
          _AnimatedBlob(
            controller: _breatheController,
            bottom: screenH * 0.15,
            left: -100,
            size: screenH * 0.35,
            color: AppColors.tealLight,
            baseOpacity: 0.06,
            reversed: true,
          ),
          _AnimatedBlob(
            controller: _breatheController,
            top: screenH * 0.4,
            right: -60,
            size: screenH * 0.18,
            color: const Color(0xFF6C63FF),
            baseOpacity: 0.04,
          ),

          // ── 2. Scrollable Content ──
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.only(bottom: bottomInset + 32),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight:
                      screenH -
                      MediaQuery.of(context).padding.top -
                      MediaQuery.of(context).padding.bottom,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    children: [
                      SizedBox(height: screenH * 0.08),

                      // ── Logo ──
                      ScaleTransition(
                        scale: _logoScale,
                        child: FadeTransition(
                          opacity: _logoFade,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              color: AppColors.getSurfaceElevated(context),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.teal.withValues(alpha: 0.15),
                                  blurRadius: 32,
                                  spreadRadius: 0,
                                  offset: const Offset(0, 8),
                                ),
                                BoxShadow(
                                  color: AppColors.getShadow(context),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: Image.asset(
                                'assets/logo/Laween_transparent_iphone.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // ── Title & Subtitle ──
                      SlideTransition(
                        position: _titleSlide,
                        child: FadeTransition(
                          opacity: _titleFade,
                          child: Column(
                            children: [
                              Text(
                                loc.loginTitle,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.outfit(
                                  fontSize: 34,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.getTextPrimary(context),
                                  letterSpacing: -1.0,
                                  height: 1.1,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                loc.loginSubtitle,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.getTextSecondary(context),
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: screenH * 0.04),

                      // ── Auth Form Card ──
                      SlideTransition(
                        position: _formSlide,
                        child: FadeTransition(
                          opacity: _formFade,
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                            decoration: BoxDecoration(
                              color: AppColors.getSurface(context),
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.getShadow(context),
                                  blurRadius: 32,
                                  spreadRadius: 0,
                                  offset: const Offset(0, 8),
                                ),
                                BoxShadow(
                                  color: AppColors.teal.withValues(alpha: 0.03),
                                  blurRadius: 48,
                                  spreadRadius: 0,
                                  offset: const Offset(0, 16),
                                ),
                              ],
                            ),
                            child: const LoginForm(),
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── 3. Back Button ──
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 12,
            child: FadeTransition(
              opacity: _logoFade,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.getSurfaceElevated(
                    context,
                  ).withValues(alpha: 0.8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: Icon(
                  loc.isAr
                      ? Icons.arrow_forward_ios_rounded
                      : Icons.arrow_back_ios_new_rounded,
                  color: AppColors.getTextPrimary(context),
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Soft organic gradient blob that gently breathes
class _AnimatedBlob extends StatelessWidget {
  final AnimationController controller;
  final double? top;
  final double? bottom;
  final double? left;
  final double? right;
  final double size;
  final Color color;
  final double baseOpacity;
  final bool reversed;

  const _AnimatedBlob({
    required this.controller,
    this.top,
    this.bottom,
    this.left,
    this.right,
    required this.size,
    required this.color,
    this.baseOpacity = 0.08,
    this.reversed = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final t = reversed ? (1.0 - controller.value) : controller.value;
        final scale = 1.0 + (math.sin(t * math.pi) * 0.08);
        final opacity = baseOpacity + (math.sin(t * math.pi) * 0.02);

        return Positioned(
          top: top,
          bottom: bottom,
          left: left,
          right: right,
          child: Transform.scale(
            scale: scale,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    color.withValues(alpha: opacity),
                    color.withValues(alpha: 0.0),
                  ],
                  stops: const [0.0, 0.85],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
