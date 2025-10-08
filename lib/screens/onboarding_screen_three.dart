import 'package:flutter/material.dart';
import '../utils/app_utils.dart';
import 'sign_up_screen.dart';

class OnboardingScreenThree extends StatelessWidget {
  const OnboardingScreenThree({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const SizedBox(height: 12),
              Expanded(
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Icon(Icons.local_hospital, size: 100, color: Colors.white),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Discover',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  shadows: const [Shadow(color: Colors.black54, blurRadius: 6)],
                ),
              ),
              Text(
                'Insights',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryGreen,
                  shadows: const [Shadow(color: Colors.black54, blurRadius: 6)],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'See trends and findings tailored to you\nfrom community experiments.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.75),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      slideRoute(const SignUpScreen()),
                    );
                  },
                  icon: const Icon(Icons.arrow_right_alt_rounded, size: 24),
                  label: const Text('Get Started'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withOpacity(0.25)),
                    padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
