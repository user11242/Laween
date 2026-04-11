import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/colors.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:laween/core/services/biometric_service.dart';
import 'package:laween/core/message/app_messenger.dart';
import '../widgets/biometric_auth_dialog.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  bool _biometricEnabled = false;
  bool _isBiometricAvailable = false;
  bool _isLoading = true;
  final _biometricService = BiometricService();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final available = await _biometricService.isBiometricAvailable();
    final enabled = await _biometricService.isBiometricEnabled();
    
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            _notificationsEnabled = data['notificationsEnabled'] ?? true;
            _darkModeEnabled = data['darkModeEnabled'] ?? false;
            _biometricEnabled = enabled;
            _isBiometricAvailable = available;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _biometricEnabled = enabled;
            _isBiometricAvailable = available;
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    final l10n = AppLocalizations.of(context, listen: false)!;
    if (value) {
      final authenticated = await _biometricService.authenticate(
        reason: AppLocalizations.of(context)!.isAr 
            ? "قم بتأكيد هويتك لتفعيل الدخول بالبصمة" 
            : "Confirm your identity to enable biometric login",
      );
      
      if (authenticated) {
        final user = FirebaseAuth.instance.currentUser;
        final isGoogleUser = user?.providerData.any((p) => p.providerId == 'google.com') ?? false;

        if (isGoogleUser) {
          await _biometricService.enableForSocialLogin();
          if (mounted) {
            setState(() => _biometricEnabled = true);
            AppMessenger.showSnackBar(
              context,
              title: l10n.success,
              message: l10n.isAr ? "تم تفعيل البصمة بنجاح" : "Biometrics enabled successfully",
              type: MessengerType.success,
            );
          }
          return;
        }

        final credentials = await _biometricService.getSavedCredentials();
        if (credentials == null) {
          if (!mounted) return;
          if (mounted) {
            final password = await showDialog<String>(
              context: context,
              barrierDismissible: false,
              builder: (context) => const BiometricAuthDialog(),
            );
            
            if (password != null && mounted) {
              if (user != null && user.email != null) {
                await _biometricService.saveCredentials(user.email!, password);
                if (!mounted) return;
                setState(() => _biometricEnabled = true);
                AppMessenger.showSnackBar(
                  context,
                  title: l10n.success,
                  message: l10n.isAr ? "تم تفعيل البصمة بنجاح" : "Biometrics enabled successfully",
                  type: MessengerType.success,
                );
              }
            }
          }
        } else {
          await _biometricService.saveCredentials(credentials['email']!, credentials['password']!);
          if (mounted) setState(() => _biometricEnabled = true);
        }
      }
    } else {
      await _biometricService.disableBiometric();
      if (mounted) setState(() => _biometricEnabled = false);
    }
  }

  Future<void> _toggleNotifications(bool value) async {
    setState(() => _notificationsEnabled = value);
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'notificationsEnabled': value,
      });
    }
  }

  Future<void> _toggleDarkMode(bool value) async {
    setState(() => _darkModeEnabled = value);
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'darkModeEnabled': value,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.settings,
          style: GoogleFonts.inter(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.teal))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader("Account Settings"),
                  const SizedBox(height: 16),
                  _buildSettingTile(
                    icon: Icons.notifications_active_outlined,
                    title: l10n.notifications,
                    value: _notificationsEnabled,
                    onChanged: _toggleNotifications,
                  ),
                  const SizedBox(height: 16),
                  if (_isBiometricAvailable)
                    _buildSettingTile(
                      icon: Icons.fingerprint,
                      title: l10n.isAr ? "تسجيل الدخول بالبصمة" : "Biometric Login",
                      value: _biometricEnabled,
                      onChanged: _toggleBiometric,
                    ),
                  const SizedBox(height: 40),

                  _buildSectionHeader("Appearance"),
                  const SizedBox(height: 16),
                  _buildSettingTile(
                    icon: Icons.dark_mode_outlined,
                    title: l10n.darkMode,
                    value: _darkModeEnabled,
                    onChanged: _toggleDarkMode,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: AppColors.teal,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.teal.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.teal, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF2D3748),
              ),
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppColors.teal,
          ),
        ],
      ),
    );
  }
}
