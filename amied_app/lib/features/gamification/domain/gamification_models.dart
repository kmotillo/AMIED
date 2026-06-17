class Badge {
  final String id;
  final String name;
  final String? description;
  final String? iconUrl;
  final int pointsRequired;

  Badge({
    required this.id,
    required this.name,
    this.description,
    this.iconUrl,
    required this.pointsRequired,
  });

  factory Badge.fromJson(Map<String, dynamic> json) {
    return Badge(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      iconUrl: json['icon_url'] as String?,
      pointsRequired: json['points_required'] as int? ?? 0,
    );
  }
}

class UserGamification {
  final String userId;
  final int totalXp;
  final int currentLevel;

  UserGamification({
    required this.userId,
    required this.totalXp,
    required this.currentLevel,
  });

  factory UserGamification.fromJson(Map<String, dynamic> json) {
    return UserGamification(
      userId: json['user_id'] as String,
      totalXp: json['total_xp'] as int? ?? 0,
      currentLevel: json['current_level'] as int? ?? 1,
    );
  }
}
