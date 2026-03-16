// lib/features/auth/data/services/auth_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'email_service.dart';
import 'email_auth_service.dart';
import 'google_auth_service.dart';
import 'otp_auth_service.dart';
import 'fcm_service.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/utils/numeric_utils.dart';
import '../../../../core/services/biometric_service.dart';

class AuthService {
  final EmailAuthService _emailAuth = EmailAuthService();
  final GoogleAuthService _googleAuth = GoogleAuthService.instance;
  final BiometricService _biometricService = BiometricService();

  GoogleAuthService get googleAuth => _googleAuth;
  final OtpAuthService _otpAuth = OtpAuthService();
  final FcmService _fcmService = FcmService();
  final EmailService _emailService = EmailService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ============ 🔍 VALIDATION CHECKS (Secure) ============
  // These check the 'locked_' folders we created to prevent duplicates.

  Future<bool> isNameTaken(String name) async {
    try {
      final doc = await _firestore
          .collection('locked_usernames')
          .doc(name.trim().toLowerCase())
          .get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  Future<bool> isEmailTaken(String email) async {
    try {
      final doc = await _firestore
          .collection('locked_emails')
          .doc(email.trim().toLowerCase())
          .get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  Future<bool> isPhoneTaken(String phone) async {
    try {
      final cleanPhone = NumericUtils.normalize(phone, clean: true);
      final doc = await _firestore
          .collection('locked_phones')
          .doc(cleanPhone)
          .get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  // ============ 🟢 PRE-REGISTRATION CHECK ============

  Future<String?> preRegistrationCheck({
    required String name,
    required String email,
    required String phone,
    required String role,
  }) async {
    if (await isNameTaken(name)) return "Username is already taken.";
    if (await isEmailTaken(email)) return "Email is already registered.";

    // Only check phone if it's provided (Teachers)
    if (phone.isNotEmpty) {
      if (await isPhoneTaken(phone)) return "Phone number is already in use.";
    }
    return null;
  }

  // ============ 📧 REGISTER (Delegates to EmailAuthService) ============

  Future<String?> registerWithEmail({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
    required bool acceptedTerms,
    String? phone,
    String? portfolio,
    String? language,
  }) {
    // ✅ No need to pass 'this'. EmailAuthService handles the saving now.
    return _emailAuth.register(
      name: name,
      email: email,
      password: password,
      confirmPassword: confirmPassword,
      acceptedTerms: acceptedTerms,
      phone: phone,
      portfolio: portfolio,
      language: language,
    );
  }

  // ============ 🌍 GOOGLE METHODS ============

  // Note: We pass 'this' because signInWithGoogle signature expects it,
  // even if it doesn't use it heavily.
  Future<String?> loginWithGoogle() => _googleAuth.signInWithGoogle(this);

  Future<String?> loginWithBiometrics() async {
    final credentials = await _biometricService.getSavedCredentials();
    if (credentials == null) return "NO_SAVED_CREDENTIALS";
    
    return loginWithEmail(
      credentials['email']!,
      credentials['password']!,
    );
  }

  Future<String?> createGoogleUserWithRole({
    bool acceptedTerms = true,
    String? phone,
    String? portfolio,
  }) {
    // ✅ No need to pass 'this'. GoogleAuthService handles the saving now.
    return _googleAuth.createGoogleUserWithRole(
      phone: phone,
      portfolio: portfolio,
      acceptedTerms: acceptedTerms,
    );
  }

  // ============ 📱 OTP METHODS ============

  Future<void> startPhoneVerification({
    required String phone,
    required Function(String, int?) codeSent,
    required Function(String) onError,
    int? forceResendingToken,
  }) => _otpAuth.startPhoneVerification(
    phone: phone,
    codeSent: codeSent,
    onError: onError,
    forceResendingToken: forceResendingToken,
  );

  Future<PhoneAuthCredential?> verifySmsCode({
    required String verificationId,
    required String smsCode,
  }) =>
      _otpAuth.verifySmsCode(verificationId: verificationId, smsCode: smsCode);

  // ============ 🛠️ UTILITIES ============

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    await _googleAuth.signOut();
  }

  /// 👻 CLEANUP GHOST ACCOUNT
  /// Deletes the current Firebase Auth user if they don't have a Firestore document.
  /// This "unlocks" their email and phone number if they abandon registration part-way.
  /// Returns [true] if user was a ghost and was handled.
  Future<bool> cleanupGhostAccount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint("👻 Ghost Check: No user logged in. Skipping.");
      return false;
    }

    try {
      debugPrint("👻 Ghost Check: Checking if ${user.uid} (${user.email ?? user.phoneNumber ?? 'Unknown'}) is a ghost...");
      
      // Check if document exists in 'users' collection
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      
      if (!userDoc.exists) {
        debugPrint("👻 Ghost Detected: No Firestore doc for ${user.uid}. Deleting Auth account...");
        
        // Delete from Auth to free up email/phone
        try {
          await user.delete();
          debugPrint("👻 Ghost Cleaned: Auth account deleted successfully.");
        } catch (e) {
          debugPrint("⚠️ Ghost Delete Failed (likely requires recent login): $e");
          // If we can't delete (e.g. requires recent login), we MUST at least sign out
          // so the app doesn't think they are logged in on next start.
        }
        
        // ALWAYS ensure we are signed out locally if it's a ghost
      await signOut();
      return true;
    } else {
      debugPrint("✅ Not a Ghost: Firestore doc exists for ${user.uid}.");
      return false;
    }
  } catch (e) {
    debugPrint("⚠️ Ghost Cleanup Error: $e");
    // Safety sign out
    await signOut();
    return true; // Treat as ghost for safety to return to onboarding
  }
}

  /// 📱 UNLINK PHONE
  /// Removes the phone provider from the current user.
  /// Used if the user wants to go back and change their phone number after verification.
  Future<void> unlinkPhone() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      debugPrint("📱 Unlinking phone for ${user.uid}...");
      // Check for phone provider
      bool hasPhone = user.providerData.any((info) => info.providerId == 'phone');
      
      if (hasPhone) {
        await user.unlink('phone');
        debugPrint("✅ Phone unlinked successfully.");
      } else {
        debugPrint("ℹ️ No phone provider found to unlink.");
      }
    } catch (e) {
      debugPrint("⚠️ Failed to unlink phone: $e");
    }
  }

  /// Soft deletes the user account by anonymizing public data and removing credentials.
  /// Assumes the user has just re-authenticated to satisfy Firebase requirements.
  Future<void> deleteAccount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("No authenticated user found.");

    final uid = user.uid;
    final userDoc = await _firestore.collection('users').doc(uid).get();
    
    if (!userDoc.exists) {
      // If no doc exists, just try to delete auth.
      await user.delete();
      return;
    }

    final data = userDoc.data()!;
    final String role = data['role'] ?? 'student';
    final String? phone = data['phone'];
    final String? email = data['email'];
    final String? oldName = data['name_lower'];

    final batch = _firestore.batch();

    // 1. Anonymize User Document
    final anonymizeUpdates = {
      'name': 'حساب محذوف', // User deleted in Arabic (could localize, hardcoded for DB consistency)
      'name_lower': 'deleted user',
      'photoUrl': null,
      'status': 'deleted',
      'bio': '',
      'phone': '',
      'email': '', // Clear email so they don't receive notifications
      'updatedAt': FieldValue.serverTimestamp(),
    };

    batch.update(_firestore.collection('users').doc(uid), anonymizeUpdates);

    // Sync name changes to their courses if they are a teacher
    if (role == 'teacher') {
      final coursesQuery = await _firestore.collection('courses').where('teacherId', isEqualTo: uid).get();
      for (var doc in coursesQuery.docs) {
        batch.update(doc.reference, {
          'teacherName': 'حساب محذوف',
          'teacherProfilePic': null,
        });
      }
    }

    // 2. Release Locks (Allow these credentials to be used by new users)
    if (email != null && email.isNotEmpty) {
      batch.delete(_firestore.collection('locked_emails').doc(email.trim().toLowerCase()));
    }
    if (phone != null && phone.isNotEmpty) {
      final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
      if (cleanPhone.isNotEmpty) {
        batch.delete(_firestore.collection('locked_phones').doc(cleanPhone));
      }
    }
    if (oldName != null && oldName.isNotEmpty && oldName != 'deleted user') {
      batch.delete(_firestore.collection('locked_usernames').doc(oldName));
    }

    // Attempt to delete photo from storage (fire and forget, don't block if fails)
    try {
      if (data['photoUrl'] != null) {
        final storageRef = FirebaseStorage.instance.refFromURL(data['photoUrl']);
        storageRef.delete().catchError((e) => debugPrint("Failed to delete photo: $e"));
      }
    } catch (e) {
      debugPrint("Storage deletion omitted or failed: $e");
    }

    // 3. Commit Database Changes First!
    await batch.commit();

    // 4. Finally, securely delete the Firebase Auth user.
    // This MUST happen last. If it fails due to "requires recent login", the DB won't be corrupted 
    // because we should prompt re-auth BEFORE calling this function.
    await user.delete();
  }

  Future<String?> loginWithEmail(String email, String password) =>
      _emailAuth.login(email: email, password: password);

  Future<bool> sendEmailOtp(String email, String otpCode) =>
      _emailService.sendOtp(email, otpCode);

  Future<void> saveUserFcmToken(String uid) =>
      _fcmService.saveUserFcmToken(uid);

  // ============ 🔐 PASSWORD RESET METHODS ============

  /// Get the list of sign-in methods (providers) for a given email
  /// Returns list like ['password'], ['google.com'], or ['password', 'google.com']
  Future<List<String>> getUserSignInMethods(String email) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('getUserProviders');
      final result = await callable.call({'email': email});
      final providers = List<String>.from(result.data['providers'] ?? []);
      return providers;
    } on FirebaseFunctionsException catch (e) {
      // If the function doesn't exist yet, don't crash the whole login flow
      if (e.code == 'not-found') {
        debugPrint("ℹ️ Cloud Function 'getUserProviders' not found. This is expected if it wasn't deployed yet.");
        return [];
      }
      debugPrint("Error fetching user providers: ${e.code} - ${e.message}");
      return [];
    } catch (e) {
      debugPrint("Error fetching user providers: $e");
      return [];
    }
  }

  /// Reset password after OTP verification
  /// This works for both email/password users and Google users who want to add a password
  Future<void> resetPasswordWithOtp(String email, String newPassword) async {
    final user = FirebaseAuth.instance.currentUser;
    
    // If user is not logged in, we need to use a different approach
    // Since we can't directly set password without being authenticated,
    // we'll use the password reset email token approach
    if (user == null || user.email != email) {
      throw Exception('User must be authenticated to reset password');
    }
    
    // Update the password for the current user
    await user.updatePassword(newPassword);
  }

  /// Link the pending Google account to the existing email/password account
  /// 1. Re-authenticate with email/password
  /// 2. Link with the pending Google credential
  Future<String?> linkGoogleAccount(String email, String password) async {
    try {
      // 1. Re-authenticate
      // We need a signed-in user to link. But the user isn't signed in yet.
      // So first we sign in with email.
      UserCredential userCred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.trim(), 
        password: password
      );
      
      // 2. Get pending credential
      final googleCred = _googleAuth.pendingGoogleCredential;
      if (googleCred == null) throw Exception("No pending Google credential found");
      
      // 3. Link
      await userCred.user!.linkWithCredential(googleCred);

      // 4. Update Firestore authProvider to 'google'
      final uid = userCred.user!.uid;
      final updates = {'authProvider': 'google'};
      
      final batch = _firestore.batch();
      batch.update(_firestore.collection("users").doc(uid), updates);
      
      await batch.commit();
      
      // 5. Cleanup
      _googleAuth.clearPendingCredential();
      
      final userDoc = await _firestore.collection("users").doc(uid).get();
      if (userDoc.exists) {
        return (userDoc.data() as Map<String, dynamic>)["role"] ?? "student";
      }
      return "student"; // Default fallback
    } catch (e) {
      debugPrint("Error linking account: $e");
      rethrow;
    }
  }
}
