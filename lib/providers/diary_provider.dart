import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/food_item.dart';
import '../models/diary_entry.dart';
import '../services/database_service.dart';
import '../services/local_cache_service.dart';
import '../services/auth_service.dart';
import '../services/achievement_service.dart';
import '../services/recognition_service.dart';

import '../models/achievement.dart';

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

class DiaryProvider with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  final LocalCacheService _cacheService;
  final RecognitionService _recognitionService = RecognitionService();
  AchievementService? _achievementService;

  final List<DiaryEntry> _entries = [];
  String _searchQuery = '';
  final NutritionGoals _goals = NutritionGoals.defaultGoals;
  String? _userId;
  // ignore: unused_field
  int _currentStreak = 0; // Current logging streak in days

  // Track which goals have been celebrated today
  final Set<AchievementType> _celebratedToday = {};

  // Callback for achievements (for haptic/confetti)
  void Function(AchievementType achievement)? onAchievement;

  // Callback for Level Up
  void Function(int newLevel)? onLevelUp;

  // Constructor
  DiaryProvider(this._cacheService);

  // Getters
  List<DiaryEntry> get entries => _entries;
  List<DiaryEntry> get todayEntries {
    final now = DateTime.now();
    return _entries
        .where((e) =>
            e.date.year == now.year &&
            e.date.month == now.month &&
            e.date.day == now.day)
        .toList();
  }

  String get searchQuery => _searchQuery;

  double get totalCalories =>
      todayEntries.fold(0, (sum, e) => sum + e.calories);
  double get totalProteins =>
      todayEntries.fold(0, (sum, e) => sum + e.proteins);
  double get totalFats => todayEntries.fold(0, (sum, e) => sum + e.fats);
  double get totalCarbs =>
      todayEntries.fold(0, (sum, e) => sum + e.carbohydrates);
  double get totalCarbohydrates => totalCarbs; // Alias for compatibility

  NutritionGoals get goals => _goals;
  int get currentStreak => _currentStreak;

  // Status getters
  bool get isCaloriesGoalReached => totalCalories >= _goals.calories;
  bool get isProteinsGoalReached => totalProteins >= _goals.proteins;
  bool get isFatsGoalReached => totalFats >= _goals.fats;
  bool get isCarbsGoalReached => totalCarbs >= _goals.carbohydrates;

  bool get isPerfectDay =>
      isCaloriesGoalReached &&
      isProteinsGoalReached &&
      isFatsGoalReached &&
      isCarbsGoalReached;

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void updateAuth(AuthService auth) {
    final newUserId = auth.currentUser?.id;
    if (_userId != newUserId) {
      _userId = newUserId;
      if (_userId != null) {
        // Load cached entries and sync from DB
        loadEntries();
      }
      notifyListeners();
    }
  }

  void updateAchievements(AchievementService service) {
    _achievementService = service;
  }

  // Callback for sync errors (for SnackBar notifications)
  void Function(String message)? onSyncError;

  /// Load entries from local cache and optionally sync from Supabase
  Future<void> loadEntries() async {
    final userId = _userId;
    if (userId == null || userId.isEmpty) return;

    // 1. Load from Hive cache first (instant UI)
    final cachedEntries = _cacheService.getCachedEntries(userId);
    if (cachedEntries.isNotEmpty && _entries.isEmpty) {
      _entries.addAll(cachedEntries);
      _calculateStreak();
      notifyListeners();
    }

    // 2. Try to sync from Supabase in background
    try {
      final dbEntries = await _dbService.getEntries(userId);
      if (dbEntries.isNotEmpty) {
        // Merge: keep local entries not yet synced, add remote ones
        final localIds = _entries.map((e) => e.id).toSet();
        for (final remote in dbEntries) {
          if (!localIds.contains(remote.id)) {
            _entries.add(remote);
          }
        }
        await _cacheService.saveEntries(userId, _entries);
        _calculateStreak();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('⚠️ DB sync failed, using cache: $e');
    }

    // 3. Process any pending offline actions
    await _processPendingActions();
  }

  /// Process pending offline actions (add/delete) queued while offline
  Future<void> _processPendingActions() async {
    if (_userId == null || !_dbService.isConfigured) return;

    final pending = _cacheService.getPendingActions(_userId!);
    if (pending.isEmpty) return;

    debugPrint('🔄 Processing ${pending.length} pending actions...');

    for (final action in pending) {
      try {
        final type = action['action'] as String;
        final data = Map<String, dynamic>.from(action['data'] as Map);
        final timestamp = action['timestamp'] as int;

        if (type == 'add') {
          final entry = DiaryEntry.fromJson(data);
          await _dbService.addEntry(entry, _userId!);
        } else if (type == 'delete') {
          final id = data['id'] as String;
          await _dbService.deleteEntry(id);
        }

        await _cacheService.clearPendingAction(timestamp);
      } catch (e) {
        debugPrint('⚠️ Failed to process pending action: $e');
        // Leave it in queue for next try
        break;
      }
    }
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

    // Award XP (10 points per logged food)
    if (_achievementService != null) {
      final result = await _achievementService!.addXp(10);
      if (result != null && result['leveledUp'] == true) {
        onLevelUp?.call(result['newLevel']);
      }
    }

    // Sync to database (or queue if offline)
    try {
      if (_userId != null) {
        await _dbService.addEntry(entry, _userId!);
        // Optionally reload to get server-generated ID if needed
      }
    } catch (e) {
      debugPrint('Error syncing add entry: $e');
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
      }
    } catch (e) {
      debugPrint('Error syncing remove entry: $e');
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

      // ignore: todo
      // TODO: Implement update in DatabaseService
      // For now, delete and add (inefficient but works)
      if (_userId != null) {
        await _dbService.deleteEntry(id);
        if (_userId != null) {
          await _dbService.addEntry(_entries[index], _userId!);
        }
      }

      // Recalculate streak
      _calculateStreak();

      // Check for achievements after update
      _checkAchievements();
    }
  }

  /// Calculate current streak based on entry dates
  void _calculateStreak() {
    if (_entries.isEmpty) {
      _currentStreak = 0;
      return;
    }

    // 1. Extract unique dates (normalized to midnight)
    final uniqueDates = _entries
        .map((e) {
          return DateTime(e.date.year, e.date.month, e.date.day);
        })
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a)); // Newest first

    if (uniqueDates.isEmpty) {
      _currentStreak = 0;
      return;
    }

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final yesterdayDate = todayDate.subtract(const Duration(days: 1));

    // 2. Check if streak is active (must have logged today or yesterday)
    final lastLogDate = uniqueDates.first;
    if (lastLogDate != todayDate && lastLogDate != yesterdayDate) {
      _currentStreak = 0;
      return;
    }

    // 3. Count consecutive days
    int streak = 1;
    for (int i = 0; i < uniqueDates.length - 1; i++) {
      final current = uniqueDates[i];
      final next = uniqueDates[i + 1];

      final diff = current.difference(next).inDays;
      if (diff == 1) {
        streak++;
      } else {
        break;
      }
    }

    _currentStreak = streak;

    // Check for streak achievements
    _achievementService
        ?.checkStreakMilestone(_currentStreak)
        .then((achievement) {
      if (achievement != null) {
        onAchievement?.call(achievement.type);
      }
    });
  }

  /// Get calories for last 7 days
  Map<DateTime, double> getLast7DaysCalories() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final Map<DateTime, double> result = {};

    // Initialize last 7 days with 0
    for (int i = 6; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      result[date] = 0.0;
    }

    // Sum up entries
    for (final entry in _entries) {
      final entryDate =
          DateTime(entry.date.year, entry.date.month, entry.date.day);
      if (result.containsKey(entryDate)) {
        result[entryDate] = (result[entryDate] ?? 0) + entry.calories;
      }
    }

    return result;
  }

  /// Check and trigger achievements
  void _checkAchievements() {
    // Reset celebrations at midnight (new day)
    // final now = DateTime.now(); // Unused
    if (_celebratedToday.isNotEmpty) {
      // Simple check: if first entry of day, reset
      if (todayEntries.length == 1) {
        _celebratedToday.clear();
      }
    }

    // Check individual goals
    if (isCaloriesGoalReached &&
        !_celebratedToday.contains(AchievementType.caloriesGoal)) {
      _celebratedToday.add(AchievementType.caloriesGoal);
      onAchievement?.call(AchievementType.caloriesGoal);
    }

    if (isProteinsGoalReached &&
        !_celebratedToday.contains(AchievementType.proteinsGoal)) {
      _celebratedToday.add(AchievementType.proteinsGoal);
      onAchievement?.call(AchievementType.proteinsGoal);
    }

    if (isFatsGoalReached &&
        !_celebratedToday.contains(AchievementType.fatsGoal)) {
      _celebratedToday.add(AchievementType.fatsGoal);
      onAchievement?.call(AchievementType.fatsGoal);
    }

    if (isCarbsGoalReached &&
        !_celebratedToday.contains(AchievementType.carbohydratesGoal)) {
      _celebratedToday.add(AchievementType.carbohydratesGoal);
      onAchievement?.call(AchievementType.carbohydratesGoal);
    }

    // Perfect day achievement
    if (isPerfectDay &&
        !_celebratedToday.contains(AchievementType.perfectDay)) {
      _celebratedToday.add(AchievementType.perfectDay);
      onAchievement?.call(AchievementType.perfectDay);
    }
  }

  /// Starts background AI processing for a local image
  Future<void> addProcessingEntry(String imagePath) async {
    final entryId = const Uuid().v4();
    final tempItem = FoodItem(
      id: entryId,
      name: 'Обработка фото...',
      calories: 0,
      proteins: 0,
      fats: 0,
      carbohydrates: 0,
      category: 'processing',
    );

    final entry = DiaryEntry(
      id: entryId,
      foodItem: tempItem,
      weight: 100, // deafult weight
      date: DateTime.now(),
      isProcessing: true,
      localImagePath: imagePath,
    );

    _entries.add(entry);
    notifyListeners();

    // Start background processing
    _processImageAsync(entryId, imagePath);
  }

  Future<void> _processImageAsync(String entryId, String imagePath) async {
    try {
      final result = await _recognitionService.processImage(imagePath);
      final error = result['error'] as String?;

      final index = _entries.indexWhere((e) => e.id == entryId);
      if (index == -1) return; // Entry might have been deleted by user

      if (error != null) {
        // Update to error state
        final oldEntry = _entries[index];
        _entries[index] = DiaryEntry(
          id: oldEntry.id,
          foodItem: FoodItem(
            id: oldEntry.foodItem.id,
            name: 'Ошибка: $error',
            calories: 0,
            proteins: 0,
            fats: 0,
            carbohydrates: 0,
          ),
          weight: oldEntry.weight,
          date: oldEntry.date,
          isProcessing: false,
          localImagePath: oldEntry.localImagePath,
        );
      } else {
        final suggestions =
            (result['suggestions'] as List?)?.cast<String>() ?? [];
        if (suggestions.isNotEmpty) {
          final name = suggestions.first;
          // Создаём базовый продукт
          final foodItem = FoodItem(
            id: const Uuid().v4(),
            name: name,
            calories: 100,
            proteins: 1,
            fats: 1,
            carbohydrates: 20,
            category: 'other',
          );

          final oldEntry = _entries[index];
          _entries[index] = DiaryEntry(
            id: oldEntry.id,
            foodItem: foodItem,
            weight: oldEntry.weight,
            date: oldEntry.date,
            isProcessing: false,
            localImagePath: oldEntry.localImagePath,
          );

          // Sync to DB
          if (_userId != null) {
            await _dbService.addEntry(_entries[index], _userId!);
          }
        }
      }

      // Award XP for successful photo log
      if (_achievementService != null && error == null) {
        final xpResult = await _achievementService!.addXp(15);
        if (xpResult != null && xpResult['leveledUp'] == true) {
          onLevelUp?.call(xpResult['newLevel']);
        }
      }

      _calculateStreak();
      _checkAchievements();

      notifyListeners();
      await _cacheService.saveEntries(_userId ?? '', _entries);
    } catch (e) {
      debugPrint('Error in background processing: $e');
      final index = _entries.indexWhere((e) => e.id == entryId);
      if (index != -1) {
        final oldEntry = _entries[index];
        _entries[index] = DiaryEntry(
          id: oldEntry.id,
          foodItem: FoodItem(
            id: oldEntry.foodItem.id,
            name: 'Не удалось распознать',
            calories: 0,
            proteins: 0,
            fats: 0,
            carbohydrates: 0,
          ),
          weight: oldEntry.weight,
          date: oldEntry.date,
          isProcessing: false,
          localImagePath: oldEntry.localImagePath,
        );
        notifyListeners();
        await _cacheService.saveEntries(_userId ?? '', _entries);
      }
    }
  }
}
