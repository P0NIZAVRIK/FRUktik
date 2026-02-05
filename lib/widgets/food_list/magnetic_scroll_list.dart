import 'package:flutter/material.dart';
import '../../design_system/colors.dart';
import '../../design_system/spacing.dart';
import '../../design_system/animations.dart';
import '../../core/haptics/haptic_manager.dart';

/// Magnetic scroll list with focus effects and haptic feedback
class MagneticScrollList<T> extends StatefulWidget {
  final List<T> items;
  final Widget Function(BuildContext context, T item, bool isFocused) itemBuilder;
  final double itemHeight;
  final ScrollController? controller;
  final EdgeInsets? padding;
  
  const MagneticScrollList({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.itemHeight = 120,
    this.controller,
    this.padding,
  });

  @override
  State<MagneticScrollList<T>> createState() => _MagneticScrollListState<T>();
}

class _MagneticScrollListState<T> extends State<MagneticScrollList<T>> {
  late ScrollController _scrollController;
  int _focusedIndex = 0;
  
  @override
  void initState() {
    super.initState();
    _scrollController = widget.controller ?? ScrollController();
    _scrollController.addListener(_onScroll);
  }
  
  @override
  void dispose() {
    if (widget.controller == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }
  
  void _onScroll() {
    if (!mounted) return;
    
    final offset = _scrollController.offset;
    final viewportHeight = _scrollController.position.viewportDimension;
    final centerOffset = offset + (viewportHeight / 2) - (widget.itemHeight / 2);
    final newFocusedIndex = (centerOffset / widget.itemHeight).round().clamp(0, widget.items.length - 1);
    
    if (newFocusedIndex != _focusedIndex) {
      setState(() => _focusedIndex = newFocusedIndex);
      HapticManager.selection(); // Subtle tick on focus change
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      padding: widget.padding ?? AppSpacing.allMD,
      physics: const BouncingScrollPhysics(),
      itemCount: widget.items.length,
      itemBuilder: (context, index) {
        final isFocused = index == _focusedIndex;
        final distance = (index - _focusedIndex).abs();
        
        // Calculate scale and opacity based on distance from center
        final scale = isFocused 
            ? 1.05 
            : (1.0 - distance * 0.05).clamp(0.85, 1.0);
        final opacity = isFocused 
            ? 1.0 
            : (1.0 - distance * 0.15).clamp(0.4, 1.0);
        
        return AnimatedContainer(
          duration: AppAnimations.fast,
          curve: AppAnimations.easeOut,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001) // Perspective
            ..scale(scale),
          transformAlignment: Alignment.center,
          child: AnimatedOpacity(
            duration: AppAnimations.fast,
            opacity: opacity,
            child: Container(
              height: widget.itemHeight,
              margin: EdgeInsets.symmetric(vertical: AppSpacing.xs),
              decoration: isFocused 
                  ? BoxDecoration(
                      borderRadius: AppSpacing.radiusLG,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    )
                  : null,
              child: widget.itemBuilder(context, widget.items[index], isFocused),
            ),
          ),
        );
      },
    );
  }
}
