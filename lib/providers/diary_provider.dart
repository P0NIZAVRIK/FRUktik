import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/food_item.dart';
import '../models/diary_entry.dart';
import '../services/database_service.dart';
import '../services/local_cache_service.dart';
import '../services/auth_service.dart';

/// Goal targets for КБЖУ
class NutritionGoals {
  final double calories;
  final double proteins;
  final double fats;
  final double carbohydrates;
  
  const NutritionGoals({
    this.calories = 2000.0,
    this.proteins = 150.0,
    this.fats = 65.0,
    this.carbohydrates = 250.0,
  });
  
  /// Default daily goals
  static const NutritionGoals defaultGoals = NutritionGoals();
}

/// Achievement event when a goal is reached
enum AchievementType {
  caloriesGoal,
  proteinsGoal,
  fatsGoal,
  carbohydratesGoal,
  perfectDay, // All goals met
}

class DiaryProvider with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  final LocalCacheService _cacheService;
  
  List<DiaryEntry> _entries = [];
  String _searchQuery = '';
  NutritionGoals _goals = NutritionGoals.defaultGoals;
  String? _userId;
  bool _isOffline = false;
  
  // Track which goals have been celebrated today
  final Set<AchievementType> _celebratedToday = {};
  
  // Callback for achievements (for haptic/confetti)
  void Function(AchievementType achievement)? onAchievement;
  
  // Constructor
  DiaryProvider(this._cacheService);

  // Getters
  List<DiaryEntry> get entries => List.unmodifiable(_entries);
  String get searchQuery => _searchQuery;
  NutritionGoals get goals => _goals;

  // Get today's entries
  List<DiaryEntry> get todayEntries {
    final today = DateTime.now();
    return _entries.where((entry) {
      return entry.date.year == today.year &&
          entry.date.month == today.month &&
          entry.date.day == today.day;
    }).toList();
  }

  // Total КБЖУ statistics for today
  double get totalCalories {
    return todayEntries.fold(0.0, (sum, entry) => sum + entry.calories);
  }

  double get totalProteins {
    return todayEntries.fold(0.0, (sum, entry) => sum + entry.proteins);
  }

  double get totalFats {
    return todayEntries.fold(0.0, (sum, entry) => sum + entry.fats);
  }

  double get totalCarbohydrates {
    return todayEntries.fold(0.0, (sum, entry) => sum + entry.carbohydrates);
  }
  
  // Progress percentages (0.0 to 1.0+)
  double get caloriesProgress => totalCalories / _goals.calories;
  double get proteinsProgress => totalProteins / _goals.proteins;
  double get fatsProgress => totalFats / _goals.fats;
  double get carbsProgress => totalCarbohydrates / _goals.carbohydrates;
  
  // Check if goals are reached (80-110% range)
  bool get isCaloriesGoalReached => caloriesProgress >= 0.8 && caloriesProgress <= 1.1;
  bool get isProteinsGoalReached => proteinsProgress >= 0.8 && proteinsProgress <= 1.1;
  bool get isFatsGoalReached => fatsProgress >= 0.8 && fatsProgress <= 1.1;
  bool get isCarbsGoalReached => carbsProgress >= 0.8 && carbsProgress <= 1.1;
  bool get isPerfectDay => 
      isCaloriesGoalReached && 
      isProteinsGoalReached && 
      isFatsGoalReached && 
      isCarbsGoalReached;

  // Methods
  void updateAuth(AuthService auth) {
    final newUserId = auth.currentUser?.id;
    if (_userId != newUserId) {
      _userId = newUserId;
      if (_userId != null) {
        // Sync user's calorie goals
        final userCalTarget = auth.currentUser?.dailyCalorieTarget ?? 2000;
        _goals = NutritionGoals(
          calories: userCalTarget,
          // Calculate macros based on standard ratio (40% carbs, 30% protein, 30% fat)
          proteins: userCalTarget * 0.30 / 4, // 1g protein = 4 cal
          fats: userCalTarget * 0.30 / 9, // 1g fat = 9 cal
          carbohydrates: userCalTarget * 0.40 / 4, // 1g carb = 4 cal
        );
        _loadData();
      } else {
        _entries = [];
        _goals = NutritionGoals.defaultGoals;
        notifyListeners();
      }
    }
  }
  
  Future<void> _loadData() async {
    if (_userId == null) return;
    
    // Try loading from cache first (instant offline access)
    _entries = _cacheService.getCachedEntries(_userId!);
    notifyListeners();
    
    // Then sync with cloud
    try {
      final loadedEntries = await _dbService.getEntries(_userId!);
      _entries = loadedEntries;
      await _cacheService.saveEntries(_userId!, _entries);
      _isOffline = false;
      
      // Process pending offline actions
      await _processPendingActions();
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading diary entries: $e');
      _isOffline = true;
    }
  }
  
  /// Process pending offline actions (sync queue)
  Future<void> _processPendingActions() async {
    if (_userId == null) return;
    
    final pendingActions = _cacheService.getPendingActions(_userId!);
    for (final action in pendingActions) {
      try {
        switch (action['action']) {
          case 'add':
            final entry = DiaryEntry.fromJson(action['data']);
            await _dbService.addEntry(entry, _userId!);
            break;
          case 'delete':
            await _dbService.deleteEntry(action['data']['id']);
            break;
        }
        await _cacheService.clearPendingAction(action['timestamp']);
      } catch (e) {
        debugPrint('Error syncing pending action: $e');
      }
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }
  
  void setGoals(NutritionGoals newGoals) {
    _goals = newGoals;
    notifyListeners();
  }

  Future<void> addEntry(FoodItem foodItem, double weight) async {
    final entry = DiaryEntry(
      id: const Uuid().v4(), // Generate proper UUID
      foodItem: foodItem,
      weight: weight,
      date: DateTime.now(),
    );
    
    // Optimistic UI update
    _entries.add(entry);
    await _cacheService.saveEntries(_userId ?? '', _entries);
    notifyListeners();
    
    // Sync to database (or queue if offline)
    try {
      if (_userId != null) {
        await _dbService.addEntry(entry, _userId!);
        _isOffline = false;
        // Optionally reload to get server-generated ID if needed
      }
    } catch (e) {
      debugPrint('Error syncing add entry: $e');
      _isOffline = true;
      // Queue for later sync
      if (_userId != null) {
        await _cacheService.addPendingAction(
          userId: _userId!,
          action: 'add',
          data: entry.toJson(),
        );
      }
    }
  }

  Future<void> removeEntry(String entryId) async {
    // Optimistic UI update
    _entries.removeWhere((e) => e.id == entryId);
    await _cacheService.saveEntries(_userId ?? '', _entries);
    notifyListeners();
    
    // Sync to database (or queue if offline)
    try {
      if (_userId != null) {
        await _dbService.deleteEntry(entryId);
        _isOffline = false;
      }
    } catch (e) {
      debugPrint('Error syncing remove entry: $e');
      _isOffline = true;
      // Queue for later sync
      if (_userId != null) {
        await _cacheService.addPendingAction(
          userId: _userId!,
          action: 'delete',
          data: {'id': entryId},
        );
      }
    }
  }

  Future<void> updateEntryWeight(String id, double newWeight) async {
    final index = _entries.indexWhere((entry) => entry.id == id);
    if (index != -1) {
      final oldEntry = _entries[index];
      // Note: updating weight technically creates a new record in immutable model
      // For DB sync, create new entry logic or update specific field (not implemented in DB service yet)
      // For now, let's just update local state. Full update logic requires 'update' SQL.
      
      _entries[index] = DiaryEntry(
        id: oldEntry.id,
        foodItem: oldEntry.foodItem,
        weight: newWeight,
        date: oldEntry.date,
      );
      notifyListeners();
      
      // TODO: Implement update in DatabaseService
      // For now, delete and add (inefficient but works)
      if (_userId != null) {
        await _dbService.deleteEntry(id);
        await _dbService.addEntry(_entries[index], _userId!);
      }
      
      // Check for achievements after update
      _checkAchievements();
    }
  }
  
  /// Check and trigger achievements
  void _checkAchievements() {
    // Reset celebrations at midnight (new day)
    final now = DateTime.now();
    if (_celebratedToday.isNotEmpty) {
      // Simple check: if first entry of day, reset
      if (todayEntries.length == 1) {
        _celebratedToday.clear();
      }
    }
    
    // Check individual goals
    if (isCaloriesGoalReached && !_celebratedToday.contains(AchievementType.caloriesGoal)) {
      _celebratedToday.add(AchievementType.caloriesGoal);
      onAchievement?.call(AchievementType.caloriesGoal);
    }
    
    if (isProteinsGoalReached && !_celebratedToday.contains(AchievementType.proteinsGoal)) {
      _celebratedToday.add(AchievementType.proteinsGoal);
      onAchievement?.call(AchievementType.proteinsGoal);
    }
    
    if (isFatsGoalReached && !_celebratedToday.contains(AchievementType.fatsGoal)) {
      _celebratedToday.add(AchievementType.fatsGoal);
      onAchievement?.call(AchievementType.fatsGoal);
    }
    
    if (isCarbsGoalReached && !_celebratedToday.contains(AchievementType.carbohydratesGoal)) {
      _celebratedToday.add(AchievementType.carbohydratesGoal);
      onAchievement?.call(AchievementType.carbohydratesGoal);
    }
    
    // Perfect day achievement
    if (isPerfectDay && !_celebratedToday.contains(AchievementType.perfectDay)) {
      _celebratedToday.add(AchievementType.perfectDay);
      onAchievement?.call(AchievementType.perfectDay);
    }
  }
}
