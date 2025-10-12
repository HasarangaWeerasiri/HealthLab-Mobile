import 'package:flutter/material.dart';
import '../models/achievement.dart';
import '../services/achievement_service.dart';
import '../widgets/achievement_popup.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  final AchievementService _achievementService = AchievementService();
  List<Achievement> _achievements = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAchievements();
    // Check for new achievements when screen opens
    _achievementService.checkAndUnlockAchievements(context: context);
  }

  Future<void> _loadAchievements() async {
    try {
      // First check for new achievements
      await _achievementService.checkAndUnlockAchievements(context: context);
      
      // Then load the updated achievements
      final achievements = await _achievementService.getUserAchievements();
      setState(() {
        _achievements = achievements;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading achievements: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF201E1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF00432D),
        title: const Text(
          'Achievements',
          style: TextStyle(
            color: Color(0xFFE6FDD8),
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFE6FDD8)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // Test button for achievement popup
          IconButton(
            icon: const Icon(Icons.sports_esports, color: Color(0xFFE6FDD8)),
            onPressed: () {
              showTestAchievementPopup(context, AchievementTier.beginner);
            },
            tooltip: 'Test Achievement Popup',
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFE6FDD8),
              ),
            )
          : RefreshIndicator(
              onRefresh: () async {
                await _loadAchievements();
              },
              color: const Color(0xFFE6FDD8),
              backgroundColor: const Color(0xFF00432D),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Achievement Summary
                    _buildAchievementSummary(),
                    const SizedBox(height: 30),
                    
                    // Achievement Tiers
                    ...AchievementTier.values.map((tier) => 
                      _buildTierSection(tier)
                    ).toList(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildAchievementSummary() {
    final completedCount = _achievements.where((a) => a.isCompleted).length;
    final totalCount = _achievements.length;
    final completionPercentage = totalCount > 0 ? (completedCount / totalCount * 100).round() : 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: const Color(0xFF00432D),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Achievement Progress',
            style: TextStyle(
              color: Color(0xFFE6FDD8),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$completedCount / $totalCount',
                      style: const TextStyle(
                        color: Color(0xFFE6FDD8),
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'Achievements Unlocked',
                      style: TextStyle(
                        color: Color(0xFFE6FDD8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$completionPercentage%',
                    style: const TextStyle(
                      color: Color(0xFFE6FDD8),
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Complete',
                    style: TextStyle(
                      color: Color(0xFFE6FDD8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: completionPercentage / 100,
            backgroundColor: const Color(0xFFE6FDD8).withOpacity(0.2),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFE6FDD8)),
            minHeight: 8,
          ),
        ],
      ),
    );
  }

  Widget _buildTierSection(AchievementTier tier) {
    final tierAchievements = _achievements.where((a) => a.tier == tier).toList();
    final completedInTier = tierAchievements.where((a) => a.isCompleted).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: const Color(0xFF00432D),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFE6FDD8).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    tier.badgeImage,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Text(
                          tier.color,
                          style: const TextStyle(fontSize: 20),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${tier.displayName} Tier',
                      style: const TextStyle(
                        color: Color(0xFFE6FDD8),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '$completedInTier / ${tierAchievements.length} completed',
                      style: const TextStyle(
                        color: Color(0xFFE6FDD8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ...tierAchievements.map((achievement) => 
          _buildAchievementCard(achievement)
        ).toList(),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildAchievementCard(Achievement achievement) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: achievement.isCompleted 
            ? const Color(0xFF00432D) 
            : const Color(0xFF00432D).withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: achievement.isCompleted 
              ? const Color(0xFFE6FDD8).withOpacity(0.3)
              : const Color(0xFFE6FDD8).withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Achievement Icon
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: achievement.isCompleted 
                  ? const Color(0xFFE6FDD8).withOpacity(0.2)
                  : const Color(0xFFE6FDD8).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                achievement.icon,
                style: TextStyle(
                  fontSize: 24,
                  color: achievement.isCompleted 
                      ? const Color(0xFFE6FDD8)
                      : const Color(0xFFE6FDD8).withOpacity(0.5),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          
          // Achievement Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        achievement.title,
                        style: TextStyle(
                          color: achievement.isCompleted 
                              ? const Color(0xFFE6FDD8)
                              : const Color(0xFFE6FDD8).withOpacity(0.7),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (achievement.isCompleted)
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 20,
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  achievement.description,
                  style: TextStyle(
                    color: achievement.isCompleted 
                        ? const Color(0xFFE6FDD8).withOpacity(0.8)
                        : const Color(0xFFE6FDD8).withOpacity(0.5),
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (achievement.progress != null && !achievement.isCompleted) ...[
                  const SizedBox(height: 8),
                  _buildProgressIndicator(achievement.progress!),
                ],
                if (achievement.isCompleted && achievement.completedAt != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Completed ${_formatDate(achievement.completedAt!)}',
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Tier Badge
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: const Color(0xFFE6FDD8).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset(
                achievement.tier.badgeImage,
                width: 30,
                height: 30,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Text(
                      achievement.tier.color,
                      style: const TextStyle(fontSize: 16),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(Map<String, dynamic> progress) {
    final current = progress['current'] ?? 0;
    final target = progress['target'] ?? 1;
    final percentage = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                progress['description'] ?? 'Progress',
                style: const TextStyle(
                  color: Color(0xFFE6FDD8),
                  fontSize: 10,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$current / $target',
              style: const TextStyle(
                color: Color(0xFFE6FDD8),
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: percentage,
          backgroundColor: const Color(0xFFE6FDD8).withOpacity(0.2),
          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFE6FDD8)),
          minHeight: 4,
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return weeks == 1 ? '1 week ago' : '$weeks weeks ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
