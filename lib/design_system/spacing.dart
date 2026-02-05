import 'package:flutter/material.dart';

/// Spacing system based on 8px grid
/// Ensures visual consistency across the app
class AppSpacing {
  AppSpacing._();

  // ============================================================================
  // Base Spacing Values (8px increments)
  // ============================================================================
  
  static const double xs = 4.0;   // Extra small
  static const double sm = 8.0;   // Small
  static const double md = 16.0;  // Medium (base unit)
  static const double lg = 24.0;  // Large
  static const double xl = 32.0;  // Extra large
  static const double xxl = 48.0; // 2x Extra large
  static const double xxxl = 64.0; // 3x Extra large

  // ============================================================================
  // Semantic Spacing
  // ============================================================================
  
  /// Padding inside cards/containers
  static const double cardPadding = md;
  static const double cardPaddingLarge = lg;
  
  /// Spacing between list items
  static const double listItemSpacing = sm;
  
  /// Screen edge padding
  static const double screenPadding = md;
  static const double screenPaddingLarge = lg;
  
  /// Section spacing
  static const double sectionSpacing = xl;
  
  /// Icon spacing
  static const double iconSpacing = sm;

  // ============================================================================
  // EdgeInsets Shortcuts
  // ============================================================================
  
  static const EdgeInsets allXS = EdgeInsets.all(xs);
  static const EdgeInsets allSM = EdgeInsets.all(sm);
  static const EdgeInsets allMD = EdgeInsets.all(md);
  static const EdgeInsets allLG = EdgeInsets.all(lg);
  static const EdgeInsets allXL = EdgeInsets.all(xl);
  
  static const EdgeInsets horizontalMD = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets horizontalLG = EdgeInsets.symmetric(horizontal: lg);
  static const EdgeInsets verticalMD = EdgeInsets.symmetric(vertical: md);
  static const EdgeInsets verticalLG = EdgeInsets.symmetric(vertical: lg);
  
  // ============================================================================
  // SizedBox Shortcuts
  // ============================================================================
  
  static const SizedBox verticalSpaceXS = SizedBox(height: xs);
  static const SizedBox verticalSpaceSM = SizedBox(height: sm);
  static const SizedBox verticalSpaceMD = SizedBox(height: md);
  static const SizedBox verticalSpaceLG = SizedBox(height: lg);
  static const SizedBox verticalSpaceXL = SizedBox(height: xl);
  
  static const SizedBox horizontalSpaceXS = SizedBox(width: xs);
  static const SizedBox horizontalSpaceSM = SizedBox(width: sm);
  static const SizedBox horizontalSpaceMD = SizedBox(width: md);
  static const SizedBox horizontalSpaceLG = SizedBox(width: lg);
  static const SizedBox horizontalSpaceXL = SizedBox(width: xl);

  // ============================================================================
  // Border Radius
  // ============================================================================
  
  static const BorderRadius radiusXS = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius radiusSM = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius radiusMD = BorderRadius.all(Radius.circular(md));
  static const BorderRadius radiusLG = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius radiusXL = BorderRadius.all(Radius.circular(xl));
  
  /// Fully rounded
  static const BorderRadius radiusFull = BorderRadius.all(Radius.circular(9999));
}
