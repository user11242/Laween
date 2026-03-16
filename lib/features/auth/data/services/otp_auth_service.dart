// lib/features/auth/data/services/otp_auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class OtpAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 🔹 Start Phone Verification
  /// This sends the SMS code to the user.
  Future<void> startPhoneVerification({
    required String phone,
    required Function(String verificationId, int? resendToken) codeSent,
    required Function(String error) onError,
    int? forceResendingToken, // ✅ Added for resend support
  }) async {
    try {
      // 1. CLEAN PHONE: Remove all spaces, dashes, parentheses
      // Keep '+' if it exists at the start
      final String cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
      
      debugPrint("📱 Starting verification for: $cleanPhone (Original: $phone)");

      await _auth.verifyPhoneNumber(
        phoneNumber: cleanPhone,
        forceResendingToken: forceResendingToken,

        // 🤖 ANDROID ONLY: Auto-resolves SMS code without typing
        verificationCompleted: (PhoneAuthCredential cred) async {
          debugPrint("✅ Android Auto-Verification completed");
        },

        // ❌ FAILED
        verificationFailed: (FirebaseAuthException e) {
          String userFriendlyError = "Phone verification failed.";
          
          if (e.code == 'invalid-phone-number') {
            userFriendlyError = "The provided phone number is not valid.";
          } else if (e.code == 'too-many-requests') {
            userFriendlyError = "Too many attempts. Please try again later.";
          } else if (e.code == 'captcha-check-failed') {
            userFriendlyError = "Safety check failed. Please try again.";
          } else if (e.code == 'app-not-authorized') {
            userFriendlyError = "App not authorized. Check SHA-256 fingerprints in Firebase.";
          }

          // Return both the friendly message and the internal code for debugging
          onError("$userFriendlyError (${e.code})");
          debugPrint("❌ Firebase OTP Error: ${e.code} - ${e.message}");
        },

        // 📩 CODE SENT (Standard Flow)
        codeSent: (String verificationId, int? resendToken) {
          debugPrint("✅ OTP Code Sent to $cleanPhone");
          codeSent(verificationId, resendToken);
        },

        // ⏳ TIMEOUT (Auto-retrieval expired)
        codeAutoRetrievalTimeout: (String verificationId) {
          debugPrint("⚠️ SMS Auto-retrieval timeout");
        },
      );
    } catch (e) {
      onError("Failed to start phone verification: $e");
    }
  }

  /// 🔹 Verify OTP Code
  /// Returns the Credential so the caller can decide whether to Link or Sign In.
  Future<PhoneAuthCredential?> verifySmsCode({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      // Create the credential
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      // Just creating the object doesn't verify the code with the server.
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
         try {
           // If a user is logged in (e.g., Google Wizard or linking phone), try to LINK.
           await currentUser.linkWithCredential(credential);
         } on FirebaseAuthException catch (e) {
           if (e.code == 'user-not-found' || e.code == 'user-disabled') {
             // ⚠️ Vital Fix: If the current user was deleted on the server (e.g. by Admin),
             // the local token is stale. linking will fail with 'user-not-found'.
             // We must sign out and treat this as a fresh sign-in.
             debugPrint("⚠️ Stale user detected (User deleted on server). Signing out and retrying...");
             await _auth.signOut();
             // We do NOT sign in here. The registration flow handles auth entirely.
           } else {
             rethrow; // Other errors (like invalid code) should be handled normally
           }
         }
      }

      // If we got here, the code is VALID. We do NOT sign in for new users here, 
      // because Email/Password registration handles the actual account creation later.
      return credential;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'invalid-verification-code') {
        throw "The code you entered is incorrect.";
      } else if (e.code == 'credential-already-in-use') {
         // This is a specific case for linking: the phone is already used.
         throw "This phone number is already linked to another account. If you started registration before, please try to sign in with that account.";
      }
      throw e.message ?? "Invalid OTP Code";
    } catch (e) {
      throw "An unknown error occurred verifying OTP.";
    }
  }
}
