class FoodItem {
  final String id;
  final String name;
  final double calories; // калории на 100г
  final double proteins; // белки на 100г
  final double fats; // жиры на 100г
  final double carbohydrates; // углеводы на 100г
  final String? imageUrl; // URL изображения продукта
  final String category; // категория продукта (fruits, vegetables, meat, etc.)

  FoodItem({
    required this.id,
    required this.name,
    required this.calories,
    required this.proteins,
    required this.fats,
    required this.carbohydrates,
    this.imageUrl,
    this.category = 'other',
  });

  /// Рассчитывает КБЖУ в зависимости от веса (в граммах)
  Map<String, double> calculateNutrition(double weightInGrams) {
    final multiplier = weightInGrams / 100.0;
    return {
      'calories': calories * multiplier,
      'proteins': proteins * multiplier,
      'fats': fats * multiplier,
      'carbohydrates': carbohydrates * multiplier,
    };
  }

  /// Получает калории для указанного веса
  double getCalories(double weightInGrams) {
    return (calories * weightInGrams) / 100.0;
  }

  /// Получает белки для указанного веса
  double getProteins(double weightInGrams) {
    return (proteins * weightInGrams) / 100.0;
  }

  /// Получает жиры для указанного веса
  double getFats(double weightInGrams) {
    return (fats * weightInGrams) / 100.0;
  }

  /// Получает углеводы для указанного веса
  double getCarbohydrates(double weightInGrams) {
    return (carbohydrates * weightInGrams) / 100.0;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'calories': calories,
    'proteins': proteins,
    'fats': fats,
    'carbohydrates': carbohydrates,
    'imageUrl': imageUrl,
    'category': category,
  };

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    return FoodItem(
      id: json['id'] as String,
      name: json['name'] as String,
      calories: (json['calories'] as num).toDouble(),
      proteins: (json['proteins'] as num).toDouble(),
      fats: (json['fats'] as num).toDouble(),
      carbohydrates: (json['carbohydrates'] as num).toDouble(),
      imageUrl: json['imageUrl'] as String?,
      category: json['category'] as String? ?? 'other',
    );
  }

  @override
  String toString() {
    return 'FoodItem(id: $id, name: $name, calories: $calories, proteins: $proteins, fats: $fats, carbohydrates: $carbohydrates)';
  }
}
