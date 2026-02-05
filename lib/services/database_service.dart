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
          .order('date', ascending: false); // Order by date, newest first
          
      return (data as List).map((e) => DiaryEntry.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error fetching entries: $e');
      rethrow;
    }
  }
  
  Future<void> addEntry(DiaryEntry entry, String userId) async {
    if (!isConfigured) return;
    
    try {
      final json = entry.toJson();
      json['user_id'] = userId;
      // remove 'id' if you want postgres to generate it, but we generate it locally to support offline/optimistic
      
      await _client!.from('diary_entries').insert(json);
    } catch (e) {
      debugPrint('Error adding entry: $e');
      rethrow;
    }
  }
  
  Future<void> deleteEntry(String entryId) async {
    if (!isConfigured) return;
    
    try {
      await _client!.from('diary_entries').delete().eq('id', entryId);
    } catch (e) {
      debugPrint('Error deleting entry: $e');
      rethrow;
    }
  }
}
