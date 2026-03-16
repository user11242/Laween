import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:laween/l10n/app_localizations.dart';
import '../pages/create_group_page.dart';
import '../pages/join_group_page.dart';

class CreateJoinDialog extends StatelessWidget {
  final VoidCallback onClose;

  const CreateJoinDialog({super.key, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.close, color: Colors.black54),
                onPressed: onClose,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 10),
          
          // Create Group Option
          _buildOption(
            context: context,
            icon: Icons.group_add,
            iconColor: const Color(0xFFFF9F1C), // Orange
            iconBgColor: const Color(0xFFFF9F1C).withValues(alpha: 0.1),
            title: l10n.createGroup,
            subtitle: l10n.makeNewGroupDesc,
            onTap: () {
              onClose();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CreateGroupPage()),
              );
            },
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 15),
            child: Divider(height: 1, thickness: 1, color: Colors.grey.withValues(alpha: 0.1)),
          ),
          
          // Join Group Option
          _buildOption(
            context: context,
            icon: Icons.qr_code_scanner,
            iconColor: const Color(0xFF006D77), // Teal
            iconBgColor: const Color(0xFF006D77).withValues(alpha: 0.1),
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
          const SizedBox(height: 5),
        ],
      ),
    );
  }

  Widget _buildOption({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2D3748),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
