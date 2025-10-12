import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';

class FingerprintService {
  static final FingerprintService _instance = FingerprintService._internal();
  factory FingerprintService() => _instance;
  FingerprintService._internal();

  final LocalAuthentication _localAuth = LocalAuthentication();

  /// Check if biometric authentication is available on the device
  Future<bool> isBiometricAvailable() async {
    try {
      final bool isAvailable = await _localAuth.canCheckBiometrics;
      final bool isDeviceSupported = await _localAuth.isDeviceSupported();
      
      return isAvailable && isDeviceSupported;
    } catch (e) {
      print('Error checking biometric availability: $e');
      return false;
    }
  }

  /// Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      print('Error getting available biometrics: $e');
      return [];
    }
  }

  /// Authenticate using biometric (fingerprint/face)
  Future<bool> authenticateWithBiometric({
    String reason = 'Please authenticate to continue',
    String cancelButton = 'Cancel',
    String? goToSettingsButton,
  }) async {
    try {
      final bool isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        throw PlatformException(
          code: 'biometric_not_available',
          message: 'Biometric authentication is not available on this device',
        );
      }

      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      return didAuthenticate;
    } on PlatformException catch (e) {
      print('Biometric authentication error: ${e.code} - ${e.message}');
      
      switch (e.code) {
        case 'NotAvailable':
          throw Exception('Biometric authentication is not available on this device');
        case 'NotEnrolled':
          throw Exception('No biometric data is enrolled. Please set up biometric authentication in your device settings.');
        case 'LockedOut':
          throw Exception('Biometric authentication is locked. Please use your device passcode.');
        case 'PermanentlyLockedOut':
          throw Exception('Biometric authentication is permanently locked. Please use your device passcode.');
        case 'UserCancel':
          return false; // User cancelled, not an error
        case 'SystemCancel':
          throw Exception('Authentication was cancelled by the system');
        case 'InvalidContext':
          throw Exception('Invalid authentication context');
        case 'NotInteractive':
          throw Exception('Authentication is not interactive');
        default:
          throw Exception('Biometric authentication failed: ${e.message}');
      }
    } catch (e) {
      print('Unexpected biometric authentication error: $e');
      throw Exception('An unexpected error occurred during biometric authentication');
    }
  }

  /// Check if biometric authentication is enabled for the app
  Future<bool> isBiometricEnabled() async {
    try {
      final bool isAvailable = await isBiometricAvailable();
      if (!isAvailable) return false;

      // Try to authenticate with a very short timeout to check if it's enabled
      // This is a workaround since there's no direct way to check if biometric is enabled
      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Checking biometric availability',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: false,
        ),
      );

      return didAuthenticate;
    } catch (e) {
      // If authentication fails, it might mean biometric is not enabled
      return false;
    }
  }

  /// Get a user-friendly description of available biometric types
  Future<String> getBiometricDescription() async {
    try {
      final List<BiometricType> biometrics = await getAvailableBiometrics();
      
      if (biometrics.isEmpty) {
        return 'No biometric authentication available';
      }
      
      if (biometrics.contains(BiometricType.fingerprint)) {
        return 'Fingerprint authentication available';
      } else if (biometrics.contains(BiometricType.face)) {
        return 'Face authentication available';
      } else if (biometrics.contains(BiometricType.iris)) {
        return 'Iris authentication available';
      } else {
        return 'Biometric authentication available';
      }
    } catch (e) {
      return 'Biometric authentication not available';
    }
  }
}
