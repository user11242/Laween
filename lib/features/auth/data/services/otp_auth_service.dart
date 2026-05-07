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

      debugPrint(
        "📱 Starting verification for: $cleanPhone (Original: $phone)",
      );

      await _auth.verifyPhoneNumber(
        phoneNumber: cleanPhone,
        forceResendingToken: forceResendingToken,

        // 🤖 ANDROID ONLY: Auto-resolves SMS code without typing
        verificationCompleted: (PhoneAuthCredential cred) async {
          debugPrint("✅ Android Auto-Verification completed");
          // If auto-verification happens, we can immediately verify it.
          // Note: We don't have the verificationId here, but the credential itself is enough.
          try {
             final currentUser = _auth.currentUser;
             if (currentUser != null) {
               await currentUser.linkWithCredential(cred);
             } else {
               final userCred = await _auth.signInWithCredential(cred);
               if (userCred.user != null) await _auth.signOut();
             }
             // How do we tell the UI to move forward? 
             // We can use a callback or just let the UI handle the standard codeSent flow.
             // Usually, for auto-verification, we might want to notify the caller.
          } catch (e) {
             debugPrint("❌ Auto-verification error: $e");
          }
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
            userFriendlyError =
                "App not authorized. Check SHA-256 fingerprints in Firebase.";
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
      // 1. Create the credential
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      // 2. ACTUALLY VERIFY with the server
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        // CASE A: User is logged in (e.g. Google Sign-in Wizard). LINK the phone.
        try {
          // 🚨 FIX: If the user already has a phone linked, unlink it first.
          final hasPhone = currentUser.providerData.any((p) => p.providerId == 'phone');
          if (hasPhone) {
            debugPrint("📱 User already has a phone linked. Unlinking first...");
            await currentUser.unlink('phone');
          }

          debugPrint("📱 Linking phone OTP to current user...");
          await currentUser.linkWithCredential(credential);
        } on FirebaseAuthException catch (e) {
          if (e.code == 'user-not-found' || e.code == 'user-disabled' || e.code == 'invalid-user-token') {
            // 👻 STALE USER: The user was deleted on the server or the token is dead.
            debugPrint("⚠️ Stale user detected. Signing out and retrying...");
            await _auth.signOut();
            return verifySmsCode(verificationId: verificationId, smsCode: smsCode); // Recursive retry as Guest
          }
          rethrow;
        }
      } else {
        // CASE B: No user logged in (e.g. Email Registration). 
        // To verify the code is correct, we MUST attempt a sign-in.
        debugPrint("📱 Verifying phone OTP via temporary sign-in...");
        final userCred = await _auth.signInWithCredential(credential);
        
        // If we reached here, the code is 100% correct.
        if (userCred.user != null) {
          debugPrint("✅ Phone OTP verified. Signing out temporary session.");
          await _auth.signOut();
        }
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      debugPrint("❌ verifySmsCode Error: ${e.code} - ${e.message}");
      if (e.code == 'invalid-verification-code') {
        throw "The code you entered is incorrect. Please check your messages and try again.";
      } else if (e.code == 'credential-already-in-use') {
        throw "This phone number is already linked to another account. Please use a different number.";
      } else if (e.code == 'session-expired') {
        throw "Verification session has expired. Please request a new code.";
      } else if (e.code == 'app-not-authorized') {
        throw "App not authorized. This usually means the SHA-1 fingerprint is missing in Firebase or the package name is mismatched. Please ensure you ran 'flutter clean'.";
      }
      throw e.message ?? "Verification failed: ${e.code}";
    } catch (e) {
      debugPrint("❌ verifySmsCode Unknown Error: $e");
      throw "An unexpected error occurred during verification.";
    }
  }
}
