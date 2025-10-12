class Achievement {
  final String id;
  final String title;
  final String description;
  final AchievementTier tier;
  final String icon;
  final bool isCompleted;
  final DateTime? completedAt;
  final Map<String, dynamic>? progress;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.tier,
    required this.icon,
    this.isCompleted = false,
    this.completedAt,
    this.progress,
  });

  factory Achievement.fromMap(Map<String, dynamic> map) {
    return Achievement(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      tier: AchievementTier.values.firstWhere(
        (tier) => tier.name == map['tier'],
        orElse: () => AchievementTier.beginner,
      ),
      icon: map['icon'] ?? '🏆',
      isCompleted: map['isCompleted'] ?? false,
      completedAt: map['completedAt'] != null 
          ? DateTime.tryParse(map['completedAt']) 
          : null,
      progress: map['progress'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'tier': tier.name,
      'icon': icon,
      'isCompleted': isCompleted,
      'completedAt': completedAt?.toIso8601String(),
      'progress': progress,
    };
  }

  Achievement copyWith({
    String? id,
    String? title,
    String? description,
    AchievementTier? tier,
    String? icon,
    bool? isCompleted,
    DateTime? completedAt,
    Map<String, dynamic>? progress,
  }) {
    return Achievement(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      tier: tier ?? this.tier,
      icon: icon ?? this.icon,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      progress: progress ?? this.progress,
    );
  }
}

enum AchievementTier {
  beginner,
  intermediate,
  advanced;

  String get displayName {
    switch (this) {
      case AchievementTier.beginner:
        return 'Beginner';
      case AchievementTier.intermediate:
        return 'Intermediate';
      case AchievementTier.advanced:
        return 'Advanced';
    }
  }

  String get badgeImage {
    switch (this) {
      case AchievementTier.beginner:
        return 'assets/icons/beginner.png';
      case AchievementTier.intermediate:
        return 'assets/icons/intermediate.png';
      case AchievementTier.advanced:
        return 'assets/icons/pro.png';
    }
  }

  String get color {
    switch (this) {
      case AchievementTier.beginner:
        return '🟢';
      case AchievementTier.intermediate:
        return '🟡';
      case AchievementTier.advanced:
        return '🔵';
    }
  }
}
