import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/achievement.dart';
import 'dart:convert';

/// Service for managing achievements and tracking progress
class AchievementService extends ChangeNotifier {
  final SupabaseClient? _client;
  List<Achievement> _achievements = [];
  List<Achievement> _unlockedAchievements = [];

  AchievementService({SupabaseClient? client}) : _client = client {
    _loadAchievements();
  }

  List<Achievement> get achievements => _achievements;
  List<Achievement> get unlockedAchievements => _unlockedAchievements;
  int get unlockedCount => _unlockedAchievements.length;
  int get totalCount => _achievements.length;

  Future<void> _loadAchievements() async {
    // Initialize with predefined achievements
    _achievements = List.from(Achievement.all);

    // Load unlocked achievements from local storage (fallback)
    final prefs = await SharedPreferences.getInstance();
    final unlockedJson = prefs.getString('unlocked_achievements');

    if (unlockedJson != null) {
      final List<dynamic> unlockedIds = jsonDecode(unlockedJson);
      _unlockedAchievements = _achievements
          .where((a) => unlockedIds.contains(a.id))
          .map((a) => a.copyWith(unlockedAt: DateTime.now()))
          .toList();
    }

    // Try to sync with Supabase
    await _syncWithSupabase();

    notifyListeners();
  }

  Future<void> _syncWithSupabase() async {
    if (_client == null) return;

    try {
      final userId = _client!.auth.currentUser?.id;
      if (userId == null) return;

      final response =
          await _client!.from('achievements').select().eq('user_id', userId);

      if (response.isNotEmpty) {
        // Update achievements with unlocked status from DB
        for (var row in response) {
          final achievementId = row['achievement_id'] as String;
          final unlockedAt = DateTime.parse(row['unlocked_at'] as String);

          final index = _achievements.indexWhere((a) => a.id == achievementId);
          if (index != -1) {
            _achievements[index] = _achievements[index].copyWith(
              unlockedAt: unlockedAt,
            );

            if (!_unlockedAchievements.any((a) => a.id == achievementId)) {
              _unlockedAchievements.add(_achievements[index]);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error syncing achievements: $e');
    }
  }

  /// Check and unlock achievement if conditions met
  Future<Achievement?> checkAndUnlock({
    required AchievementType type,
    required int currentValue,
  }) async {
    // Find matching achievement that's not yet unlocked
    final achievement = _achievements.firstWhere(
      (a) => a.type == type && a.targetValue == currentValue && !a.isUnlocked,
      orElse: () => throw StateError('No matching achievement'),
    );

    if (achievement.id.isEmpty) return null;

    // Unlock it
    final unlocked = achievement.copyWith(unlockedAt: DateTime.now());
    final index = _achievements.indexWhere((a) => a.id == achievement.id);
    _achievements[index] = unlocked;
    _unlockedAchievements.add(unlocked);

    // Save to local storage
    await _saveToLocal();

    // Save to Supabase
    await _saveToSupabase(unlocked);

    notifyListeners();

    return unlocked;
  }

  Future<void> _saveToLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final unlockedIds = _unlockedAchievements.map((a) => a.id).toList();
    await prefs.setString('unlocked_achievements', jsonEncode(unlockedIds));
  }

  Future<void> _saveToSupabase(Achievement achievement) async {
    if (_client == null) return;

    try {
      final userId = _client!.auth.currentUser?.id;
      if (userId == null) return;

      await _client!.from('achievements').insert({
        'user_id': userId,
        'achievement_id': achievement.id,
        'unlocked_at': achievement.unlockedAt!.toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error saving achievement to Supabase: $e');
    }
  }

  /// Check for entry count milestones
  Future<Achievement?> checkEntryMilestone(int totalEntries) async {
    try {
      return await checkAndUnlock(
        type: AchievementType.entriesCount,
        currentValue: totalEntries,
      );
    } catch (e) {
      return null;
    }
  }

  /// Check for streak milestones
  Future<Achievement?> checkStreakMilestone(int currentStreak) async {
    try {
      return await checkAndUnlock(
        type: AchievementType.streak,
        currentValue: currentStreak,
      );
    } catch (e) {
      return null;
    }
  }

  /// Check for perfect day achievement
  Future<Achievement?> checkPerfectDay() async {
    try {
      return await checkAndUnlock(
        type: AchievementType.perfectDay,
        currentValue: 1,
      );
    } catch (e) {
      return null;
    }
  }
  // ... (Existing achievement methods) ...

  /// Add XP to user and check for level up
  Future<Map<String, dynamic>?> addXp(int amount) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataStr = prefs.getString('user_data');

      if (userDataStr == null) return null;

      final userData = jsonDecode(userDataStr);
      int currentXp = (userData['xp'] as num?)?.toInt() ?? 0;
      int currentLevel = (userData['level'] as num?)?.toInt() ?? 1;

      int newXp = currentXp + amount;
      int newLevel = currentLevel;
      bool leveledUp = false;

      // Level calculation: Level = 1 + (XP / 100)
      // e.g. 0-99 XP = Lvl 1, 100-199 = Lvl 2
      final calculatedLevel = 1 + (newXp ~/ 100);

      if (calculatedLevel > currentLevel) {
        newLevel = calculatedLevel;
        leveledUp = true;
      }

      // Update local storage via AuthService (we need to trigger Auth updates)
      // Since we can't easily access AuthService here without circular dependency,
      // we'll update SharedPreferences and let AuthService reload or update strictly explicitly if passed.
      // Better approach: We return the result and let the UI/Provider handle the AuthService update.

      // For now, we update local prefs directly so it persists
      userData['xp'] = newXp;
      userData['level'] = newLevel;
      await prefs.setString('user_data', jsonEncode(userData));

      // Sync with Supabase
      await _syncXpToSupabase(newXp, newLevel);

      if (leveledUp) {
        return {
          'leveledUp': true,
          'newLevel': newLevel,
          'newXp': newXp,
        };
      }

      return {
        'leveledUp': false,
        'newLevel': newLevel,
        'newXp': newXp,
      };
    } catch (e) {
      debugPrint('Error adding XP: $e');
      return null;
    }
  }

  /// Track whether Supabase schema supports xp/level columns
  static bool _supabaseXpSupported = true;

  Future<void> _syncXpToSupabase(int xp, int level) async {
    if (_client == null || !_supabaseXpSupported) return;
    try {
      final userId = _client!.auth.currentUser?.id;
      if (userId == null) return;

      await _client!.from('profiles').update({
        'xp': xp,
        'level': level,
      }).eq('id', userId);
    } catch (e) {
      final errorStr = e.toString();
      // If schema doesn't have xp/level columns, stop retrying
      if (errorStr.contains('PGRST204') || errorStr.contains('column')) {
        _supabaseXpSupported = false;
        debugPrint(
            '⚠️ Supabase profiles table missing xp/level columns. XP saved locally only.');
      } else {
        debugPrint('Error syncing XP to Supabase: $e');
      }
    }
  }
}
