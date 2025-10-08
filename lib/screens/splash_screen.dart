import 'package:flutter/material.dart';
import 'onboarding_screen.dart';
import 'username_screen.dart';
import 'homepage_screen.dart';
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
