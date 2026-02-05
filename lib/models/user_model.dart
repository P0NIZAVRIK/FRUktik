/// User model for authentication
class UserModel {
  final String id;
  final String email;
  final String displayName;
  final String? avatarUrl;
  final DateTime createdAt;
  final UserGoal? goal;
  final double dailyCalorieTarget;
  
  const UserModel({
    required this.id,
    required this.email,
    required this.displayName,
    this.avatarUrl,
    required this.createdAt,
    this.goal,
    this.dailyCalorieTarget = 2000,
  });
  
  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    String? avatarUrl,
    DateTime? createdAt,
    UserGoal? goal,
    double? dailyCalorieTarget,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      goal: goal ?? this.goal,
      dailyCalorieTarget: dailyCalorieTarget ?? this.dailyCalorieTarget,
    );
  }
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'displayName': displayName,
    'avatarUrl': avatarUrl,
    'createdAt': createdAt.toIso8601String(),
    'goal': goal?.name,
    'dailyCalorieTarget': dailyCalorieTarget,
  };
  
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      // Support both camelCase (old local) and snake_case (Supabase)
      displayName: (json['displayName'] ?? json['display_name']) as String? ?? 'User',
      avatarUrl: (json['avatarUrl'] ?? json['avatar_url']) as String?,
      createdAt: DateTime.parse(json['created_at'] != null 
          ? json['created_at'] as String 
          : (json['createdAt'] ?? DateTime.now().toIso8601String())),
      goal: json['goal'] != null 
          ? UserGoal.values.firstWhere(
              (e) => e.name == json['goal'],
              orElse: () => UserGoal.maintenance,
            )
          : null,
      dailyCalorieTarget: ((json['dailyCalorieTarget'] ?? json['daily_cal_target']) as num?)?.toDouble() ?? 2000,
    );
  }
}

enum UserGoal {
  weightLoss,
  weightGain,
  maintenance,
}

extension UserGoalExtension on UserGoal {
  String get displayName {
    switch (this) {
      case UserGoal.weightLoss:
        return 'Снижение веса';
      case UserGoal.weightGain:
        return 'Набор массы';
      case UserGoal.maintenance:
        return 'Поддержание';
    }
  }
}
