import 'dart:ui';
import 'package:flutter/material.dart';
import '../../design_system/colors.dart';
import '../../design_system/spacing.dart';

/// Glass morphism container with blur effect
/// Creates premium frosted glass appearance
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final List<Color>? gradientColors;
  final Border? border;
  final List<BoxShadow>? boxShadow;
  final double blurSigma;
  final double opacity;

  const GlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius,
    this.gradientColors,
    this.border,
    this.boxShadow,
    this.blurSigma = 10.0,
    this.opacity = 0.1,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: borderRadius ?? AppSpacing.radiusLG,
        boxShadow: boxShadow ?? AppColors.softShadow,
      ),
      child: ClipRRect(
        borderRadius: borderRadius ?? AppSpacing.radiusLG,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors ?? [
                  Colors.white.withOpacity(opacity),
                  Colors.white.withOpacity(opacity * 0.5),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: borderRadius ?? AppSpacing.radiusLG,
              border: border ?? Border.all(
                color: AppColors.glassBorder,
                width: 1,
              ),
            ),
            padding: padding ?? AppSpacing.allMD,
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Glass panel for major sections
class GlassPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool hasBorder;

  const GlassPanel({
    super.key,
    required this.child,
    this.padding,
    this.hasBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: hasBorder ? Border.all(
          color: AppColors.glassBorder,
          width: 1,
        ) : null,
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            color: AppColors.surface.withOpacity(0.7),
            padding: padding ?? AppSpacing.allLG,
            child: child,
          ),
        ),
      ),
    );
  }
}
