import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../utils/app_utils.dart';
import 'homepage_screen.dart';

class ReadyToGoScreen extends StatelessWidget {
  const ReadyToGoScreen({super.key});

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
                  child: Lottie.asset(
                    'assets/lottie/ready.json',
                    repeat: true,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "You're good to\ngo!",
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white, height: 1.1),
              ),
              const SizedBox(height: 8),
              Text(
                'Explore, create, and track your\nexperiments in HealthLab',
                style: TextStyle(color: Colors.white.withOpacity(0.7)),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const HomepageScreen()),
                    );
                  },
                  icon: const Icon(Icons.arrow_right_alt_rounded, size: 24),
                  label: const Text('Start using HealthLab'),
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
