import 'food_item.dart';

class DiaryEntry {
  final String id;
  final FoodItem foodItem;
  final double weight; // вес в граммах
  final DateTime date;

  DiaryEntry({
    required this.id,
    required this.foodItem,
    required this.weight,
    required this.date,
  });

  // Вычисляемые значения для данного веса
  double get calories => foodItem.getCalories(weight);
  double get proteins => foodItem.getProteins(weight);
  double get fats => foodItem.getFats(weight);
  double get carbohydrates => foodItem.getCarbohydrates(weight);

  Map<String, double> get nutrition => foodItem.calculateNutrition(weight);

  Map<String, dynamic> toJson() => {
    'id': id,
    'food_item_json': foodItem.toJson(),
    'weight': weight,
    'date': date.toIso8601String(),
  };

  factory DiaryEntry.fromJson(Map<String, dynamic> json) {
    // Handle nested foodItem Map which might come from Hive as Map<dynamic, dynamic>
    final foodItemData = json['food_item_json'];
    final foodItemMap = foodItemData is Map<String, dynamic>
        ? foodItemData
        : Map<String, dynamic>.from(foodItemData as Map);
    
    return DiaryEntry(
      id: json['id'] as String,
      foodItem: FoodItem.fromJson(foodItemMap),
      weight: (json['weight'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
    );
  }

  @override
  String toString() {
    return 'DiaryEntry(id: $id, food: ${foodItem.name}, weight: $weight, calories: $calories)';
  }
}
