import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';
import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../design_system/spacing.dart';
import '../../design_system/animations.dart';
import '../../core/haptics/haptic_manager.dart';
import '../../models/food_item.dart';

/// Drag target sphere that accepts food items with magnetic attraction
class DragTargetSphere extends StatefulWidget {
  final void Function(FoodItem food, double weight)? onFoodAdded;
  final double size;
  
  const DragTargetSphere({
    super.key,
    this.onFoodAdded,
    this.size = 150,
  });

  @override
  State<DragTargetSphere> createState() => _DragTargetSphereState();
}

class _DragTargetSphereState extends State<DragTargetSphere>
    with TickerProviderStateMixin {
  bool _isAccepting = false;
  late AnimationController _pulseController;
  late AnimationController _absorptionController;
  late ConfettiController _confettiController;
  
  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _absorptionController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _confettiController = ConfettiController(
      duration: const Duration(milliseconds: 500),
    );
  }
  
  @override
  void dispose() {
    _pulseController.dispose();
    _absorptionController.dispose();
    _confettiController.dispose();
    super.dispose();
  }
  
  Future<void> _playAbsorptionAnimation() async {
    if (!mounted) return;
    
    _absorptionController.forward();
    _confettiController.play();
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Check if still mounted before resetting
    if (mounted && _absorptionController.status != AnimationStatus.dismissed) {
      _absorptionController.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Confetti explosion
        ConfettiWidget(
          confettiController: _confettiController,
          blastDirectionality: BlastDirectionality.explosive,
          particleDrag: 0.05,
          emissionFrequency: 0.05,
          numberOfParticles: 20,
          gravity: 0.3,
          colors: [
            AppColors.proteinNeon,
            AppColors.fatsNeon,
            AppColors.carbsNeon,
            AppColors.caloriesNeon,
            AppColors.primary,
          ],
        ),
        
        DragTarget<FoodItem>(
          onWillAcceptWithDetails: (details) {
            setState(() => _isAccepting = true);
            _pulseController.repeat(reverse: true);
            HapticManager.light(); // Magnetic snap feeling
            return true;
          },
          onLeave: (data) {
            setState(() => _isAccepting = false);
            _pulseController.stop();
            _pulseController.reset();
          },
          onAcceptWithDetails: (details) async {
            setState(() => _isAccepting = false);
            _pulseController.stop();
            _pulseController.reset();
            
            // Energy burst animation
            await _playAbsorptionAnimation();
            
            // Heavy haptic impact
            HapticManager.impact();
            
            // Callback to add food
            widget.onFoodAdded?.call(details.data, 100);
          },
          builder: (context, candidateData, rejectedData) {
            return AnimatedBuilder(
              animation: Listenable.merge([_pulseController, _absorptionController]),
              builder: (context, child) {
                final pulseScale = _isAccepting 
                    ? 1.0 + (_pulseController.value * 0.15)
                    : 1.0;
                final absorptionScale = 1.0 + (_absorptionController.value * 0.3);
                
                return Transform.scale(
                  scale: pulseScale * absorptionScale,
                  child: Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: _isAccepting
                            ? [
                                AppColors.primary,
                                AppColors.primary.withOpacity(0.5),
                                AppColors.primary.withOpacity(0.2),
                              ]
                            : [
                                AppColors.surface,
                                AppColors.surfaceVariant,
                                AppColors.backgroundSecondary,
                              ],
                        stops: const [0.3, 0.7, 1.0],
                      ),
                      boxShadow: _isAccepting
                          ? [
                              ...AppColors.getNeonGlow(AppColors.primary),
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.5),
                                blurRadius: 40,
                                spreadRadius: 10,
                              ),
                            ]
                          : AppColors.softShadow,
                      border: Border.all(
                        color: _isAccepting 
                            ? AppColors.primary 
                            : AppColors.glassBorder,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isAccepting 
                              ? Icons.add_circle 
                              : Icons.restaurant,
                          size: widget.size * 0.3,
                          color: _isAccepting 
                              ? AppColors.textPrimary 
                              : AppColors.textSecondary,
                        ),
                        SizedBox(height: AppSpacing.sm),
                        Text(
                          _isAccepting 
                              ? 'Отпустите' 
                              : 'Тарелка',
                          style: AppTypography.labelMedium.copyWith(
                            color: _isAccepting 
                                ? AppColors.textPrimary 
                                : AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
        
        // Magnetic field rings when accepting
        if (_isAccepting) ...[
          _buildMagneticRing(1.2, 0.3),
          _buildMagneticRing(1.4, 0.2),
          _buildMagneticRing(1.6, 0.1),
        ],
      ],
    );
  }
  
  Widget _buildMagneticRing(double scale, double opacity) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          final animatedScale = scale + (_pulseController.value * 0.1);
          final animatedOpacity = opacity * (1 - _pulseController.value * 0.5);
          
          return Transform.scale(
            scale: animatedScale,
            child: Opacity(
              opacity: animatedOpacity,
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary,
                    width: 1,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Wrapper to make any widget draggable as food item
class DraggableFoodItem extends StatelessWidget {
  final FoodItem foodItem;
  final Widget child;
  final VoidCallback? onDragStarted;
  final VoidCallback? onDragEnd;
  
  const DraggableFoodItem({
    super.key,
    required this.foodItem,
    required this.child,
    this.onDragStarted,
    this.onDragEnd,
  });

  @override
  Widget build(BuildContext context) {
    return LongPressDraggable<FoodItem>(
      data: foodItem,
      feedback: Material(
        borderRadius: AppSpacing.radiusLG,
        elevation: 12,
        shadowColor: AppColors.primary.withOpacity(0.5),
        child: Container(
          width: 200,
          padding: AppSpacing.allMD,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppSpacing.radiusLG,
            border: Border.all(
              color: AppColors.primary,
              width: 2,
            ),
            boxShadow: AppColors.getNeonGlow(AppColors.primary),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.restaurant,
                color: AppColors.primary,
              ),
              SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  foodItem.name,
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      )
          .animate(onPlay: (controller) => controller.repeat(reverse: true))
          .scale(
            begin: const Offset(1.0, 1.0),
            end: const Offset(1.05, 1.05),
            duration: const Duration(milliseconds: 500),
          ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: child,
      ),
      onDragStarted: () {
        HapticManager.medium();
        onDragStarted?.call();
      },
      onDragEnd: (details) {
        onDragEnd?.call();
      },
      child: child,
    );
  }
}
