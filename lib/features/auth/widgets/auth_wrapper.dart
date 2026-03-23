import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import 'package:laween/features/auth/pages/onboarding_page.dart';
import 'package:laween/features/home/pages/home_page.dart';
import 'package:laween/core/services/biometric_service.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        // 1. Connection Loading
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingScreen();
        }

        final user = authSnapshot.data;

        // 2. Not Logged In -> Onboarding
        if (user == null) {
          return const OnboardingPage();
        }

        // 3. Logged In -> Check if App is Locked (Biometrics)
        return FutureBuilder<bool>(
          future: BiometricService().isAppLocked(),
          builder: (context, lockedSnapshot) {
            if (lockedSnapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingScreen();
            }

            final isLocked = lockedSnapshot.data ?? false;
            
            // If the app is locked, force them to the login/onboarding screen
            if (isLocked) {
              return const OnboardingPage();
            }

            // 4. Not Locked -> Listen to Firestore Profile Real-time
            return StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
              builder: (context, docSnapshot) {
                // Profile Check connection
                if (docSnapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoadingScreen();
                }

                final docExists = docSnapshot.data?.exists ?? false;

                if (!docExists) {
                  return const OnboardingPage();
                }

                // Profile exists -> Home
                return const HomePage();
              },
            );
          },
        );
      },
    );
  }

  Widget _buildLoadingScreen() {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: CircularProgressIndicator(color: AppColors.teal),
      ),
    );
  }
}
