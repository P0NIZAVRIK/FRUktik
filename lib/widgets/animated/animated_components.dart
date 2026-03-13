import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../design_system/animations.dart';

/// Spring-animated card with press effect
class SpringCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final List<BoxShadow>? boxShadow;
  final bool enabled;

  const SpringCard({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadius,
    this.backgroundColor,
    this.padding,
    this.margin,
    this.boxShadow,
    this.enabled = true,
  });

  @override
  State<SpringCard> createState() => _SpringCardState();
}

class _SpringCardState extends State<SpringCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.enabled && widget.onTap != null
          ? (_) => setState(() => _isPressed = true)
          : null,
      onTapUp: widget.enabled && widget.onTap != null
          ? (_) {
              setState(() => _isPressed = false);
              widget.onTap?.call();
            }
          : null,
      onTapCancel: widget.enabled && widget.onTap != null
          ? () => setState(() => _isPressed = false)
          : null,
      child: AnimatedScale(
        scale: _isPressed ? AppAnimations.pressedScale : 1.0,
        duration: AppAnimations.pressDuration,
        curve: AppAnimations.spring,
        child: AnimatedContainer(
          duration: AppAnimations.fast,
          padding: widget.padding,
          margin: widget.margin,
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: widget.borderRadius,
            boxShadow: widget.boxShadow,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

/// Hero wrapper for seamless transitions
class HeroWrapper extends StatelessWidget {
  final String tag;
  final Widget child;
  final bool enabled;

  const HeroWrapper({
    super.key,
    required this.tag,
    required this.child,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;

    return Hero(
      tag: tag,
      flightShuttleBuilder: (
        BuildContext flightContext,
        Animation<double> animation,
        HeroFlightDirection flightDirection,
        BuildContext fromHeroContext,
        BuildContext toHeroContext,
      ) {
        return ScaleTransition(
          scale: CurvedAnimation(
            parent: animation,
            curve: AppAnimations.spring,
          ),
          child: child,
        );
      },
      child: child,
    );
  }
}

/// Staggered list animation
class StaggeredList extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final Axis scrollDirection;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;

  const StaggeredList({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.scrollDirection = Axis.vertical,
    this.padding,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      scrollDirection: scrollDirection,
      padding: padding,
      physics: physics,
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return itemBuilder(context, index)
            .animate()
            .fadeIn(
              duration: AppAnimations.normal,
              delay: AppAnimations.getStaggerDelay(index),
              curve: AppAnimations.easeOut,
            )
            .slideY(
              begin: 0.2,
              end: 0,
              duration: AppAnimations.medium,
              delay: AppAnimations.getStaggerDelay(index),
              curve: AppAnimations.spring,
            );
      },
    );
  }
}

/// Animated counter for numbers
class AnimatedCounter extends StatelessWidget {
  final double value;
  final TextStyle? textStyle;
  final int decimals;
  final String? suffix;

  const AnimatedCounter({
    super.key,
    required this.value,
    this.textStyle,
    this.decimals = 0,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: AppAnimations.slow,
      curve: AppAnimations.easeOut,
      builder: (context, value, child) {
        final displayValue = decimals > 0
            ? value.toStringAsFixed(decimals)
            : value.toInt().toString();
        
        return Text(
          '$displayValue${suffix ?? ''}',
          style: textStyle,
        );
      },
    );
  }
}

/// Pulsing glow effect for important elements
class PulsingGlow extends StatelessWidget {
  final Widget child;
  final Color glowColor;
  final double glowRadius;

  const PulsingGlow({
    super.key,
    required this.child,
    required this.glowColor,
    this.glowRadius = 20,
  });

  @override
  Widget build(BuildContext context) {
    return child
        .animate(
          onPlay: (controller) => controller.repeat(),
        )
        .shimmer(
          duration: const Duration(milliseconds: 2000),
          color: glowColor,
        );
  }
}
