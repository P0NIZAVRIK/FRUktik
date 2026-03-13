import 'package:flutter/animation.dart';
import 'package:flutter/material.dart'; // Added for Curves

/// Animation constants and curves
/// Ensures consistent, smooth transitions throughout the app
class AppAnimations {
  AppAnimations._();

  // ============================================================================
  // Duration Constants (Slowed down for smoother feel)
  // ============================================================================
  
  /// Ultra fast - micro interactions
  static const Duration ultraFast = Duration(milliseconds: 150); // was 100
  
  /// Fast - quick feedback
  static const Duration fast = Duration(milliseconds: 300); // was 200
  
  /// Normal - standard transitions
  static const Duration normal = Duration(milliseconds: 500); // was 300
  
  /// Medium - drawer, dialogs
  static const Duration medium = Duration(milliseconds: 700); // was 400
  
  /// Slow - page transitions
  static const Duration slow = Duration(milliseconds: 1000); // was 600
  
  /// Very slow - complex animations
  static const Duration verySlow = Duration(milliseconds: 1200); // was 800

  // ============================================================================
  // Custom Curves (Smoother Physics)
  // ============================================================================
  
  /// Smooth natural spring (Apple-like)
  static const Curve spring = Curves.easeOutBack; // Standard Flutter spring-like curve
  
  /// Gentle spring for subtle movements
  static const Curve springGentle = Curves.easeOutQuart; // Smoother than Cubic
  
  /// Aggressive spring for playful interactions
  static const Curve springBounce = Curves.elasticOut;
  
  /// Standard ease for entering elements
  static const Curve easeIn = Curves.easeInQuad;
  
  /// Standard ease for exiting elements
  static const Curve easeOut = Curves.easeOutQuad;
  
  /// Smooth ease in and out
  static const Curve easeInOut = Curves.easeInOutCubic;
  
  /// Premium feeling curve (Quint is very smooth start/end)
  static const Curve premium = Curves.easeOutQuint;

  // ============================================================================
  // Stagger Animation Settings
  // ============================================================================
  
  /// Delay between list items appearing
  static const Duration staggerDelay = Duration(milliseconds: 80); // Increased
  
  /// Maximum stagger delay (to avoid too long waits)
  static const Duration maxStaggerDelay = Duration(milliseconds: 800);

  // ============================================================================
  // Hero Animation Settings
  // ============================================================================
  
  /// Hero animation duration
  static const Duration heroDuration = medium;
  
  // ============================================================================
  // Shimmer/Skeleton Settings
  // ============================================================================
  
  /// Shimmer animation period
  static const Duration shimmerDuration = Duration(milliseconds: 2000);
  
  /// Skeleton pulse duration
  static const Duration skeletonDuration = Duration(milliseconds: 1500);

  // ============================================================================
  // Interactive Feedback
  // ============================================================================
  
  /// Scale down on press
  static const double pressedScale = 0.96; // Less aggressive scale down
  
  /// Scale up on hover
  static const double hoveredScale = 1.02;
  
  /// Duration for press animation
  static const Duration pressDuration = ultraFast;

  // ============================================================================
  // Page Transition Settings
  // ============================================================================
  
  /// Fade in duration
  static const Duration fadeInDuration = normal;
  
  /// Slide transition offset
  static const double slideOffset = 0.2; // Reduced offset for steeper slide

  // ============================================================================
  // Helper Methods
  // ============================================================================
  
  /// Calculate stagger delay for index
  static Duration getStaggerDelay(int index) {
    final delay = staggerDelay * index;
    return delay > maxStaggerDelay ? maxStaggerDelay : delay;
  }
}

