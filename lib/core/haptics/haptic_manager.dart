import 'package:flutter/services.dart';

/// Haptic feedback patterns for premium tactile experience
enum HapticPattern {
  /// Light tap - UI buttons and selections (10ms)
  light,
  
  /// Medium impact - Adding food, confirmations (20ms)
  medium,
  
  /// Heavy impact - Delete, errors (30ms)
  heavy,
  
  /// Success pattern - Goal achieved (multi-vibration pattern)
  success,
  
  /// Error pattern - Validation failed (double heavy)
  error,
  
  /// Selection tick - Scroll through items
  selection,
  
  /// Impact - Drag & drop feedback
  impact,
}

/// Manager for haptic feedback throughout the app
class HapticManager {
  static bool _isEnabled = true;
  
  /// Enable haptic feedback globally
  static void enable() => _isEnabled = true;
  
  /// Disable haptic feedback globally
  static void disable() => _isEnabled = false;
  
  /// Check if haptics are enabled
  static bool get isEnabled => _isEnabled;
  
  /// Trigger a haptic pattern
  static Future<void> trigger(HapticPattern pattern) async {
    if (!_isEnabled) return;
    
    switch (pattern) {
      case HapticPattern.light:
        await HapticFeedback.lightImpact();
        break;
      
      case HapticPattern.medium:
        await HapticFeedback.mediumImpact();
        break;
      
      case HapticPattern.heavy:
        await HapticFeedback.heavyImpact();
        break;
      
      case HapticPattern.success:
        // Custom success pattern: medium, pause, medium, pause, heavy
        await HapticFeedback.mediumImpact();
        await Future.delayed(const Duration(milliseconds: 50));
        await HapticFeedback.mediumImpact();
        await Future.delayed(const Duration(milliseconds: 50));
        await HapticFeedback.heavyImpact();
        break;
      
      case HapticPattern.error:
        // Double heavy vibration for errors
        await HapticFeedback.heavyImpact();
        await Future.delayed(const Duration(milliseconds: 100));
        await HapticFeedback.heavyImpact();
        break;
      
      case HapticPattern.selection:
        await HapticFeedback.selectionClick();
        break;
      
      case HapticPattern.impact:
        await HapticFeedback.mediumImpact();
        break;
    }
  }
  
  /// Trigger light haptic - for UI interactions
  static Future<void> light() => trigger(HapticPattern.light);
  
  /// Trigger medium haptic - for confirmations
  static Future<void> medium() => trigger(HapticPattern.medium);
  
  /// Trigger heavy haptic - for important actions
  static Future<void> heavy() => trigger(HapticPattern.heavy);
  
  /// Trigger success haptic pattern - for achievements
  static Future<void> success() => trigger(HapticPattern.success);
  
  /// Trigger error haptic pattern - for validation errors
  static Future<void> error() => trigger(HapticPattern.error);
  
  /// Trigger selection haptic - for scrolling/selecting
  static Future<void> selection() => trigger(HapticPattern.selection);
  
  /// Trigger impact haptic - for drag & drop
  static Future<void> impact() => trigger(HapticPattern.impact);
}
