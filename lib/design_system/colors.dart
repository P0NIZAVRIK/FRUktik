import 'package:flutter/material.dart';

/// Premium color system for FRUktik
/// AMOLED-optimized dark theme with vibrant neon accents
class AppColors {
  AppColors._();

  // ============================================================================
  // AMOLED Dark Theme (Primary)
  // ============================================================================
  
  /// Pure black for AMOLED screens (battery efficient)
  static const Color backgroundPrimary = Color(0xFF000000);
  
  /// Slightly elevated black for cards
  static const Color backgroundSecondary = Color(0xFF0A0A0A);
  
  /// Surface color for containers
  static const Color surface = Color(0xFF121212);
  static const Color surfaceVariant = Color(0xFF1E1E1E);
  
  /// Text colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0B0);
  static const Color textTertiary = Color(0xFF808080);

  // ============================================================================
  // Neon Accents (Nutrition Categories)
  // ============================================================================
  
  /// Protein - Vibrant Green
  static const Color proteinNeon = Color(0xFF00FF88);
  static const Color proteinGlow = Color(0xFF00CC6A);
  
  /// Fats - Electric Blue
  static const Color fatsNeon = Color(0xFF00D4FF);
  static const Color fatsGlow = Color(0xFF00A8CC);
  
  /// Carbs - Warm Orange
  static const Color carbsNeon = Color(0xFFFF6B35);
  static const Color carbsGlow = Color(0xFFCC5529);
  
  /// Calories - Hot Pink
  static const Color caloriesNeon = Color(0xFFFF006E);
  static const Color caloriesGlow = Color(0xFFCC0058);

  // ============================================================================
  // Accent Colors
  // ============================================================================
  
  static const Color primary = Color(0xFF7B61FF);
  static const Color primaryVariant = Color(0xFF5B41DB);
  
  /// Success states
  static const Color success = Color(0xFF00FF88);
  static const Color successContainer = Color(0xFF003322);
  
  /// Warning states
  static const Color warning = Color(0xFFFFB800);
  static const Color warningContainer = Color(0xFF3D2E00);
  
  /// Error states
  static const Color error = Color(0xFFFF4444);
  static const Color errorContainer = Color(0xFF3D1111);
  
  /// Info states
  static const Color info = Color(0xFF00D4FF);
  static const Color infoContainer = Color(0xFF003544);

  // ============================================================================
  // Glassmorphism
  // ============================================================================
  
  static const Color glassBackground = Color(0x1AFFFFFF);
  static const Color glassBorder = Color(0x33FFFFFF);
  
  // ============================================================================
  // Gradients
  // ============================================================================
  
  static const LinearGradient proteinGradient = LinearGradient(
    colors: [proteinNeon, proteinGlow],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient fatsGradient = LinearGradient(
    colors: [fatsNeon, fatsGlow],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient carbsGradient = LinearGradient(
    colors: [carbsNeon, carbsGlow],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient caloriesGradient = LinearGradient(
    colors: [caloriesNeon, caloriesGlow],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  /// Premium purple gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF7B61FF), Color(0xFFB47BFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  /// Dynamic gradient based on calorie ratio
  static LinearGradient getCalorieGradient(double current, double goal) {
    final ratio = current / goal;
    
    if (ratio > 1.2) {
      // Overconsumption - Red gradient
      return const LinearGradient(
        colors: [Color(0xFFFF4444), Color(0xFFCC0000)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (ratio > 0.8 && ratio <= 1.1) {
      // Perfect balance - Green gradient
      return const LinearGradient(
        colors: [proteinNeon, proteinGlow],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (ratio > 0.5) {
      // On track - Blue gradient
      return const LinearGradient(
        colors: [fatsNeon, fatsGlow],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else {
      // Low intake - Yellow gradient
      return const LinearGradient(
        colors: [Color(0xFFFFB800), Color(0xFFCC9200)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
  }

  // ============================================================================
  // Shadows & Glow
  // ============================================================================
  
  /// Soft shadow for elevation
  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.3),
      blurRadius: 20,
      offset: const Offset(0, 10),
    ),
  ];
  
  /// Neon glow effect
  static List<BoxShadow> getNeonGlow(Color color) => [
    BoxShadow(
      color: color.withOpacity(0.5),
      blurRadius: 20,
      spreadRadius: 2,
    ),
    BoxShadow(
      color: color.withOpacity(0.3),
      blurRadius: 40,
      spreadRadius: 4,
    ),
  ];
}
