import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:laween/features/auth/pages/onboarding_page.dart';
import 'package:laween/features/home/pages/home_page.dart';

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

        // 3. Logged In -> Listen to Firestore Profile Real-time
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
  }

  Widget _buildLoadingScreen() {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: CircularProgressIndicator(color: Color(0xFF006D77)),
      ),
    );
  }
}
