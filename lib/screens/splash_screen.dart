import 'package:flutter/material.dart';
import 'onboarding_screen.dart';
import 'username_screen.dart';
import 'homepage_screen.dart';
import 'sign_in_screen.dart';
import '../services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    // Show splash for at least 1.5 seconds
    await Future.delayed(const Duration(milliseconds: 1500));
    
    if (!mounted) return;

    try {
      final authService = AuthService();
      final initialRoute = await authService.getInitialRoute();
      
      // Check if user is logged in and fingerprint is enabled
      if (initialRoute == '/homepage') {
        final isFingerprintEnabled = await authService.isFingerprintEnabled();
        final isFingerprintAvailable = await authService.isFingerprintAvailable();
        
        if (isFingerprintEnabled && isFingerprintAvailable) {
          // Show fingerprint authentication
          await _authenticateWithFingerprint();
          return;
        }
      }
      
      Widget destination;
      switch (initialRoute) {
        case '/homepage':
          destination = const HomepageScreen();
          break;
        case '/username':
          destination = const UsernameScreen();
          break;
        default:
          destination = const OnboardingScreen();
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => destination),
      );
    } catch (e) {
      // If there's an error, default to onboarding
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        );
      }
    }
  }

  Future<void> _authenticateWithFingerprint() async {
    try {
      final authService = AuthService();
      final success = await authService.authenticateWithFingerprint();
      
      if (mounted) {
        if (success) {
          // Authentication successful, proceed to homepage
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomepageScreen()),
          );
        } else {
          // Authentication failed or cancelled, show error and go to sign-in
          _showAuthenticationFailedDialog();
        }
      }
    } catch (e) {
      if (mounted) {
        // Handle authentication errors
        String errorMessage = 'Authentication failed';
        
        if (e.toString().contains('not available')) {
          errorMessage = 'Fingerprint authentication is not available';
        } else if (e.toString().contains('not enrolled')) {
          errorMessage = 'Please set up fingerprint authentication in your device settings';
        } else if (e.toString().contains('locked')) {
          errorMessage = 'Fingerprint authentication is locked. Please use your device passcode';
        }
        
        _showAuthenticationErrorDialog(errorMessage);
      }
    }
  }

  void _showAuthenticationFailedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF00432D),
        title: const Text(
          'Authentication Required',
          style: TextStyle(color: Color(0xFFE6FDD8)),
        ),
        content: const Text(
          'Fingerprint authentication is required to access the app. Please try again or sign in with your credentials.',
          style: TextStyle(color: Color(0xFFE6FDD8)),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Go to sign-in screen
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const SignInScreen()),
              );
            },
            child: const Text(
              'Sign In',
              style: TextStyle(color: Color(0xFFE6FDD8)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Try fingerprint authentication again
              _authenticateWithFingerprint();
            },
            child: const Text(
              'Try Again',
              style: TextStyle(color: Color(0xFFE6FDD8)),
            ),
          ),
        ],
      ),
    );
  }

  void _showAuthenticationErrorDialog(String errorMessage) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF00432D),
        title: const Text(
          'Authentication Error',
          style: TextStyle(color: Color(0xFFE6FDD8)),
        ),
        content: Text(
          errorMessage,
          style: const TextStyle(color: Color(0xFFE6FDD8)),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Go to sign-in screen
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const SignInScreen()),
              );
            },
            child: const Text(
              'Sign In',
              style: TextStyle(color: Color(0xFFE6FDD8)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF201E1A),
      body: Center(
        child: Image(
          image: AssetImage('assets/logo.png'),
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
