import 'package:flutter/material.dart';
import 'package:laween/l10n/app_localizations.dart';
import 'package:laween/core/theme/colors.dart';

class StepRole extends StatelessWidget {
  final String selectedRole;
  final ValueChanged<String> onRoleChanged;

  const StepRole({
    super.key,
    required this.selectedRole,
    required this.onRoleChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          l10n.chooseRole,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 12),
        Text(
          l10n.learnOrTeach,
          style: TextStyle(fontSize: 16, color: Colors.white.withValues(alpha: 0.7)),
        ),
        const SizedBox(height: 30),
        Row(
          children: [
            Expanded(
              child: _RoleCard(
                icon: Icons.school_outlined,
                title: l10n.student,
                isSelected: selectedRole == "student",
                onTap: () => onRoleChanged("student"),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _RoleCard(
                icon: Icons.assignment_ind,
                title: l10n.teacher,
                isSelected: selectedRole == "teacher",
                onTap: () => onRoleChanged("teacher"),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 120,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentGold : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.accentGold : Colors.white.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 36,
              color: isSelected ? AppColors.primary : Colors.white,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isSelected ? AppColors.primary : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
