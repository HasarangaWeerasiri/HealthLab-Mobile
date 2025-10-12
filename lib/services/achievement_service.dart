import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/achievement.dart';
import '../widgets/achievement_popup.dart';
import 'experiment_service.dart';

class AchievementService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ExperimentService _experimentService = ExperimentService();

  // Define all achievements
  static final List<Achievement> _allAchievements = [
    // Beginner Tier
    Achievement(
      id: 'first_step',
      title: 'First Step',
      description: 'Complete your first experiment',
      tier: AchievementTier.beginner,
      icon: '🚀',
    ),
    Achievement(
      id: 'quick_starter',
      title: 'Quick Starter',
      description: 'Complete a new experiment within 24 hours of creating it',
      tier: AchievementTier.beginner,
      icon: '⚡',
    ),
    Achievement(
      id: 'daily_logger',
      title: 'Daily Logger',
      description: 'Log data for 3 consecutive days',
      tier: AchievementTier.beginner,
      icon: '📅',
    ),
    
    // Intermediate Tier
    Achievement(
      id: 'ten_entries_club',
      title: '10 Entries Club',
      description: 'Add 10 data points to any experiment',
      tier: AchievementTier.intermediate,
      icon: '📊',
    ),
    Achievement(
      id: 'experiment_creator',
      title: 'Experiment Creator',
      description: 'Create your first custom experiment',
      tier: AchievementTier.intermediate,
      icon: '🧪',
    ),
    Achievement(
      id: 'persistent_logger',
      title: 'Persistent Logger',
      description: 'Log data for 7 consecutive days',
      tier: AchievementTier.intermediate,
      icon: '🔥',
    ),
    Achievement(
      id: 'multi_creator',
      title: 'Multi-Creator',
      description: 'Create 3 custom experiments',
      tier: AchievementTier.intermediate,
      icon: '🎨',
    ),
    
    // Advanced Tier
    Achievement(
      id: 'experiment_explorer',
      title: 'Experiment Explorer',
      description: 'Finish 5 different experiments',
      tier: AchievementTier.advanced,
      icon: '🔍',
    ),
    Achievement(
      id: 'data_collector',
      title: 'Data Collector',
      description: 'Add 50 total data points across any experiments',
      tier: AchievementTier.advanced,
      icon: '📈',
    ),
    Achievement(
      id: 'completionist',
      title: 'Completionist',
      description: 'Finish all experiments you started',
      tier: AchievementTier.advanced,
      icon: '🏆',
    ),
  ];

  // Get all achievements with user progress
  Future<List<Achievement>> getUserAchievements() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return _allAchievements;

    try {
      // Get user's achievement progress from Firestore
      final userAchievementsDoc = await _db
          .collection('users')
          .doc(currentUser.uid)
          .collection('achievements')
          .doc('progress')
          .get();

      final userProgress = userAchievementsDoc.data() ?? {};

      // Calculate current progress for each achievement
      final achievementsWithProgress = <Achievement>[];
      
      for (final achievement in _allAchievements) {
        final userAchievementData = userProgress[achievement.id] ?? {};
        final isCompleted = userAchievementData['isCompleted'] ?? false;
        final completedAt = userAchievementData['completedAt'] != null
            ? DateTime.tryParse(userAchievementData['completedAt'])
            : null;

        // Calculate current progress
        final progress = await _calculateAchievementProgress(achievement.id);
        
        achievementsWithProgress.add(achievement.copyWith(
          isCompleted: isCompleted,
          completedAt: completedAt,
          progress: progress,
        ));
      }

      return achievementsWithProgress;
    } catch (e) {
      print('Error fetching user achievements: $e');
      return _allAchievements;
    }
  }

  // Calculate progress for a specific achievement
  Future<Map<String, dynamic>> _calculateAchievementProgress(String achievementId) async {
    try {
      switch (achievementId) {
        case 'first_step':
          return await _calculateFirstStepProgress();
        case 'quick_starter':
          return await _calculateQuickStarterProgress();
        case 'daily_logger':
          return await _calculateDailyLoggerProgress();
        case 'ten_entries_club':
          return await _calculateTenEntriesProgress();
        case 'experiment_creator':
          return await _calculateExperimentCreatorProgress();
        case 'persistent_logger':
          return await _calculatePersistentLoggerProgress();
        case 'multi_creator':
          return await _calculateMultiCreatorProgress();
        case 'experiment_explorer':
          return await _calculateExperimentExplorerProgress();
        case 'data_collector':
          return await _calculateDataCollectorProgress();
        case 'completionist':
          return await _calculateCompletionistProgress();
        default:
          return {};
      }
    } catch (e) {
      print('Error calculating progress for $achievementId: $e');
      return {};
    }
  }

  // Check and unlock achievements
  Future<void> checkAndUnlockAchievements({BuildContext? context}) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      print('Checking achievements for user: ${currentUser.uid}');
      
      // Get current user progress from Firestore
      final userAchievementsDoc = await _db
          .collection('users')
          .doc(currentUser.uid)
          .collection('achievements')
          .doc('progress')
          .get();

      final userProgress = userAchievementsDoc.data() ?? {};
      final newAchievements = <Achievement>[];

      for (final achievement in _allAchievements) {
        final userAchievementData = userProgress[achievement.id] ?? {};
        final isCompleted = userAchievementData['isCompleted'] ?? false;
        
        print('Checking achievement: ${achievement.id}, completed: $isCompleted');
        
        if (!isCompleted) {
          final shouldUnlock = await _shouldUnlockAchievement(achievement);
          print('Should unlock ${achievement.id}: $shouldUnlock');
          
          if (shouldUnlock) {
            await _unlockAchievement(achievement.id);
            newAchievements.add(achievement);
            print('Unlocked achievement: ${achievement.title}');
          }
        }
      }

      // Show popup for new achievements
      if (newAchievements.isNotEmpty && context != null && context.mounted) {
        print('New achievements unlocked: ${newAchievements.map((a) => a.title).join(', ')}');
        
        // Show popup for the first achievement (you can modify this to show multiple)
        final firstAchievement = newAchievements.first;
        showAchievementPopup(context, firstAchievement);
      } else if (newAchievements.isNotEmpty) {
        print('New achievements unlocked: ${newAchievements.map((a) => a.title).join(', ')}');
      } else {
        print('No new achievements unlocked');
      }
    } catch (e) {
      print('Error checking achievements: $e');
    }
  }

  // Check if an achievement should be unlocked
  Future<bool> _shouldUnlockAchievement(Achievement achievement) async {
    try {
      switch (achievement.id) {
        case 'first_step':
          return await _checkFirstStep();
        case 'quick_starter':
          return await _checkQuickStarter();
        case 'daily_logger':
          return await _checkDailyLogger();
        case 'ten_entries_club':
          return await _checkTenEntries();
        case 'experiment_creator':
          return await _checkExperimentCreator();
        case 'persistent_logger':
          return await _checkPersistentLogger();
        case 'multi_creator':
          return await _checkMultiCreator();
        case 'experiment_explorer':
          return await _checkExperimentExplorer();
        case 'data_collector':
          return await _checkDataCollector();
        case 'completionist':
          return await _checkCompletionist();
        default:
          return false;
      }
    } catch (e) {
      print('Error checking achievement ${achievement.id}: $e');
      return false;
    }
  }

  // Unlock an achievement
  Future<void> _unlockAchievement(String achievementId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      await _db
          .collection('users')
          .doc(currentUser.uid)
          .collection('achievements')
          .doc('progress')
          .set({
        achievementId: {
          'isCompleted': true,
          'completedAt': DateTime.now().toIso8601String(),
        }
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error unlocking achievement $achievementId: $e');
    }
  }

  // Achievement check methods
  Future<bool> _checkFirstStep() async {
    final joinedExperiments = await _experimentService.getJoinedExperiments();
    return joinedExperiments.isNotEmpty;
  }

  Future<bool> _checkQuickStarter() async {
    // This would require tracking when experiments are created vs completed
    // For now, return false as this needs more complex logic
    return false;
  }

  Future<bool> _checkDailyLogger() async {
    // This would require tracking daily logging streaks
    // For now, return false as this needs more complex logic
    return false;
  }

  Future<bool> _checkTenEntries() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return false;

    try {
      // Get all joined experiments
      final joinedExperiments = await _experimentService.getJoinedExperiments();
      int totalEntries = 0;

      for (final experiment in joinedExperiments) {
        final experimentId = experiment['id'] as String;
        
        // Get entries count for this experiment
        final joinedDoc = await _db
            .collection('users')
            .doc(currentUser.uid)
            .collection('joinedExperiments')
            .doc(experimentId)
            .get();
        
        if (joinedDoc.exists) {
          final data = joinedDoc.data()!;
          totalEntries += (data['entriesCount'] as int? ?? 0);
        }
      }

      return totalEntries >= 10;
    } catch (e) {
      print('Error checking ten entries: $e');
      return false;
    }
  }

  Future<bool> _checkExperimentCreator() async {
    final createdExperiments = await _experimentService.getCreatedExperiments();
    return createdExperiments.isNotEmpty;
  }

  Future<bool> _checkPersistentLogger() async {
    // This would require tracking 7-day logging streaks
    // For now, return false as this needs more complex logic
    return false;
  }

  Future<bool> _checkMultiCreator() async {
    final createdExperiments = await _experimentService.getCreatedExperiments();
    return createdExperiments.length >= 3;
  }

  Future<bool> _checkExperimentExplorer() async {
    final joinedExperiments = await _experimentService.getJoinedExperiments();
    return joinedExperiments.length >= 5;
  }

  Future<bool> _checkDataCollector() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return false;

    try {
      // Get all joined experiments
      final joinedExperiments = await _experimentService.getJoinedExperiments();
      int totalEntries = 0;

      for (final experiment in joinedExperiments) {
        final experimentId = experiment['id'] as String;
        
        // Get entries count for this experiment
        final joinedDoc = await _db
            .collection('users')
            .doc(currentUser.uid)
            .collection('joinedExperiments')
            .doc(experimentId)
            .get();
        
        if (joinedDoc.exists) {
          final data = joinedDoc.data()!;
          totalEntries += (data['entriesCount'] as int? ?? 0);
        }
      }

      return totalEntries >= 50;
    } catch (e) {
      print('Error checking data collector: $e');
      return false;
    }
  }

  Future<bool> _checkCompletionist() async {
    // This would require tracking completed vs started experiments
    // For now, return false as this needs more complex logic
    return false;
  }

  // Progress calculation methods
  Future<Map<String, dynamic>> _calculateFirstStepProgress() async {
    final joinedExperiments = await _experimentService.getJoinedExperiments();
    return {
      'current': joinedExperiments.length,
      'target': 1,
      'description': 'Joined ${joinedExperiments.length} experiment(s)',
    };
  }

  Future<Map<String, dynamic>> _calculateExperimentCreatorProgress() async {
    final createdExperiments = await _experimentService.getCreatedExperiments();
    return {
      'current': createdExperiments.length,
      'target': 1,
      'description': 'Created ${createdExperiments.length} experiment(s)',
    };
  }

  Future<Map<String, dynamic>> _calculateMultiCreatorProgress() async {
    final createdExperiments = await _experimentService.getCreatedExperiments();
    return {
      'current': createdExperiments.length,
      'target': 3,
      'description': 'Created ${createdExperiments.length}/3 experiments',
    };
  }

  Future<Map<String, dynamic>> _calculateExperimentExplorerProgress() async {
    final joinedExperiments = await _experimentService.getJoinedExperiments();
    return {
      'current': joinedExperiments.length,
      'target': 5,
      'description': 'Joined ${joinedExperiments.length}/5 experiments',
    };
  }

  // Placeholder methods for achievements that need more complex tracking
  Future<Map<String, dynamic>> _calculateQuickStarterProgress() async {
    return {
      'current': 0,
      'target': 1,
      'description': 'Complete an experiment within 24 hours of creating it',
    };
  }

  Future<Map<String, dynamic>> _calculateDailyLoggerProgress() async {
    return {
      'current': 0,
      'target': 3,
      'description': 'Log data for 3 consecutive days',
    };
  }

  Future<Map<String, dynamic>> _calculateTenEntriesProgress() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return {
        'current': 0,
        'target': 10,
        'description': 'Add 10 data points to any experiment',
      };
    }

    try {
      // Get all joined experiments
      final joinedExperiments = await _experimentService.getJoinedExperiments();
      int totalEntries = 0;

      for (final experiment in joinedExperiments) {
        final experimentId = experiment['id'] as String;
        
        // Get entries count for this experiment
        final joinedDoc = await _db
            .collection('users')
            .doc(currentUser.uid)
            .collection('joinedExperiments')
            .doc(experimentId)
            .get();
        
        if (joinedDoc.exists) {
          final data = joinedDoc.data()!;
          totalEntries += (data['entriesCount'] as int? ?? 0);
        }
      }

      print('Ten entries progress: $totalEntries/10');
      return {
        'current': totalEntries,
        'target': 10,
        'description': 'Added $totalEntries/10 data points',
      };
    } catch (e) {
      print('Error calculating ten entries progress: $e');
      return {
        'current': 0,
        'target': 10,
        'description': 'Add 10 data points to any experiment',
      };
    }
  }

  Future<Map<String, dynamic>> _calculatePersistentLoggerProgress() async {
    return {
      'current': 0,
      'target': 7,
      'description': 'Log data for 7 consecutive days',
    };
  }

  Future<Map<String, dynamic>> _calculateDataCollectorProgress() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return {
        'current': 0,
        'target': 50,
        'description': 'Add 50 total data points across any experiments',
      };
    }

    try {
      // Get all joined experiments
      final joinedExperiments = await _experimentService.getJoinedExperiments();
      int totalEntries = 0;

      for (final experiment in joinedExperiments) {
        final experimentId = experiment['id'] as String;
        
        // Get entries count for this experiment
        final joinedDoc = await _db
            .collection('users')
            .doc(currentUser.uid)
            .collection('joinedExperiments')
            .doc(experimentId)
            .get();
        
        if (joinedDoc.exists) {
          final data = joinedDoc.data()!;
          totalEntries += (data['entriesCount'] as int? ?? 0);
        }
      }

      print('Data collector progress: $totalEntries/50');
      return {
        'current': totalEntries,
        'target': 50,
        'description': 'Added $totalEntries/50 data points',
      };
    } catch (e) {
      print('Error calculating data collector progress: $e');
      return {
        'current': 0,
        'target': 50,
        'description': 'Add 50 total data points across any experiments',
      };
    }
  }

  Future<Map<String, dynamic>> _calculateCompletionistProgress() async {
    return {
      'current': 0,
      'target': 1,
      'description': 'Finish all experiments you started',
    };
  }
}
