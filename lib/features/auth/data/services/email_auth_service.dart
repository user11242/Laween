import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../../../../core/utils/numeric_utils.dart';

class EmailAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ============ 📧 REGISTER ============
  Future<String?> register({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
    required bool acceptedTerms,
    String? phone,
    String? portfolio,
    String? language,
  }) async {
    if (password != confirmPassword) return "Passwords do not match.";
 
    try {
      debugPrint("DEBUG: Creating Auth user for $email");
      // 1. Create User in Auth
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);
      String uid = userCredential.user!.uid;
      debugPrint("DEBUG: Auth user created: $uid");
 
 
      // 3. Prepare Model
      UserModel newUser = UserModel(
        uid: uid,
        email: email,
        name: name,
        phone: phone ?? '',
        acceptedTerms: acceptedTerms,
        createdAt: DateTime.now(),
        photoUrl: '', // Profile photo can be uploaded later
        authProvider: 'email', // ✅ Explicitly set provider
        language: language ?? 'en',
      );
 
      debugPrint("DEBUG: Starting document batch write for $uid");
      // 4. Batch Write
      WriteBatch batch = _firestore.batch();
      batch.set(_firestore.collection('users').doc(uid), newUser.toMap());
 
      // Locks
      batch.set(
        _firestore.collection('locked_emails').doc(email.trim().toLowerCase()),
        {'uid': uid, 'createdAt': Timestamp.now()},
      );
      batch.set(
        _firestore
            .collection('locked_usernames')
            .doc(name.trim().toLowerCase()),
        {'uid': uid, 'createdAt': Timestamp.now()},
      );
 
      // ✅ ADDED: Lock the Phone (Security - Only if provided)
      if (phone != null && phone.isNotEmpty) {
        final cleanPhone = NumericUtils.normalize(phone, clean: true);
        debugPrint("DEBUG: Locking phone: $cleanPhone");
        batch.set(
          _firestore.collection('locked_phones').doc(cleanPhone),
          {
            'uid': uid,
            'email': email.trim().toLowerCase(),
            'createdAt': Timestamp.now(),
          },
        );
      }
 
      await batch.commit();
      debugPrint("DEBUG: Batch commit successful for $uid");
      return null;
    } on FirebaseAuthException catch (e) {
      debugPrint("DEBUG: FirebaseAuthException: ${e.message}");
      return e.message;
    } catch (e) {
      debugPrint("DEBUG: General Registration error: $e");
      return "Registration error: $e";
    }
  }

  // ============ 🔓 LOGIN ============
  Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      
      DocumentSnapshot doc = await _firestore.collection('users').doc(cred.user!.uid).get();
      if (doc.exists) {
        return null; // Success
      }
      
      return null; // Document might not exist if it's a ghost, but Auth succeeded.
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return "An unexpected error occurred during login.";
    }
  }
}
