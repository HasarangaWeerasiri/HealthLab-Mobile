import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../models/achievement.dart';

class AchievementPopup extends StatelessWidget {
  final Achievement achievement;
  final VoidCallback onClose;

  const AchievementPopup({
    super.key,
    required this.achievement,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.black.withOpacity(0.7),
        child: Stack(
          children: [
            // Blur effect
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    color: Colors.transparent,
                  ),
                ),
              ),
            ),
            
            // Content
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 40),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF00432D),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFE6FDD8).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Close button
                    Align(
                      alignment: Alignment.topRight,
                      child: GestureDetector(
                        onTap: onClose,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Color(0xFFE6FDD8),
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Achievement icon
                    Text(
                      achievement.icon,
                      style: const TextStyle(fontSize: 48),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Achievement title
                    Text(
                      achievement.title,
                      style: const TextStyle(
                        color: Color(0xFFE6FDD8),
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Achievement description
                    Text(
                      achievement.description,
                      style: const TextStyle(
                        color: Color(0xFFE6FDD8),
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Lottie animation
                    SizedBox(
                      width: 200,
                      height: 200,
                      child: Lottie.asset(
                        _getAnimationPath(achievement.tier),
                        fit: BoxFit.contain,
                        repeat: true,
                        animate: true,
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Achievement unlocked text
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6FDD8).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFE6FDD8).withOpacity(0.3),
                        ),
                      ),
                      child: const Text(
                        'Achievement Unlocked!',
                        style: TextStyle(
                          color: Color(0xFFE6FDD8),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getAnimationPath(AchievementTier tier) {
    switch (tier) {
      case AchievementTier.beginner:
        return 'assets/lottie/Trophy.json';
      case AchievementTier.intermediate:
      case AchievementTier.advanced:
        return 'assets/lottie/Businessman flies up with rocket.json';
    }
  }
}

// Helper function to show achievement popup
void showAchievementPopup(
  BuildContext context,
  Achievement achievement,
) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AchievementPopup(
        achievement: achievement,
        onClose: () {
          Navigator.of(context).pop();
        },
      );
    },
  );
}

// Helper function to show test achievement popup (for testing purposes)
void showTestAchievementPopup(BuildContext context, AchievementTier tier) {
  final testAchievement = Achievement(
    id: 'test_${tier.name}',
    title: 'Test Achievement',
    description: 'This is a test achievement for ${tier.displayName} tier',
    tier: tier,
    icon: tier == AchievementTier.beginner ? '🏆' : '🚀',
    isCompleted: true,
    completedAt: DateTime.now(),
  );
  
  showAchievementPopup(context, testAchievement);
}
