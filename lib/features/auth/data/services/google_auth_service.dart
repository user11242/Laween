// lib/features/auth/data/services/google_auth_service.dart

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart' as gsi;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import 'auth_service.dart';
import '../../../../core/utils/numeric_utils.dart';
import '../../../../core/templates/email_templates.dart';

class GoogleAuthService {
  // --- 1. Singleton Setup ---
  GoogleAuthService._privateConstructor();
  static final GoogleAuthService instance =
      GoogleAuthService._privateConstructor();

  // --- 2. Class Variables ---
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final gsi.GoogleSignIn _googleSignIn = gsi.GoogleSignIn.instance;

  bool _isInitialized = false;
  AuthCredential? _pendingGoogleCredential;
  String? _pendingEmail;

  AuthCredential? get pendingGoogleCredential => _pendingGoogleCredential;
  String? get pendingEmail => _pendingEmail;

  // PUBLIC GETTER FOR CONSISTENCY
  gsi.GoogleSignIn get googleSignIn => _googleSignIn;

  void clearPendingCredential() {
    _pendingGoogleCredential = null;
    _pendingEmail = null;
  }

  /// ---------------------------------------------------------------
  /// 🔹 Initialization Method
  /// ---------------------------------------------------------------
  Future<void> initialize() async {
    if (!_isInitialized) {
      // In v7.x Initialize must be called exactly once.
      await _googleSignIn.initialize();
      _isInitialized = true;
    }
  }

  /// ---------------------------------------------------------------
  /// 🔹 Sign In With Google
  /// ---------------------------------------------------------------
  Future<String?> signInWithGoogle(AuthService authService, {bool silent = false}) async {
    AuthCredential? credential;
    gsi.GoogleSignInAccount? googleUser;
    
    try {
      if (!_isInitialized) {
        await initialize();
      }

      if (silent) {
        googleUser = await _googleSignIn.attemptLightweightAuthentication();
      } else {
        await _googleSignIn.signOut();
        googleUser = await _googleSignIn.authenticate();
      }

      if (googleUser == null) {
        return silent ? "SILENT_SIGN_IN_FAILED" : null;
      }
      
      final googleAuth = googleUser.authentication;
      
      credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      // 🛑 INTERCEPT: Prevent Firebase from silently deleting the password provider.
      if (googleUser.email.isNotEmpty) {
        try {
          final methods = await authService.getUserSignInMethods(googleUser.email);
          if (methods.contains('password') && !methods.contains('google.com')) {
            _pendingGoogleCredential = credential;
            _pendingEmail = googleUser.email;
            return "ACCOUNT_EXISTS_DIFFERENT_CREDENTIAL";
          }
        } catch (e) {
          debugPrint("Error checking providers: $e");
        }
      }

      final userCred = await _auth.signInWithCredential(credential);
      final doc = await _firestore
          .collection("users")
          .doc(userCred.user!.uid)
          .get();

      if (doc.exists) {
        return null; // Success
      } else {
        return "NEEDS_PROFILE";
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'account-exists-with-different-credential') {
        _pendingGoogleCredential = credential;
        _pendingEmail = googleUser?.email;
        return "ACCOUNT_EXISTS_DIFFERENT_CREDENTIAL";
      }
      return e.message;
    } catch (e) {
      debugPrint("Serious error in flow: $e");
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('canceled') || errorStr.contains('cancel')) {
        return "CANCELED";
      }
      return e.toString();
    }
  }

  /// ---------------------------------------------------------------
  /// 🔹 Create User Document (✅ UPDATED FOR FOLDER STRUCTURE)
  /// ---------------------------------------------------------------
  Future<String?> createGoogleUserWithRole({
    // Removed 'authService' because we save directly here for safety
    required bool acceptedTerms,
    String? phone,
    String? portfolio,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return "Not signed in";

    try {
      // 1. Photo Logic
      String finalPhotoUrl = user.photoURL ?? "";

      // 2. Create Model
      UserModel newUser = UserModel(
        uid: user.uid,
        name: user.displayName ?? "User",
        email: user.email ?? "",
        acceptedTerms: acceptedTerms,
        photoUrl: finalPhotoUrl,
        phone: phone ?? "",
        createdAt: DateTime.now(),
        authProvider: 'google', // ✅ Explicitly set provider
        language: ui.PlatformDispatcher.instance.locale.languageCode, // ✅ Capture language
      );

      // 3. 🔹 START BATCH WRITE (The "7 Folder" Logic)
      WriteBatch batch = _firestore.batch();

      // A. Add to 'users' (Master List)
      DocumentReference userRef = _firestore.collection('users').doc(user.uid);
      batch.set(userRef, newUser.toMap());

      // C. Lock the Email (Security)
      if (user.email != null) {
        DocumentReference emailLockRef = _firestore
            .collection('locked_emails')
            .doc(user.email!.trim().toLowerCase());
        batch.set(emailLockRef, {
          'uid': user.uid,
          'createdAt': Timestamp.now(),
        });
      }

      // D. ✅ ADDED: Lock the Username (Security)
      if (newUser.name.isNotEmpty) {
        DocumentReference usernameLockRef = _firestore
            .collection('locked_usernames')
            .doc(newUser.name.trim().toLowerCase());
        batch.set(usernameLockRef, {
          'uid': user.uid,
          'createdAt': Timestamp.now(),
        });
      }

      // E. Lock the Phone (Security - Only if provided)
      if (phone != null && phone.isNotEmpty) {
        final cleanPhone = NumericUtils.normalize(phone, clean: true);
        DocumentReference phoneRef = _firestore
            .collection('locked_phones')
            .doc(cleanPhone);
        batch.set(phoneRef, {
          'uid': user.uid,
          'email': user.email,
          'createdAt': Timestamp.now(),
        });
      }

      // F. ✅ ADDED: Trigger Welcome Email
      if (user.email != null) {
        debugPrint("✅ Queueing welcome email for Google user ${user.email}");
        batch.set(
          _firestore.collection('mail').doc(), // Auto-ID document
          {
            'to': user.email!.trim().toLowerCase(),
            'message': {
              'subject': 'Welcome to Laween! 🕊️',
              'html': EmailTemplates.welcomeEmail(newUser.name),
            },
            'createdAt': Timestamp.now(),
          },
        );
      }

      // 4. Commit everything at once
      await batch.commit();
      debugPrint("✅ Google user document created (uid: ${user.uid})");
      return null; // null means success
    } catch (e) {
      debugPrint("❌ Error creating Google user document: $e");
      return e.toString();
    }
  }

  /// ---------------------------------------------------------------
  /// 🔹 Sign Out
  /// ---------------------------------------------------------------
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      debugPrint("Error signing out: $e");
    }
  }
}
