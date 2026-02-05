import 'package:hive_flutter/hive_flutter.dart';
import '../models/diary_entry.dart';

/// Local cache service using Hive for offline-first diary entries
class LocalCacheService {
  static const String _entriesBox = 'diary_entries';
  static const String _pendingActionsBox = 'pending_actions';
  
  Box<Map>? _entries;
  Box<Map>? _pendingActions;
  
  /// Initialize Hive boxes
  Future<void> init() async {
    await Hive.initFlutter();
    _entries = await Hive.openBox<Map>(_entriesBox);
    _pendingActions = await Hive.openBox<Map>(_pendingActionsBox);
  }
  
  /// Save entries to local cache (by user ID)
  Future<void> saveEntries(String userId, List<DiaryEntry> entries) async {
    final data = entries.map((e) => e.toJson()).toList();
    await _entries?.put(userId, {'entries': data});
  }
  
  /// Get cached entries for user
  List<DiaryEntry> getCachedEntries(String userId) {
    final data = _entries?.get(userId);
    if (data == null) return [];
    
    final entriesList = data['entries'] as List?;
    if (entriesList == null) return [];
    
    return entriesList
        .map((e) {
          // Hive returns Map<dynamic, dynamic>, need to convert properly
          final entryMap = Map<String, dynamic>.from(e as Map);
          return DiaryEntry.fromJson(entryMap);
        })
        .toList();
  }
  
  /// Add pending action for offline sync
  Future<void> addPendingAction({
    required String userId,
    required String action, // 'add', 'delete', 'update'
    required Map<String, dynamic> data,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    await _pendingActions?.put(timestamp, {
      'userId': userId,
      'action': action,
      'data': data,
      'timestamp': timestamp,
    });
  }
  
  /// Get all pending actions for a user
  List<Map<String, dynamic>> getPendingActions(String userId) {
    final allActions = _pendingActions?.values.toList() ?? [];
    return allActions
        .where((action) {
          final actionMap = action as Map;
          return actionMap['userId'] == userId;
        })
        .map((e) {
          // Convert Hive Map to proper type
          final actionMap = e as Map;
          return Map<String, dynamic>.from(actionMap);
        })
        .toList();
  }
  
  /// Clear pending action after successful sync
  Future<void> clearPendingAction(int timestamp) async {
    await _pendingActions?.delete(timestamp);
  }
  
  /// Clear all cache for user (on logout)
  Future<void> clearUserCache(String userId) async {
    await _entries?.delete(userId);
    
    // Clear user's pending actions
    final userActions = getPendingActions(userId);
    for (final action in userActions) {
      await _pendingActions?.delete(action['timestamp']);
    }
  }
  
  /// Clear all data
  Future<void> clearAll() async {
    await _entries?.clear();
    await _pendingActions?.clear();
  }
}
