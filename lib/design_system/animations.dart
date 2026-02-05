import 'package:flutter/animation.dart';

/// Animation constants and curves
/// Ensures consistent, smooth transitions throughout the app
class AppAnimations {
  AppAnimations._();

  // ============================================================================
  // Duration Constants
  // ============================================================================
  
  /// Ultra fast - micro interactions
  static const Duration ultraFast = Duration(milliseconds: 100);
  
  /// Fast - quick feedback
  static const Duration fast = Duration(milliseconds: 200);
  
  /// Normal - standard transitions
  static const Duration normal = Duration(milliseconds: 300);
  
  /// Medium - drawer, dialogs
  static const Duration medium = Duration(milliseconds: 400);
  
  /// Slow - page transitions
  static const Duration slow = Duration(milliseconds: 600);
  
  /// Very slow - complex animations
  static const Duration verySlow = Duration(milliseconds: 800);

  // ============================================================================
  // Custom Curves (Spring Physics)
  // ============================================================================
  
  /// Smooth ease out with bounce
  static const Curve spring = Curves.easeOutBack;
  
  /// Gentle spring for subtle movements
  static const Curve springGentle = Curves.easeOutCubic;
  
  /// Aggressive spring for playful interactions
  static const Curve springBounce = Curves.elasticOut;
  
  /// Standard ease for entering elements
  static const Curve easeIn = Curves.easeIn;
  
  /// Standard ease for exiting elements
  static const Curve easeOut = Curves.easeOut;
  
  /// Smooth ease in and out
  static const Curve easeInOut = Curves.easeInOutCubic;
  
  /// Premium feeling curve (similar to iOS)
  static const Curve premium = Curves.easeOutQuint;

  // ============================================================================
  // Stagger Animation Settings
  // ============================================================================
  
  /// Delay between list items appearing
  static const Duration staggerDelay = Duration(milliseconds: 50);
  
  /// Maximum stagger delay (to avoid too long waits)
  static const Duration maxStaggerDelay = Duration(milliseconds: 500);

  // ============================================================================
  // Hero Animation Settings
  // ============================================================================
  
  /// Hero animation duration
  static const Duration heroDuration = medium;
  
  // ============================================================================
  // Shimmer/Skeleton Settings
  // ============================================================================
  
  /// Shimmer animation period
  static const Duration shimmerDuration = Duration(milliseconds: 1500);
  
  /// Skeleton pulse duration
  static const Duration skeletonDuration = Duration(milliseconds: 1200);

  // ============================================================================
  // Interactive Feedback
  // ============================================================================
  
  /// Scale down on press
  static const double pressedScale = 0.95;
  
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
  static const double slideOffset = 0.3;

  // ============================================================================
  // Helper Methods
  // ============================================================================
  
  /// Calculate stagger delay for index
  static Duration getStaggerDelay(int index) {
    final delay = staggerDelay * index;
    return delay > maxStaggerDelay ? maxStaggerDelay : delay;
  }
  
  /// Combine multiple curves
  static Curve combineCurves(Curve first, Curve second) {
    return Interval(0.0, 1.0, curve: first);
  }
}

/// Custom cubic curve for ultra-smooth animations
class UltraSmoothCurve extends Curve {
  const UltraSmoothCurve();

  @override
  double transform(double t) {
    // Bezier curve: (0.4, 0, 0.2, 1)
    final t2 = t * t;
    final t3 = t2 * t;
    return 3 * (1 - t) * (1 - t) * t * 0.4 +
           3 * (1 - t) * t2 * 1.0 +
           t3;
  }
}

/// Spring curve with damping
class SpringCurve extends Curve {
  final double damping;
  final double mass;
  final double stiffness;

  const SpringCurve({
    this.damping = 0.7,
    this.mass = 1.0,
    this.stiffness = 100.0,
  });

  @override
  double transform(double t) {
    final omega = 2.0 * 3.14159 / (2.0 * 3.14159 * 1.0 / stiffness);
    final envelope = 1.0 - (1.0 - t) * (1.0 - t);
    return envelope * (1.0 - (1.0 - t) * damping);
  }
}
