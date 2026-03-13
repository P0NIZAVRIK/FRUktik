import 'package:equatable/equatable.dart';

/// Achievement model for gamification
class Achievement extends Equatable {
  final String id;
  final String title;
  final String description;
  final String icon; // emoji or icon name
  final AchievementType type;
  final int targetValue;
  final DateTime? unlockedAt;
  
  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.type,
    required this.targetValue,
    this.unlockedAt,
  });
  
  bool get isUnlocked => unlockedAt != null;
  
  /// Predefined achievements
  static final List<Achievement> all = [
    // First actions
    const Achievement(
      id: 'first_entry',
      title: 'Первый шаг',
      description: 'Добавьте первую запись в дневник',
      icon: '🎯',
      type: AchievementType.entriesCount,
      targetValue: 1,
    ),
    
    const Achievement(
      id: 'perfect_day',
      title: 'Идеальный день',
      description: 'Выполните дневную норму калорий',
      icon: '✨',
      type: AchievementType.perfectDay,
      targetValue: 1,
    ),
    
    // Streak achievements
    const Achievement(
      id: 'week_streak',
      title: 'Неделя силы',
      description: 'Заполняйте дневник 7 дней подряд',
      icon: '🔥',
      type: AchievementType.streak,
      targetValue: 7,
    ),
    
    const Achievement(
      id: 'month_streak',
      title: 'Месяц дисциплины',
      description: '30 дней подряд ведите дневник',
      icon: '💪',
      type: AchievementType.streak,
      targetValue: 30,
    ),
    
    // Entries count
    const Achievement(
      id: 'entries_50',
      title: 'Опытный',
      description: '50 записей в дневнике',
      icon: '📝',
      type: AchievementType.entriesCount,
      targetValue: 50,
    ),
    
    const Achievement(
      id: 'entries_100',
      title: 'Мастер',
      description: '100 записей в дневнике',
      icon: '🏆',
      type: AchievementType.entriesCount,
      targetValue: 100,
    ),
    
    // Protein goals
    const Achievement(
      id: 'protein_week',
      title: 'Белковый воин',
      description: 'Выполните белковую норму 7 дней подряд',
      icon: '🥩',
      type: AchievementType.proteinStreak,
      targetValue: 7,
    ),
  ];
  
  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      icon: json['icon'] as String,
      type: AchievementType.values.firstWhere(
        (e) => e.name == json['type'],
      ),
      targetValue: json['target_value'] as int,
      unlockedAt: json['unlocked_at'] != null
          ? DateTime.parse(json['unlocked_at'] as String)
          : null,
    );
  }
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'icon': icon,
    'type': type.name,
    'target_value': targetValue,
    'unlocked_at': unlockedAt?.toIso8601String(),
  };
  
  Achievement copyWith({
    String? id,
    String? title,
    String? description,
    String? icon,
    AchievementType? type,
    int? targetValue,
    DateTime? unlockedAt,
  }) {
    return Achievement(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      type: type ?? this.type,
      targetValue: targetValue ?? this.targetValue,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }

  @override
  List<Object?> get props => [id, title, description, icon, type, targetValue, unlockedAt];
}

enum AchievementType {
  entriesCount,
  perfectDay,
  streak,
  proteinStreak,
  caloriesGoal,
  proteinsGoal,
  fatsGoal,
  carbohydratesGoal,
}
