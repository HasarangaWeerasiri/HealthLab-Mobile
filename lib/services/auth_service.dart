import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _userIdKey = 'user_id';
  static const String _userEmailKey = 'user_email';
  static const String _usernameKey = 'username';
  static const String _userPreferencesKey = 'user_preferences';
  static const String _lastLoginKey = 'last_login';

  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Check if user is logged in (both Firebase and local storage)
  Future<bool> isLoggedIn() async {
    try {
      // Check Firebase auth state
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        await _clearLocalData();
        return false;
      }

      // Check if user is verified
      if (!user.emailVerified) {
        return false;
      }

      // Check local storage
      final prefs = await SharedPreferences.getInstance();
      final isLoggedInLocally = prefs.getBool(_isLoggedInKey) ?? false;
      final storedUserId = prefs.getString(_userIdKey);

      // If Firebase user matches stored user, return true
      if (isLoggedInLocally && storedUserId == user.uid) {
        return true;
      }

      // If Firebase user exists but no local data, save it
      if (user.emailVerified) {
        await saveUserData(user);
        return true;
      }

      return false;
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

  // Update username in local storage
  Future<void> updateUsername(String username) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_usernameKey, username);
    } catch (e) {
      print('Error updating username: $e');
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
}
