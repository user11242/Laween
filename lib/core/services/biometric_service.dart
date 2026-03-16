import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const String _credentialsKey = 'user_credentials';
  static const String _biometricEnabledKey = 'biometric_enabled';

  /// Check if biometrics are available and configured on the device
  Future<bool> isBiometricAvailable() async {
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await _auth.isDeviceSupported();
      return canAuthenticate;
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// Check which types of biometrics are available (Face, Fingerprint, etc.)
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } on PlatformException catch (_) {
      return <BiometricType>[];
    }
  }

  /// Perform biometric authentication
  Future<bool> authenticate({String reason = 'Please authenticate to log in'}) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// Save credentials securely
  Future<void> saveCredentials(String email, String password) async {
    final credentials = {
      'email': email,
      'password': password,
    };
    await _storage.write(key: _credentialsKey, value: jsonEncode(credentials));
    await _storage.write(key: _biometricEnabledKey, value: 'true');
  }

  /// Retrieve saved credentials
  Future<Map<String, String>?> getSavedCredentials() async {
    final String? credentialsJson = await _storage.read(key: _credentialsKey);
    if (credentialsJson == null) return null;
    
    try {
      final Map<String, dynamic> decoded = jsonDecode(credentialsJson);
      return {
        'email': decoded['email'] as String,
        'password': decoded['password'] as String,
      };
    } catch (_) {
      return null;
    }
  }

  /// Check if biometric login is enabled by the user
  Future<bool> isBiometricEnabled() async {
    final String? enabled = await _storage.read(key: _biometricEnabledKey);
    return enabled == 'true';
  }

  /// Disable biometric login
  Future<void> disableBiometric() async {
    await _storage.write(key: _biometricEnabledKey, value: 'false');
  }

  /// Completely clear saved credentials
  Future<void> clearCredentials() async {
    await _storage.delete(key: _credentialsKey);
    await _storage.delete(key: _biometricEnabledKey);
  }
}
