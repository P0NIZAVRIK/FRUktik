import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../core/config/supabase_config.dart';

/// Authentication service using Supabase
class AuthService extends ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;
  
  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  AuthService() {
    _initAuth();
  }
  
  Future<void> _initAuth() async {
    _isLoading = true;
    notifyListeners();
    
    // Check if Supabase is initialized
    if (SupabaseConfig.isConfigured) {
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        await _fetchProfile(session.user.id, session.user.email!);
      } else {
        // Fallback to local storage (migration or offline)
        await _loadLocalUser();
      }
      
      // Listen to auth changes
      Supabase.instance.client.auth.onAuthStateChange.listen((data) {
        final AuthChangeEvent event = data.event;
        final Session? session = data.session;
        
        if (event == AuthChangeEvent.signedIn && session != null) {
          _fetchProfile(session.user.id, session.user.email!);
        } else if (event == AuthChangeEvent.signedOut) {
          _currentUser = null;
          notifyListeners();
        }
      });
    } else {
      await _loadLocalUser();
    }
    
    _isLoading = false;
    notifyListeners();
  }
  
  Future<void> _loadLocalUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString('user_data');
      if (userData != null) {
        _currentUser = UserModel.fromJson(jsonDecode(userData));
      }
    } catch (e) {
      debugPrint('Error loading local user: $e');
    }
  }

  Future<void> _fetchProfile(String userId, String email) async {
    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      
      if (data != null) {
        // Merge auth email with profile data
        final Map<String, dynamic> fullData = Map.from(data);
        fullData['email'] = email;
        _currentUser = UserModel.fromJson(fullData);
        await _saveUserLocally(); // Cache for offline
      } else {
        // If profile doesn't exist yet, creates minimal user
        _currentUser = UserModel(
          id: userId,
          email: email,
          displayName: email.split('@').first,
          createdAt: DateTime.now(),
        );
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching profile: $e');
    }
  }
  
  Future<bool> register({
    required String email,
    required String password,
    required String displayName,
    UserGoal? goal,
    double dailyCalorieTarget = 2000,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      if (!SupabaseConfig.isConfigured) throw Exception('Supabase not configured');

      // Pass user data as metadata for the Trigger to handle
      final res = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        data: {
          'display_name': displayName,
          'goal': goal?.name,
          'daily_cal_target': dailyCalorieTarget,
        },
      );
      
      if (res.user != null) {
        // We don't insert manually anymore. The Postgres Trigger does it.
        // Just wait a bit for trigger to finish and fetch profile
        await Future.delayed(const Duration(milliseconds: 1000));
        
        await _fetchProfile(res.user!.id, email);
        return true;
      }
      return false;
      
    } on AuthException catch (e) {
      _error = e.message;
      return false;
    } catch (e) {
      _error = 'Ошибка регистрации: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      if (!SupabaseConfig.isConfigured) throw Exception('Supabase not configured');

      final res = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (res.user != null) {
        await _fetchProfile(res.user!.id, res.user!.email!);
        return true;
      }
      return false;
      
    } on AuthException catch (e) {
      _error = e.message; // E.g. Invalid login credentials
      return false;
    } catch (e) {
      _error = 'Ошибка входа: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> updateProfile({
    String? displayName,
    String? avatarUrl,
    UserGoal? goal,
    double? dailyCalorieTarget,
  }) async {
    if (_currentUser == null) return;
    
    try {
      // Optimistic update
      _currentUser = _currentUser!.copyWith(
        displayName: displayName,
        avatarUrl: avatarUrl,
        goal: goal,
        dailyCalorieTarget: dailyCalorieTarget,
      );
      notifyListeners();
      
      if (SupabaseConfig.isConfigured) {
        final updates = <String, dynamic>{};
        if (displayName != null) updates['display_name'] = displayName;
        if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
        if (goal != null) updates['goal'] = goal.name;
        if (dailyCalorieTarget != null) updates['daily_cal_target'] = dailyCalorieTarget;
        
        await Supabase.instance.client
            .from('profiles')
            .update(updates)
            .eq('id', _currentUser!.id);
            
        await _saveUserLocally();
      }
    } catch (e) {
      _error = 'Ошибка обновления профиля: $e';
      notifyListeners();
    }
  }
  
  Future<void> logout() async {
    try {
      if (SupabaseConfig.isConfigured) {
        await Supabase.instance.client.auth.signOut();
      }
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_data');
      
      _currentUser = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Logout error: $e');
    }
  }
  
  Future<void> _saveUserLocally() async {
    if (_currentUser == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', jsonEncode(_currentUser!.toJson()));
  }
}
