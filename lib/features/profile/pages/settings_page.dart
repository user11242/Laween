import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/colors.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:laween/core/services/biometric_service.dart';
import 'package:laween/core/message/app_messenger.dart';
import '../widgets/biometric_auth_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:laween/core/providers/theme_provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;
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
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final notifEnabled = data['notificationsEnabled'] ?? true;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('notifications_enabled', notifEnabled);

        if (mounted) {
          setState(() {
            _notificationsEnabled = notifEnabled;
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
        final isGoogleUser =
            user?.providerData.any((p) => p.providerId == 'google.com') ??
            false;

        if (isGoogleUser) {
          await _biometricService.enableForSocialLogin();
          if (mounted) {
            setState(() => _biometricEnabled = true);
            AppMessenger.showSnackBar(
              context,
              title: l10n.success,
              message: l10n.isAr
                  ? "تم تفعيل البصمة بنجاح"
                  : "Biometrics enabled successfully",
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
                  message: l10n.isAr
                      ? "تم تفعيل البصمة بنجاح"
                      : "Biometrics enabled successfully",
                  type: MessengerType.success,
                );
              }
            }
          }
        } else {
          await _biometricService.saveCredentials(
            credentials['email']!,
            credentials['password']!,
          );
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', value);
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {'notificationsEnabled': value},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AppBar(
        backgroundColor: AppColors.getSurface(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: AppColors.getTextPrimary(context),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.settings,
          style: GoogleFonts.inter(
            color: AppColors.getTextPrimary(context),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.teal),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(
                    l10n.isAr ? "إعدادات الحساب" : "Account Settings",
                  ),
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
                      title: l10n.isAr
                          ? "تسجيل الدخول بالبصمة"
                          : "Biometric Login",
                      value: _biometricEnabled,
                      onChanged: _toggleBiometric,
                    ),
                  const SizedBox(height: 16),
                  _buildAppearanceTile(context),
                ],
              ),
            ),
    );
  }

  Widget _buildAppearanceTile(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isAr = AppLocalizations.of(context)!.isAr;

    return InkWell(
      onTap: () => _showThemeSelector(context),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.getSurfaceElevated(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.getBorder(context)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.teal.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                themeProvider.themeMode == ThemeMode.system
                    ? Icons.brightness_auto_outlined
                    : themeProvider.themeMode == ThemeMode.dark
                        ? Icons.dark_mode_outlined
                        : Icons.light_mode_outlined,
                color: AppColors.teal,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isAr ? "المظهر" : "Appearance",
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.getTextPrimary(context),
                    ),
                  ),
                  Text(
                    themeProvider.getThemeModeNameLocalized(isAr),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.getTextSecondary(context),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.getTextSecondary(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showThemeSelector(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isAr = AppLocalizations.of(context)!.isAr;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.getSurface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.getDivider(context),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                isAr ? "اختر المظهر" : "Choose Appearance",
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.getTextPrimary(context),
                ),
              ),
              const SizedBox(height: 20),
              _buildThemeOption(
                context,
                title: isAr ? "تلقائي (حسب النظام)" : "System default",
                mode: ThemeMode.system,
                currentMode: themeProvider.themeMode,
                icon: Icons.brightness_auto_outlined,
              ),
              _buildThemeOption(
                context,
                title: isAr ? "فاتح" : "Light",
                mode: ThemeMode.light,
                currentMode: themeProvider.themeMode,
                icon: Icons.light_mode_outlined,
              ),
              _buildThemeOption(
                context,
                title: isAr ? "داكن" : "Dark",
                mode: ThemeMode.dark,
                currentMode: themeProvider.themeMode,
                icon: Icons.dark_mode_outlined,
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildThemeOption(
    BuildContext context, {
    required String title,
    required ThemeMode mode,
    required ThemeMode currentMode,
    required IconData icon,
  }) {
    final isSelected = mode == currentMode;
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    return ListTile(
      onTap: () {
        themeProvider.setThemeMode(mode);
        Navigator.pop(context);
      },
      leading: Icon(
        icon,
        color: isSelected ? AppColors.teal : AppColors.getTextSecondary(context),
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? AppColors.teal : AppColors.getTextPrimary(context),
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_circle_rounded, color: AppColors.teal)
          : null,
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
        color: AppColors.getSurfaceElevated(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.getBorder(context)),
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
                color: AppColors.getTextPrimary(context),
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
