class AchievementDefinition {
  const AchievementDefinition({
    required this.id,
    required this.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.rarity,
    required this.target,
    required this.category,
  });

  final String id;
  final String key;
  final String title;
  final String description;
  final String icon;
  final String rarity;
  final int target;
  final String category;
}

class UserAchievement {
  const UserAchievement({
    required this.id,
    required this.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.rarity,
    required this.target,
    required this.category,
    required this.progress,
    required this.unlocked,
    required this.unlockedAt,
  });

  final String id;
  final String key;
  final String title;
  final String description;
  final String icon;
  final String rarity;
  final int target;
  final String category;
  final int progress;
  final bool unlocked;
  final String? unlockedAt;

  factory UserAchievement.fromJson(Map<String, dynamic> json) =>
      UserAchievement(
        id: json['id']?.toString() ?? '',
        key: json['key']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        icon: json['icon']?.toString() ?? '🏅',
        rarity: json['rarity']?.toString() ?? 'common',
        target: (json['target'] as num?)?.toInt() ?? 0,
        category: json['category']?.toString() ?? 'general',
        progress: (json['progress'] as num?)?.toInt() ?? 0,
        unlocked: json['unlocked'] == true,
        unlockedAt: json['unlockedAt']?.toString(),
      );
}

class ClubAchievementEvent {
  const ClubAchievementEvent({
    this.userId = '',
    required this.userName,
    required this.avatarUrl,
    required this.achievementTitle,
    required this.achievementIcon,
    required this.unlockedAt,
  });

  final String userName;
  final String userId;
  final String avatarUrl;
  final String achievementTitle;
  final String achievementIcon;
  final String unlockedAt;

  factory ClubAchievementEvent.fromJson(Map<String, dynamic> json) =>
      ClubAchievementEvent(
        userId: json['userId']?.toString() ?? '',
        userName: json['userName']?.toString() ?? '',
        avatarUrl: json['avatarUrl']?.toString() ?? '',
        achievementTitle: json['achievementTitle']?.toString() ?? '',
        achievementIcon: json['achievementIcon']?.toString() ?? '🏅',
        unlockedAt: json['unlockedAt']?.toString() ?? '',
      );
}
