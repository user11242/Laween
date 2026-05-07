import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/colors.dart';
import 'package:laween/l10n/app_localizations.dart';
import '../pages/create_group_page.dart';
import '../pages/join_group_page.dart';

class CreateJoinDialog extends StatelessWidget {
  final VoidCallback onClose;

  const CreateJoinDialog({super.key, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isAr = l10n.isAr;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        color: AppColors.getSurfaceElevated(context),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppColors.getShadow(context).withValues(alpha: 0.15),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isAr ? "المجموعات" : "Groups",
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.getTextPrimary(context),
                ),
              ),
              GestureDetector(
                onTap: onClose,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.getSurface(context),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close,
                    color: AppColors.getTextSecondary(context),
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Create Group Option
          _buildEnhancedOption(
            context: context,
            icon: Icons.add_to_photos_rounded,
            iconColor: const Color(0xFFFF9F1C),
            title: l10n.createGroup,
            subtitle: l10n.makeNewGroupDesc,
            onTap: () {
              onClose();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateGroupPage(),
                ),
              );
            },
          ),

          const SizedBox(height: 16),

          // Join Group Option
          _buildEnhancedOption(
            context: context,
            icon: Icons.qr_code_scanner_rounded,
            iconColor: AppColors.teal,
            title: l10n.joinGroup,
            subtitle: l10n.enterCodeToJoinDesc,
            onTap: () {
              onClose();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const JoinGroupPage()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedOption({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return _AnimatedOptionCard(
      icon: icon,
      baseColor: iconColor,
      title: title,
      subtitle: subtitle,
      onTap: onTap,
    );
  }
}

class _AnimatedOptionCard extends StatefulWidget {
  final IconData icon;
  final Color baseColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _AnimatedOptionCard({
    required this.icon,
    required this.baseColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  State<_AnimatedOptionCard> createState() => _AnimatedOptionCardState();
}

class _AnimatedOptionCardState extends State<_AnimatedOptionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutBack),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAr = AppLocalizations.of(context)!.isAr;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          _controller.forward();
          await Future.delayed(const Duration(milliseconds: 100));
          _controller.reverse();
          widget.onTap();
        },
        borderRadius: BorderRadius.circular(20),
        highlightColor: AppColors.getSurface(context),
        splashColor: widget.baseColor.withValues(alpha: 0.1),
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) => Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              decoration: BoxDecoration(
                color: AppColors.getSurface(context),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.getShadow(context).withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: AppColors.getDivider(context),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: widget.baseColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(widget.icon, color: widget.baseColor, size: 26),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: GoogleFonts.outfit(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: AppColors.getTextPrimary(context),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.subtitle,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.getTextSecondary(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isAr ? Icons.chevron_left : Icons.chevron_right,
                    color: AppColors.getTextMuted(context),
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
