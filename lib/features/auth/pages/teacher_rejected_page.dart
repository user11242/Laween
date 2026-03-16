import 'package:flutter/material.dart';
import 'package:laween/l10n/app_localizations.dart';
import 'package:laween/core/theme/colors.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';

class TeacherRejectedPage extends StatefulWidget {
  const TeacherRejectedPage({super.key});

  @override
  State<TeacherRejectedPage> createState() => _TeacherRejectedPageState();
}

class _TeacherRejectedPageState extends State<TeacherRejectedPage> {
  bool _isDeleting = false;

  Future<void> _deleteAccount() async {
    final l10n = AppLocalizations.of(context)!;
    
    // 1. Confirm with user
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F1F1F),
        title: Text(l10n.deleteAccountConfirmTitle, style: const TextStyle(color: Colors.white)),
        content: Text(l10n.deleteAccountConfirmMessage, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel, style: const TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.deleteMyAccount, style: const TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isDeleting = true);

    try {
      // 2. Call Cloud Function to delete own account
      final callable = FirebaseFunctions.instance.httpsCallable('deleteOwnAccount');
      await callable.call();
      
      // 3. User is deleted from Auth, so StreamBuilder in AuthWrapper will revert to Onboarding
      // No need to navigate manually, but we can show a success msg if useful
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.success)),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isDeleting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${l10n.error}: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon or illustration
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.assignment_late_outlined,
                  color: Colors.redAccent,
                  size: 64,
                ),
              ).animate().scale(delay: 200.ms, duration: 600.ms, curve: Curves.easeOutBack),
              
              const SizedBox(height: 32),
              
              Text(
                l10n.teacherApplicationRejectedTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ).animate().fadeIn(delay: 400.ms),
              
              const SizedBox(height: 16),
              
              Text(
                l10n.teacherApplicationRejectedMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 16,
                  height: 1.5,
                ),
              ).animate().fadeIn(delay: 600.ms),
              
              const SizedBox(height: 48),
              
              // Contact Support Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Logic for contact support (e.g. email)
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.contactSupport)),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(l10n.contactSupport, style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ).animate().slideY(begin: 0.2, delay: 800.ms),
              
              const SizedBox(height: 16),
              
              // Delete My Account Button
              if (_isDeleting)
                const CircularProgressIndicator(color: Colors.redAccent)
              else
                TextButton(
                  onPressed: _deleteAccount,
                  child: Text(
                    l10n.deleteMyAccount,
                    style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.normal),
                  ),
                ).animate().fadeIn(delay: 1000.ms),
              
              const SizedBox(height: 32),
              
              // Logout Option
              TextButton(
                onPressed: () => FirebaseAuth.instance.signOut(),
                child: Text(
                  l10n.signOut,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                ),
              ).animate().fadeIn(delay: 1200.ms),
            ],
          ),
        ),
      ),
    );
  }
}
