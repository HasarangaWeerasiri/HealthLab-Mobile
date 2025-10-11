import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'fingerprint_service.dart';

class AuthService {
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _userIdKey = 'user_id';
  static const String _userEmailKey = 'user_email';
  static const String _usernameKey = 'username';
  static const String _userPreferencesKey = 'user_preferences';
  static const String _lastLoginKey = 'last_login';
  static const String _fingerprintEnabledKey = 'fingerprint_enabled';
  static const String _pinKey = 'user_pin';

  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Check if user is logged in (both Firebase and local storage)
  Future<bool> isLoggedIn() async {
    try {
      // Check Firebase auth state only
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        await _clearLocalData();
        return false;
      }

      // Ensure local cache exists
      await saveUserData(user);

      // Check local storage
      final prefs = await SharedPreferences.getInstance();
      final isLoggedInLocally = prefs.getBool(_isLoggedInKey) ?? false;
      final storedUserId = prefs.getString(_userIdKey);

      // If Firebase user matches stored user, return true
      if (isLoggedInLocally && storedUserId == user.uid) {
        return true;
      }

      // If Firebase user exists but no local data, save it and proceed
      await saveUserData(user);
      return true;
    } catch (e) {
      print('Error checking login status: $e');
      return false;
    }
  }

  // Save user data to local storage
  Future<void> saveUserData(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_isLoggedInKey, true);
      await prefs.setString(_userIdKey, user.uid);
      await prefs.setString(_userEmailKey, user.email ?? '');
      await prefs.setString(_lastLoginKey, DateTime.now().toIso8601String());

      // Try to get additional user data from Firestore
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        if (userDoc.exists) {
          final data = userDoc.data()!;
          await prefs.setString(_usernameKey, data['username'] ?? '');
          
          // Save profile picture if available
          if (data['profilePicture'] != null) {
            await prefs.setString('profile_picture', data['profilePicture']);
          }
          
          // Save preferences if available
          if (data['preferences'] != null) {
            final preferences = List<String>.from(data['preferences']);
            await prefs.setStringList(_userPreferencesKey, preferences);
          }
        }
      } catch (e) {
        print('Error fetching user data from Firestore: $e');
        // Continue without additional data
      }
    } catch (e) {
      print('Error saving user data: $e');
    }
  }

  // Get stored user data
  Future<Map<String, dynamic>> getStoredUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return {
        'userId': prefs.getString(_userIdKey),
        'email': prefs.getString(_userEmailKey),
        'username': prefs.getString(_usernameKey),
        'preferences': prefs.getStringList(_userPreferencesKey) ?? [],
        'lastLogin': prefs.getString(_lastLoginKey),
        'profilePicture': prefs.getString('profile_picture'),
        'fingerprintEnabled': prefs.getBool(_fingerprintEnabledKey) ?? false,
      };
    } catch (e) {
      print('Error getting stored user data: $e');
      return {};
    }
  }

  // Update user preferences in local storage
  Future<void> updateUserPreferences(List<String> preferences) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_userPreferencesKey, preferences);
    } catch (e) {
      print('Error updating user preferences: $e');
    }
  }

  // Validate username format
  String? validateUsername(String username) {
    if (username.isEmpty) {
      return 'Username cannot be empty';
    }
    
    if (username.length < 3) {
      return 'Username must be at least 3 characters long';
    }
    
    if (username.length > 20) {
      return 'Username cannot exceed 20 characters';
    }
    
    // Allow only alphanumeric characters and underscores
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username)) {
      return 'Username can only contain letters, numbers, and underscores';
    }
    
    // Cannot start with underscore or number
    if (username.startsWith('_') || RegExp(r'^[0-9]').hasMatch(username)) {
      return 'Username must start with a letter';
    }
    
    return null; // Valid username
  }

  // Check if username is already taken by another user
  Future<bool> isUsernameTaken(String username) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentUserId = prefs.getString(_userIdKey);
      
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: username.toLowerCase())
          .get();
      
      // If no documents found, username is available
      if (querySnapshot.docs.isEmpty) {
        return false;
      }
      
      // If documents found, check if any belong to a different user
      for (var doc in querySnapshot.docs) {
        if (doc.id != currentUserId) {
          return true; // Username is taken by another user
        }
      }
      
      return false; // Username belongs to current user or is available
    } catch (e) {
      print('Error checking username availability: $e');
      throw e;
    }
  }

  // Update username in both local storage and Firestore
  Future<void> updateUsername(String username) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(_userIdKey);
      
      if (userId != null) {
        // Validate username format
        final validationError = validateUsername(username);
        if (validationError != null) {
          throw Exception(validationError);
        }
        
        // Check if username is already taken
        final isTaken = await isUsernameTaken(username);
        if (isTaken) {
          throw Exception('Username is already taken. Please choose a different username.');
        }
        
        // Store username in lowercase for consistency
        final usernameToStore = username.toLowerCase();
        
        // Update in Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update({'username': usernameToStore});
        
        // Update in local storage
        await prefs.setString(_usernameKey, usernameToStore);
      }
    } catch (e) {
      print('Error updating username: $e');
      throw e; // Re-throw to handle in UI
    }
  }

  // Update profile picture URL in both local storage and Firestore
  Future<void> updateProfilePicture(String profilePictureUrl) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(_userIdKey);
      
      if (userId != null) {
        // Update in Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update({'profilePicture': profilePictureUrl});
        
        // Update in local storage
        await prefs.setString('profile_picture', profilePictureUrl);
      }
    } catch (e) {
      print('Error updating profile picture: $e');
      throw e; // Re-throw to handle in UI
    }
  }

  // Clear all local data
  Future<void> _clearLocalData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_isLoggedInKey);
      await prefs.remove(_userIdKey);
      await prefs.remove(_userEmailKey);
      await prefs.remove(_usernameKey);
      await prefs.remove(_userPreferencesKey);
      await prefs.remove(_lastLoginKey);
      await prefs.remove('profile_picture');
      await prefs.remove(_fingerprintEnabledKey);
      await prefs.remove(_pinKey);
    } catch (e) {
      print('Error clearing local data: $e');
    }
  }

  // Sign out and clear local data
  Future<void> signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      await _clearLocalData();
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  // Check if user has completed onboarding
  Future<bool> hasCompletedOnboarding() async {
    try {
      final userData = await getStoredUserData();
      return userData['username'] != null && 
             userData['username']!.isNotEmpty &&
             (userData['preferences'] as List).isNotEmpty;
    } catch (e) {
      print('Error checking onboarding status: $e');
      return false;
    }
  }

  // Get the appropriate screen to navigate to based on auth state
  Future<String> getInitialRoute() async {
    try {
      final userLoggedIn = await isLoggedIn();
      if (!userLoggedIn) {
        return '/onboarding';
      }

      final hasOnboarding = await hasCompletedOnboarding();
      if (!hasOnboarding) {
        return '/username';
      }

      return '/homepage';
    } catch (e) {
      print('Error getting initial route: $e');
      return '/onboarding';
    }
  }

  // Fingerprint Authentication Methods

  /// Check if fingerprint authentication is available on the device
  Future<bool> isFingerprintAvailable() async {
    try {
      final fingerprintService = FingerprintService();
      return await fingerprintService.isBiometricAvailable();
    } catch (e) {
      print('Error checking fingerprint availability: $e');
      return false;
    }
  }

  /// Get fingerprint authentication status
  Future<bool> isFingerprintEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_fingerprintEnabledKey) ?? false;
    } catch (e) {
      print('Error checking fingerprint enabled status: $e');
      return false;
    }
  }

  /// Enable fingerprint authentication
  Future<bool> enableFingerprint() async {
    try {
      final fingerprintService = FingerprintService();
      
      // Check if biometric is available
      final isAvailable = await fingerprintService.isBiometricAvailable();
      if (!isAvailable) {
        throw Exception('Fingerprint authentication is not available on this device');
      }

      // Test authentication to ensure it works
      final didAuthenticate = await fingerprintService.authenticateWithBiometric(
        reason: 'Enable fingerprint authentication for HealthLab',
        cancelButton: 'Cancel',
      );

      if (didAuthenticate) {
        // Save the setting
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_fingerprintEnabledKey, true);
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print('Error enabling fingerprint: $e');
      throw e;
    }
  }

  /// Disable fingerprint authentication
  Future<void> disableFingerprint() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_fingerprintEnabledKey, false);
    } catch (e) {
      print('Error disabling fingerprint: $e');
      throw e;
    }
  }

  /// Authenticate using fingerprint
  Future<bool> authenticateWithFingerprint() async {
    try {
      final fingerprintService = FingerprintService();
      return await fingerprintService.authenticateWithBiometric(
        reason: 'Authenticate to access HealthLab',
        cancelButton: 'Cancel',
      );
    } catch (e) {
      print('Error authenticating with fingerprint: $e');
      throw e;
    }
  }

  /// Get biometric description for UI display
  Future<String> getBiometricDescription() async {
    try {
      final fingerprintService = FingerprintService();
      return await fingerprintService.getBiometricDescription();
    } catch (e) {
      print('Error getting biometric description: $e');
      return 'Biometric authentication not available';
    }
  }

  // PIN Authentication Methods

  /// Check if PIN is set up
  Future<bool> isPinSet() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pin = prefs.getString(_pinKey);
      return pin != null && pin.isNotEmpty;
    } catch (e) {
      print('Error checking PIN status: $e');
      return false;
    }
  }

  /// Set up PIN for the user
  Future<void> setPin(String pin) async {
    try {
      if (pin.length != 4) {
        throw Exception('PIN must be exactly 4 digits');
      }
      
      if (!RegExp(r'^\d{4}$').hasMatch(pin)) {
        throw Exception('PIN must contain only numbers');
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_pinKey, pin);
    } catch (e) {
      print('Error setting PIN: $e');
      throw e;
    }
  }

  /// Verify PIN
  Future<bool> verifyPin(String pin) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedPin = prefs.getString(_pinKey);
      
      if (storedPin == null) {
        return false;
      }
      
      return storedPin == pin;
    } catch (e) {
      print('Error verifying PIN: $e');
      return false;
    }
  }

  /// Update PIN (requires current PIN verification)
  Future<bool> updatePin(String currentPin, String newPin) async {
    try {
      // Verify current PIN first
      final isCurrentPinValid = await verifyPin(currentPin);
      if (!isCurrentPinValid) {
        return false;
      }

      // Set new PIN
      await setPin(newPin);
      return true;
    } catch (e) {
      print('Error updating PIN: $e');
      return false;
    }
  }

  /// Remove PIN
  Future<void> removePin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_pinKey);
    } catch (e) {
      print('Error removing PIN: $e');
      throw e;
    }
  }
}
