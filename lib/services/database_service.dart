import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/diary_entry.dart';
import '../core/config/supabase_config.dart';

class DatabaseService {
  SupabaseClient? _client;

  DatabaseService() {
    if (SupabaseConfig.isConfigured) {
      _client = Supabase.instance.client;
    }
  }

  bool get isConfigured => _client != null && SupabaseConfig.isConfigured;

  Future<List<DiaryEntry>> getEntries(String userId) async {
    if (!isConfigured) return [];

    try {
      final data = await _client!
          .from('diary_entries')
          .select()
          .eq('user_id', userId)
          .order('date', ascending: false);

      return (data as List).map((e) => DiaryEntry.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error fetching entries: $e');
      return []; // Return empty instead of rethrow — use cache
    }
  }

  Future<bool> addEntry(DiaryEntry entry, String userId) async {
    if (!isConfigured) return false;

    try {
      final json = entry.toJson();
      json['user_id'] = userId;
      // Remove local-only fields that are not in the Supabase schema
      json.remove('isProcessing');
      json.remove('localImagePath');

      await _client!.from('diary_entries').insert(json);
      return true;
    } catch (e) {
      debugPrint('Error adding entry: $e');
      return false; // Caller should queue for offline sync
    }
  }

  Future<bool> deleteEntry(String entryId) async {
    if (!isConfigured) return false;

    try {
      await _client!.from('diary_entries').delete().eq('id', entryId);
      return true;
    } catch (e) {
      debugPrint('Error deleting entry: $e');
      return false;
    }
  }

  Future<bool> updateEntry(DiaryEntry entry, String userId) async {
    if (!isConfigured) return false;

    try {
      final json = entry.toJson();
      json['user_id'] = userId;
      json.remove('isProcessing');
      json.remove('localImagePath');

      await _client!.from('diary_entries').update(json).eq('id', entry.id);
      return true;
    } catch (e) {
      debugPrint('Error updating entry: $e');
      return false;
    }
  }
}
